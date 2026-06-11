extends CharacterBody2D

# ============================================================
# CONFIGURATION
# ============================================================

const SPEED: float = Data.BLOB_SPEED      # Movement speed

# Knockback configuration
const KNOCKBACK_FORCE: float = 100.0
const KNOCKBACK_DECAY: float = 500.0
const KNOCKBACK_TIME: float = 0.5

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_timer: float = 0
var is_knocked: bool = false

var stuck_counter: int = 0
var last_pos: Vector2 = Vector2.ZERO

# ============================================================
# STATE VARIABLES
# ============================================================

var direction: Vector2 = Vector2.ZERO     # Current movement direction
var animation_direction: Vector2 = Vector2.DOWN

var blob_health: int = Data.BLOB_ENEMY_HEALTH
var is_dead: bool = false                 # Locks logic after death

# ============================================================
# NODE REFERENCES
# ============================================================

@onready var flash_sprite_2d: Sprite2D = $FlashSprite2D
@onready var animation_tree: AnimationTree = $Animation/AnimationTree
@onready var move_state_machine = animation_tree.get("parameters/StateMachine/playback")

var target_plant: StaticBody2D


func setup(start_pos, parent, targetPlant):
	position = start_pos
	parent.add_child(self)
	target_plant = targetPlant

# ============================================================
# READY
# ============================================================

func _ready():
	add_to_group("Enemy")
	animation_tree.active = true
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING  # No sliding/pushing


# ============================================================
# MAIN LOOP
# ============================================================

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if is_knocked:
		handle_knockback(delta)
		# Reset stuck tracking when knocked
		stuck_counter = 0
		last_pos = position
		return
	
	if target_plant and is_instance_valid(target_plant): 
		# Store position before movement
		var old_pos = position
		
		# Calculate direction to plant
		direction = (target_plant.position - position).normalized()
		velocity = direction * SPEED
		
		# Animate and move
		animate()
		move_and_slide()
		
		## Check if we reached the plant
		#if position.distance_to(target_plant.position) < 10:
			#target_plant.grow(false)
			#die()
			#return
		
		# ========================================
		# STUCK CHECK - Simplified Version
		# ========================================
		# If barely moved after moving, we might be stuck
		if position.distance_to(old_pos) < 0.4:
			stuck_counter += 1
			
			# Stuck for 10+ frames? Try random direction
			if stuck_counter > 10:
				# Try a random direction to get unstuck
				var random_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1))
				if random_dir.length() > 0:
					random_dir = random_dir.normalized()
				else:
					random_dir = Vector2.RIGHT
				
				direction = random_dir
				velocity = direction * SPEED
				move_and_slide()  # Move again with new direction
				
				# Reset counter after attempting
				stuck_counter = 0
				
				# Optional: Add debug print
				#print("Blob was stuck, attempted random direction: ", direction)
		else:
			# We moved successfully, reset counter
			stuck_counter = 0
		
		# Update last position for next frame's check
		last_pos = position
		
	else:
		die()
		
		
# ============================================================
# DAMAGE SYSTEM
# ============================================================

func hit(tool: Enum.Tool, knock_dir: Vector2) -> void:
	if is_dead:
		return
	
	if tool == Enum.Tool.SWORD:
		flash_sprite_2d.flash(0.25, 0.25)
		
		blob_health -= 1
		
		apply_knockback(knock_dir)
		
		if blob_health <= 0:
			die()


func die() -> void:
	is_dead = true
	
	# Stop movement immediately
	direction = Vector2.ZERO
	velocity = Vector2.ZERO
	
	# Play Death animation
	move_state_machine.travel("death")


func delete_enemy():
	self.queue_free()


func apply_knockback(knock_dir: Vector2) -> void:
	is_knocked = true
	knockback_timer = KNOCKBACK_TIME
	
	# Direction AWAY from attacker
	var push_dir = knock_dir
	
	knockback_velocity = push_dir * KNOCKBACK_FORCE


func handle_knockback(delta: float) -> void:
	knockback_timer -= delta
	
	# Move using knockback velocity
	velocity = knockback_velocity
	move_and_slide()
	
	# Smooth deceleration
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	
	if knockback_timer <= 0.0:
		is_knocked = false
		knockback_velocity = Vector2.ZERO

# ============================================================
# MOVEMENT
# ============================================================

func move(_delta: float) -> void:
	velocity = direction * SPEED
	move_and_slide()

# ============================================================
# ANIMATION CONTROL
# ============================================================

func animate() -> void:
	# Safety guard
	if is_dead:
		return
	
	if direction != Vector2.ZERO:
		move_state_machine.travel("walk")
	else:
		move_state_machine.travel("idle")
	
	update_blend_positions()


func update_blend_positions() -> void:
	# Update blend direction for idle and walk
	animation_tree.set(
		"parameters/StateMachine/idle/blend_position",
		animation_direction
	)
	
	animation_tree.set(
		"parameters/StateMachine/walk/blend_position",
		animation_direction
	)

	animation_tree.set(
		"parameters/StateMachine/death/blend_position",
		animation_direction
	)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("grow"):
		body.grow(false)
		die()
