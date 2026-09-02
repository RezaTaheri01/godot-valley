extends MenuBase

@onready var first_button = $Root/CenterContainer/ButtonPanel/VBoxContainer/HBoxContainer/Easy
signal difficulty(mode: Enum.Difficulty)

func  _ready() -> void:
	hide()

func _on_easy_pressed() -> void:
	difficulty.emit(Enum.Difficulty.EASY)


func _on_normal_pressed() -> void:
	difficulty.emit(Enum.Difficulty.NORMAL)


func _on_hard_pressed() -> void:
	difficulty.emit(Enum.Difficulty.HARD)


func _on_back_pressed() -> void:
	hide_menu()
