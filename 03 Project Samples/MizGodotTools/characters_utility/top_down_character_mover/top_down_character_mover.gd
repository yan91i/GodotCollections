class_name TopDownCharacterMover extends Node

## Standard CharacterBody2D mover for a top down game

@onready var character_body : CharacterBody2D = get_parent()

@export var max_move_speed = 300.0 # pixels per second
@export var time_to_reach_max_speed = 0.2 # in seconds
@export var time_to_stop_from_max_speed = 0.1 # in seconds
var accel_force = 0.0
var stop_drag = 0.0
var move_drag = 0.0

@export var turn_speed = 300.0 # degrees per second
@export var instantly_turn = false # ignore turn speed and face 'face_vec' instantly

# degrees, character wont move unless its facing 'face_vec' within this arc
# set to 360.0 to always move
@export var only_move_if_facing_within_angle = 30.0 
var within_moving_angle = false

var move_vec : Vector2
var face_vec : Vector2

enum DIRECTIONS {RIGHT, DOWN, LEFT, UP}
@export var front_direction = DIRECTIONS.RIGHT #which way does this character face by default

func _ready() -> void:
	accel_force = (4.6 * max_move_speed) / time_to_reach_max_speed # 4.6 is magic number to assume time to reach ~99% max speed
	move_drag = accel_force / max_move_speed
	stop_drag = (log(max_move_speed / 0.01))/time_to_stop_from_max_speed # 0.01 magic number again, assuming ~99% stopped

func _physics_process(delta: float) -> void:
	process_turning(delta)
	process_movement(delta)

func process_turning(delta: float):
	var fwd = get_forward_vector()
	var angle_diff = fwd.angle_to(face_vec)
	if instantly_turn:
		character_body.global_rotation += angle_diff
		within_moving_angle = true
		return
	var turn_amnt = sign(angle_diff) * deg_to_rad(turn_speed) * delta
	if abs(turn_amnt) > abs(angle_diff):
		turn_amnt = angle_diff
	character_body.global_rotation += turn_amnt
	within_moving_angle = abs(rad_to_deg(angle_diff)) < only_move_if_facing_within_angle

var t = 0.0
func process_movement(delta: float):
	var drag = move_drag
	if move_vec.is_equal_approx(Vector2.ZERO) or move_vec.dot(character_body.velocity) < 0.0:
		drag = stop_drag
	
	if !within_moving_angle:
		move_vec = Vector2.ZERO
	
	if !move_vec.is_zero_approx():
		t += delta
	var net_acceleration = move_vec * accel_force - character_body.velocity * drag
	character_body.velocity += net_acceleration * delta
	character_body.move_and_slide()
	#print(character_body.velocity.length())

func stop_moving():
	move_vec = Vector2.ZERO

func stop_turning():
	face_vec = get_forward_vector()

func face_point(point: Vector2):
	face_vec = character_body.global_position.direction_to(point)

func get_forward_vector() -> Vector2:
	match front_direction:
		DIRECTIONS.RIGHT:
			return character_body.global_transform.x
		DIRECTIONS.LEFT:
			return -character_body.global_transform.x
		DIRECTIONS.DOWN:
			return character_body.global_transform.y
	return -character_body.global_transform.y # up
