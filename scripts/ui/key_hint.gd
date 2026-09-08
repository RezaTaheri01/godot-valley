extends Control

# Displays a keyboard key and its associated item icon, and updates either
# the item icon or key texture when the player's controls change.

var keyboard_key: Enum.Keyboard
var last_icon_texture 

func setup(texture, icon, key: Enum.Keyboard):
	last_icon_texture = icon
	keyboard_key = key
	if DisplayServer.is_touchscreen_available():
		$HBoxContainer/Key.texture = null
		$HBoxContainer.scale = Vector2(1.5, 1.5)
		$HBoxContainer/Item/Button.modulate = Color("ffffff20")
	else:
		$HBoxContainer/Key.texture = texture
		
	if icon != null:
		$HBoxContainer/Item.texture = icon
		
	
func _ready() -> void:
	$HBoxContainer/Item/Button.pressed.connect(_on_button_pressed)
	
		
func update(item_enum):
	$HBoxContainer/Item.texture = Data.KEYBOARD_TO_ICONS[keyboard_key][item_enum]


func update_key_texture(texture_key):
	$HBoxContainer/Key.texture = texture_key


func _on_button_pressed() -> void:
	var action: String = Data.KEYBOARD_KEYS_TO_ACTION.get(keyboard_key, "")

	if action.is_empty():
		return

	Input.action_press(action)

	await get_tree().create_timer(0.05).timeout

	Input.action_release(action)
