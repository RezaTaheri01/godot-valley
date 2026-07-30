class_name Machines
extends StaticBody2D

var coord: Vector2i

func setup(grid_coord: Vector2i, _level: Node2D, parent: Node2D):
	coord = grid_coord
	position = Vector2(grid_coord * Data.TILE_SIZE)
	parent.add_child(self)

func delete(delete_coord) -> void:
	if Vector2i(delete_coord) == coord:
		queue_free()
