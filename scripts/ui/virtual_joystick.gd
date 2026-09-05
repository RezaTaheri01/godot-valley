extends Control

@onready var knob: Control = $Knob

var dragging := false
var center: Vector2
var value := Vector2.ZERO

@export var radius := 70.0


func _ready():
	center = size / 2.0
	knob.position = center - knob.size / 2.0


func _input(event):
	if not visible:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var distance_to_knob: float = event.position.distance_to(
				knob.global_position
			)

			if distance_to_knob > 250.0:
				return
				
			if event.pressed:
				dragging = true
				update_joystick(event.position)
			else:
				dragging = false
				reset_joystick()


	elif event is InputEventMouseMotion:

		if dragging:
			update_joystick(event.position)


func update_joystick(screen_position: Vector2):

	# Convert mouse screen position into joystick local position
	var local_position = get_global_transform().affine_inverse() * screen_position

	var offset = local_position - center

	if offset.length() > radius:
		offset = offset.normalized() * radius

	knob.position = center + offset - knob.size / 2.0

	value = offset / radius


func reset_joystick():

	value = Vector2.ZERO

	knob.position = center - knob.size / 2.0



func get_value() -> Vector2:
	return value
