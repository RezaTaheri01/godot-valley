extends Control

# Manages the inventory UI and periodically checks for
# changes to displayed item amounts.

const RESOURCE_TEXTURE_SCENE := preload(
	"res://scenes/ui/resourse_texture.tscn"
)

@onready var resource_container = $VBoxContainer
@onready var update_timer: Timer = $Timer

signal save_progress
# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	_create_resource_items()
	update_timer.start()


# ============================================================
# INVENTORY UI
# ============================================================

# Creates one UI element for each available inventory item.
func _create_resource_items() -> void:
	for item: Enum.Item in Data.items_amount[Data.difficulty].keys():
		var resource_texture = RESOURCE_TEXTURE_SCENE.instantiate()

		resource_texture.setup(item)
		resource_container.add_child(resource_texture)


# ============================================================
# INVENTORY UPDATES
# ============================================================

# Checks all inventory UI elements for amount changes.
# Saves the player once if any amount changed.
func _on_timer_timeout() -> void:
	var inventory_changed := false

	for child in resource_container.get_children():
		if child.update_amount():
			inventory_changed = true

	if inventory_changed:
		save_progress.emit()
