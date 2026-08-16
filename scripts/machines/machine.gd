class_name Machines
extends StaticBody2D

var coord: Vector2i
var current_machine: int

signal machine_deleted(curr_machine: int)

func setup(grid_coord: Vector2i, _level: Node2D, parent: Node2D, curr_machine: int):
	coord = grid_coord
	position = Vector2(grid_coord * Data.TILE_SIZE)
	current_machine = curr_machine
	parent.add_child(self)


func delete(delete_coord) -> void:
	if Vector2i(delete_coord) != coord:
		return

	machine_deleted.emit(current_machine)
	queue_free()
