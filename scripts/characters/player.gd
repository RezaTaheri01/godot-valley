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

@onready var joystick = %VirtualJoystick


# ============================================================
# Camera
# ============================================================

@onready var camera: Camera2D = $Camera2D

# ============================================================
# Animation
# ============================================================

@onready var move_state_machine = $Animation/AnimationTree.get("parameters/StateMachine/playback")
@onready var tool_state_machine = $Animation/AnimationTree.get("parameters/ToolStateMachine/playback")
@onready var animation_tree = $Animation/AnimationTree

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
# Fishing
# ============================================================

var catched_fish_tween: Tween
var fish_escape_tween: Tween
@onready var catched_fish_sprite: Sprite2D = $CatchedFishVisual/CatchedFishSprite
@onready var catched_fish_label: Label = $CatchedFishVisual/CatchedFishLabel

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

# ============================================================
# Player Save
# ============================================================
@onready var _auto_save_timer = $AutoSaveTimer


func _ready() -> void:
	Data.player = self
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_create_player_light()
	
	# Wait one frame to ensure all nodes have finished their _ready() initialization.
	await get_tree().process_frame
	
	_auto_save_timer.wait_time = Data.BACKUP_SAVE_INTERVAL_TIME_IN_SEC
	
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
	if joystick.visible != Data.touch_input:
		joystick.visible = !joystick.visible
		
	var joystick_direction = joystick.get_value()

	if joystick_direction != Vector2.ZERO:
		direction = joystick_direction
	else:
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
			do_action.emit(animation_tree, "parameters/OneShot/request", current_tool, position, animation_direction)
			#animation_tree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		
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
		update_style()
		
	if Input.is_action_just_pressed("build"):
		current_state = Enum.State.BUILDING
		change_machine.emit(current_machine)
		Data.target_highlighter = false
		update_control_ui.emit(Enum.Keyboard.CHANGE_HIGHLIGHT, 0)
		update_control_ui.emit(Enum.Keyboard.CHANGE_MACHINE, current_machine, Enum.State.BUILDING)
		
	if Input.is_action_just_pressed("camera_zoom_in"):
		var zoom = camera.zoom
		zoom += Vector2.ONE
		camera.zoom = zoom.clamp(Data.MIN_ZOOM, Data.MAX_ZOOM)

	if Input.is_action_just_pressed("camera_zoom_out"):
		var zoom = camera.zoom
		zoom -= Vector2.ONE
		camera.zoom = zoom.clamp(Data.MIN_ZOOM, Data.MAX_ZOOM)

		
func _input(event):
	if event is InputEventMagnifyGesture:
		camera.zoom *= event.factor
		camera.zoom = camera.zoom.clamp(
			Data.MIN_ZOOM,
			Data.MAX_ZOOM
		)
		
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
		update_style()
		
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
		animation_tree.set("parameters/StateMachine/idle/blend_position", animation_direction)	
		animation_tree.set("parameters/StateMachine/walk/blend_position", animation_direction)
		animation_tree.set("parameters/FishIdleBlendSpace2D/blend_position", animation_direction)	
		
		# Update tools animation
		for tool_animation in Data.TOOL_STATE_ANIMATIONS.values():
			animation_tree.set("parameters/ToolStateMachine/" + tool_animation + "/blend_position", animation_direction)		
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
	animation_tree.set("parameters/FishBlend/blend_amount", 1)
	current_state = Enum.State.FISHING


func _on_fishing_game_fish_game_finish(is_success: bool, fish_type: Enum.Fish) -> void:
	catched_fish_sprite.texture = load(Data.FISH_DATA[Data.difficulty][fish_type]["icon_texture"])
	
	if is_success:
		await play_catched_fish_animation()
		
		Data.items_amount[Data.difficulty][Enum.Item.FISH] += 1
	else:
		await play_fish_escape_animation()

	animation_tree.set("parameters/FishBlend/blend_amount", 0)
	current_state = Enum.State.DEFAULT


func play_catched_fish_animation() -> void:
	var fish: Sprite2D = catched_fish_sprite

	# Stop previous animation if another fish was caught
	if catched_fish_tween and catched_fish_tween.is_valid():
		catched_fish_tween.kill()

	fish.show()

	# Starting state
	fish.modulate.a = 0.0
	fish.scale = Vector2(0.4, 0.4)

	# Make sure Sprite2D scales from its center
	fish.centered = true

	# --------------------------------
	# SHOW / POP IN
	# --------------------------------

	catched_fish_tween = create_tween()
	catched_fish_tween.set_parallel(true)

	# Fade in
	catched_fish_tween.tween_property(
		fish,
		"modulate:a",
		1.0,
		0.18
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Pop from 0.4 -> 1.15
	catched_fish_tween.tween_property(
		fish,
		"scale",
		Vector2(1.15, 1.15),
		0.28
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await catched_fish_tween.finished

	# --------------------------------
	# SETTLE
	# --------------------------------

	catched_fish_tween = create_tween()

	catched_fish_tween.tween_property(
		fish,
		"scale",
		Vector2.ONE,
		0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await catched_fish_tween.finished

	# Keep fish visible
	await get_tree().create_timer(0.7).timeout

	# --------------------------------
	# HIDE
	# --------------------------------

	catched_fish_tween = create_tween()
	catched_fish_tween.set_parallel(true)

	# Fade out
	catched_fish_tween.tween_property(
		fish,
		"modulate:a",
		0.0,
		0.2
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Shrink
	catched_fish_tween.tween_property(
		fish,
		"scale",
		Vector2(0.7, 0.7),
		0.2
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	await catched_fish_tween.finished

	fish.hide()#endregion


func play_fish_escape_animation() -> void:
	var fish: Sprite2D = catched_fish_sprite
	var label: Label = catched_fish_label

	# Stop previous animation
	if fish_escape_tween and fish_escape_tween.is_valid():
		fish_escape_tween.kill()

	# Save original position
	var original_position := fish.position

	# --------------------------------
	# PREPARE
	# --------------------------------

	fish.show()
	label.show()

	fish.modulate.a = 1.0
	fish.scale = Vector2.ONE
	fish.rotation = 0.0

	label.modulate.a = 0.0
	label.scale = Vector2(0.7, 0.7)

	# Center label pivot
	label.pivot_offset = label.size / 2.0

	# --------------------------------
	# FISH SHAKE
	# --------------------------------

	fish_escape_tween = create_tween()

	fish_escape_tween.tween_property(
		fish,
		"rotation",
		deg_to_rad(-8.0),
		0.05
	)

	fish_escape_tween.tween_property(
		fish,
		"rotation",
		deg_to_rad(8.0),
		0.05
	)

	fish_escape_tween.tween_property(
		fish,
		"rotation",
		deg_to_rad(-6.0),
		0.05
	)

	fish_escape_tween.tween_property(
		fish,
		"rotation",
		0.0,
		0.05
	)

	await fish_escape_tween.finished

	# --------------------------------
	# ESCAPE
	# --------------------------------

	var escape_tween := create_tween()
	escape_tween.set_parallel(true)

	# Fish moves down and away
	escape_tween.tween_property(
		fish,
		"position",
		original_position + Vector2(0, 80),
		0.3
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Fish shrinks
	escape_tween.tween_property(
		fish,
		"scale",
		Vector2(0.55, 0.55),
		0.3
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Fish fades
	escape_tween.tween_property(
		fish,
		"modulate:a",
		0.0,
		0.3
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# --------------------------------
	# LABEL POP
	# --------------------------------

	escape_tween.tween_property(
		label,
		"modulate:a",
		1.0,
		0.15
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	escape_tween.tween_property(
		label,
		"scale",
		Vector2(1.1, 1.1),
		0.2
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await escape_tween.finished

	# --------------------------------
	# LABEL SETTLE
	# --------------------------------

	var settle_tween := create_tween()

	settle_tween.tween_property(
		label,
		"scale",
		Vector2.ONE,
		0.1
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await settle_tween.finished

	# Keep message visible
	await get_tree().create_timer(0.5).timeout

	# --------------------------------
	# HIDE LABEL
	# --------------------------------

	var hide_tween := create_tween()
	hide_tween.set_parallel(true)

	hide_tween.tween_property(
		label,
		"modulate:a",
		0.0,
		0.2
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	hide_tween.tween_property(
		label,
		"scale",
		Vector2(0.8, 0.8),
		0.2
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await hide_tween.finished

	# --------------------------------
	# RESET
	# --------------------------------

	fish.position = original_position
	fish.rotation = 0.0
	fish.scale = Vector2.ONE

	fish.hide()
	label.hide()
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
func save_player(save_path = null):
	var save_data := {
		"current_style": current_style,
		"current_machine": current_machine,
		"current_seed": current_seed,
		"current_tool": current_tool,
		# ============================
		# ============================				
		"unlocked_styles": Data.unlocked_styles,
		"unlocked_machines": Data.unlocked_machines,
		# ============================
		# ============================
		"inventory": Data.items_amount,
		"player_level": Data.player_level,
		"player_position": [position.x, position.y],
		"target_highlighter": Data.target_highlighter,
		"difficulty": Data.difficulty,
		"camera_zoom": camera.zoom[0]
	}
	
	var file
	if save_path:
		file = FileAccess.open(save_path, FileAccess.WRITE)
	else:
		file = FileAccess.open(Data.PLAYER_SAVE_PATH, FileAccess.WRITE)
		
	file.store_string(JSON.stringify(save_data))
	
	
func _on_inventory_save_progress() -> void:
	save_player()
	
func load_player() -> void:
	if !FileAccess.file_exists(Data.PLAYER_SAVE_PATH):
		return

	var file := FileAccess.open(Data.PLAYER_SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())

	if typeof(data) != TYPE_DICTIONARY:
		return

	_load_camera_zoom(data)
	_load_difficulty(data)
	_load_unlocked_styles(data)
	_load_current_style(data)
	_load_unlocked_machines(data)
	_load_current_machine(data)
	_load_current_seed(data)
	_load_current_tool(data)
	_load_inventory(data)
	_load_upgrades(data)
	_load_player_position(data)
	_load_highlight(data)
	
	
func  _load_camera_zoom(data: Dictionary) -> void:
	if !data.has("camera_zoom"):
		return
		
	camera.zoom = Vector2(data.camera_zoom, data.camera_zoom)
		
	
func _load_difficulty(data: Dictionary) -> void:
	if !data.has("difficulty"):
		return
		
	Data.difficulty = data.difficulty

	
func _load_unlocked_styles(data: Dictionary) -> void:
	if !data.has("unlocked_styles"):
		return

	Data.unlocked_styles.clear()

	for style in data.unlocked_styles:
		Data.unlocked_styles.append(style as Enum.Style)
		
	style_count = Data.unlocked_styles.size()
		
func _load_current_style(data: Dictionary) -> void:
	if !data.has("current_style"):
		return

	style_index = Data.unlocked_styles.find(data.current_style)

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

func _load_current_machine(data: Dictionary) -> void:
	if !data.has("current_machine"):
		return

	machine_index = Data.unlocked_machines.find(data.current_machine)

	if machine_index == -1:
		machine_index = 0

	current_machine = Data.unlocked_machines[machine_index]
	
func _load_current_seed(data: Dictionary) -> void:
	if !data.has("current_seed"):
		return

	current_seed = data.current_seed
	update_control_ui.emit(Enum.Keyboard.CHANGE_SEED, current_seed)
	
func _load_current_tool(data: Dictionary) -> void:
	if !data.has("current_tool"):
		return

	current_tool = data.current_tool
	update_control_ui.emit(Enum.Keyboard.CHANGE_TOOL, current_tool)
	
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
	
func _load_upgrades(data: Dictionary) -> void:
	if data.has("player_level"):
		Data.player_level = data.player_level

func _load_player_position(data: Dictionary) -> void:
	if not data.has("player_position"):
		return

	var saved_position = data.player_position
	position = Vector2(
		float(saved_position[0]),
		float(saved_position[1])
	)
	
func _load_highlight(data: Dictionary) -> void:
	if not data.has("target_highlighter"):
		return
		
	Data.target_highlighter = data.target_highlighter
	update_control_ui.emit(Enum.Keyboard.CHANGE_HIGHLIGHT, 1 if Data.target_highlighter else 0)

# Backup save every 5 minutes
func _on_auto_save_timer_timeout() -> void:
	if debug:
		print("Backup save saved.")
	save_player(Data.PLAYER_SAVE_PATH_BACKUP)
	
#endregion
