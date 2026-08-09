# Manages the on-screen control hints and updates their key and item icons
# based on the current input device, selected item, and player state.
extends Control


# ============================================================
# RESOURCES
# ============================================================

const KEY_HINT_SCENE := preload("res://scenes/ui/key_hint.tscn")


# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	_create_key_hints()


# ============================================================
# SETUP
# ============================================================

func _create_key_hints() -> void:
	var keys = _get_current_key_bindings()

	for key in Enum.Keyboard.values():
		var key_hint = KEY_HINT_SCENE.instantiate()
		var key_icon = keys[key]
		var item_icon = Data.KEYBOARD_TO_ICONS[key][0]

		key_hint.setup(key_icon, item_icon, key)

		# CHANGE_MACHINE is only shown while building.
		if key == Enum.Keyboard.CHANGE_MACHINE:
			key_hint.hide()

		$VBoxContainer.add_child(key_hint)


func _get_current_key_bindings() -> Dictionary:
	if Input.get_connected_joypads().is_empty():
		return Data.KEYBOARD_KEYS

	return Data.KEYBOARD_CONTROLLER


# ============================================================
# PLAYER STATE
# ============================================================

# Updates the control hints when the player's selected item or state changes.
func _on_player_update_control_ui(
	key_enum,
	current_item,
	state: Enum.State = Enum.State.DEFAULT
) -> void:
	for key_hint in $VBoxContainer.get_children():
		if key_hint.keyboard_key == key_enum:
			key_hint.show()
			key_hint.update(current_item)

		match key_hint.keyboard_key:
			Enum.Keyboard.CHANGE_TOOL:
				key_hint.visible = state != Enum.State.BUILDING

			Enum.Keyboard.CHANGE_MACHINE:
				key_hint.visible = state == Enum.State.BUILDING


# ============================================================
# INPUT DEVICE
# ============================================================

# Updates all displayed key icons when the input device changes.
func _on_level_update_hint_ui_keys() -> void:
	var keys := _get_current_key_bindings()

	for key_hint in $VBoxContainer.get_children():
		key_hint.update_key_texture(keys[key_hint.keyboard_key])
