extends CanvasLayer

@warning_ignore("unused_signal")
signal save_progress


func _ready() -> void:
	if DisplayServer.is_touchscreen_available():
		$Control/TouchScreenButton.visible = true

func hide_menu():
	$Root.hide_menu()
	
func show_menu():
	$Root.show_menu()
	$Root.first_button.grab_focus()
	
	

#region Pause Menu

func _input(event):
	# Check if the player pressed the "pause" action.	
	if Data.player.current_state == Enum.State.SHOP:
		return
	
	if event.is_action_pressed("pause"):
		toggle_pause()



func toggle_pause():
	# If the game is currently paused...
	if $Root.visible:
		# Gameplay
		Input.emulate_mouse_from_touch = false
		# Resume the game.
		get_tree().paused = false
		
		$Root/OptionsMenu.hide_menu()
		$Root/DifficultyMenu.hide_menu()
		# Play the pause menu hide animation.
		hide_menu()
	
	# If the game is currently running...
	else:
		# Menu
		Input.emulate_mouse_from_touch = true
		# Pause the game.
		get_tree().paused = true
		
		# Play the pause menu show animation.
		show_menu()

#endregion


func open_menu() -> void:
	toggle_pause()


func _on_touch_screen_button_pressed() -> void:
	toggle_pause()
