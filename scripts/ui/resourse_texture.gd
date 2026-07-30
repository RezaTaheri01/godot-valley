extends TextureRect

var curr_item: Enum.Item


func setup(item: Enum.Item):
	curr_item = item
	texture = Data.TEXTURES[item]
	$Label.text = str(Data.items_amount[Data.difficulty][item])


func update():
	$Label.text = str(Data.items_amount[Data.difficulty][curr_item])
