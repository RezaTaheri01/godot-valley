extends MenuBase


# ============================================================
# NODE REFERENCES
# ============================================================

@onready var master_volume_slider: HSlider = $Panel/MarginContainer/VBoxContainer/MasterVolumeRow/MasterVolumeSlider
@onready var display_size_option_button: OptionButton = $Panel/MarginContainer/VBoxContainer/DisplaySizeRow/DisplaySizeOptionButton
@onready var v_sync_check_box: CheckBox = $Panel/MarginContainer/VBoxContainer/VSyncRow/VSyncCheckBox
@onready var display_mode_option_button: OptionButton = $Panel/MarginContainer/VBoxContainer/DisplayModeRow/DisplayModeOptionButton
@onready var first_button = $Panel/MarginContainer/VBoxContainer/MasterVolumeRow/MasterVolumeSlider

# ============================================================
# READY
# ============================================================

func _ready() -> void:
	hide()
	# Load saved settings when the game starts.
	load_settings()


# ============================================================
# CLOSE OPTIONS MENU
# ============================================================

func _on_close_button_pressed() -> void:
	hide_menu()


# ============================================================
# MASTER VOLUME
# ============================================================

func _on_master_volume_slider_value_changed(value: float) -> void:
	var volume := value / 100.0

	# Prevent linear_to_db(0) from causing -infinity.
	if volume <= 0.0:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)

		var db := linear_to_db(volume)
		AudioServer.set_bus_volume_db(0, db)

	if self.visible:
		save_settings()


# ============================================================
# DISPLAY SIZE / RESOLUTION
# ============================================================

func _on_display_size_option_button_item_selected(index: int) -> void:
	var new_size := get_resolution_from_index(index)

	# Apply the selected window size.
	DisplayServer.window_set_size(new_size)

	if self.visible:
		save_settings()


# ============================================================
# VSYNC
# ============================================================

func _on_v_sync_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED
		)
	else:
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_DISABLED
		)

	if self.visible:
		save_settings()


# ============================================================
# DISPLAY MODE
# ============================================================

func _on_display_mode_option_button_item_selected(index: int) -> void:

	# Reset borderless before applying the new mode.
	DisplayServer.window_set_flag(
		DisplayServer.WINDOW_FLAG_BORDERLESS,
		false
	)

	match index:

		# 0 = Windowed
		0:
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_WINDOWED
			)

		# 1 = Borderless
		1:
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_WINDOWED
			)

			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS,
				true
			)

		# 2 = Fullscreen
		2:
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_FULLSCREEN
			)

	if self.visible:
		save_settings()


# ============================================================
# GET RESOLUTION
# ============================================================

func get_resolution_from_index(index: int) -> Vector2i:
	match index:

		0:
			return Vector2i(1280, 720)

		1:
			return Vector2i(1600, 900)

		2:
			return Vector2i(1920, 1080)

		3:
			return Vector2i(2560, 1440)

	return Vector2i(1280, 720)


# ============================================================
# SAVE SETTINGS
# ============================================================

func save_settings() -> void:

	var settings := {
		"master_volume": master_volume_slider.value,
		"display_size": display_size_option_button.selected,
		"vsync": v_sync_check_box.button_pressed,
		"display_mode": display_mode_option_button.selected
	}

	var file := FileAccess.open(
		Data.OPTIONS_SAVE_PATH,
		FileAccess.WRITE
	)

	file.store_var(settings)


# ============================================================
# LOAD SETTINGS
# ============================================================

func load_settings() -> void:

	# Check if a settings file exists.
	if not FileAccess.file_exists(Data.OPTIONS_SAVE_PATH):
		return

	var file := FileAccess.open(
		Data.OPTIONS_SAVE_PATH,
		FileAccess.READ
	)

	var settings = file.get_var()


	# --------------------------------------------------------
	# MASTER VOLUME
	# --------------------------------------------------------

	master_volume_slider.value = settings.get(
		"master_volume",
		100.0
	)

	var volume: float = master_volume_slider.value / 100.0

	if volume <= 0.0:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(
			0,
			linear_to_db(volume)
		)


	# --------------------------------------------------------
	# DISPLAY SIZE
	# --------------------------------------------------------

	var display_size_index: int = settings.get(
		"display_size",
		0
	)

	display_size_option_button.select(display_size_index)

	var new_size := get_resolution_from_index(
		display_size_index
	)

	DisplayServer.window_set_size(new_size)


	# --------------------------------------------------------
	# VSYNC
	# --------------------------------------------------------

	var vsync_enabled: bool = settings.get(
		"vsync",
		true
	)

	v_sync_check_box.button_pressed = vsync_enabled

	if vsync_enabled:
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED
		)
	else:
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_DISABLED
		)


	# --------------------------------------------------------
	# DISPLAY MODE
	# --------------------------------------------------------

	var display_mode_index: int = settings.get(
		"display_mode",
		0
	)

	display_mode_option_button.select(display_mode_index)

	apply_display_mode(display_mode_index)


# ============================================================
# APPLY DISPLAY MODE
# ============================================================

func apply_display_mode(index: int) -> void:

	# Reset borderless first.
	DisplayServer.window_set_flag(
		DisplayServer.WINDOW_FLAG_BORDERLESS,
		false
	)

	match index:

		# Windowed
		0:
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_WINDOWED
			)

		# Borderless
		1:
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_WINDOWED
			)

			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS,
				true
			)

		# Fullscreen
		2:
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_FULLSCREEN
			)
