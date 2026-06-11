extends Node2D

@onready var player: CharacterBody2D = $Objects/Player

@onready var waterGrassLayer := $Layers/WaterGrassLayer

var projectile_scene = preload("res://scenes/machines/projectile.tscn")
var machine_coord: Vector2 
var machine_cells: Array[Vector2i]
signal delete_machine(coord: Vector2i)


# Refer to a tileset
const target_highlight_green: Vector2i = Vector2i(12, 1)
const target_highlight_red: Vector2i = Vector2i(1, 1)

# Plant
var plant_scene = preload("res://scenes/objects/plant.tscn")
var planted_cells: Array[Vector2i]
var plant_info_scene = preload("res://scenes/ui/plant_info.tscn")
var blob_scene = preload("res://scenes/characters/blob_enemy.tscn")


# Day and Weather
@onready var day_transition_material = $Overlay/CanvasLayer/DayTransitionLayer.material
@export var daytimer_color: Gradient
@export var rain_color: Color
var raining: bool = false:
	set(value):
		raining = value
		$Layers/RainFloorsParticles.emitting = value
		$Overlay/RainParticles2D.emitting = value
		
signal update_hint_ui_keys
		
func _process(_delta):
	var daytime_point = 1 - ($Timers/DayTimer.time_left / $Timers/DayTimer.wait_time)
	var color = daytimer_color.sample(daytime_point)
	
	if raining:
		color = color.lerp(rain_color, 1 - daytime_point)
	$Overlay/CanvasModulate.color = color
	
	if Data.TARGET_HIGHLIGHTER:
		update_target_highlight()
	else:
		$Layers/TargetLayer.clear()
		
	$Overlay/PreviewMachineSprite2D.visible = player.current_state == Enum.State.BUILDING
	if player.animation_direction != Vector2.ZERO:
		machine_coord = get_target_grid(player.position, player.animation_direction)
		$Overlay/PreviewMachineSprite2D.position = (Vector2i(machine_coord * Data.TILE_SIZE) +
					 					Data.MACHINE_PREVIEW_TEXTURES[player.current_machine]["offset"])


# =========================================================
# Todo: Disable keys during day restart
# Day Night Cycle
# =========================================================
func _on_player_day_change() -> void:
	day_restart()


func day_restart():
	var tween = create_tween()
	
	tween.tween_property(day_transition_material, "shader_parameter/progress", 1.0, 1.0)
	tween.tween_interval(0.5)
	tween.tween_callback(level_reset)
	tween.tween_property(day_transition_material, "shader_parameter/progress", 0.0, 1.0)


func level_reset():
	for plant: StaticBody2D in get_tree().get_nodes_in_group("Plants"):
		plant.grow(plant.coord in $Layers/WetSoilLayer.get_used_cells())
			
	$Timers/DayTimer.start()
	$Layers/WetSoilLayer.clear()
	
	for object in get_tree().get_nodes_in_group("Objects"):
		# 50% that apples number not changing
		if not object.is_in_group("Tree") or [false, true].pick_random():
			continue
			
			
		object.create_apple()

	raining = Data.FORECAST_RAIN
	Data.FORECAST_RAIN = [true, false].pick_random()
	print("Tommorw will rain" if Data.FORECAST_RAIN else "Tommorow is sunny")
	
	if raining:
		waterSoils()


func waterSoils():
	for cell in $Layers/SoilLayer.get_used_cells():
		$Layers/WetSoilLayer.set_cell(
				cell,
				0,
				Vector2i(randi_range(0, 2), 0)
			)


# =========================================================
# TOOL USE
# =========================================================
func _on_player_tool_use(tool: Enum.Tool, pos: Vector2, dir: Vector2) -> void:
	var grid_coord: Vector2i = get_target_grid(pos, dir)

	if grid_coord in machine_cells:
		return
	# already checked in _on_player_do_action
	#if not is_tool_valid(tool, grid_coord):
		#return

	match tool:
		Enum.Tool.HOE:
			#$Layers/SoilLayer.set_cells_terrain_connect([grid_coord], 0, 0)
			$Layers/SoilLayer.set_cells_terrain_connect([grid_coord], 0, 1)	
			if raining:
				$Layers/WetSoilLayer.set_cell(
					grid_coord,
					0,
					Vector2i(randi_range(0, 2), 0)
				)

		Enum.Tool.WATER:
			$Layers/WetSoilLayer.set_cell(
				grid_coord,
				0,
				Vector2i(randi_range(0, 2), 0)
			)

		Enum.Tool.FISH:
			$Objects/Player.start_fishing()
			
		Enum.Tool.SEED:			
			if Data.ITEMS_AMOUNT[Data.SEED_TO_ITEM[%Player.current_seed]] <= 0:
				return
			else:
				Data.ITEMS_AMOUNT[Data.SEED_TO_ITEM[%Player.current_seed]] -= 1
					
			var plant_res = PlantResource.new()
			plant_res.setup(%Player.current_seed)
			var plant := plant_scene.instantiate()
			
			# Plant Info
			var plant_info = plant_info_scene.instantiate()
			plant_info.setup(plant_res)
			$Overlay/CanvasLayer/PlantInfoControl.add(plant_info)
			
			plant.setup(grid_coord, $Objects, plant_res, plant_info,
						 plant_death, plant_harvest)
			planted_cells.append(grid_coord)
		Enum.Tool.AXE:
			for object in get_tree().get_nodes_in_group("Axe_able"):
				var to_object = (object.position - pos)
	
				if to_object.length() < 22:
					var to_object_dir = to_object.normalized()
					
					# dot > 0 means in front, closer to 1 means more aligned
					if dir.dot(to_object_dir) > 0.65:
						object.hit(tool, dir)
		Enum.Tool.SWORD:
			for object in get_tree().get_nodes_in_group("Sword_able"):
				var to_object = (object.position - pos)
	
				if to_object.length() < 26:
					var to_object_dir = to_object.normalized()
					
					# dot > 0 means in front, closer to 1 means more aligned
					if dir.dot(to_object_dir) > 0.65:
						object.hit(tool, dir)


func _on_player_diagnose() -> void:
	$Overlay/CanvasLayer/PlantInfoControl.visible = not $Overlay/CanvasLayer/PlantInfoControl.visible 


func _ready() -> void:
	Data.FORECAST_RAIN = [true, false].pick_random()
	if raining:
		waterSoils()
		
	# Add CanvasModulate for darkness
	var canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = Color(0.1, 0.1, 0.15)
	add_child(canvas_modulate)
	
	#$Objects/ScareCrow.connect("shoot_projectile", create_projectile)
	for character in get_tree().get_nodes_in_group("ShopCharacters"):
		character.connect("open_shop", open_shop)
		
	# Connect to device connection signals
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	
	if Input.get_connected_joypads().size() > 0:
		print("True")
		Data.ControllerConnected = true

# Projectile
func create_projectile(start_pos: Vector2, dir: Vector2):
	var projectile = projectile_scene.instantiate()
	$Objects.add_child(projectile)
	projectile.setup(start_pos, dir)


func _on_player_build(curr_machine: int) -> void:
	if $Objects/House.is_point_inside_house(machine_coord):
		return
	
	if curr_machine != Enum.Machine.DELETE:
		if is_object_near_cell(machine_coord):
			return
			
		if machine_coord in machine_cells:
			return
			
		if machine_coord in planted_cells:
			return
		
		var cell = $Layers/WaterGrassLayer.get_cell_tile_data(machine_coord)
		if cell.get_custom_data("water"):
			return
		
		var machine = Data.MACHINE_SCENE[curr_machine]["scene"].instantiate()
		self.connect("delete_machine", machine.delete)
		machine.setup(machine_coord, self, $Objects/Machines)
		machine_cells.append(machine_coord)
	else:
		if machine_coord in machine_cells:
			delete_machine.emit(machine_coord)
			machine_cells.erase(machine_coord)
	
		
func _on_player_change_machine(curr_machine: int) -> void:
	var machine_texture = Data.MACHINE_PREVIEW_TEXTURES[curr_machine]["texture"]
	$Overlay/PreviewMachineSprite2D.texture = machine_texture


func water_near_soils(sprinkler_coord: Vector2i):
	# Check the 3x3 area around the sprinkler
	for x in range(-1, 2):  # -1, 0, 1
		for y in range(-1, 2):  # -1, 0, 1
			var check_coord = Vector2i(sprinkler_coord.x + x, sprinkler_coord.y + y)
			
			# Check if this cell has soil
			var has_soil = $Layers/SoilLayer.get_cell_source_id(check_coord) != -1
			
			if has_soil:				
				# Add wet soil to WetSoilLayer
				$Layers/WetSoilLayer.set_cell(check_coord, 0, Vector2i(randi_range(0, 2), 0)
			)


# =========================================================
# TARGET HIGHLIGHT
# =========================================================
func update_target_highlight():
	var dir = player.animation_direction

	if dir == Vector2.ZERO:
		$Layers/TargetLayer.clear()
		return

	var grid_coord: Vector2i = get_target_grid(player.position, dir)

	$Layers/TargetLayer.clear()
	
	if is_tool_valid(player.current_tool, grid_coord):
		$Layers/TargetLayer.set_cell(grid_coord, 0, target_highlight_green)
	else:
		$Layers/TargetLayer.set_cell(grid_coord, 0, target_highlight_red)


# =========================================================
# VALIDATION (Single Terrain Authority)
# =========================================================
func is_tool_valid(tool: Enum.Tool, grid_coord: Vector2i) -> bool:
	if $Objects/House.is_point_inside_house(grid_coord):
		return false
		
	var cell = $Layers/WaterGrassLayer.get_cell_tile_data(grid_coord)

	if not cell:
		return false

	var is_water = cell.get_custom_data("water")
	var is_farmable = cell.get_custom_data("farmable")
	var has_soil = $Layers/SoilLayer.get_cell_source_id(grid_coord) != -1

	match tool:

		Enum.Tool.HOE:
			if is_water or not is_farmable:
				return false

			if is_object_near_cell(grid_coord):
				return false

			return true

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
		#if not object.is_in_group("Tree"):
			#continue

		# Tree top-left tile
		var object_top_left := Vector2i(
			floor(object.position.x / Data.TILE_SIZE),
			floor(object.position.y / Data.TILE_SIZE)
		)

		# Exact 2x2 footprint (4 tiles)
		if grid_coord.x >= object_top_left.x \
		and grid_coord.x <= object_top_left.x + 1 \
		and grid_coord.y >= object_top_left.y \
		and grid_coord.y <= object_top_left.y + 1:
			return true

	return false


# =========================================================
# GRID CALCULATION
# =========================================================
func get_target_grid(pos: Vector2, dir: Vector2) -> Vector2i:
	var base_cell = Vector2i(floor(pos.x / Data.TILE_SIZE), floor(pos.y / Data.TILE_SIZE))
	return base_cell + Vector2i(dir)


# =========================================================
# Signal Func for Plant Death and Harvest
func plant_death(coord: Vector2i):
	planted_cells.erase(coord)
	
	
func plant_harvest(coord: Vector2i):
	planted_cells.erase(coord)


# Tools animation
func _on_player_do_action(anim_tree: AnimationTree, property: StringName, tool: int, pos: Vector2, dir: Vector2) -> void:
	if is_tool_valid(tool, get_target_grid(pos, dir)):
		anim_tree.set(property, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _on_blob_timer_timeout() -> void:
	var plants = get_tree().get_nodes_in_group("Plants")
	var spawn_points = $BlobSpawnPositions.get_children()
	
	if plants:
		var start_pos = spawn_points.pick_random().position
		var target_plant = plants.pick_random()
		var blob = blob_scene.instantiate()
		blob.setup(start_pos,$Objects/Enemies, target_plant)


func open_shop(shop_type: Enum.Shop):
	$Overlay/CanvasLayer/ShopUI.reveal(shop_type)
	player.current_state = Enum.State.SHOP


func _on_player_close_shop() -> void:
	$Overlay/CanvasLayer/ShopUI.hide()
	$Overlay/CanvasLayer/ShopUI.remove_items()
	player.current_state = Enum.State.DEFAULT


func _on_joy_connection_changed(device_id: int, connected: bool):
	update_hint_ui_keys.emit()
	if connected:
		Data.ControllerConnected = true
		print("Controller ", device_id, " connected!")
		var controller_name = Input.get_joy_name(device_id)
		print("Controller name: ", controller_name)
		var controller_guid = Input.get_joy_guid(device_id)
		print("GUID: ", controller_guid)
	else:
		Data.ControllerConnected = false
		print("Controller ", device_id, " disconnected!")
