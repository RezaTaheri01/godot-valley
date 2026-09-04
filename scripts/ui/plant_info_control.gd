extends Control


func _process(_delta: float) -> void:
	if $MarginContainer.visible:
		if Input.is_action_just_pressed("scroll_down"):
			$MarginContainer/ScrollContainer.scroll_vertical += 100
		if Input.is_action_just_pressed("scroll_up"):
			$MarginContainer/ScrollContainer.scroll_vertical -= 100
			
		
func add(child: PanelContainer):
	$MarginContainer/ScrollContainer/VBoxContainer.add_child(child)

func hide_show_ui() -> bool:
	$MarginContainer.visible = not $MarginContainer.visible
	return $MarginContainer.visible
