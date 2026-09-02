class_name MenuBase
extends Control


var is_open := false
var is_animating := false
var last_foucs: Button = null

signal pause_menu_foucs(enable: bool)

func show_menu(foucs: Button = null) -> void:
	last_foucs = foucs
		
	if is_open or is_animating:
		return

	is_open = true
	is_animating = true

	show()

	scale = Vector2.ZERO
	modulate.a = 0.0
	pivot_offset = size / 2

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)

	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

	await tween.finished

	is_animating = false
	
	pause_menu_foucs.emit(false)


func hide_menu() -> void:
	if not is_open or is_animating:
		return

	is_animating = true

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)

	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(self, "scale", Vector2.ZERO, 0.25)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)

	await tween.finished

	hide()

	is_open = false
	is_animating = false
	
	pause_menu_foucs.emit(true)
	
	if last_foucs:
		last_foucs.grab_focus()
		
