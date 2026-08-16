extends Machines

# ============================================================
# SETTINGS
# ============================================================

var anim_name: String = "up"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var progress_bar: TextureProgressBar = $Control/TextureProgressBar


# ============================================================
# SETUP
# ============================================================

func setup(grid_coord: Vector2i, level: Node2D, parent: Node2D, curr_machine: int) -> bool:
	# Directions to search for adjacent water.
	var directions := {
		Vector2i.UP: "up",
		Vector2i.RIGHT: "right",
		Vector2i.DOWN: "down",
		Vector2i.LEFT: "left"
	}

	# Find the first water tile surrounding this machine.
	for direction in directions:
		var tile_data = level.water_grass_layer.get_cell_tile_data(grid_coord + direction)

		if tile_data and tile_data.get_custom_data("water"):
			anim_name = directions[direction]
			super.setup(grid_coord, level, parent, curr_machine)
			return true

	# Cannot be placed if no adjacent water exists.
	return false


func _ready() -> void:
	# Configure the fishing progress bar.
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0

	start_fishing()


# ============================================================
# PROCESS
# ============================================================

func _process(_delta: float) -> void:
	# Update the progress bar while fishing.
	if timer.is_stopped():
		return

	progress_bar.value = (1.0 - timer.time_left / timer.wait_time) * 100.0


# ============================================================
# TIMER
# ============================================================

func _on_timer_timeout() -> void:
	# Give the player one fish and begin the next fishing cycle.
	Data.items_amount[Data.difficulty][Enum.Item.FISH] += 1
	start_fishing()


# ============================================================
# FISHING
# ============================================================

func start_fishing() -> void:
	# Play the casting animation.
	sprite.play(anim_name)
	await sprite.animation_finished

	# Switch to the idle animation while waiting.
	sprite.play(anim_name + "_idle")

	timer.wait_time = Data.FISHING_TIMER_TIME[Data.difficulty][Data.fisherman_level]
	
	# Begin the fishing timer.
	timer.start()
