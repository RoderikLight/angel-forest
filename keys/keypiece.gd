extends Node3D

@onready var area = $Area3D

func _ready():
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	print("ENTERED:", body.name)
	print("Is player group:", body.is_in_group("player"))
		
	if body.is_in_group("player"):
		body.on_key_collected(self)
		queue_free()
