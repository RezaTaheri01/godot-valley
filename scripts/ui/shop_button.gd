extends Button

var item_enum: int
var shop_type: Enum.Shop

@onready var cost_parent: HBoxContainer = $VBoxContainer/VBoxContainer/Control/HBoxContainer
@onready var color_rect: ColorRect = $VBoxContainer/ColorRect
@onready var texture_rect: TextureRect = $VBoxContainer/ColorRect/TextureRect
@onready var name_label: Label = $VBoxContainer/VBoxContainer/Label

signal press(shop_type: Enum.Shop)

func setup(new_item_enum: int, parent_node: Node, new_shop_type: Enum.Shop) -> void:	
	item_enum = new_item_enum
	shop_type = new_shop_type
	
	parent_node.add_child(self)
	
	var source = Data.STYLE_UPGRADES if shop_type == Enum.Shop.HAT else Data.MACHINE_UPGRADE_COST
	var data = source[item_enum]
		
	
	texture_rect.texture = data["icon"]
	color_rect.color = data["color"]
	name_label.text = data["name"]
	
	for cost_item_enum in data["cost"]:
		var cost = data["cost"][cost_item_enum]
		
		var hbox = HBoxContainer.new()
		var cost_texture = TextureRect.new()
		var cost_label = Label.new()
		
		cost_texture.texture = load(Data.ICON_PATHS[cost_item_enum])
		cost_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cost_texture.custom_minimum_size = Vector2(30, 30)
		
		cost_label.text = str(cost)
		cost_label.add_theme_font_size_override("font_size", 30)  # 16 pixels
		
		hbox.add_child(cost_texture)
		hbox.add_child(cost_label)
		cost_parent.add_child(hbox)


func _on_focus_entered() -> void:
	$BG.theme_type_variation = "FocusPanel"


func _on_focus_exited() -> void:
	$BG.theme_type_variation = ""


func _on_pressed() -> void:
	var upgrade_cost 
	if shop_type == Enum.Shop.MAIN:
		upgrade_cost = Data.MACHINE_UPGRADE_COST[item_enum]["cost"]
	else:
		upgrade_cost = Data.STYLE_UPGRADES[item_enum]["cost"]
	
	for item in upgrade_cost.keys():
		var cost = upgrade_cost[item]
		if Data.ITEMS_AMOUNT[item] < cost:
			# Not enough item
			print("Not enough item to buy")
			return
		
	for item in upgrade_cost.keys():
		var cost = upgrade_cost[item]
		Data.ITEMS_AMOUNT[item] -= cost
		
	Data.shop_connection[shop_type]["tracker"].append(item_enum)
	press.emit(shop_type)
