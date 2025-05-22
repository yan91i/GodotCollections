class_name TopDownInput extends Node2D

## Input for a top-down 2d game
## Keyboard Movement + Mouse Looking and Left Joystick movement Right Joystick Looking
## Automatically detects switching between keyboard+mouse and controller and hides/shows cursor accordingly
## Access from another script by connecting signals or just get the values directly

signal move_vec_updated(move_vec: Vector2)
signal face_vec_updated(face_vec: Vector2)
signal face_angle_updated(face_angle: float)

var move_vec : Vector2
var face_vec : Vector2
var face_angle : float # radians
var using_mouse = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		set_using_mouse(true)

func _process(_delta: float) -> void:
	move_vec = Input.get_vector("move_left", "move_right", "move_up", "move_down") # keyboard and controller input
	
	var dir_to_face = Input.get_vector("look_left", "look_right", "look_up", "look_down") # this is controller input only
	if dir_to_face.length_squared() > 0.01:
		set_using_mouse(false)
	if using_mouse:
		dir_to_face = global_position.direction_to(get_global_mouse_position())
	
	if dir_to_face.length_squared() > 0.1: # make so releasing joystick keeps same facing direction
		face_vec = dir_to_face
		face_angle = dir_to_face.angle()
	
	move_vec_updated.emit(move_vec)
	face_vec_updated.emit(face_vec)
	face_angle_updated.emit(face_angle)

func set_using_mouse(b: bool):
	using_mouse = b
	if b:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
