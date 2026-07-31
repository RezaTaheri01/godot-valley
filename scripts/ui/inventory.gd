extends Control

# Manages the inventory UI and periodically refreshes displayed item amounts.

const RESOURCE_TEXTURE_SCENE := preload(
	"res://scenes/ui/resourse_texture.tscn"
)


func _ready() -> void:
	_create_resource_items()
	$Timer.start()


func _create_resource_items() -> void:
	for item: Enum.Item in Data.items_amount[Data.difficulty].keys():
		var resource_texture = RESOURCE_TEXTURE_SCENE.instantiate()
		resource_texture.setup(item)
		$VBoxContainer.add_child(resource_texture)


func _on_timer_timeout() -> void:
	for child in $VBoxContainer.get_children():
		child.update_amount()
