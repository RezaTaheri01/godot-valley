extends Machine

signal shoot_projectile(start_pos: Vector2, dir: Vector2)

@export var detection_range: float = 125.0
@export var enable_debug_logs: bool = false


# Override machine setup function
func setup(grid_coord: Vector2i, level: Node2D, parent: Node2D):
	self.connect("shoot_projectile", level.create_projectile)
	
	return super.setup(grid_coord, level, parent)


func _on_timer_timeout() -> void:
	var blobs: Array[Node] = get_tree().get_nodes_in_group("Sword_able")
	if blobs.is_empty():
		return
		
	var nearest_blob := get_nearest_enemy_in_range(blobs)
	if nearest_blob:
		var direction := (nearest_blob.global_position - global_position).normalized()
		shoot_projectile.emit(global_position, direction)
		
		if enable_debug_logs:
			print("Shot at: ", nearest_blob.name, " Distance: ", global_position.distance_to(nearest_blob.global_position))


func get_nearest_enemy_in_range(blobs: Array[Node]) -> CharacterBody2D:
	var nearest_blob: CharacterBody2D = null
	var nearest_distance_squared: float = detection_range * detection_range
	
	for blob in blobs:
		if not blob is CharacterBody2D:
			continue
			
		var distance_squared := global_position.distance_squared_to(blob.global_position)
		
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_blob = blob
	
	return nearest_blob
