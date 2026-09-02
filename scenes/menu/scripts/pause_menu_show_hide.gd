extends CanvasLayer

@warning_ignore("unused_signal")
signal save_progress

func hide_menu():
	$Root.hide_menu()
	
func show_menu():
	$Root.show_menu()
	$Root.first_button.grab_focus()
	
	

#region Pause Menu

func _input(event):
	# Check if the player pressed the "pause" action.
	# Example: Escape key.
	if event.is_action_pressed("pause") and Data.player.current_state != Enum.State.SHOP:
		toggle_pause()


func toggle_pause():
	# If the game is currently paused...
	if $Root.visible:
		
		# Resume the game.
		get_tree().paused = false
		
		# Play the pause menu hide animation.
		hide_menu()
	
	# If the game is currently running...
	else:
		
		# Pause the game.
		get_tree().paused = true
		
		# Play the pause menu show animation.
		show_menu()

#endregion
