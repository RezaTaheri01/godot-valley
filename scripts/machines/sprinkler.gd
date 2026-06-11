extends Machine

signal water_near_soils(sprinkler_coord: Vector2i)


func setup(grid_coord: Vector2i, level: Node2D, parent: Node2D):
	self.connect("water_near_soils", level.water_near_soils)
	
	return super.setup(grid_coord, level, parent)


func _on_timer_timeout() -> void:
	$AnimatedSprite2D.play("action")
	water_near_soils.emit(coord)
	await $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.play("default")
