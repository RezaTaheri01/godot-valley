extends PanelContainer

var res: PlantResource

func setup(plant_res: PlantResource):
	res = plant_res
	
	$HBoxContainer/IconTexture.texture = res.icon_texture
	$HBoxContainer/VBoxContainer/Label.text = res.plant_name
	
	$HBoxContainer/VBoxContainer/GrowthBar.max_value = res.h_frames
	$HBoxContainer/VBoxContainer/GrowthBar.step = res.grow_speed
	$HBoxContainer/VBoxContainer/DeathBar.max_value = res.death_max
	
	update_info()
	

func update_info():
	$HBoxContainer/VBoxContainer/GrowthBar.value = res.age
	$HBoxContainer/VBoxContainer/DeathBar.value = res.death_count
	
	
