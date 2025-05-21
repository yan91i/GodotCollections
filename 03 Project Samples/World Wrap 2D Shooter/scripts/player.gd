extends RigidBody2D
signal laser(pos,angle)
var speed := 750
var torque := 2000
var damping := 0.0
var dampingspeed := .2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#var direction = Input.get_vector("left","right","up","down")
	#velocity = direction * speed
	#if not direction == Vector2(0,0):
		#rotation = atan2(direction[0],-direction[1])
	#move_and_slide()
	if Input.is_action_just_pressed("shoot"):
		laser.emit(position,rotation)
		$LaserSound.play()
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	
	if Input.get_action_strength("right"):
		rotation += .03
		state.apply_torque(1 * torque)
	if Input.get_action_strength("left"):
		rotation -= .03
		state.apply_torque(-1 * torque)
	if Input.get_action_strength("up"):
		state.apply_force(Vector2(0,-speed).rotated(rotation))
	if Input.get_action_strength("down"):
		damping += dampingspeed
		set_linear_damp(damping)
		set_angular_damp(damping)
	else:
		damping = 0
		set_linear_damp(damping)
		set_angular_damp(damping)


	
#func _physics_process(delta: float) -> void:
	##velocity.x = Input.get_action_strength("right")-Input.get_action_strength("left")
	##velocity.y = Input.get_action_strength("down")-Input.get_action_strength("up")
	#
	#if Input.get_action_strength("right"):
		#rotation += .03
	#if Input.get_action_strength("left"):
		#rotation -= .03
	#if Input.get_action_strength("up"):
		#state.aVector2(0,-speed).rotated(rotation)
	#if Input.get_action_strength("down"):
		#velocity = velocity - Vector2(0,-speed).rotated(rotation)
	#
	##velocity.normalized()
	##velocity = velocity * speed
	##if not velocity == Vector2(0,0):
		##rotation = atan2(velocity.x,-velocity.y)
	#move_and_slide()
	#var collision_info = move_and_collide(velocity * delta)
	#if collision_info:
		#print("collision_info ",collision_info.get_normal()," bounce ", velocity.bounce(collision_info.get_collider_velocity())," get_collider_velocity() ",collision_info.get_collider_velocity())
		#velocity = velocity.bounce(collision_info.get_collider_velocity())*100
		##velocity = velocity + collision_info.get_collider_velocity()
	##print("player position",position)
	#
func playerHit():
	$PlayerHit.play()
	#position += Vector2(300,0) * delta
	#$PlayerImage.rotation += .2 * delta
