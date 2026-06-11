class_name ShopCharacter extends CharacterBody2D

@export var dialog: Array[String]
@export var texture: Texture2D
@export var shop_type: Enum.Shop
@export var animated_sprite: AnimatedSprite2D
var dialog_index: int
var can_open_shop: bool = true

signal open_shop(shop_type: Enum.Shop)

var can_interact: bool = false:
	set(value):
		can_interact = value
		$InteractSign.visible = value
		if not value:
			$Dialog.hide()
			dialog_index = 0
	
		

func _ready() -> void:
	$Sprite2D.texture = texture
	can_interact = false
	if animated_sprite:
		$Sprite2D.hide()
		animated_sprite.play("idle_down")
	else:
		$AnimatedSprite2D.hide()
		$Sprite2D.frame_coords.y = 0
		

func interact(player: CharacterBody2D) -> void:
	if can_interact:
		print("Interact")
		var raw_dir = (player.position - position).normalized()
		
		# Find the cardinal direction with highest absolute value
		var dir: Vector2i
		if abs(raw_dir.x) > abs(raw_dir.y):
			# Horizontal priority
			dir = Vector2i(sign(raw_dir.x), 0)
		else:
			# Vertical priority
			dir = Vector2i(0, sign(raw_dir.y))
		
		var direction_map = {
			Vector2i.LEFT: 1,
			Vector2i.RIGHT: 2,
			Vector2i.DOWN: 0,
			Vector2i.UP: 3
		}
		
		var animation_map = {
			Vector2i.LEFT: "idle_left",
			Vector2i.RIGHT: "idle_right",
			Vector2i.DOWN: "idle_down",
			Vector2i.UP: "idle_up"
		}
		
		if animated_sprite:
			var anim_name = animation_map.get(dir, "idle_left")
			animated_sprite.play(anim_name)
		else:
			$Sprite2D.frame_coords.y = direction_map[dir]
		
		if (Data.shop_connection[shop_type]["tracker"].size() ==
			Data.shop_connection[shop_type]["all"].size()) :
			dialog = ["Sold out"]
			can_open_shop = false
		
		$Dialog.show()
		if dialog_index < dialog.size():
			$Dialog.set_text(dialog[dialog_index])
			dialog_index += 1
		else:
			$Dialog.hide()
			dialog_index = 0
			if can_open_shop:
				open_shop.emit(shop_type)
				
				
