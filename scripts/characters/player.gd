# TODO: Move while using tools 
extends CharacterBody2D

var debug: bool = true

const SPEED: float = Data.PLAYER_SPEED
var direction: Vector2
var can_move: bool = true
@onready var move_state_machine = $Animation/AnimationTree.get("parameters/StateMachine/playback")

@onready var tool_state_machine = $Animation/AnimationTree.get("parameters/ToolStateMachine/playback")
var current_tool: Enum.Tool = Enum.Tool.AXE
var tools_count: int = Enum.Tool.size()

var current_seed: Enum.Seed = Enum.Seed.TOMATO
var seeds_count: int = Enum.Seed.size()

var current_state: Enum.State = Enum.State.DEFAULT

var current_style: Enum.Style = Enum.Style.STRAW
var style_count: int = Data.unlocked_styles.size()
var style_index: int = 0

var current_machine: Enum.Machine = Enum.Machine.DELETE
var machine_count = Data.unlocked_machines.size()
var machine_index: int = 0
signal build(machine: Enum.Machine)
signal change_machine(machine: Enum.Machine)

var animation_direction: Vector2 = Vector2(0, 1)
signal tool_use(tool: Enum.Tool, pos: Vector2, dir: Vector2)
signal do_action(anim_tree: AnimationTree, property: StringName, tool: Enum.Tool, pos: Vector2, dir: Vector2)

signal diagnose
signal day_change

var can_interact: bool = false
var last_interactable

signal update_control_ui(key_enum: Enum.KEYBOARD, currentItem: Enum)

signal close_shop 

var update_state: Enum.State = Enum.State.HOUSE;


func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING  # No sliding/pushing
	var player_light: PointLight2D = PointLight2D.new()
	$".".add_child(player_light)
	
	# Create smooth faded circle texture
	var size = 256
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # Fill with transparent
	
	var center = size / 2.0
	var max_radius = size / 2.0
	
	for x in size:
		for y in size:
			var dx = x - center
			var dy = y - center
			var distance = sqrt(dx * dx + dy * dy)
			
			if distance <= max_radius:
				# Calculate alpha: 1.0 at center, 0.0 at edge
				var alpha = 1.0 - (distance / max_radius)
				# Square it for smoother fade
				alpha = alpha * alpha
				
				# Set pixel color with alpha
				var color = Color(1.0, 1.0, 0.9, alpha)
				image.set_pixel(x, y, color)
	
	# Create texture and apply
	var texture = ImageTexture.create_from_image(image)
	player_light.texture = texture
	player_light.energy = 0.25
	player_light.texture_scale = 0.5


func _physics_process(_delta: float) -> void:
	if update_state != current_state:
		if current_state == Enum.State.BUILDING:
			update_control_ui.emit(Enum.KEYBOARD.CHANGE_MODE, current_state, Enum.State.BUILDING)		
		else:
			update_control_ui.emit(Enum.KEYBOARD.CHANGE_MODE, current_state)		
			
		update_state = current_state
		
	match current_state:
		Enum.State.DEFAULT:
			if can_move:
				get_basic_input()
				move()
				animate()
		
		Enum.State.FISHING:
			get_fishing_input()
		
		Enum.State.BUILDING:
			get_fishing_input()
			get_building_input()
			move()
			animate()
			
		Enum.State.HOUSE:
			get_house_input()
			move()
			animate()
			
		Enum.State.SHOP:
			get_shop_input()
				
	
func move():
	direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * SPEED
	move_and_slide()
	
	
func get_basic_input():
	# Switch seeds
	if Input.is_action_just_pressed("seed_forward"):
		current_seed = posmod((current_seed + 1), seeds_count) as Enum.Seed
		if debug:
			print("Current Seed:" + Enum.Seed.keys()[current_seed])
		$ToolUI.reveal(null, current_seed)
		update_control_ui.emit(Enum.KEYBOARD.CHANGE_SEED, current_seed)
		
	# Switch tools
	if Input.is_action_just_pressed("tool_forward") or Input.is_action_just_pressed("tool_backward"):
		var dir = Input.get_axis("tool_backward", "tool_forward") # -1, 1
		current_tool = posmod((current_tool + int(dir)), tools_count) as Enum.Tool
		$ToolUI.reveal(current_tool, null)
		update_control_ui.emit(Enum.KEYBOARD.CHANGE_TOOL, current_tool)

	if Input.is_action_just_pressed("action"):
		if can_interact and last_interactable:
			last_interactable.interact(self)
		else:
			tool_state_machine.travel(Data.TOOL_STATE_ANIMATIONS[current_tool])
			do_action.emit($Animation/AnimationTree, "parameters/OneShot/request", current_tool, position, animation_direction)
			#$Animation/AnimationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		
	if Input.is_action_just_pressed("highlighter"):
		Data.TARGET_HIGHLIGHTER = not Data.TARGET_HIGHLIGHTER 
		update_control_ui.emit(Enum.KEYBOARD.CHANGE_HIGHLIGHT, 1 if Data.TARGET_HIGHLIGHTER else 0)

	if Input.is_action_just_pressed("day_change"):
		day_change.emit()
		
	if Input.is_action_just_pressed("diagnose"):
		diagnose.emit()
		
	if Input.is_action_just_pressed("style_toggle"):
		style_count = Data.unlocked_styles.size()
		style_index = posmod((style_index + 1), style_count - 1)
		current_style = Data.unlocked_styles[style_index] as Enum.Style
		print(current_style)
		$Sprite2D.texture = Data.PLAYER_SKINS[current_style]
		update_control_ui.emit(Enum.KEYBOARD.CHANGE_STYLE, current_style)
		
	if Input.is_action_just_pressed("build"):
		current_state = Enum.State.BUILDING
		change_machine.emit(current_machine)
		Data.TARGET_HIGHLIGHTER = false
		update_control_ui.emit(Enum.KEYBOARD.CHANGE_HIGHLIGHT, 0)
		update_control_ui.emit(Enum.KEYBOARD.CHANGE_MACHINE, current_machine, Enum.State.BUILDING)
		
		

func get_fishing_input():
	if Input.is_action_just_pressed("action"):
		$FishingGame.apply_bar_boost()


func get_building_input():
	if Input.is_action_just_pressed("build"):
		current_state = Enum.State.DEFAULT
		update_control_ui.emit(Enum.KEYBOARD.CHANGE_TOOL, current_tool)
		
	
	# Switch Machines
	if Input.is_action_just_pressed("tool_forward") or Input.is_action_just_pressed("tool_backward"):
		var dir = Input.get_axis("tool_backward", "tool_forward") # -1, 1
		machine_count = Data.unlocked_machines.size()
		machine_index = posmod((machine_index + int(dir)), machine_count) as Enum.Machine
		current_machine = Data.unlocked_machines[machine_index] as Enum.Machine 
		change_machine.emit(current_machine)
		if debug:
			print("Machine" + str(current_machine))
			
		update_control_ui.emit(Enum.KEYBOARD.CHANGE_MACHINE, current_machine, Enum.State.BUILDING)
		
			
	if Input.is_action_just_pressed("action"):
		build.emit(current_machine)


func get_house_input():
	if Input.is_action_just_pressed("diagnose"):
		diagnose.emit()
		
	if Input.is_action_just_pressed("style_toggle"):
		current_style = posmod((current_style + 1), style_count - 1) as Enum.Style
		$Sprite2D.texture = Data.PLAYER_SKINS[current_style]
		
	if Input.is_action_just_pressed("action"):
		if can_interact and last_interactable:
			last_interactable.interact(self)
	
	
func get_shop_input():
	if Input.is_action_just_pressed("ui_cancel"):
		close_shop.emit()


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
	
		
func tool_use_emit():
	tool_use.emit(current_tool, position, animation_direction)
	if current_tool == Enum.Tool.AXE or current_tool == Enum.Tool.SWORD:
		$Sounds/Axe.play()
	elif current_tool == Enum.Tool.FISH:
		$Sounds/Fish.play()
	elif current_tool == Enum.Tool.HOE:
		$Sounds/Hoe.play()	
	elif current_tool == Enum.Tool.WATER:
		$Sounds/Water.play()	


func _on_animation_tree_animation_started(_anim_name: StringName) -> void:
	can_move = false


func _on_animation_tree_animation_finished(_anim_name: StringName) -> void:
	can_move = true


# Fishing Part
func start_fishing():
	$FishingGame.reveal()
	$Animation/AnimationTree.set("parameters/FishBlend/blend_amount", 1)
	current_state = Enum.State.FISHING


func _on_fishing_game_fish_game_finish(is_success: bool) -> void:
	if is_success:
		Data.ITEMS_AMOUNT[Enum.Item.FISH] += 1
	$Animation/AnimationTree.set("parameters/FishBlend/blend_amount", 0)
	current_state = Enum.State.DEFAULT



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

	
	
