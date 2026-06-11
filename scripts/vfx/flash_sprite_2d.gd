extends Sprite2D


func flash(start_duration: float=0.15, end_duration: float=0.15) -> void:
	var tween = create_tween()
	
	tween.tween_property(material, "shader_parameter/Progress", 0.8, start_duration)
	tween.tween_property(material, "shader_parameter/Progress", 0.0, end_duration)
	
