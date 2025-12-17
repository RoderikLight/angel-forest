extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


@onready var mouse_sensitivity = 0.15 / (get_viewport().get_visible_rect().size.x/1152.0)
@onready var cam = $Camera3D
@onready var flashlight = $Camera3D/Flashlight
@onready var keycounter = $Camera3D/HUD/KeyCounter
@onready var subtitle = $Camera3D/HUD/Subtitles
@onready var vignette = $Camera3D/KillUI/Vignette
@onready var fadeblack = $Camera3D/KillUI/FadeBlack
@onready var audio = $AudioStreamPlayer

var interact_target: Node = null
var is_dead = false
var base_fov = 75.0
var walk_time = 0.0
var flashlight_base_rot = Vector3.ZERO

var flashlight_on = true
var flashlight_energy = 4.0
var flashlight_flicker = false
var flicker_distance = 2.0
var flicker_random = 0.002

const FLASHLIGHT_SWAY_YAW = deg_to_rad(1.5)
const FLASHLIGHT_SWAY_PITCH = deg_to_rad(1.0)
const FLASHLIGHT_WALK_SPEED = 10.0
const SFX_FOOTSTEPS = preload("res://sounds/footsteps-278819.mp3")
const SFX_DEATH = preload("res://sounds/bone-break-3-218510.mp3")
const SFX_WHISPER = preload("res://sounds/riser-horror-330827.mp3")
const SFX_KEYS = preload("res://sounds/jingling-keys-419578.mp3")


func _ready():
	total_key_pieces = GameSettings.total_keys
	keycounter.text = "Keys: 0 / %d" % total_key_pieces
	set_physics_process(true)
	set_process(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	base_fov = cam.fov
	flashlight_base_rot = flashlight.rotation
	subtitle.text = "I need to find a way out of here..."
	await get_tree().create_timer(5.0).timeout
	subtitle.text = ""

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	if flashlight_on:
		_check_flashlight_flicker()
	_update_flashlight(delta)

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		if not audio.playing:
			audio.volume_db = -15.0
			audio.stream = SFX_FOOTSTEPS
			audio.play()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		if audio.playing:
			audio.volume_db = 0.0
			audio.stop()

	move_and_slide()
	
func _unhandled_input(event):
	if event.is_action_pressed("interact") and interact_target:
		interact_target.interact(self)

#DYING STUFF OVER HERE

func on_killed(enemy: Node3D):
	if is_dead:
		return
	is_dead = true
	flashlight.visible = false
	
	set_physics_process(false)
	set_process(false)
	
	start_kill_effect(enemy)

func start_kill_effect(enemy: Node3D):
	#rad neck snap and fov increase to make it feel more brutal!!11!
	cam.rotation.z = deg_to_rad(22) 
	cam.rotation.x += deg_to_rad(5)
	cam.fov = base_fov + 25
	audio.stream = SFX_DEATH
	audio.play()
	_start_vignette_fade(0.75,0.4)
		
	var roll_strength := deg_to_rad(6) 
	for i in 6:
		cam.rotation.z = deg_to_rad(22) + roll_strength
		await get_tree().create_timer(0.05).timeout
		cam.rotation.z = deg_to_rad(22) - roll_strength
		await get_tree().create_timer(0.05).timeout
		roll_strength *= 0.6 
	#This one is the aftershock.
	
	audio.stream = SFX_WHISPER
	audio.play()
	
	#Player character loses consciousness and dies, big sad.
	await get_tree().create_timer(0.5).timeout
	var fov = cam.fov
	for i in 12:
		fov = lerp(fov, base_fov, 0.25)
		cam.fov = fov
		
		fadeblack.color.a = lerp(fadeblack.color.a, 1.0,0.2)
		await get_tree().create_timer(0.05).timeout
		
		
	await get_tree().create_timer(2.0).timeout
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
	
func _start_vignette_fade(target_alpha: float, speed: float):
	_vignette_fade(target_alpha, speed)
		
func _vignette_fade(target_alpha: float, speed: float) -> void:
	for i in 12:
		vignette.color.a = lerp(vignette.color.a, target_alpha, speed)
		await get_tree().create_timer(0.04).timeout
		
# COOL FLASHLIGHT STUFF OVER HERE
func start_flashlight_flicker(duration = 2.0):
	if flashlight_flicker:
		return
		
	flashlight_flicker = true
	var t = 0.0
	while t < duration:
		flashlight.visible = randf() > 0.4
		await get_tree().create_timer(randf_range(0.05,0.12)).timeout
		t += 0.1
	flashlight.visible = flashlight_on
	flashlight_flicker = false
	
func _check_flashlight_flicker():
	var enemy = get_tree().get_nodes_in_group("enemy")

	for e in enemy:
		if not e is Node3D:
			continue
		if global_position.distance_to(e.global_position) < flicker_distance:
			start_flashlight_flicker(1.8)
			return
			
		if randf() < flicker_random:
			start_flashlight_flicker(randf_range(0.6, 1.2))
			
func _update_flashlight(delta: float) -> void:
	#if player is dead js do nothing
	if is_dead:
		return
		
	var is_moving = velocity.length() > 0.1
	
	#wobble while moving
	if is_moving:
		walk_time += delta * FLASHLIGHT_WALK_SPEED
		
		var yaw = sin(walk_time) * FLASHLIGHT_SWAY_YAW
		var pitch = abs(cos(walk_time)) * FLASHLIGHT_SWAY_PITCH
		
		flashlight.rotation.y = flashlight_base_rot.y + yaw
		flashlight.rotation.x = flashlight_base_rot.x + pitch
	
	#stop wobbling and go back to default stance
	else:
		walk_time = 0.0
		flashlight.rotation = flashlight_base_rot
		

#Thingies to do with collecting key pieces
var total_key_pieces = 3
var collected_key_pieces = 0

func on_key_collected(_piece):
	audio.stream = SFX_KEYS
	audio.play()
	collected_key_pieces += 1
	keycounter.text = "Keys: %d/%d" % [collected_key_pieces, total_key_pieces]
	
	if collected_key_pieces >= total_key_pieces:
		subtitle.text = "I need to find the exit now!"
		await get_tree().create_timer(3.0).timeout
		subtitle.text = ""
	else:
		subtitle.text = "I found one of the keys..."
		await get_tree().create_timer(3.0).timeout
		subtitle.text = ""


		
func player_escape():
	set_physics_process(false)
	set_process(false)

	subtitle.text = "I escaped!"
	for i in 20:
		fadeblack.color.a = lerp(fadeblack.color.a, 1.0, 0.25)
		await get_tree().create_timer(0.05).timeout

	
	await get_tree().create_timer(4.0).timeout
	subtitle.text = ""
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

	
		

func _input(event):
	if is_dead:
		return
	
	if event is InputEventMouseMotion:
		rotation_degrees.y += event.relative.x * -mouse_sensitivity
		cam.rotation_degrees.x += event.relative.y * -mouse_sensitivity
		cam.rotation_degrees.x = clamp(cam.rotation_degrees.x, -90, 90)
