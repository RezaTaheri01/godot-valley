extends Area2D

var direction: Vector2
var speed: int = 200

func setup(start_pos: Vector2, new_dir: Vector2):
	position = start_pos
	direction = new_dir
	$Timer.start()
	

func _process(delta: float) -> void:
	position += direction * speed * delta


func _on_timer_timeout() -> void:
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Sword_able"):
		body.hit(Enum.Tool.SWORD, direction)
		queue_free()
