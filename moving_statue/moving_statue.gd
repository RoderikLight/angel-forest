extends CharacterBody3D


const SPEED = 15.0
const OCC_RAY_TARGET_Y_OFFSET = 0.5

@export var target_player : CharacterBody3D
@export var kill_distance = 1.6

var _occlusion_check_rays : Array[RayCast3D]
var is_looked_at = true
var follow_player = false
var is_killing = false

@onready var occlusion_check_rays_parent = $OcclusionCheckRaysParent
@onready var visible_on_screen_notifier = $VisibleOnScreenNotifier3D
@onready var nav_agent = $NavigationAgent3D


func _ready():
	# validate that the player target export var is set
	if not target_player:
		printerr(self.name + " has no player target")
		set_physics_process(false)
		return
	
	# add all RayCast3Ds to the _occlusion_check_rays array
	for r in occlusion_check_rays_parent.get_children():
		if r is RayCast3D:
			r.add_exception(self)
			r.add_exception(target_player) 
			_occlusion_check_rays.append(r)
	
	_start_following_player.call_deferred()


func _start_following_player():
	# start following player on the next physics frame (NavigationServer has to sync blablabla)
	await get_tree().physics_frame
	follow_player = true


func _physics_process(_delta):
	if is_killing or not follow_player:
		return
	
	is_looked_at = _is_viewed()
	
	if is_looked_at:
		return
	
	# movement direction
	var direction = Vector3.ZERO
	nav_agent.target_position = target_player.global_position
	direction = nav_agent.get_next_path_position() - global_position
	direction.y = 0
	direction = direction.normalized()
	
	# look direction
	if nav_agent.get_current_navigation_path():
		var where_to_look = nav_agent.get_next_path_position()
		where_to_look.y = self.global_position.y
		if not where_to_look.is_equal_approx(self.global_position):
			look_at(where_to_look, Vector3.UP)
	
	# applying velocity using move direction
	velocity = direction * SPEED
	move_and_slide()
	
	if global_position.distance_to(target_player.global_position) <= kill_distance:
		_start_kill()

func _start_kill():
	is_killing = true
	follow_player = false
	velocity = Vector3.ZERO	
	
	look_at(target_player.global_position, Vector3.UP)
	
	if target_player.has_method("on_killed"):
		target_player.on_killed(self)
	

func _is_viewed() -> bool:
	var viewed = visible_on_screen_notifier.is_on_screen()
	
	if not viewed:
		return viewed
	
	var colliding_rays = 0
	
	# make raycasts point to player position and count how many are colliding with an obstacle
	for r in _occlusion_check_rays:
		r.target_position = (target_player.global_position - r.global_position) * self.basis
		r.target_position.y += OCC_RAY_TARGET_Y_OFFSET
		if viewed and r.is_colliding():
			colliding_rays += 1
	
	# if all raycasts are colliding, the statue is hidden so it can move
	if colliding_rays >= _occlusion_check_rays.size():
		viewed = false
	
	return viewed
