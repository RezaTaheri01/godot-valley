extends Control

var keyboard_key: Enum.KEYBOARD
var last_icon_texture 

func setup(texture, icon, key: Enum.KEYBOARD):
	last_icon_texture = icon
	keyboard_key = key
	$HBoxContainer/Key.texture = texture
	if icon != null:
		$HBoxContainer/Item.texture = icon
		
		
func update(item_enum):
	$HBoxContainer/Item.texture = Data.KEYBOARD_TO_ICONS[keyboard_key][item_enum]


func update_key_texture(texture_key):
	$HBoxContainer/Key.texture = texture_key
