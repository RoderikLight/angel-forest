extends Node

@onready var pause_menu = $"../Camera3D/PauseMenu"
var paused = false

func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		pauseMenu()
		
func pauseMenu():
	if paused:
		pause_menu.hide()
		get_tree().paused = not get_tree().paused
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		pause_menu.show()
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	paused = !paused
