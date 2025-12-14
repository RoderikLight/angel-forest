extends Node3D

@export var key_scene: PackedScene
@export var keys_to_spawn := 3

func _ready():
	await get_tree().process_frame
	spawn_keys()

func spawn_keys():
	var spawn_points := get_children()
	spawn_points.shuffle()

	for i in min(keys_to_spawn, spawn_points.size()):
		var sp := spawn_points[i]
		if not sp is Node3D:
			continue

		var key = key_scene.instantiate()

		get_parent().add_child(key)

		key.global_transform = sp.global_transform
		key.global_position += Vector3.UP * 0.2

		print("Spawned key at:", key.global_position)
