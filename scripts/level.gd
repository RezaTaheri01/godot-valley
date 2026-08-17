extends Node2D


#region Variables
# ============================================================
# SIGNALS
# ============================================================

signal delete_machine(coord: Vector2i)
signal update_hint_ui_keys


# ============================================================
# NODE REFERENCES
# ============================================================

@onready var player: CharacterBody2D = $Objects/Player

# World
@onready var water_grass_layer: TileMapLayer = $Layers/WaterGrassLayer
@onready var soil_layer: TileMapLayer = $Layers/SoilLayer
@onready var wet_soil_layer: TileMapLayer = $Layers/WetSoilLayer
@onready var target_layer: TileMapLayer = $Layers/TargetLayer

# Objects
@onready var objects_container: Node2D = $Objects
@onready var machines_container: Node2D = $Objects/Machines
@onready var enemies_container: Node2D = $Objects/Enemies
@onready var house = $Objects/House

# UI
@onready var machine_preview: Sprite2D = $Overlay/PreviewMachineSprite2D
@onready var plant_info_control = $Overlay/CanvasLayer/PlantInfoControl
@onready var shop_ui = $Overlay/CanvasLayer/ShopUI
@onready var day_transition_material = (
	$Overlay/CanvasLayer/DayTransitionLayer.material
)

# Day / Weather
@onready var day_timer: Timer = $Timers/DayTimer
@onready var rain_floor_particles = $Layers/RainFloorsParticles
@onready var rain_particles = $Overlay/RainParticles2D
@onready var rain_sound = $Sounds/Rain
@onready var background_music = $Sounds/BG

# Enemy spawning
@onready var blob_spawn_positions: Node2D = $BlobSpawnPositions


# ============================================================
# PRELOADED SCENES
# ============================================================

const PROJECTILE_SCENE: PackedScene = preload(
	"res://scenes/machines/projectile.tscn"
)

const PLANT_SCENE: PackedScene = preload(
	"res://scenes/objects/plant.tscn"
)

const PLANT_INFO_SCENE: PackedScene = preload(
	"res://scenes/ui/plant_info.tscn"
)

const BLOB_SCENE: PackedScene = preload(
	"res://scenes/characters/blob_enemy.tscn"
)


# ============================================================
# TILE HIGHLIGHT
# ============================================================

# Coordinates of highlight tiles in the tileset.
const TARGET_HIGHLIGHT_GREEN := Vector2i(12, 1)
const TARGET_HIGHLIGHT_RED := Vector2i(1, 1)

var last_dir: Vector2


# ============================================================
# MACHINE STATE
# ============================================================

var machine_coord: Vector2
var machine_cells: Array[Vector2i]
var machine_counter = {
	Enum.Machine.SCARECROW: 0,
	Enum.Machine.SPRINKLER: 0,
	Enum.Machine.FISHER: 0,
}


# ============================================================
# PLANT STATE
# ============================================================

var planted_cells: Array[Vector2i]


# ============================================================
# DAY / WEATHER
# ============================================================

@export var daytimer_color: Gradient
@export var rain_color: Color
@export var volume_curve: Curve

var _raining := false

# Controls all rain-related effects through a single property.
# Changing this value updates the rain particles and audio.
var raining: bool:
	get:
		return _raining
	set(value):
		_raining = value

		rain_floor_particles.emitting = value
		rain_particles.emitting = value
		rain_sound.playing = value
#endregion
	
		
#region Ready			
# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	_initialize_weather()
	_initialize_day_night()
	_connect_shop_characters()
	_initialize_controller()


# ============================================================
# WEATHER
# ============================================================

# Generates the first weather forecast and applies the current
# weather to the world.
func _initialize_weather() -> void:
	Data.forecast_rain = [true, false].pick_random()

	if raining:
		_water_soils()


# ============================================================
# DAY / NIGHT
# ============================================================

# Configures the scene's darkness overlay.
func _initialize_day_night() -> void:
	var canvas_modulate := CanvasModulate.new()
	canvas_modulate.color = Color(0.1, 0.1, 0.15)

	add_child(canvas_modulate)


# ============================================================
# SHOP CHARACTERS
# ============================================================

# Connects all shop characters to the shop-opening handler.
func _connect_shop_characters() -> void:
	for character in get_tree().get_nodes_in_group("ShopCharacters"):
		character.connect("open_shop", open_shop)


# ============================================================
# CONTROLLER
# ============================================================

# Initializes controller detection and listens for future
# controller connection/disconnection events.
func _initialize_controller() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

	Data.controller_connected = Input.get_connected_joypads().size() > 0

#endregion


#region Main Loop
# ============================================================
# MAIN LOOP
# ============================================================

func _process(_delta: float) -> void:
	_update_day_and_weather()
	_update_target_highlight()
	_update_machine_preview()


# ============================================================
# DAY / WEATHER
# ============================================================

# Updates the environment visuals and background music based
# on the current position in the day/night cycle.
func _update_day_and_weather() -> void:
	var daytime_point := _get_daytime_point()
	var color := daytimer_color.sample(daytime_point)
	var volume := volume_curve.sample(daytime_point)

	$Sounds/BG.volume_db = volume

	if raining:
		color = color.lerp(rain_color, 1.0 - daytime_point)

	$Overlay/CanvasModulate.color = color


# Returns the current progress through the day/night cycle.
# 0.0 = start of the cycle, 1.0 = end of the cycle.
func _get_daytime_point() -> float:
	var timer: Timer = $Timers/DayTimer

	return 1.0 - (timer.time_left / timer.wait_time)


# ============================================================
# TARGET HIGHLIGHT
# ============================================================

# Updates or clears the target tile highlight based on the
# current target-highlighter setting.
func _update_target_highlight() -> void:
	if Data.target_highlighter:
		update_target_highlight()
	else:
		$Layers/TargetLayer.clear()


# ============================================================
# MACHINE PREVIEW
# ============================================================

# Updates the machine preview while the player is in building mode.
func _update_machine_preview() -> void:
	machine_preview.modulate = (
		Data.REACH_LIMIT_COLOR
		if _reach_machine_limit(player.current_machine)
		else Data.NO_LIMIT_COLOR
	)
	
	machine_preview.visible = player.current_state == Enum.State.BUILDING

	if player.animation_direction == Vector2.ZERO:
		return

	machine_coord = get_target_grid(
		player.position,
		player.animation_direction
	)

	machine_preview.position = (
		Vector2i(machine_coord * Data.TILE_SIZE)
		+ Data.MACHINE_PREVIEW_TEXTURES[player.current_machine]["offset"]
	)
#endregion


#region Day Restart
# ============================================================
# DAY / NIGHT CYCLE
# ============================================================

# Starts the transition to the next day when the player triggers
# a day change.
func _on_player_day_change() -> void:
	_start_day_transition()


# Plays the day-transition animation and resets the level
# once the screen is fully covered.
func _start_day_transition() -> void:
	var tween := create_tween()

	tween.tween_property(
		day_transition_material,
		"shader_parameter/progress",
		1.0,
		1.0
	)
	tween.tween_interval(0.5)
	tween.tween_callback(_reset_for_new_day)
	tween.tween_property(
		day_transition_material,
		"shader_parameter/progress",
		0.0,
		1.0
	)


# ============================================================
# NEW DAY RESET
# ============================================================

# Resets all systems that change when a new day begins.
func _reset_for_new_day() -> void:
	_update_plants()
	_reset_soil()
	_update_trees()
	_update_weather()

	day_timer.start()


# ============================================================
# PLANTS
# ============================================================

# Grows plants that are currently planted in wet soil.
func _update_plants() -> void:
	var wet_soil_cells := wet_soil_layer.get_used_cells()

	for plant: StaticBody2D in get_tree().get_nodes_in_group("Plants"):
		plant.grow(plant.coord in wet_soil_cells)


# ============================================================
# SOIL
# ============================================================

# Clears all wet-soil cells at the beginning of a new day.
func _reset_soil() -> void:
	wet_soil_layer.clear()


# Waters all existing soil cells.
func _water_soils() -> void:
	for cell in soil_layer.get_used_cells():
		_water_soil(cell)


# ============================================================
# TREES
# ============================================================

# Gives trees a chance to create a new apple.
func _update_trees() -> void:
	for object in get_tree().get_nodes_in_group("Objects"):
		# Trees have a 50% chance of keeping their current apple state.
		if not object.is_in_group("Tree") or [false, true].pick_random():
			continue

		object.create_apple()


# ============================================================
# WEATHER
# ============================================================

# Applies today's forecast and generates tomorrow's forecast.
func _update_weather() -> void:
	raining = Data.forecast_rain
	Data.forecast_rain = [true, false].pick_random()

	print(
		"Tomorrow will rain"
		if Data.forecast_rain
		else
		"Tomorrow is sunny"
	)

	if raining:
		_water_soils()
#endregion


#region Tool Use

# ============================================================
# TOOL USE
# ============================================================

# Handles the player's tool action at the targeted grid position.
# Tool-specific behavior is delegated to dedicated functions.
func _on_player_tool_use(tool: Enum.Tool, pos: Vector2, dir: Vector2) -> void:
	var grid_coord := get_target_grid(pos, dir)

	# Machines occupy their cells and cannot be interacted with.
	if grid_coord in machine_cells:
		return

	match tool:
		Enum.Tool.HOE:
			_use_hoe(grid_coord)

		Enum.Tool.WATER:
			_use_water(grid_coord)

		Enum.Tool.FISH:
			_start_fishing()

		Enum.Tool.SEED:
			_plant_seed(grid_coord)

		Enum.Tool.AXE:
			_hit_nearby_objects(
				"Axe_able",
				tool,
				pos,
				dir,
				22.0
			)

		Enum.Tool.SWORD:
			_hit_nearby_objects(
				"Sword_able",
				tool,
				pos,
				dir,
				26.0
			)


# ============================================================
# FARMING
# ============================================================

# Tills the targeted cell and wets it immediately if it is raining.
func _use_hoe(grid_coord: Vector2i) -> void:
	soil_layer.set_cells_terrain_connect(
		[grid_coord],
		0,
		1
	)

	if raining:
		_water_soil(grid_coord)


# Waters the targeted soil cell.
func _use_water(grid_coord: Vector2i) -> void:
	_water_soil(grid_coord)


# Waters a single soil cell.
func _water_soil(cell: Vector2i) -> void:
	wet_soil_layer.set_cell(
		cell,
		0,
		Vector2i(randi_range(0, 2), 0)
	)


# ============================================================
# FISHING
# ============================================================

# Starts fishing from the player's current position.
func _start_fishing() -> void:
	player.start_fishing()


# ============================================================
# PLANTING
# ============================================================

# Attempts to plant the currently selected seed.
func _plant_seed(grid_coord: Vector2i) -> void:
	var item_id = Data.SEED_TO_ITEM[player.current_seed]
	var seed_amount = Data.items_amount[Data.difficulty][item_id]

	if seed_amount <= 0:
		return

	Data.items_amount[Data.difficulty][item_id] -= 1

	var plant_res := PlantResource.new()
	plant_res.setup(player.current_seed)

	var plant = PLANT_SCENE.instantiate()

	_create_plant_info(plant_res, plant)
	_setup_plant(plant, grid_coord, plant_res)

	planted_cells.append(grid_coord)


# Creates and displays the plant information UI.
func _create_plant_info(
	plant_res: PlantResource,
	plant: Node
) -> void:
	var plant_info = PLANT_INFO_SCENE.instantiate()
	plant_info.setup(plant_res)

	plant_info_control.add(plant_info)

	plant.set_meta("plant_info", plant_info)


# Configures the newly planted plant.
func _setup_plant(
	plant: Node,
	grid_coord: Vector2i,
	plant_res: PlantResource
) -> void:
	var plant_info = plant.get_meta("plant_info")

	plant.setup(
		grid_coord,
		objects_container,
		plant_res,
		plant_info,
		plant_death,
		plant_harvest
	)


# ============================================================
# COMBAT / OBJECT INTERACTION
# ============================================================

# Finds objects within range and in front of the player,
# then applies the selected tool action to them.
func _hit_nearby_objects(
	group_name: StringName,
	tool: Enum.Tool,
	pos: Vector2,
	dir: Vector2,
	hit_range: float
) -> void:
	for object in get_tree().get_nodes_in_group(group_name):
		var to_object: Vector2 = object.position - pos

		if to_object.length() >= hit_range:
			continue

		var to_object_dir := to_object.normalized()

		# Dot product determines whether the object is in front
		# of the player and sufficiently aligned with the attack.
		if dir.dot(to_object_dir) > 0.65:
			object.hit(tool, dir)


# Toggles the plant information panel.
func _on_player_diagnose() -> void:
	plant_info_control.hide_show_ui()
#endregion


#region Tool Validation
# ============================================================
# TOOL VALIDATION
# ============================================================

# Determines whether the selected tool can be used at the
# specified grid cell.
func is_tool_valid(tool: Enum.Tool, grid_coord: Vector2i) -> bool:
	if house.is_point_inside_house(grid_coord):
		return false

	var tile_data = water_grass_layer.get_cell_tile_data(grid_coord)

	if tile_data == null:
		return false

	var is_water: bool = tile_data.get_custom_data("water")
	var is_farmable: bool = tile_data.get_custom_data("farmable")
	var has_soil := soil_layer.get_cell_source_id(grid_coord) != -1

	match tool:
		Enum.Tool.HOE:
			return (
				not is_water
				and is_farmable
				and not is_object_near_cell(grid_coord)
			)

		Enum.Tool.WATER:
			return has_soil

		Enum.Tool.FISH:
			return is_water

		Enum.Tool.SEED:
			return has_soil and grid_coord not in planted_cells

		Enum.Tool.AXE, Enum.Tool.SWORD:
			return true

	return false


func is_object_near_cell(grid_coord: Vector2i) -> bool:
	for object in get_tree().get_nodes_in_group("Objects"):
		var object_pos := Vector2i(
			floor(object.position.x / Data.TILE_SIZE),
			floor(object.position.y / Data.TILE_SIZE)
		)
		
		# Check if it's a Tree (3x3 bottom center footprint)
		if object.is_in_group("Tree"):
			# 3x3 footprint with pivot at bottom center
			# Spans rows object_pos.y-2 to object_pos.y
			# and columns object_pos.x-1 to object_pos.x+1
			if grid_coord.x >= object_pos.x - 1 \
			and grid_coord.x <= object_pos.x + 1 \
			and grid_coord.y >= object_pos.y - 2 \
			and grid_coord.y <= object_pos.y:
				return true
		else:
			# All other objects: 2x2 top-left footprint
			if grid_coord.x >= object_pos.x \
			and grid_coord.x <= object_pos.x + 1 \
			and grid_coord.y >= object_pos.y \
			and grid_coord.y <= object_pos.y + 1:
				return true
	
	return false
	

# =========================================================
# GRID CALCULATION
# =========================================================
func get_target_grid(pos: Vector2, dir: Vector2) -> Vector2i:
	if dir != Vector2.ZERO:
		last_dir = dir
	else:
		dir = last_dir
	var base_cell = Vector2i(floor(pos.x / Data.TILE_SIZE), floor(pos.y / Data.TILE_SIZE))
	return base_cell + Vector2i(dir)
#endregion


#region Build
# ============================================================
# MACHINE BUILDING
# ============================================================

# Builds the selected machine or deletes the machine at the
# current target position.
func _on_player_build(curr_machine: int) -> void:
	if _reach_machine_limit(curr_machine):
		return
	
	if house.is_point_inside_house(machine_coord):
		return

	if curr_machine == Enum.Machine.DELETE:
		_delete_machine()
		return

	if not _can_build_machine(machine_coord):
		return

	_build_machine(curr_machine)
	
	
	
# ============================================================
# MACHINE VALIDATION
# ============================================================

# Determines whether a machine can be placed at the target cell.
func _can_build_machine(grid_coord: Vector2i) -> bool:
	if _is_cell_occupied(grid_coord):
		return false

	if grid_coord in planted_cells:
		return false

	var tile_data = water_grass_layer.get_cell_tile_data(grid_coord)

	if tile_data == null:
		return false

	return not tile_data.get_custom_data("water")


# Checks whether the target cell is occupied by an existing
# object or machine.
func _is_cell_occupied(grid_coord: Vector2i) -> bool:
	return (
		is_object_near_cell(grid_coord)
		or grid_coord in machine_cells
	)
	
	
func _reach_machine_limit(curr_machine: int) -> bool:
	if curr_machine == Enum.Machine.DELETE:
		# No Limit For Delete
		return false
		

	var machine_max = Data.get_level_value(
		Data.MACHINE_LIMIT[Data.difficulty][curr_machine],
		Data.player_level
	)

	var machine_count = machine_counter[curr_machine]
	
	return not machine_count < machine_max
		
# ============================================================
# MACHINE CREATION
# ============================================================

# Creates and initializes the selected machine.
func _build_machine(curr_machine: int) -> void:
	var machine = Data.MACHINE_SCENE[curr_machine]["scene"].instantiate()

	delete_machine.connect(machine.delete)
	machine.machine_deleted.connect(update_machine_count_after_delete)

	var result = machine.setup(
		machine_coord,
		self,
		machines_container,
		curr_machine
	)
	
	if result:
		machine_counter[curr_machine] += 1
		machine_cells.append(machine_coord)
	
	
# ============================================================
# MACHINE DELETION
# ============================================================

# Requests deletion of the machine at the current target cell.
func _delete_machine() -> void:
	if machine_coord not in machine_cells:
		return

	delete_machine.emit(machine_coord)
	machine_cells.erase(machine_coord)
	

func update_machine_count_after_delete(curr_machine: int):
	machine_counter[curr_machine] = max(0, machine_counter[curr_machine] - 1)
	
#endregion
	
	
# ============================================================
# PROJECTILES
# ============================================================

# Creates and initializes a projectile using the current
# difficulty and scarecrow level.
func create_projectile(start_pos: Vector2, dir: Vector2) -> void:
	var projectile_speed: float = Data.get_level_value(
		 Data.PROJECTILE_SPEED[Data.difficulty],
		 Data.player_level
	)

	var projectile = PROJECTILE_SCENE.instantiate()

	objects_container.add_child(projectile)
	projectile.setup(start_pos, dir, projectile_speed)

	
# Updates the machine preview texture when the selected machine changes.
func _on_player_change_machine(curr_machine: int) -> void:
	machine_preview.texture = Data.MACHINE_PREVIEW_TEXTURES[curr_machine]["texture"]


# Waters all soil cells within the sprinkler's 3x3 area.
func _water_near_soils(sprinkler_coord: Vector2i) -> void:
	for x in range(-1, 2):
		for y in range(-1, 2):
			var cell := sprinkler_coord + Vector2i(x, y)

			if soil_layer.get_cell_source_id(cell) != -1:
				_water_soil(cell)


# ============================================================
# TARGET HIGHLIGHT
# ============================================================

# Updates the target tile highlight based on the player's
# current tool and facing direction.
func update_target_highlight() -> void:
	var grid_coord := get_target_grid(
		player.position,
		player.animation_direction
	)

	target_layer.clear()

	if is_tool_valid(player.current_tool, grid_coord):
		target_layer.set_cell(
			grid_coord,
			0,
			TARGET_HIGHLIGHT_GREEN
		)
	else:
		target_layer.set_cell(
			grid_coord,
			0,
			TARGET_HIGHLIGHT_RED
		)


# ============================================================
# PLANT CALLBACKS
# ============================================================

# Removes a plant from the tracked cells when it dies.
func plant_death(coord: Vector2i) -> void:
	_remove_planted_cell(coord)


# Removes a plant from the tracked cells when it is harvested.
func plant_harvest(coord: Vector2i) -> void:
	_remove_planted_cell(coord)


# Removes a plant from the list of currently planted cells.
func _remove_planted_cell(coord: Vector2i) -> void:
	planted_cells.erase(coord)


# ============================================================
# TOOL ANIMATION
# ============================================================

# Triggers the tool animation only when the targeted cell
# is valid for the selected tool.
func _on_player_do_action(
	anim_tree: AnimationTree,
	property: StringName,
	tool: int,
	pos: Vector2,
	dir: Vector2
) -> void:
	var grid_coord := get_target_grid(pos, dir)

	if not is_tool_valid(tool, grid_coord):
		return

	anim_tree.set(
		property,
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	)


# ============================================================
# BLOB SPAWNING
# ============================================================

# Spawns a blob that targets a random plant.
func _on_blob_timer_timeout() -> void:
	var plants := get_tree().get_nodes_in_group("Plants")

	if plants.is_empty():
		return

	var spawn_points := blob_spawn_positions.get_children()
	var start_pos = spawn_points.pick_random().position
	var target_plant = plants.pick_random()

	var blob = BLOB_SCENE.instantiate()
	blob.setup(
		start_pos,
		enemies_container,
		target_plant
	)


# ============================================================
# SHOP
# ============================================================

# Opens the shop UI and switches the player to the shop state.
func open_shop(shop_type: Enum.Shop) -> void:
	shop_ui.reveal(shop_type)
	player.current_state = Enum.State.SHOP


# Closes the shop UI, clears its items, and restores player control.
func _on_player_close_shop() -> void:
	shop_ui.hide()
	shop_ui.remove_items()
	player.current_state = Enum.State.DEFAULT


# ============================================================
# CONTROLLER
# ============================================================

# Updates the controller state when a device is connected
# or disconnected.
func _on_joy_connection_changed(
	device_id: int,
	connected: bool
) -> void:
	Data.controller_connected = connected
	update_hint_ui_keys.emit()

	_log_controller_connection(device_id, connected)


# Logs controller connection details for debugging.
func _log_controller_connection(
	device_id: int,
	connected: bool
) -> void:
	if not connected:
		print("Controller ", device_id, " disconnected!")
		return

	var controller_name := Input.get_joy_name(device_id)
	var controller_guid := Input.get_joy_guid(device_id)

	print("Controller ", device_id, " connected!")
	print("Controller name: ", controller_name)
	print("GUID: ", controller_guid)
