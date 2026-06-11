extends Node2D

# ============================================================================
# Fishing Mini-game Controller
# Controls the bar-catching mechanic where the player must keep the fish
# within the moving bar to fill a progress bar and catch the fish.
# ============================================================================

# References & Configuration
var y_range: float                          # Vertical range of the fishing area
var half_bar_height: float                  # Half height of the catching bar
var sprite_size: Vector2                    # Size of the bar sprite
var fish_enum: Enum.Fish                    # Currently selected fish type

# Movement Variables
var bar_velocity: float = 8.0               # Current vertical velocity of the bar
var bar_addon_velocity: float = 20.0        # Acceleration added to bar each frame
var fish_velocity: float = 16.0             # Current vertical velocity of the fish

# Game State
var progress: float = 30.0                  # Current catch progress (0-100)
var catch_speed: float = 0.0                # How fast progress increases when catching
var lose_speed: float = 0.0                 # How fast progress decreases when missing

# Signals
signal fish_game_finish(is_success: bool)   # Emitted when game ends, true if caught


# ============================================================================
# LIFECYCLE METHODS
# ============================================================================

func _ready() -> void:
	"""Initialize the fishing mini-game and hide it until revealed."""
	hide()
	
	# Get the vertical range from the background panel
	var panel: NinePatchRect = $Control/NinePatchRect
	y_range = panel.size[1]
	
	# Get bar sprite dimensions and calculate half height for collision detection
	sprite_size = $BarSprite.get_rect().size
	half_bar_height = sprite_size[1] / 2.0 + 2.0  # +2 pixels for visual padding
	
	# Configure progress bar
	var progress_bar: TextureProgressBar = $Control/TextureProgressBar
	progress_bar.value = 0
	progress_bar.min_value = 0
	progress_bar.max_value = 100


func _process(delta: float) -> void:
	"""
	Update game logic each frame when visible.
	Handles bar movement, fish movement, collision detection, and progress updates.
	"""
	if not visible:
		return  # Exit early if game isn't active
	
	# ------------------------------------------------------------------------
	# BAR MOVEMENT
	# ------------------------------------------------------------------------
	bar_velocity += bar_addon_velocity * delta
	$BarSprite.position.y += bar_velocity * delta
	
	# Clamp bar position to prevent it from escaping the fishing area
	$BarSprite.position.y = clamp(
		$BarSprite.position.y,
		-y_range / 2.0 + half_bar_height,
		y_range / 2.0 - half_bar_height
	)
	
	# ------------------------------------------------------------------------
	# FISH MOVEMENT
	# ------------------------------------------------------------------------
	$FishSprite.position.y += fish_velocity * delta
	
	# Bounce fish off top/bottom boundaries
	var fish_top_edge: float = -y_range / 2.0
	var fish_bottom_edge: float = y_range / 2.0
	
	if $FishSprite.position.y <= fish_top_edge or $FishSprite.position.y >= fish_bottom_edge:
		fish_velocity *= -1  # Reverse direction
		# Slight position correction to prevent sticking at edges
		$FishSprite.position.y = clamp($FishSprite.position.y, fish_top_edge, fish_bottom_edge)
	
	# ------------------------------------------------------------------------
	# COLLISION DETECTION & PROGRESS UPDATE
	# ------------------------------------------------------------------------
	var bar_top: float = $BarSprite.position.y - half_bar_height
	var bar_bottom: float = $BarSprite.position.y + half_bar_height
	var fish_y: float = $FishSprite.position.y
	
	# Check if fish is within the bar's catching zone
	if fish_y >= bar_top and fish_y <= bar_bottom:
		progress += catch_speed * delta
	else:
		progress -= lose_speed * delta
	
	# Clamp progress to valid range
	progress = clamp(progress, 0.0, 100.0)
	
	# Update UI
	$Control/TextureProgressBar.value = progress


# ============================================================================
# PUBLIC METHODS (Called from external scripts/input handling)
# ============================================================================

func apply_bar_boost(boost_velocity: float = -25.0) -> void:
	"""
	Apply a velocity boost to the bar (typically from player input).
	
	Parameters:
		boost_velocity: The velocity to apply (negative = up, positive = down)
	"""
	bar_velocity = boost_velocity


func reveal() -> void:
	"""
	Start a new fishing attempt by displaying the UI and setting up a random fish.
	Called when the player begins a fishing encounter.
	"""
	# Select a random fish type from available options
	fish_enum = Enum.Fish.values().pick_random()
	
	# Load fish-specific data
	var fish_data: Dictionary = Data.FISH_DATA[fish_enum]
	
	# Apply fish properties
	$FishSprite.texture = load(fish_data["icon_texture"])
	catch_speed = fish_data["catch_speed"]
	lose_speed = fish_data["lose_speed"]
	progress = fish_data["start_progress"]
	
	# Reset progress bar
	$Control/TextureProgressBar.value = progress
	
	# Position fish randomly within the fishing area
	var random_y: float = randf_range(-y_range / 2.0, y_range / 2.0)
	$FishSprite.position.y = random_y
	
	# Set random initial fish velocity (either upward or downward)
	var velocity_options: Array[float] = [
		randf_range(15.0, 25.0),   # Moving down
		randf_range(-25.0, -15.0)  # Moving up
	]
	fish_velocity = velocity_options.pick_random()
	
	# Randomize timer for future velocity changes
	$FishUpdateTimer.wait_time = randf_range(1.0, 3.0)
	
	# Show the game UI
	show()


# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_timer_timeout() -> void:
	"""
	Periodically change fish direction to make the mini-game more challenging.
	Called when FishUpdateTimer times out.
	"""
	# Randomly choose new velocity (could be same direction or opposite)
	var velocity_options: Array[float] = [
		randf_range(15.0, 25.0),   # Move down
		randf_range(-25.0, -15.0)  # Move up
	]
	fish_velocity = velocity_options.pick_random()
	
	# Set random interval for next direction change (1-3 seconds)
	$FishUpdateTimer.wait_time = randf_range(1.0, 3.0)


func _on_texture_progress_bar_value_changed(value: float) -> void:
	"""
	Check for game completion when progress bar value changes.
	Emits signal with success status (caught if progress reached 100, escaped if 0).
	"""
	if value >= 100.0:
		# Success - fish caught!
		hide()
		print("Fish caught successfully!")
		fish_game_finish.emit(true)
		
	elif value <= 0.0:
		# Failure - fish escaped
		hide()
		print("Fish escaped!")
		fish_game_finish.emit(false)
