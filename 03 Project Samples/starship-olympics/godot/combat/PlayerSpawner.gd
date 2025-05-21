extends Node2D

class_name PlayerSpawner

@export (String, 'kb1', 'kb2', 'joy1', 'joy2', 'joy3', 'joy4') var controls = "kb1"
@export (Resource) var species
@export (String) var team = ''
# temporary for cpu
@export (bool) var cpu = false
@export var cpu_ship_texture : Texture2D

signal player_assigned(info_player)
signal entered_battlefield

var id : String
var uid : int
var info_player = null
@onready var sprite = $Sprite2D
@onready var animation = $AnimationPlayer

func _ready():
	visible = false
	global.arena.connect("all_ships_spawned", Callable(self, '_on_all_ships_spawned'))
	
func appears(animate_drop_ship: bool):
	var device_controller_id
	if ("rm" in controls):
		device_controller_id = 0
	else:
		device_controller_id = InputMap.action_get_events(controls+"_right")[0].device
	if "joy" in controls and global.rumbling:
		# Vibrate if joypad
		Input.start_joy_vibration(device_controller_id, 1, 1, 0.8)
	
	if info_player.is_cpu():
		sprite.texture = cpu_ship_texture
		sprite.modulate = info_player.get_color()
	else:
		sprite.texture = species.ship
		sprite.modulate = Color.WHITE
	visible = true
	if animate_drop_ship:
		animation.play("Appearing")
		await animation.animation_finished
	emit_signal("entered_battlefield")
	visible = false
	
func is_cpu()->bool:
	#return info_player.cpu
	return cpu

func set_info_player(v):
	info_player = v
	emit_signal('player_assigned', info_player)
	
func get_player():
	return info_player
	
func is_assigned():
	return info_player != null
	
const CAMERA_RECT_SIZE := 800.0
func get_camera_rect() -> Rect2:
	return Rect2(global_position - Vector2(CAMERA_RECT_SIZE,CAMERA_RECT_SIZE)/2, Vector2(CAMERA_RECT_SIZE,CAMERA_RECT_SIZE))

func _on_all_ships_spawned(_spawners):
	remove_from_group('in_camera')
	
