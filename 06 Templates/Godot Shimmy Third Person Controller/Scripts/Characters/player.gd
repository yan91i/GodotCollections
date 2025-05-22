extends CharacterBody3D

const LERP_VALUE : float = 0.15
const SHIMMY_SPEED : float = 1

var snap_vector : Vector3 = Vector3.DOWN
var speed : float
var is_hanging : bool = false
var has_jumped : bool = false

@export_group("Movement variables")
@export var walk_speed : float = 3.0
@export var run_speed : float = 7.0
@export var jump_strength : float = 15.0
@export var gravity : float = 50.0

@onready var shape_cast_3d = $Mesh/ShapeCast3D
@onready var armature = $Mesh/Armature
const ANIMATION_BLEND : float = 7.0
@onready var player_mesh = $Mesh
@onready var spring_arm_pivot = $SpringArmPivot
@onready var animator = $AnimationTree
@onready var r_1 = $Mesh/R1
@onready var r_2 = $Mesh/R2
@onready var r_3 = $Mesh/R3
@onready var collision_shape_3d = $CollisionShape3D

func _physics_process(delta):
	if is_hanging:
		var wall_normal : Vector3 = -r_2.get_collision_normal()
		player_mesh.rotation = Vector3(0, atan2(wall_normal.x, wall_normal.z), 0)
		var shimmy_direction : Vector3 = wall_normal.cross(r_3.get_collision_normal()).normalized()
		if !r_1.is_colliding() and r_2.is_colliding():
			is_hanging = true
		else:
			is_hanging = false
		if Input.is_action_pressed("move_left"):
			velocity = -shimmy_direction * SHIMMY_SPEED
		elif Input.is_action_pressed("move_right"):
			velocity = shimmy_direction * SHIMMY_SPEED
		else:
			velocity = Vector3.ZERO
		if Input.is_action_just_pressed("ui_cancel"):
			is_hanging = false
			has_jumped = false
			velocity.y = 0
		if Input.is_action_just_pressed("jump"):
			is_hanging = false
			velocity.y = jump_strength
			has_jumped = true
	else:
		var move_direction : Vector3 = Vector3.ZERO
		move_direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		move_direction.z = Input.get_action_strength("move_backwards") - Input.get_action_strength("move_forwards")
		move_direction = move_direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)
		velocity.y -= gravity * delta
		if Input.is_action_pressed("run"):
			speed = run_speed
		else:
			speed = walk_speed
		velocity.x = move_direction.x * speed
		velocity.z = move_direction.z * speed
		if move_direction:
			player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, atan2(velocity.x, velocity.z), LERP_VALUE)
		if has_jumped and !is_on_floor():
			r_1.force_raycast_update()
			r_2.force_raycast_update()
			if !r_1.is_colliding() and r_2.is_colliding():
				is_hanging = true
				velocity = Vector3.ZERO
	var just_landed := is_on_floor() and snap_vector == Vector3.ZERO
	var is_jumping := is_on_floor() and Input.is_action_just_pressed("jump")
	if is_jumping:
		velocity.y = jump_strength
		snap_vector = Vector3.ZERO
		has_jumped = true
		is_hanging = false
	elif just_landed:
		snap_vector = Vector3.DOWN
		has_jumped = false
	move_and_slide()
	animate(delta)
func animate(delta):
	if is_hanging:
		if Input.is_action_pressed("move_left"):
			animator.set("parameters/ground_air_transition/transition_request","onedge")
			animator.set("parameters/hang/blend_amount",1.0)
		elif Input.is_action_pressed("move_right"):
			animator.set("parameters/ground_air_transition/transition_request","onedge")
			animator.set("parameters/hang/blend_amount",-1.0)
		else:
			animator.set("parameters/ground_air_transition/transition_request","onedge")
			animator.set("parameters/hang/blend_amount",0.0)
	elif is_on_floor():
		animator.set("parameters/ground_air_transition/transition_request", "grounded")
		if velocity.length() > 0:
			if speed == run_speed:
				animator.set("parameters/iwr_blend/blend_amount", lerp(animator.get("parameters/iwr_blend/blend_amount"), 1.0, delta * ANIMATION_BLEND))
			else:
				animator.set("parameters/iwr_blend/blend_amount", lerp(animator.get("parameters/iwr_blend/blend_amount"), 0.0, delta * ANIMATION_BLEND))
		else:
			animator.set("parameters/iwr_blend/blend_amount", lerp(animator.get("parameters/iwr_blend/blend_amount"), -1.0, delta * ANIMATION_BLEND))
	else:
		animator.set("parameters/ground_air_transition/transition_request", "air")
