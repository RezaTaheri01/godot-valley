extends StaticBody2D

var can_interact: bool = false:
	set(value):
		can_interact = value
		$InteractSign.visible = value
		

func _ready() -> void:
	can_interact = false
		

func interact(_player: CharacterBody2D) -> void:
	if can_interact:
		$AnimatedSprite2D.play("rain" if Data.FORECAST_RAIN else "sun")
		$Timer.start()
	

func _on_timer_timeout() -> void:
	$AnimatedSprite2D.play("default")
