extends TextureRect

# Displays an inventory item's icon and current quantity.
# Updates the displayed quantity whenever the item's amount changes.

var curr_item: Enum.Item
var last_amount: int = -1

func setup(item: Enum.Item):
	curr_item = item
	texture = Data.TEXTURES[item]
	$Label.text = str(Data.items_amount[Data.difficulty][item])



func update_amount() -> bool:
	var current_amount: int = Data.items_amount[Data.difficulty][curr_item]

	if current_amount == last_amount:
		return false

	last_amount = current_amount
	$Label.text = str(current_amount)
	return true
