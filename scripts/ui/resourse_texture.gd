extends TextureRect

# Displays an inventory item's icon and current quantity.
# Updates the displayed quantity whenever the item's amount changes.

var curr_item: Enum.Item


func setup(item: Enum.Item):
	curr_item = item
	texture = Data.TEXTURES[item]
	$Label.text = str(Data.items_amount[Data.difficulty][item])


func update_amount():
	$Label.text = str(Data.items_amount[Data.difficulty][curr_item])
