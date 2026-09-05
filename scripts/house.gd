extends Node2D


# ============================================================
# CONFIGURATION
# ============================================================

const EMPTY_TILE_ATLAS_COORD := Vector2i(0, 5)
const DOOR_TILE_ATLAS_COORD := Vector2i(0, 4)

const ROOF_FADE_DURATION := 0.25


# ============================================================
# STATE
# ============================================================

var door_coord: Vector2i
var last_state: Enum.State = Enum.State.DEFAULT

var _in_house: bool = false
var in_house: bool = false:
	get:
		return _in_house
	set(value):
		_in_house = value
		# Open the door when inside the house and close it when outside.
		$WallsLayer.set_cell(
			door_coord,
			0,
			EMPTY_TILE_ATLAS_COORD if value else DOOR_TILE_ATLAS_COORD
		)

		# Fade the roof when the player enters the house.
		var tween := create_tween()
		tween.tween_property(
			$RoofLayer,
			"modulate:a",
			0.0 if value else 1.0,
			ROOF_FADE_DURATION
		)


# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	_find_door_and_setup_floor()


# ============================================================
# HOUSE SETUP
# ============================================================

func _find_door_and_setup_floor() -> void:
	# Copy the used wall cells to the floor layer.
	# The house currently assumes there is only one door.
	for cell in $WallsLayer.get_used_cells():
		$FloorLayer.set_cell(cell, 0, Vector2i.ZERO)

		if $WallsLayer.get_cell_atlas_coords(cell) == DOOR_TILE_ATLAS_COORD:
			door_coord = cell


# ============================================================
# PLAYER DETECTION
# ============================================================

func _on_house_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	last_state = body.current_state
	body.current_state = Enum.State.HOUSE

	in_house = true


func _on_house_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	body.current_state = last_state
	in_house = false


# ============================================================
# UTILITY
# ============================================================

func is_point_inside_house(global_pos: Vector2) -> bool:
	var local_pos = $HouseArea.to_local(global_pos * Data.TILE_SIZE)
	var collision_polygon := $HouseArea/CollisionPolygon2D

	return Geometry2D.is_point_in_polygon(
		local_pos,
		collision_polygon.polygon
	)
