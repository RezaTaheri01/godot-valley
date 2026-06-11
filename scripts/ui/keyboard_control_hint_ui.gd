extends Control

var key_hint_scene = preload("res://scenes/ui/key_hint.tscn")

func _ready() -> void:
	var keys = Data.KEYBOARD_KEYS if Input.get_connected_joypads().size() == 0 else Data.KEYBOARD_CONTROLLER
	
	for key in Enum.KEYBOARD.values():
		var key_icon = keys[key]
		var key_hint = key_hint_scene.instantiate()
		var icon = Data.KEYBOARD_TO_ICONS[key][0]
		key_hint.setup(key_icon, icon, key)
		if key == Enum.KEYBOARD.CHANGE_MACHINE:
			key_hint.hide()
			
		$VBoxContainer.add_child(key_hint)
		

func _on_player_update_control_ui(key_enum, currentItem, state=Enum.State.DEFAULT) -> void:
	for key_hint in $VBoxContainer.get_children():
		if state == Enum.State.BUILDING:
			# In BUILDING state: show CHANGE_MACHINE, hide CHANGE_TOOL
			if key_enum == key_hint.keyboard_key:
				key_hint.show()
				key_hint.update(currentItem)
			if Enum.KEYBOARD.CHANGE_TOOL == key_hint.keyboard_key:
				key_hint.hide()
			if Enum.KEYBOARD.CHANGE_MACHINE == key_hint.keyboard_key:
				key_hint.show()  # Show CHANGE_MACHINE in BUILDING state
		else:
			# In non-BUILDING state: show CHANGE_TOOL, hide CHANGE_MACHINE
			if key_enum == key_hint.keyboard_key:
				key_hint.show()
				key_hint.update(currentItem)
			if Enum.KEYBOARD.CHANGE_MACHINE == key_hint.keyboard_key:
				key_hint.hide()
			if Enum.KEYBOARD.CHANGE_TOOL == key_hint.keyboard_key:
				key_hint.show()  # Show CHANGE_TOOL in non-BUILDING state
			


func _on_level_update_hint_ui_keys() -> void:
	var keys = Data.KEYBOARD_KEYS if Input.get_connected_joypads().size() == 0 else Data.KEYBOARD_CONTROLLER
 
	for key_hint in $VBoxContainer.get_children():
		key_hint.update_key_texture(keys[key_hint.keyboard_key])
