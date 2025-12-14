extends Node3D

@export var required_keys := 3

@onready var area = $Area3D
@onready var label = $Label3D
@onready var audio = $AudioStreamPlayer

const SFX_DOOR = preload("res://sounds/door-opening-78648.mp3")

func _ready():
	label.visible = false
	area.body_entered.connect(_on_enter)
	area.body_exited.connect(_on_exit)

func interact(player):
	if player.collected_key_pieces >= required_keys:
		audio.stream = SFX_DOOR
		audio.play()
		player.player_escape()
	else:
		player.subtitle.text = "It's locked..."
		await get_tree().create_timer(2.0).timeout
		player.subtitle.text = ""

func _on_enter(body):
	if body.is_in_group("player"):
		body.interact_target = self
		label.visible = true

func _on_exit(body):
	if body.is_in_group("player"):
		body.interact_target = null
		label.visible = false
