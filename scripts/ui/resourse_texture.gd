extends TextureRect

var curr_item: Enum.Item


func setup(item: Enum.Item):
	curr_item = item
	texture = Data.TEXTURES[item]
	$Label.text = str(Data.ITEMS_AMOUNT[item])


func update():
	$Label.text = str(Data.ITEMS_AMOUNT[curr_item])
