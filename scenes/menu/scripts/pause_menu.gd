extends MenuBase


# ============================================================
# REFERENCES
# ============================================================

# Reference to the main Control that contains the entire
# pause menu (background, panel, buttons, etc.)
@onready var first_button: Button = $CenterContainer/ButtonPanel/VBoxContainer/ResumeButton
@onready var difficulty_menu: Control = $DifficultyMenu
@onready var option_menu: Control = $OptionsMenu


# ===========================================================
# GODOT LIFECYCLE
# ============================================================

func _ready():
	# Set the scale pivot to the center of the menu.
	# This makes the menu scale from the center instead of
	# scaling from the top-left corner.
	self.pivot_offset = self.size / 2
	
	# Hide the pause menu when the game starts.
	self.hide()


# ============================================================
# BUTTON SIGNALS
# ============================================================

# Resume button
func _on_resume_button_pressed():
	# Play the hide animation.
	hide_menu()
	
	# Resume the game.
	get_tree().paused = false


# Quit button
func _on_quit_button_pressed() -> void:
	$"..".save_progress.emit()
	get_tree().quit()


func _on_options_button_pressed() -> void:
	option_menu.show_menu(first_button)
	set_pause_buttons_focus(false)
	option_menu.first_button.grab_focus()

#region New Game
func _on_new_game_button_pressed() -> void:
	difficulty_menu.show_menu(first_button)
	set_pause_buttons_focus(false)
	difficulty_menu.first_button.grab_focus()


func _on_difficulty_menu_difficulty(mode: int) -> void:
	Data.new_game(mode)
	
	# Make sure the new scene isn't loaded in a paused state
	get_tree().paused = false

	var error := get_tree().change_scene_to_file(
		"res://scenes/menu/loading.tscn"
	)

	if error != OK:
		push_error("Failed to load level: %s" % error)

#endregion

# Disable Pause Menu Foucs
func set_pause_buttons_focus(enabled: bool) -> void:
	for child in $CenterContainer/ButtonPanel/VBoxContainer.get_children():
		if child is Button:
			child.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
