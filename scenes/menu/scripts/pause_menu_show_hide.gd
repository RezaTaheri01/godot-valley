extends CanvasLayer

@warning_ignore("unused_signal")
signal save_progress

func hide_menu():
	$Root.hide_menu()
	
func show_menu():
	$Root.show_menu()
	$Root.first_button.grab_focus()
