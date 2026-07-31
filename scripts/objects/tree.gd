extends StaticBody2D


# ============================================================
# REFERENCES
# ============================================================

@onready var flash_sprite_2d_upper: Sprite2D = $FlashSprite2DUpper
@onready var flash_sprite_2d_bottom: Sprite2D = $FlashSprite2DBottom
@onready var apples: Node2D = $Apples


# ============================================================
# CONFIGURATION
# ============================================================

const APPLE_TEXTURE := preload("res://graphics/plants/apple.png")

const PLAYER_TREE_COLOR := Color("ffffff96")
const DEFAULT_TREE_COLOR := Color("ffffff")

const TREE_COLOR_TWEEN_DURATION := 0.2


# ============================================================
# STATE
# ============================================================

var tree_health: float = Data.APPLE_TREE_HEALTH[Data.difficulty]
var color_tween: Tween


# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	flash_sprite_2d_upper.frame = Data.APPLE_TREE_SPRITES.pick_random()

	add_to_group("Tree")

	# Trees start without a stump collision.
	$CollisionShapeStumpD2.disabled = true

	create_apple()


# ============================================================
# COMBAT
# ============================================================

func hit(tool: Enum.Tool, _attacker_position: Vector2) -> void:
	if tool != Enum.Tool.AXE:
		return

	# Flash the tree when it is hit.
	flash_sprite_2d_upper.flash()
	flash_sprite_2d_bottom.flash()

	var damage_amount: float = Data.TOOL_DAMAGE_AMOUNT[Data.difficulty][tool][Data.sword_level]

	# Each axe hit can collect apples that fall from the tree.
	get_apple(damage_amount)

	tree_health -= damage_amount

	if tree_health <= 0:
		_destroy_tree()


func _destroy_tree() -> void:
	Data.items_amount[Data.difficulty][Enum.Item.WOOD] += Data.WoodAmount[Data.difficulty]

	flash_sprite_2d_upper.hide()
	flash_sprite_2d_bottom.hide()

	$CollisionShapeTree2D.disabled = true

	$Stump.show()
	$CollisionShapeStumpD2.disabled = false

	remove_from_group("Tree")


# ============================================================
# APPLES
# ============================================================

func get_apple(damage_amount: float) -> void:
	var apple_list := apples.get_children()

	if apple_list.is_empty():
		return

	var apple_count = min(int(damage_amount), apple_list.size())

	for i in apple_count:
		var apple = apple_list.pick_random()

		if is_instance_valid(apple):
			apple.queue_free()
			Data.items_amount[Data.difficulty][Enum.Item.APPLE] += 1

		# Stop if there are no more apples available.
		apple_list.erase(apple)

		if apple_list.is_empty():
			break


func create_apple() -> void:
	if not $CollisionShapeStumpD2.disabled:
		return

	# Remove existing apples before creating the new set.
	for child in apples.get_children():
		child.queue_free()

	var apple_range: Array = Data.APPLE_RANGE[Data.difficulty]
	var apple_count := randi_range(apple_range[0], apple_range[1])

	var apple_markers := $AppleSpawnPositions.get_children().duplicate()
	apple_markers.shuffle()

	# Never create more apples than available spawn positions.
	apple_count = min(apple_count, apple_markers.size())

	# Trees recover one health point each day.
	tree_health = min(
		Data.APPLE_TREE_HEALTH[Data.difficulty],
		tree_health + 1
	)

	# Never have more apples than the tree's current health.
	apple_count = min(apple_count, int(tree_health))

	for i in apple_count:
		var apple := Sprite2D.new()
		apple.texture = APPLE_TEXTURE
		apple.position = apple_markers[i].position
		apples.add_child(apple)


# ============================================================
# PLAYER DETECTION
# ============================================================

func _on_behid_tree_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		_set_tree_highlight(true)


func _on_behid_tree_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		_set_tree_highlight(false)


func _set_tree_highlight(enabled: bool) -> void:
	# Cancel the previous tween so enter/exit events cannot fight each other.
	if color_tween and color_tween.is_valid():
		color_tween.kill()

	var target_color := PLAYER_TREE_COLOR if enabled else DEFAULT_TREE_COLOR

	color_tween = create_tween()

	color_tween.tween_property(
		flash_sprite_2d_upper,
		"modulate",
		target_color,
		TREE_COLOR_TWEEN_DURATION
	)

	color_tween.parallel().tween_property(
		apples,
		"modulate",
		target_color,
		TREE_COLOR_TWEEN_DURATION
	)
