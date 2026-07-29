extends StaticBody2D

@onready var flash_sprite_2d_upper: Sprite2D = $FlashSprite2DUpper
@onready var flash_sprite_2d_bottom: Sprite2D = $FlashSprite2DBottom

const apple_texture = preload("res://graphics/plants/apple.png")
var tree_health := Data.APPLE_TREE_HEALTH
var apple_range = [2, 4]

var color_tween: Tween


func _ready() -> void:
	flash_sprite_2d_upper.frame = [0, 1, 1, 3].pick_random()
	add_to_group("Tree")
	create_apple()
	$CollisionShapeStumpD2.disabled = true


func hit(tool: Enum.Tool, _attacker_position: Vector2):
	if tool == Enum.Tool.AXE:
		flash_sprite_2d_upper.flash()
		flash_sprite_2d_bottom.flash()
		
		get_apple()
		tree_health -= 1
		if tree_health == 0:
			Data.items_amount[Enum.Item.WOOD] += 1
			self.flash_sprite_2d_upper.hide()
			self.flash_sprite_2d_bottom.hide()
			
			$CollisionShapeTree2D.disabled = true
			$Stump.show()
			$CollisionShapeStumpD2.disabled = false
			
			self.remove_from_group("Tree")


func get_apple():
	if $Apples.get_children():
		$Apples.get_children().pick_random().queue_free()
		Data.items_amount[Enum.Item.APPLE] += 1


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


func _on_behid_tree_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# Kill existing tween to prevent conflicts
		if color_tween and color_tween.is_valid():
			color_tween.kill()
		
		color_tween = create_tween()
		color_tween.tween_property(flash_sprite_2d_upper, "modulate", Color("ffffff96"), 0.2)
		color_tween.parallel().tween_property($Apples, "modulate", Color("ffffff96"), 0.2)


func _on_behid_tree_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# Kill existing tween to prevent conflicts
		if color_tween and color_tween.is_valid():
			color_tween.kill()
		
		color_tween = create_tween()
		color_tween.tween_property(flash_sprite_2d_upper, "modulate", Color("ffffff"), 0.2)
		color_tween.parallel().tween_property($Apples, "modulate", Color("ffffff"), 0.2)
