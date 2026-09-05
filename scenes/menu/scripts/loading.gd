extends Control

@export var scene_path: String = "res://scenes/levels/level.tscn"

@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar
@onready var label: Label = $CenterContainer/VBoxContainer/Label


func _ready() -> void:
	get_tree().paused = false

	ResourceLoader.load_threaded_request(scene_path)


func _process(_delta: float) -> void:
	var progress := []
	var status := ResourceLoader.load_threaded_get_status(scene_path, progress)

	if progress.size() > 0:
		progress_bar.value = progress[0] * 100.0

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			label.text = "Loading..."

		ResourceLoader.THREAD_LOAD_LOADED:
			label.text = "Starting..."
			var scene := ResourceLoader.load_threaded_get(scene_path)

			if scene:
				get_tree().change_scene_to_packed(scene)

		ResourceLoader.THREAD_LOAD_FAILED:
			label.text = "Failed to load!"
			push_error("Failed to load scene: " + scene_path)
