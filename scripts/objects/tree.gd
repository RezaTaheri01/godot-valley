extends StaticBody2D

@onready var flash_sprite_2d: Sprite2D = $FlashSprite2D
const apple_texture = preload("res://graphics/plants/apple.png")
var tree_health := Data.APPLE_TREE_HEALTH
var apple_range = [2, 4]


func _ready() -> void:
	$FlashSprite2D.frame = [0, 1, 1].pick_random()
	add_to_group("Tree")
	create_apple()


func hit(tool: Enum.Tool, _attacker_position: Vector2):
	if tool == Enum.Tool.AXE:
		flash_sprite_2d.flash()
		get_apple()
		tree_health -= 1
		if tree_health == 0:
			Data.ITEMS_AMOUNT[Enum.Item.WOOD] += 1
			self.flash_sprite_2d.hide()
			$CollisionShapeTree2D.disabled = true
			$Stump.show()
			$CollisionShapeStumpD2.disabled = false


func get_apple():
	if $Apples.get_children():
		$Apples.get_children().pick_random().queue_free()
		Data.ITEMS_AMOUNT[Enum.Item.APPLE] += 1


func create_apple():
	var num = randi_range(apple_range[0], apple_range[1])
	
	if $CollisionShapeStumpD2.disabled == false:
		return
		
	if $Apples.get_children():
		for child in $Apples.get_children():
			child.queue_free()
			
	var apple_markers = $AppleSpawnPositions.get_children().duplicate(true)
	apple_markers.shuffle()
	
	if num > apple_markers.size():
		num = apple_markers.size()
		
	# Trees heals over days
	tree_health = min(Data.APPLE_TREE_HEALTH, tree_health + 1)
	
	# Apple counts should be equal or less than tree health
	num = min(tree_health, num)
	
	for i in num:
		var sprite = Sprite2D.new()
		sprite.texture = apple_texture
		sprite.position = apple_markers[i].position
		$Apples.add_child(sprite)
