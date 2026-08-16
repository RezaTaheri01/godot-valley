extends Machines

signal shoot_projectile(start_pos: Vector2, direction: Vector2)


# ============================================================
# SETUP
# ============================================================

func setup(grid_coord: Vector2i, level: Node2D, parent: Node2D, curr_machine: int) -> void:
	# Notify the level whenever this turret fires a projectile.
	shoot_projectile.connect(level.create_projectile)

	super.setup(grid_coord, level, parent, curr_machine)


# ============================================================
# TIMER
# ============================================================

func _on_timer_timeout() -> void:
	# Maximum distance at which the turret can detect enemies.	
	var detection_range = Data.SCARE_CROW_DETECTION_RANGE[Data.difficulty][Data.scare_crow_level]
	
	# Find the closest enemy within range.
	var target := get_nearest_enemy(detection_range)

	# Don't shoot if no valid target was found.
	if target == null:
		return

	# Fire a projectile toward the target.
	var direction := (target.global_position - global_position).normalized()
	shoot_projectile.emit(global_position, direction)


# ============================================================
# TARGETING
# ============================================================

func get_nearest_enemy(detection_range: float) -> CharacterBody2D:

	var nearest: CharacterBody2D = null
	var nearest_distance_sq := detection_range * detection_range

	# Search all enemies and keep the closest one
	# that is inside the detection range.
	for enemy in get_tree().get_nodes_in_group("Sword_able"):
		if enemy is not CharacterBody2D:
			continue

		var distance_sq := global_position.distance_squared_to(enemy.global_position)

		if distance_sq < nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest = enemy

	return nearest
