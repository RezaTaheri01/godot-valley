extends StaticBody2D

var can_interact: bool = false:
	set(value):
		can_interact = value
		$InteractSign.visible = value


func _ready() -> void:
	can_interact = false


func interact(player: CharacterBody2D) -> void:
	if can_interact:
		player.day_change.emit()
