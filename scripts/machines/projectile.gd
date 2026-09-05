extends Area2D

# Movement speed of the projectile in pixels per second.
var speed: float = 0.0

# Normalized direction the projectile will travel.
var direction: Vector2


# ============================================================
# SETUP
# ============================================================

func setup(start_pos: Vector2, new_direction: Vector2, projectile_speed: float=200.0) -> void:
	speed = projectile_speed
	
	# Spawn the projectile and set its travel direction.
	global_position = start_pos
	direction = new_direction.normalized()

	# Start the lifetime timer.
	$Timer.start()


# ============================================================
# PHYSICS
# ============================================================

func _physics_process(delta: float) -> void:
	# Move the projectile forward every physics frame.
	position += direction * speed * delta


# ============================================================
# TIMER
# ============================================================

func _on_timer_timeout() -> void:
	# Destroy the projectile when its lifetime expires.
	queue_free()


# ============================================================
# COLLISION
# ============================================================

func _on_body_entered(body: Node2D) -> void:
	# Damage valid enemies, then destroy the projectile.
	if body is CharacterBody2D and body.is_in_group("Sword_able"):
		body.hit(Enum.Tool.SWORD, direction)
		queue_free()
