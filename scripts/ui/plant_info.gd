extends PanelContainer

# Displays a plant's information, including its icon, name, growth progress, and decay status.

# ============================================================
# STATE
# ============================================================

var res: PlantResource


# ============================================================
# SETUP
# ============================================================

func setup(plant_res: PlantResource) -> void:
	res = plant_res

	$HBoxContainer/IconTexture.texture = res.icon_texture
	$HBoxContainer/VBoxContainer/Label.text = res.plant_name

	$HBoxContainer/VBoxContainer/GrowthBar.max_value = res.h_frames
	$HBoxContainer/VBoxContainer/GrowthBar.step = res.grow_speed
	$HBoxContainer/VBoxContainer/DeathBar.max_value = res.death_max

	update_info()


# ============================================================
# UI UPDATE
# ============================================================

# Updates the growth and decay progress bars using the plant's current state.
func update_info() -> void:
	$HBoxContainer/VBoxContainer/GrowthBar.value = res.age
	$HBoxContainer/VBoxContainer/DeathBar.value = res.death_count
