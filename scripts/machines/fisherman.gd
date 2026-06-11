extends Machine

var anim_name: String = "up"


func setup(grid_coord: Vector2i, level: Node2D, parent: Node2D):
	# Define the 4 directions to check
	var directions = {
		Vector2i.UP: "up",
		Vector2i.RIGHT: "right",
		Vector2i.DOWN: "down",
		Vector2i.LEFT: "left"
	}
	
	var found_water = false
	
	# Check each direction for water
	for dir in directions:
		var check_coord = grid_coord + dir
		var cell = level.waterGrassLayer.get_cell_tile_data(check_coord)
		
		# Make sure cell exists before accessing custom data
		if cell and cell.get_custom_data("water"):
			anim_name = directions[dir]
			found_water = true
			break
	
	# Only call super if water was found
	if found_water:
		return super.setup(grid_coord, level, parent)
	else:
		return false  # or return null, or don't complete setup


func _ready() -> void:
	$Control/TextureProgressBar.min_value = 0
	$Control/TextureProgressBar.max_value = 100
	$Control/TextureProgressBar.value = 0
	
	start_fishing()
	
	
func _process(_delta: float) -> void:
	if $Timer.is_stopped():
		return
		
	var progress = (1 - ($Timer.time_left / $Timer.wait_time)) * 100
	$Control/TextureProgressBar.value = progress


func _on_timer_timeout() -> void:
	Data.ITEMS_AMOUNT[Enum.Item.FISH] += 1
	start_fishing()
	
	
func start_fishing():
	$AnimatedSprite2D.play(anim_name)
	await  $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.play(anim_name + "_idle")
	$Timer.start()
