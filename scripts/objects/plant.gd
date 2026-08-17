extends StaticBody2D


# ============================================================
# STATE
# ============================================================

var coord: Vector2i
var res: PlantResource
var plant_info: PanelContainer
var ready_to_harvest: bool = false
var harvest_shake_tween: Tween

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
		if res.grow($Sprite2D) and not ready_to_harvest:
			ready_to_harvest = true
			# Start animation here
			_start_harvest_shake()
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
	

# ============================================================
# Animation
# ============================================================

func _start_harvest_shake() -> void:
	harvest_shake_tween = create_tween()
	harvest_shake_tween.set_loops()

	harvest_shake_tween.tween_interval(Data.HARVEST_SHAKE_INTERVAL)

	harvest_shake_tween.tween_property(
		$Sprite2D,
		"rotation_degrees",
		Data.HARVEST_SHAKE_ANGLE,
		Data.HARVEST_SHAKE_DURATION
	).set_trans(Tween.TRANS_SINE)

	harvest_shake_tween.tween_property(
		$Sprite2D,
		"rotation_degrees",
		-Data.HARVEST_SHAKE_ANGLE,
		Data.HARVEST_SHAKE_DURATION * 2.0
	).set_trans(Tween.TRANS_SINE)

	harvest_shake_tween.tween_property(
		$Sprite2D,
		"rotation_degrees",
		0.0,
		Data.HARVEST_SHAKE_DURATION
	).set_trans(Tween.TRANS_SINE)
