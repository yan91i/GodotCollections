extends CharacterBody3D
class_name EnemyEntity

enum BehaviorState {Idling, Reaching, Attacking, Dead}

@onready var navigation_agent:NavigationAgent3D=$NavigationAgent3D
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var detection_shape: CollisionShape3D = $DetectionRange/CollisionShape3D
@onready var weapon_anchor: Node3D = $WeaponAnchor

@export var movement_speed: float = 8.0
@export var rotation_speed := 12.0

var target_object:Node3D = null
var transition:AnimationNodeTransition=null
var _last_strong_direction := Vector3.FORWARD
var gravity = -30.0
var anim_state = null
var current_state = null
var health_points = 3
var is_target_detected = false
var is_target_in_reach = false
var is_target_aligned = false
var detection_range = null

signal target_reached

func _ready() -> void:
	self.navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	DebugStats.add_property(self, "velocity", "")
	anim_tree.active = true
	transition = anim_tree.tree_root.get("nodes/state/node")
	detection_range = detection_shape.shape.radius


func update_animation_skin(delta):
	anim_state = self.anim_tree["parameters/state/current_state"]
	if  anim_state == "Idling":
		#if target_object: # align with target if any
			#self.look_at(target_object.global_position)
		if self.velocity.length_squared() > 0.01:
			self.move_to_running()
	if anim_state == "Running":
		self.orient_model_to_direction(Vector3(self.velocity.x,0, self.velocity.z), delta)
		if self.velocity.length_squared() <= 0.01:
			self.move_to_idling()
	

func update_navigation_agent(delta, target_object):
	if self.navigation_agent.is_navigation_finished():
		self.velocity = Vector3(0,0,0)
		target_reached.emit()
		return

	var next_path_position: Vector3 = self.navigation_agent.get_next_path_position()
	var new_velocity: Vector3 = self.global_position.direction_to(next_path_position) * movement_speed
	new_velocity.y = self.velocity.y + gravity*delta
	if self.navigation_agent.avoidance_enabled:
		self.navigation_agent.set_velocity(new_velocity)
	else:# we call it manually because only called by set_velocity when avoidance is true
		_on_velocity_computed(new_velocity)


func set_movement_target(movement_target: Vector3):
	self.navigation_agent.set_target_position(movement_target)
	

func _on_velocity_computed(safe_velocity: Vector3):
	self.velocity = safe_velocity
	self.move_and_slide()


func move_to_running() -> void:
	transition.xfade_time = 0.1
	anim_tree["parameters/state/transition_request"] = "Running"


func move_to_idling() -> void:
	transition.xfade_time = 0.1
	anim_tree["parameters/state/transition_request"] = "Idling"


func move_to_dying() -> void:
	transition.xfade_time = 0
	anim_tree["parameters/state/transition_request"] = "Dying"
	self.process_mode = Node.PROCESS_MODE_DISABLED
	# Note: we set the MeleeSkin so that it does not inherit the parent's state
	# This way it can continue to play the animation and then we use a tween to
	# disable it with a 2 sec delay.
	(get_tree().create_tween()
	.tween_callback(func(): 
		$MeleeSkin.process_mode = Node.PROCESS_MODE_DISABLED
		anim_tree.process_mode = Node.PROCESS_MODE_DISABLED
		)
	.set_delay(2))


func play_on_attacking(is_requested: bool) -> void:
	if is_requested:
		anim_tree["parameters/on_attacking/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	else:
		anim_tree["parameters/on_attacking/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT


func play_on_hit(is_requested:bool):
	if is_requested:
		anim_tree["parameters/on_hit/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	else:
		anim_tree["parameters/on_hit/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT
	

func deal_damage():
	## To be called by AnimationPlayer on the Skin in Attack animations
	var weapon:Weapon = weapon_anchor.get_child(0)
	if weapon != null and weapon is Weapon:
		weapon.deal_damage()


func orient_model_to_direction(direction: Vector3, delta: float) -> void:
	
	#if direction.length() > 0.05:
	_last_strong_direction = direction
	if target_object: # prioritize aligning with target if any
		_last_strong_direction = global_position.direction_to(target_object.global_position)
	
	# Remember that Y is the Up Axis
	# LERP is used cumulatively here
	rotation.y = lerp_angle(
		rotation.y, 
		Vector2(_last_strong_direction.z, _last_strong_direction.x).angle(), 
		delta*rotation_speed
	)


func _on_detection_range_body_entered(body):
	if body is PlayerEntity:
		is_target_detected = true
		target_object = body
		detection_shape.shape.radius = detection_range*1.5


func _on_attack_range_body_entered(body):
	if body is PlayerEntity:
		is_target_in_reach = true


func _on_detection_range_body_exited(body):
	if body is PlayerEntity:
		is_target_detected = false
		target_object = null
		detection_shape.shape.radius = detection_range


func _on_attack_range_body_exited(body):
	if body is PlayerEntity:
		is_target_in_reach = false


func _on_hit_area_body_entered(colliding_body):
	if colliding_body.is_in_group("bullet"):
		print("hit by", colliding_body.name, "!")
		health_points -= 1
		colliding_body.remove_from_group("bullet")
		play_on_hit(true)
