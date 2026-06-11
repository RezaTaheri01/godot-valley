#@tool
extends StaticBody2D

const DECO_TEXTURES := {
	0: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/01.png"),
	1: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/02.png"),
	2: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/03.png"),
	3: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/04.png"),
	4: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/05.png"),
	5: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/06.png"),
	6: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/07.png"),
	7: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/08.png"),
	8: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/09.png"),
	9: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/10.png"),
	10: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/11.png"),
	11: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/12.png"),
	12: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/13.png"),
	13: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/14.png"),
	14: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/15.png"),
	15: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/16.png"),
	16: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/17.png"),
	17: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/18.png"),
}

@export var random := false

@export_range(0, 10, 1) var size: int = 0:
	set(value):
		size = value
		if is_inside_tree():
			$Sprite2D.texture = DECO_TEXTURES[size]

func _ready() -> void:
	if random:
		size = randi_range(0, 10)
	if size not in [2, 5, 8, 11, 14, 17]:
		$CollisionShape2D.disabled = true
	$Sprite2D.texture = DECO_TEXTURES[size]
