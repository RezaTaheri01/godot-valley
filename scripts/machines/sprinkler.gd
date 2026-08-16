extends Machines

signal water_near_soils(sprinkler_coord: Vector2i)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Prevent the sprinkler from starting another watering cycle
# while the current animation is still playing.
var _busy := false


# ============================================================
# SETUP
# ============================================================

func setup(grid_coord: Vector2i, level: Node2D, parent: Node2D, curr_machine: int) -> void:
	# Notify the level whenever this sprinkler waters nearby soil.
	water_near_soils.connect(level._water_near_soils)

	super.setup(grid_coord, level, parent, curr_machine)


# ============================================================
# TIMER
# ============================================================

func _on_timer_timeout() -> void:
	# Ignore the timer if the previous watering cycle
	# hasn't finished yet.
	if _busy:
		return

	_busy = true

	# Play the watering animation.
	sprite.play("action")

	# Tell the level to water the surrounding soil tiles.
	water_near_soils.emit(coord)

	# Wait until the animation has finished.
	await sprite.animation_finished

	# Return to the idle animation.
	sprite.play("default")

	_busy = false
