extends Control

@onready var pausecontroller = $"../"

func _on_resume_pressed() -> void:
	pausecontroller.pauseMenu()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
