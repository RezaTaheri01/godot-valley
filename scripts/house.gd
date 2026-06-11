extends Node2D

var empty_tile_atlas_coord: Vector2i = Vector2i(0, 5)
var door_tile_atlas_coord: Vector2i = Vector2i(0, 4)
var door_coord: Vector2i
var last_state: Enum.State = Enum.State.DEFAULT


var in_house: bool:
	set(value):
		in_house = value
		$WallsLayer.set_cell(door_coord, 0, empty_tile_atlas_coord if in_house else door_tile_atlas_coord)
		var tween = create_tween()
		tween.tween_property($RoofLayer, "modulate:a", 0.0 if in_house else 1.0, 0.25)


func _ready() -> void:
	# Assuming there is only 1 door
	for cell in $WallsLayer.get_used_cells():
		$FloorLayer.set_cell(cell, 0, Vector2i(0, 0))
		if $WallsLayer.get_cell_atlas_coords(cell) == door_tile_atlas_coord:
			door_coord = cell


func _on_house_area_body_entered(body: Node2D) -> void:
	in_house = true
	if body.is_in_group("Player"):
		last_state = body.current_state
		body.current_state = Enum.State.HOUSE


func _on_house_area_body_exited(body: Node2D) -> void:
	in_house = false
	if body.is_in_group("Player"):
		body.current_state = last_state
	

func is_point_inside_house(global_pos: Vector2) -> bool:
	var local_pos = $HouseArea.to_local(global_pos * Data.TILE_SIZE)
	var collision_polygon = $HouseArea/CollisionPolygon2D
	var polygon_points = collision_polygon.polygon  # This gets the PackedVector2Array
	
	return Geometry2D.is_point_in_polygon(local_pos, polygon_points)
