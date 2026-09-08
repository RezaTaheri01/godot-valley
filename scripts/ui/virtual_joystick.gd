extends Control

@onready var knob: Control = $Knob

@export var radius := 70.0

var dragging := false
var touch_index := -1

var center: Vector2
var value := Vector2.ZERO


func _ready():
	center = size / 2.0
	knob.position = center - knob.size / 2.0


func _input(event):
	if not visible:
		return

	# =========================
	# Touch Input
	# =========================
	if event is InputEventScreenTouch:

		# Finger pressed
		if event.pressed:

			# Joystick already has a finger
			if touch_index != -1:
				return

			var knob_center := knob.global_position + knob.size / 2.0

			var distance_to_knob = event.position.distance_to(
				knob_center
			)

			# Touch is too far from joystick
			if distance_to_knob > 250.0:
				return

			# Assign this finger to the joystick
			touch_index = event.index
			dragging = true

			update_joystick(event.position)

		# Finger released
		else:

			# Only release the finger controlling the joystick
			if event.index == touch_index:
				dragging = false
				touch_index = -1
				reset_joystick()


	# =========================
	# Touch Drag
	# =========================
	elif event is InputEventScreenDrag:

		# Only the joystick's finger can move the joystick
		if dragging and event.index == touch_index:
			update_joystick(event.position)


	# =========================
	# Mouse Input
	# =========================
	elif event is InputEventMouseButton:

		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if event.pressed:

			var knob_center := knob.global_position + knob.size / 2.0

			var distance_to_knob = event.position.distance_to(
				knob_center
			)

			if distance_to_knob > 250.0:
				return

			dragging = true
			update_joystick(event.position)

		else:
			dragging = false
			reset_joystick()


	# =========================
	# Mouse Drag
	# =========================
	elif event is InputEventMouseMotion:

		if dragging:
			update_joystick(event.position)


func update_joystick(screen_position: Vector2):

	# Convert screen position to joystick local position
	var local_position := (
		get_global_transform().affine_inverse() * screen_position
	)

	var offset := local_position - center

	# Limit knob movement to radius
	if offset.length() > radius:
		offset = offset.normalized() * radius

	# Move knob
	knob.position = center + offset - knob.size / 2.0

	# Normalize joystick value
	value = offset / radius


func reset_joystick():

	value = Vector2.ZERO

	knob.position = center - knob.size / 2.0


func get_value() -> Vector2:
	return value
