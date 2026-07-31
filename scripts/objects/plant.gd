extends StaticBody2D


# ============================================================
# STATE
# ============================================================

var coord: Vector2i
var res: PlantResource
var plant_info: PanelContainer


# ============================================================
# SIGNALS
# ============================================================

signal plant_death(coord: Vector2i)
signal plant_harvest(coord: Vector2i)


# ============================================================
# SETUP
# ============================================================

func setup(
	grid_coord: Vector2i,
	parent: Node2D,
	plant_res: PlantResource,
	plant_info_panel: PanelContainer,
	plant_death_func,
	plant_harvest_func
) -> void:
	position = grid_coord * Data.TILE_SIZE + Vector2i(8, 5)
	parent.add_child(self)

	coord = grid_coord
	res = plant_res
	plant_info = plant_info_panel

	$Sprite2D.texture = res.texture

	# Connect callbacks provided by the parent.
	# The signal doesn't need to know where the callback comes from.
	plant_death.connect(plant_death_func)
	plant_harvest.connect(plant_harvest_func)


# ============================================================
# GROWTH / DECAY
# ============================================================

func grow(watered: bool, damage_amount: int = 1) -> void:
	if watered:
		res.grow($Sprite2D)
	else:
		if res.decay(self, damage_amount):
			_handle_death()
			return

	plant_info.update_info()


func _handle_death() -> void:
	plant_death.emit(coord)
	plant_info.queue_free()


# ============================================================
# HARVEST
# ============================================================

func _on_collision_area_body_entered(_body: Node2D) -> void:
	if not res.get_complete():
		return

	var item = Data.SEED_TO_ITEM[res.curr_seed_enum]
	Data.items_amount[Data.difficulty][item] += 2

	print(res.plant_name + " collected")

	plant_harvest.emit(coord)

	plant_info.queue_free()
	queue_free()
