extends CharacterBody2D

# ============================================================
# CONSTANTS
# ============================================================

# Movement
var speed: float = Data.BLOB_SPEED[Data.difficulty]

# Knockback
const KNOCKBACK_FORCE: float = Data.BLOB_KNOCKBACK_FORCE
const KNOCKBACK_DECAY: float = Data.BLOB_KNOCKBACK_DECAY
const KNOCKBACK_TIME: float = Data.BLOB_KNOCKBACK_TIME


# ============================================================
# MOVEMENT
# ============================================================

# Current movement direction.
var direction: Vector2 = Vector2.ZERO

# Direction used for idle/animation.
var animation_direction: Vector2 = Vector2.DOWN


# ============================================================
# COMBAT
# ============================================================

# Current health.
var blob_health: int = Data.BLOB_ENEMY_HEALTH[Data.difficulty]

# Damage dealt to the player.
var blob_damage: int = Data.BLOB_DAMAGE[Data.difficulty]

# Prevents updates after death.
var is_dead: bool = false


# ============================================================
# KNOCKBACK
# ============================================================

# Current knockback velocity.
var knockback_velocity: Vector2 = Vector2.ZERO

# Remaining knockback duration.
var knockback_timer: float = 0.0

# Whether the enemy is currently being knocked back.
var is_knocked: bool = false


# ============================================================
# AI / PATHFINDING
# ============================================================

# Counts how many frames the enemy has been stuck.
var stuck_counter: int = 0

# Previous position used to detect if the enemy is stuck.
var last_pos: Vector2 = Vector2.ZERO

# Current plant being targeted.
var target_plant: StaticBody2D


# ============================================================
# NODE REFERENCES
# ============================================================

@onready var flash_sprite_2d: Sprite2D = $FlashSprite2D

@onready var animation_tree: AnimationTree = $Animation/AnimationTree

@onready var move_state_machine = animation_tree.get("parameters/StateMachine/playback")



# ============================================================
# INITIALIZATION
# ============================================================

## Initializes the blob enemy.
##
## @param start_pos    World position where the blob should spawn.
## @param parent       Parent node to add the blob to.
## @param target_plant Plant that the blob will attack.
func setup(
	start_pos: Vector2,
	parent: Node,
	target_plant: StaticBody2D
) -> void:
	position = start_pos
	parent.add_child(self)
	self.target_plant = target_plant
	

# ============================================================
# READY
# ============================================================

func _ready() -> void:
	# Register this blob as an enemy so other systems can find it.
	add_to_group("Enemy")

	# Enable the AnimationTree.
	animation_tree.active = true

	# Use floating motion to prevent sliding against walls or pushing bodies.
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


# ============================================================
# PHYSICS
# ============================================================

func _physics_process(delta: float) -> void:
	# Stop all logic once the blob has died.
	if is_dead:
		return

	# Handle knockback separately from normal movement.
	if is_knocked:
		handle_knockback(delta)

		# Reset stuck detection while being knocked back.
		stuck_counter = 0
		last_pos = position
		return

	# If the target no longer exists, remove this blob.
	if !target_plant or !is_instance_valid(target_plant):
		die()
		return

	# ========================================================
	# MOVE TOWARDS TARGET
	# ========================================================

	# Save the current position to detect if movement fails.
	var old_position := position

	# Move toward the target plant.
	direction = (target_plant.position - position).normalized()
	velocity = direction * speed

	animate()
	move_and_slide()

	# ========================================================
	# STUCK DETECTION
	# ========================================================

	# If the blob barely moved this frame, it may be blocked.
	if position.distance_to(old_position) < 0.4:
		stuck_counter += 1

		# Try to escape after being stuck for several frames.
		if stuck_counter > 10:
			_attempt_unstuck()
	else:
		# Reset the counter once movement resumes.
		stuck_counter = 0

	# Save the current position for the next frame.
	last_pos = position
	
	
# ============================================================
# HELPERS
# ============================================================

## Attempts to free the blob when it has been stuck.
func _attempt_unstuck() -> void:
	var random_direction := Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	)

	if random_direction.length_squared() == 0:
		random_direction = Vector2.RIGHT
	else:
		random_direction = random_direction.normalized()

	direction = random_direction
	velocity = direction * speed
	move_and_slide()

	# Reset the stuck counter after attempting to escape.
	stuck_counter = 0

	# Uncomment for debugging.
	# print("Blob was stuck. New direction:", direction)
	
		
# ============================================================
# DAMAGE SYSTEM
# ============================================================
#region Damage System
## Applies damage to the blob from the specified tool.
##
## @param tool      Tool used to hit the blob.
## @param knock_dir Direction of the knockback.
func hit(tool: Enum.Tool, knock_dir: Vector2) -> void:
	# Ignore hits after death.
	if is_dead:
		return

	# Only swords can damage the blob.
	if tool != Enum.Tool.SWORD:
		return

	# Flash to indicate damage.
	flash_sprite_2d.flash(0.25, 0.25)

	# Reduce health.
	blob_health -= Data.TOOL_DAMAGE_AMOUNT[Data.difficulty][tool][Data.sword_level]

	# Push the blob away from the attacker.
	apply_knockback(knock_dir)

	# Die when health reaches zero.
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
#endregion


# ============================================================
# MOVEMENT
# ============================================================

func move(_delta: float) -> void:
	velocity = direction * speed
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
		body.grow(false, blob_damage)
		die()
