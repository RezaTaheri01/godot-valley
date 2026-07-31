# Represents a shop item button and handles displaying its information,
# validating its cost, purchasing the item, and notifying the shop UI.
extends Button


# ============================================================
# STATE
# ============================================================

var item_enum: int
var shop_type: Enum.Shop


# ============================================================
# REFERENCES
# ============================================================

@onready var cost_parent: HBoxContainer = $VBoxContainer/VBoxContainer/Control/HBoxContainer
@onready var color_rect: ColorRect = $VBoxContainer/ColorRect
@onready var texture_rect: TextureRect = $VBoxContainer/ColorRect/TextureRect
@onready var name_label: Label = $VBoxContainer/VBoxContainer/Label


# ============================================================
# SIGNALS
# ============================================================

signal press(shop_type: Enum.Shop)


# ============================================================
# SETUP
# ============================================================

func setup(
	new_item_enum: int,
	parent_node: Node,
	new_shop_type: Enum.Shop
) -> void:
	item_enum = new_item_enum
	shop_type = new_shop_type

	parent_node.add_child(self)

	var source = _get_shop_data()
	var data = source[item_enum]

	texture_rect.texture = data["icon"]
	color_rect.color = data["color"]
	name_label.text = data["name"]

	_setup_costs(data["cost"])


func _get_shop_data() -> Dictionary:
	if shop_type == Enum.Shop.HAT:
		return Data.STYLE_UPGRADES[Data.difficulty]

	return Data.MACHINE_UPGRADE_COST[Data.difficulty]


# ============================================================
# COST UI
# ============================================================

func _setup_costs(costs: Dictionary) -> void:
	for cost_item_enum in costs:
		var cost_amount = costs[cost_item_enum]

		var hbox := HBoxContainer.new()
		var cost_texture := TextureRect.new()
		var cost_label := Label.new()

		cost_texture.texture = load(Data.ICON_PATHS[cost_item_enum])
		cost_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cost_texture.custom_minimum_size = Vector2(30, 30)

		cost_label.text = str(cost_amount)
		cost_label.add_theme_font_size_override("font_size", 30)

		hbox.add_child(cost_texture)
		hbox.add_child(cost_label)
		cost_parent.add_child(hbox)


# ============================================================
# FOCUS
# ============================================================

func _on_focus_entered() -> void:
	$BG.theme_type_variation = "FocusPanel"


func _on_focus_exited() -> void:
	$BG.theme_type_variation = ""


# ============================================================
# PURCHASE
# ============================================================

func _on_pressed() -> void:
	var upgrade_cost := _get_upgrade_cost()

	if not _can_afford(upgrade_cost):
		print("Not enough item to buy")
		return

	_pay_cost(upgrade_cost)

	Data.shop_connection[shop_type]["tracker"].append(item_enum)

	press.emit(shop_type)


func _get_upgrade_cost() -> Dictionary:
	if shop_type == Enum.Shop.MAIN:
		return Data.MACHINE_UPGRADE_COST[Data.difficulty][item_enum]["cost"]

	return Data.STYLE_UPGRADES[Data.difficulty][item_enum]["cost"]


func _can_afford(cost: Dictionary) -> bool:
	for item in cost:
		if Data.items_amount[Data.difficulty][item] < cost[item]:
			return false

	return true


func _pay_cost(cost: Dictionary) -> void:
	for item in cost:
		Data.items_amount[Data.difficulty][item] -= cost[item]
