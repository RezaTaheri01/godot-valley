extends Control

@onready var res_texture_scene = preload("res://scenes/ui/resourse_texture.tscn")

func _ready() -> void:
	for item: Enum.Item in Data.items_amount[Data.difficulty].keys():
		var res_texture = res_texture_scene.instantiate()
		res_texture.setup(item)
		$VBoxContainer.add_child(res_texture)
		
		
func _physics_process(_delta: float) -> void:
	for child in $VBoxContainer.get_children():
		child.update()
