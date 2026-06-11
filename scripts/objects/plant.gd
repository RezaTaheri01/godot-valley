extends StaticBody2D

var coord: Vector2i
var res: PlantResource
var plant_info: PanelContainer

signal plant_death(coord: Vector2i)
signal plant_harvest(coord: Vector2i)

func setup(grid_coord: Vector2i, parent: Node2D, plant_res: PlantResource,
		   plantInfo: PanelContainer, plant_death_func, plant_harvest_func):
	position = grid_coord * Data.TILE_SIZE + Vector2i(8, 5)
	parent.add_child(self)
	coord = grid_coord
	$Sprite2D.texture = plant_res.texture
	res = plant_res
	plant_info = plantInfo
	
	# Signal doesn't care where the function come from(So powerful)
	plant_death.connect(plant_death_func)
	plant_harvest.connect(plant_harvest_func)
	
	
func grow(watered: bool):
	if watered:
		res.grow($Sprite2D)
	else:
		if res.decay(self):
			plant_death.emit(coord)
			plant_info.queue_free()
			return
	
	plant_info.update_info()


func _on_collision_area_body_entered(_body: Node2D) -> void:
	if res.get_complete():
		Data.ITEMS_AMOUNT[Data.SEED_TO_ITEM[res.curr_seed_enum]] += 2
		print(res.plant_name + " collected")
		plant_harvest.emit(coord)
		plant_info.queue_free()
		self.queue_free()
