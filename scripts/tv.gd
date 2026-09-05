extends StaticBody2D


# ============================================================
# STATE
# ============================================================

var _can_interact: bool = false

var can_interact: bool:
	get:
		return _can_interact
	set(value):
		_can_interact = value
		$InteractSign.visible = value


# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	can_interact = false


# ============================================================
# INTERACTION
# ============================================================

func interact(_player: CharacterBody2D) -> void:
	if not can_interact:
		return

	# Play the appropriate animation based on the current forecast.
	var animation := "rain" if Data.forecast_rain else "sun"
	$AnimatedSprite2D.play(animation)

	# Return to the default animation after the effect finishes.
	$Timer.start()


# ============================================================
# SIGNALS
# ============================================================

func _on_timer_timeout() -> void:
	$AnimatedSprite2D.play("default")
