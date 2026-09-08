extends Control

# Manages the shop UI by displaying available items and handling shop refreshes.

var shop_button_scene = preload("res://scenes/ui/shop_button.tscn")
signal close

func _ready() -> void:
	$TouchButton.move_to_front()
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		print("TOUCH:", event.position)

	if event is InputEventMouseButton:
		print("MOUSE:", event.position)

func reveal(shop_type: Enum.Shop = Enum.Shop.HAT):
	for child in $GridContainer.get_children():
		child.queue_free()
		
	var unlocked: Array = Data.shop_connection[shop_type]['tracker']
	var all: Array = Data.shop_connection[shop_type]['all']
	var available = all.filter(func(item): return item not in unlocked)
	
	if available:
		show()
		$HBoxContainer.show()
		for item_enum in available:
			var shop_button = shop_button_scene.instantiate()
			shop_button.setup(item_enum, $GridContainer, shop_type)
			shop_button.connect("press", reveal)
			
		await get_tree().process_frame
		$GridContainer.get_child(0).grab_focus()
		# Menu/Shop
		Input.emulate_mouse_from_touch = true
	else:
		# Gameplay
		Input.emulate_mouse_from_touch = false
		close.emit()
		
#func _ready() -> void:
	#reveal(Enum.Shop.MAIN)
	
func remove_items():
	for child in $GridContainer.get_children():
		child.queue_free()


func _on_touch_button_pressed() -> void:
	# Gameplay
	Input.emulate_mouse_from_touch = false
	close.emit()
