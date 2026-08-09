extends StaticBody2D


# ============================================================
# EDITOR SETTINGS
# ============================================================

@export var random := false
var _size: int = 0
@export_range(0, 17, 1) var size: int = 0:
	get:
		return _size
	set(value):
		_size = value
		if is_inside_tree():
			_update_decoration()
			


# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	if random:
		size = randi_range(0, Data.DECO_TEXTURES.size() - 1)

	_update_decoration()


# ============================================================
# DECORATION
# ============================================================

func _update_decoration() -> void:
	$Sprite2D.texture = Data.DECO_TEXTURES[size]
	$CollisionShape2D.disabled = size not in Data.COLLISION_SIZES
	if not $CollisionShape2D.disabled:
		self.y_sort_enabled = not $CollisionShape2D.disabled
		self.z_index = 0
