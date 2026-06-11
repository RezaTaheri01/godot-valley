extends Control

@onready var tool_container: HBoxContainer = $ToolContainer
@onready var seed_container: HBoxContainer = $SeedContainer

# tool ui textures
const TOOL_TEXTURES = {
	Enum.Tool.AXE: preload("res://graphics/icons/axe.png"),
	Enum.Tool.HOE: preload("res://graphics/icons/hoe.png"),
	Enum.Tool.WATER: preload("res://graphics/icons/water.png"),
	Enum.Tool.SWORD: preload("res://graphics/icons/sword.png"),
	Enum.Tool.FISH: preload("res://graphics/icons/fish.png"),
	Enum.Tool.SEED: preload("res://graphics/icons/wheat.png")
	}
	
const SEED_TEXTURES = {
	Enum.Seed.CORN: preload("res://graphics/icons/corn.png"),
	Enum.Seed.PUMPKIN: preload("res://graphics/icons/pumpkin.png"),
	Enum.Seed.TOMATO: preload("res://graphics/icons/tomato.png"),
	Enum.Seed.WHEAT: preload("res://graphics/icons/wheat.png")
	}

var tool_texture_scene = preload("res://scenes/ui/tool_ui_texture.tscn")


func _ready() -> void:
	tool_container.hide()
	seed_container.hide()
	texture_setup(Enum.Tool.values(), TOOL_TEXTURES, tool_container)
	texture_setup(Enum.Seed.values(), SEED_TEXTURES, seed_container)
	
	
func texture_setup(enum_list: Array, textures: Dictionary, container: HBoxContainer):
	for enum_id in enum_list:
		var tool_texture = tool_texture_scene.instantiate()
		
		container.add_child(tool_texture)
		
		tool_texture.setup(enum_id, textures[enum_id])


func reveal(current_tool=null, current_seed=null):
	$Timer.start()
	if current_tool != null:
		tool_container.show()
		seed_container.hide()
		for texture in tool_container.get_children():
			texture.highlight(current_tool == texture.tool_enum)
	elif current_seed != null:
		tool_container.hide()
		seed_container.show()	
		for texture in seed_container.get_children():
			texture.highlight(current_seed == texture.tool_enum)


func _on_timer_timeout() -> void:
	tool_container.hide()
	seed_container.hide()
