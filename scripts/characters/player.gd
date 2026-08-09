extends CharacterBody2D

# ============================================================
# Debug
# ============================================================

var debug: bool = true


# ============================================================
# Movement
# ============================================================

var speed: float = Data.PLAYER_SPEED[Data.difficulty]

var direction: Vector2
var animation_direction: Vector2 = Vector2.DOWN

var can_move: bool = true
var can_interact: bool = false
var last_interactable


# ============================================================
# Animation
# ============================================================

@onready var move_state_machine = $Animation/AnimationTree.get("parameters/StateMachine/playback")
@onready var tool_state_machine = $Animation/AnimationTree.get("parameters/ToolStateMachine/playback")


# ============================================================
# Player State
# ============================================================

var current_state: Enum.State = Enum.State.DEFAULT
var update_state: Enum.State = Enum.State.HOUSE


# ============================================================
# Tool Selection
# ============================================================

var current_tool: Enum.Tool = Enum.Tool.AXE
var tools_count: int = Enum.Tool.size()


# ============================================================
# Seed Selection
# ============================================================

var current_seed: Enum.Seed = Enum.Seed.TOMATO
var seeds_count: int = Enum.Seed.size()


# ============================================================
# Style Selection
# ============================================================

var current_style: Enum.Style = Enum.Style.STRAW
var style_index: int = 0
var style_count: int = Data.unlocked_styles.size()


# ============================================================
# Machine Selection
# ============================================================

var current_machine: Enum.Machine = Enum.Machine.DELETE
var machine_index: int = 0
var machine_count: int = Data.unlocked_machines.size()


# ============================================================
# Signals
# ============================================================

## Building
signal build(machine: Enum.Machine)
signal change_machine(machine: Enum.Machine)

## Tool Actions
signal tool_use(tool: Enum.Tool, pos: Vector2, dir: Vector2)
signal do_action(
	anim_tree: AnimationTree,
	property: StringName,
	tool: Enum.Tool,
	pos: Vector2,
	dir: Vector2
)

## Game Events
signal diagnose
signal day_change
signal close_shop

## UI
signal update_control_ui(key_enum: Enum.Keyboard, currentItem: Enum)


# ============================================================
# Player Light
# ============================================================

const LIGHT_TEXTURE_SIZE := 256
const LIGHT_COLOR := Color(1.0, 1.0, 0.9)
const LIGHT_ENERGY := 0.25
const LIGHT_SCALE := 0.5


# ============================================================
# Player Audio
# ============================================================

@onready var step_timer: Timer = $Sounds/StepTimer
@onready var step_sound: AudioStreamPlayer = $Sounds/Step
@onready var axe_sound: AudioStreamPlayer2D = $Sounds/Axe
@onready var fish_sound: AudioStreamPlayer2D = $Sounds/Fish
@onready var hoe_sound: AudioStreamPlayer2D = $Sounds/Hoe
@onready var water_sound: AudioStreamPlayer2D = $Sounds/Water


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_create_player_light()
	
	# Wait one frame to ensure all nodes have finished their _ready() initialization.
	await get_tree().process_frame
	
	load_player()
	update_style()
	


#region Physics Process

func _physics_process(_delta: float) -> void:
	# Update the UI only when the player state changes.
	if update_state != current_state:
		_on_state_changed()

	# Execute the logic for the current state.
	match current_state:
		Enum.State.DEFAULT:
			_handle_default_state()

		Enum.State.FISHING:
			_handle_fishing_state()

		Enum.State.BUILDING:
			_handle_building_state()

		Enum.State.HOUSE:
			_handle_house_state()

		Enum.State.SHOP:
			_handle_shop_state()

#endregion


#region State Management

func _on_state_changed() -> void:
	# Building mode requires both the previous and new state.
	if current_state == Enum.State.BUILDING:
		update_control_ui.emit(
			Enum.Keyboard.CHANGE_MODE,
			current_state,
			Enum.State.BUILDING
		)
	else:
		update_control_ui.emit(
			Enum.Keyboard.CHANGE_MODE,
			current_state
		)

	update_state = current_state

#endregion


#region State Handlers

# Normal gameplay.
func _handle_default_state() -> void:
	if !can_move:
		return

	get_basic_input()
	move()
	animate()


# Fishing interaction.
func _handle_fishing_state() -> void:
	get_fishing_input()


# Building mode.
func _handle_building_state() -> void:
	get_fishing_input()
	get_building_input()

	move()
	animate()


# Inside the player's house.
func _handle_house_state() -> void:
	get_house_input()

	move()
	animate()


# Shop UI interaction.
func _handle_shop_state() -> void:
	get_shop_input()

#endregion
				
	
#region Movement

func move() -> void:
	# Read movement input.
	direction = Input.get_vector("left", "right", "up", "down")

	# Apply movement velocity.
	velocity = direction * speed

	# Handle footstep audio.
	if direction == Vector2.ZERO:
		step_sound.stop()
		move_and_slide()
		return

	# Start the footstep timer if it isn't already running.
	if step_timer.is_stopped():
		step_timer.start()

	# Move the player.
	move_and_slide()

	
func _on_step_timer_timeout() -> void:
	$Sounds/Step.play()

#endregion
	
	
#region Get Input
func get_basic_input():
	# Switch seeds
	if Input.is_action_just_pressed("seed_forward"):
		current_seed = posmod((current_seed + 1), seeds_count) as Enum.Seed
		if debug:
			print("Current Seed:" + Enum.Seed.keys()[current_seed])
		$ToolUI.reveal(null, current_seed)
		update_control_ui.emit(Enum.Keyboard.CHANGE_SEED, current_seed)
		
	# Switch tools
	if Input.is_action_just_pressed("tool_forward") or Input.is_action_just_pressed("tool_backward"):
		var dir = Input.get_axis("tool_backward", "tool_forward") # -1, 1
		current_tool = posmod((current_tool + int(dir)), tools_count) as Enum.Tool
		$ToolUI.reveal(current_tool, null)
		update_control_ui.emit(Enum.Keyboard.CHANGE_TOOL, current_tool)

	if Input.is_action_just_pressed("action"):
		if can_interact and last_interactable:
			last_interactable.interact(self)
		else:
			tool_state_machine.travel(Data.TOOL_STATE_ANIMATIONS[current_tool])
			do_action.emit($Animation/AnimationTree, "parameters/OneShot/request", current_tool, position, animation_direction)
			#$Animation/AnimationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		
	if Input.is_action_just_pressed("highlighter"):
		Data.target_highlighter = not Data.target_highlighter 
		update_control_ui.emit(Enum.Keyboard.CHANGE_HIGHLIGHT, 1 if Data.target_highlighter else 0)

	if Input.is_action_just_pressed("day_change"):
		day_change.emit()
		
	if Input.is_action_just_pressed("diagnose"):
		diagnose.emit()
		
	if Input.is_action_just_pressed("style_toggle"):
		style_count = Data.unlocked_styles.size()
		style_index = posmod((style_index + 1), style_count)
		current_style = Data.unlocked_styles[style_index] as Enum.Style
		if debug:
			print(current_style)
		save_player()
		
	if Input.is_action_just_pressed("build"):
		current_state = Enum.State.BUILDING
		change_machine.emit(current_machine)
		Data.target_highlighter = false
		update_control_ui.emit(Enum.Keyboard.CHANGE_HIGHLIGHT, 0)
		update_control_ui.emit(Enum.Keyboard.CHANGE_MACHINE, current_machine, Enum.State.BUILDING)
		
		
func get_fishing_input():
	if Input.is_action_just_pressed("action"):
		$FishingGame.apply_bar_boost()


func get_building_input():
	if Input.is_action_just_pressed("build"):
		current_state = Enum.State.DEFAULT
		update_control_ui.emit(Enum.Keyboard.CHANGE_TOOL, current_tool)
		
	
	# Switch Machines
	if Input.is_action_just_pressed("tool_forward") or Input.is_action_just_pressed("tool_backward"):
		var dir = Input.get_axis("tool_backward", "tool_forward") # -1, 1
		machine_count = Data.unlocked_machines.size()
		machine_index = posmod((machine_index + int(dir)), machine_count) as Enum.Machine
		current_machine = Data.unlocked_machines[machine_index] as Enum.Machine 
		change_machine.emit(current_machine)
		if debug:
			print("Machine" + str(current_machine))
			
		update_control_ui.emit(Enum.Keyboard.CHANGE_MACHINE, current_machine, Enum.State.BUILDING)
		
			
	if Input.is_action_just_pressed("action"):
		build.emit(current_machine)


func get_house_input():
	if Input.is_action_just_pressed("diagnose"):
		diagnose.emit()
		
	if Input.is_action_just_pressed("style_toggle"):
		current_style = posmod((current_style + 1), style_count) as Enum.Style
		save_player()
		
	if Input.is_action_just_pressed("action"):
		if can_interact and last_interactable:
			last_interactable.interact(self)
	
	
func get_shop_input():
	if Input.is_action_just_pressed("ui_cancel"):
		close_shop.emit()
#endregion


#region Tool Actions
func tool_use_emit() -> void:
	# Notify listeners that the current tool was used.
	tool_use.emit(current_tool, position, animation_direction)

	# Play the appropriate sound effect.
	match current_tool:
		Enum.Tool.AXE, Enum.Tool.SWORD:
			axe_sound.play()

		Enum.Tool.FISH:
			fish_sound.play()

		Enum.Tool.HOE:
			hoe_sound.play()

		Enum.Tool.WATER:
			water_sound.play()

#endregion


#region Animation
func animate():
	if direction:
		move_state_machine.travel("walk")
		animation_direction = Vector2(round(direction.x), round(direction.y))
		$Animation/AnimationTree.set("parameters/StateMachine/idle/blend_position", animation_direction)	
		$Animation/AnimationTree.set("parameters/StateMachine/walk/blend_position", animation_direction)
		$Animation/AnimationTree.set("parameters/FishIdleBlendSpace2D/blend_position", animation_direction)	
		
		# Update tools animation
		for tool_animation in Data.TOOL_STATE_ANIMATIONS.values():
			$Animation/AnimationTree.set("parameters/ToolStateMachine/" + tool_animation + "/blend_position", animation_direction)		
	else:
		move_state_machine.travel("idle")
	
		
func _on_animation_tree_animation_started(_anim_name: StringName) -> void:
	can_move = false


func _on_animation_tree_animation_finished(_anim_name: StringName) -> void:
	can_move = true
#endregion


#region Fishing
func start_fishing():
	$FishingGame.reveal()
	$Animation/AnimationTree.set("parameters/FishBlend/blend_amount", 1)
	current_state = Enum.State.FISHING


func _on_fishing_game_fish_game_finish(is_success: bool) -> void:
	if is_success:
		Data.items_amount[Data.difficulty][Enum.Item.FISH] += 1
	$Animation/AnimationTree.set("parameters/FishBlend/blend_amount", 0)
	current_state = Enum.State.DEFAULT
#endregion


#region Interact
# Interact: this method only work if there is only 1 interactable in area 2D
func _on_interact_range_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("interact"):
		body.can_interact = true
		can_interact = true
		last_interactable = body



func _on_interact_range_area_2d_body_exited(body: Node2D) -> void:
	can_interact = false
	last_interactable = null
	if body.has_method("interact"):
		body.can_interact = false

	
	

	
	
	#region Player Light
func _create_player_light() -> void:
	var player_light := PointLight2D.new()
	player_light.texture = _generate_light_texture(
		LIGHT_TEXTURE_SIZE,
		LIGHT_COLOR
	)
	player_light.energy = LIGHT_ENERGY
	player_light.texture_scale = LIGHT_SCALE

	add_child(player_light)


func _generate_light_texture(size: int, color: Color) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)

	var center := size * 0.5
	var radius := center

	for x in range(size):
		for y in range(size):
			var distance := Vector2(x - center, y - center).length()

			if distance > radius:
				continue

			# Smooth radial falloff
			var alpha := 1.0 - (distance / radius)
			alpha *= alpha

			image.set_pixel(
				x,
				y,
				Color(color.r, color.g, color.b, alpha)
			)

	return ImageTexture.create_from_image(image)
#endregion
#endregion


#region Style
func update_style():
	$Sprite2D.texture = Data.PLAYER_SKINS[current_style]
	update_control_ui.emit(Enum.Keyboard.CHANGE_STYLE, current_style)
#endregion


#region Player Save/Load
func save_player():
	var save_data := {
		"style": current_style,
		"unlocked_styles": Data.unlocked_styles,
		"unlocked_machines": Data.unlocked_machines,
		"inventory": Data.items_amount,
		"sword_level": Data.sword_level,
		"scare_crow_level": Data.scare_crow_level,
		"fisherman_level": Data.fisherman_level
	}
	
	var file = FileAccess.open(Data.PLAYER_SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	update_style()
	
func load_player() -> void:
	if !FileAccess.file_exists(Data.PLAYER_SAVE_PATH):
		return

	var file := FileAccess.open(Data.PLAYER_SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())

	if typeof(data) != TYPE_DICTIONARY:
		return

	_load_unlocked_styles(data)
	_load_current_style(data)
	_load_unlocked_machines(data)
	_load_inventory(data)
	_load_upgrades(data)
	
func _load_unlocked_styles(data: Dictionary) -> void:
	if !data.has("unlocked_styles"):
		return

	Data.unlocked_styles.clear()

	for style in data.unlocked_styles:
		Data.unlocked_styles.append(style as Enum.Style)
		
	style_count = Data.unlocked_styles.size()
		
func _load_current_style(data: Dictionary) -> void:
	if !data.has("style"):
		return

	style_index = Data.unlocked_styles.find(data.style)

	if style_index == -1:
		style_index = 0

	current_style = Data.unlocked_styles[style_index]

func _load_unlocked_machines(data: Dictionary) -> void:
	if !data.has("unlocked_machines"):
		return

	Data.unlocked_machines.clear()

	for machine in data.unlocked_machines:
		Data.unlocked_machines.append(machine as Enum.Machine)
		
	machine_count = Data.unlocked_machines.size()

func _load_inventory(data: Dictionary) -> void:
	if not data.has("inventory"):
		return

	var saved_inventory: Dictionary = data["inventory"]

	for difficulty in saved_inventory:
		var difficulty_id := int(difficulty)

		if not Data.items_amount.has(difficulty_id):
			continue

		for item in saved_inventory[difficulty]:
			var item_id := int(item)

			Data.items_amount[difficulty_id][item_id] = (
				int(saved_inventory[difficulty][item])
			)
	
func _load_upgrades(data: Dictionary):
	if data.has("sword_level"):
		Data.sword_level = data.sword_level
		
	if data.has("scare_crow_level"):
		Data.scare_crow_level = data.scare_crow_level
		
	if data.has("fisherman_level"):
		Data.fisherman_level = data.fisherman_level
#endregion
