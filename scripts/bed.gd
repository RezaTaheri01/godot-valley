extends StaticBody2D

var _can_interact: bool = false

# Whether the player can currently interact with this object.
var can_interact: bool = false:
	get:
		return _can_interact
	set(value):
		_can_interact = value
		$InteractSign.visible = value


func _ready() -> void:
	can_interact = false


# Called when the player interacts with this object.
func interact(player: CharacterBody2D) -> void:
	if not can_interact:
		return

	player.day_change.emit()
