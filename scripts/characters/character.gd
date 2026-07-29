class_name ShopCharacter extends CharacterBody2D

# -----------------------------------------------------------------------------
# Shop Character
#
# Handles:
# - Player interaction
# - NPC facing the player
# - Dialog progression
# - Opening the shop
# - Sold-out state
# - Support for both Sprite2D and AnimatedSprite2D
# -----------------------------------------------------------------------------

# =========================
# Exported Variables
# =========================

# Dialog shown before opening the shop.
@export var dialog: Array[String]

# Dialog shown when every item has been purchased.
@export var sold_out_dialog: Array[String] = ["Sold out"]

# Sprite used when not using AnimatedSprite2D.
@export var texture: Texture2D

# Type of shop this NPC represents.
@export var shop_type: Enum.Shop

# Optional animated sprite.
# If assigned, Sprite2D will be hidden.
@export var animated_sprite: AnimatedSprite2D


# =========================
# Internal Variables
# =========================

# Current dialog index.
var dialog_index: int = 0

# Whether the shop can currently be opened.
var can_open_shop: bool = true

# Emits when dialog finishes and the shop should open.
signal open_shop(shop_type: Enum.Shop)


# =========================
# Constants
# =========================

# Sprite sheet row for each direction.
const DIRECTION_MAP := {
	Vector2i.LEFT: 1,
	Vector2i.RIGHT: 2,
	Vector2i.DOWN: 0,
	Vector2i.UP: 3
}

# Animation name for each direction.
const ANIMATION_MAP := {
	Vector2i.LEFT: "idle_left",
	Vector2i.RIGHT: "idle_right",
	Vector2i.DOWN: "idle_down",
	Vector2i.UP: "idle_up"
}


# =========================
# Interaction State
# =========================

# Whether the player is close enough to interact.
var _can_interact := false

var can_interact: bool:
	get:
		return _can_interact
	set(value):
		_can_interact = value

		# Show or hide the interaction icon.
		$InteractSign.visible = value

		# Reset dialog when the player leaves.
		if !value:
			$Dialog.hide()
			dialog_index = 0


# =========================
# Ready
# =========================

func _ready() -> void:
	# Assign the texture.
	$Sprite2D.texture = texture

	# Hide interaction sign by default.
	can_interact = false

	# Use AnimatedSprite if available.
	if animated_sprite:
		$Sprite2D.hide()
		animated_sprite.play("idle_down")
	else:
		# Otherwise use Sprite2D.
		$AnimatedSprite2D.hide()
		$Sprite2D.frame_coords.y = DIRECTION_MAP[Vector2i.DOWN]


# =========================
# Interaction
# =========================

func interact(player: CharacterBody2D) -> void:

	if !can_interact:
		return

	# -------------------------------------------------------------------------
	# Rotate the NPC to face the player.
	# -------------------------------------------------------------------------

	var raw_dir = (player.position - position).normalized()

	var dir: Vector2i
	if abs(raw_dir.x) > abs(raw_dir.y):
		# Horizontal
		dir = Vector2i(sign(raw_dir.x), 0)
	else:
		# Vertical
		dir = Vector2i(0, sign(raw_dir.y))
		
		
	# Play the correct idle animation.
	if animated_sprite:
		animated_sprite.play(ANIMATION_MAP.get(dir, "idle_down"))
	else:
		$Sprite2D.frame_coords.y = DIRECTION_MAP.get(dir, 0)

	# -------------------------------------------------------------------------
	# Check if the shop is sold out.
	# -------------------------------------------------------------------------

	var shop_data = Data.shop_connection[shop_type]

	can_open_shop = (
		shop_data["tracker"].size() <
		shop_data["all"].size()
	)

	# Choose which dialog to display.
	var current_dialog: Array[String]

	if can_open_shop:
		current_dialog = dialog
	else:
		current_dialog = sold_out_dialog

	# -------------------------------------------------------------------------
	# Show dialog.
	# -------------------------------------------------------------------------

	$Dialog.show()

	# Continue through the dialog.
	if dialog_index < current_dialog.size():
		$Dialog.set_text(current_dialog[dialog_index])
		dialog_index += 1
		return

	# Dialog finished.
	$Dialog.hide()
	dialog_index = 0

	# Open the shop if it is available.
	if can_open_shop:
		open_shop.emit(shop_type)
