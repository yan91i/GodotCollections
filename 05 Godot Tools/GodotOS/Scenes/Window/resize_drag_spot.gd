extends Control

## The resize drag spot in the bottom right of each window.

var window: FakeWindow
var is_dragging: bool

var start_size: Vector2
var mouse_start_drag_position: Vector2

signal window_resized()

func _ready() -> void:
	window = get_parent()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == 1:
		if event.is_pressed():
			is_dragging = true
			mouse_start_drag_position = get_global_mouse_position()
			start_size = get_parent().size
		else:
			is_dragging = false

func _physics_process(_delta: float) -> void:
	if is_dragging:
		# TODO optimize this a bit?
		window_resized.emit()
		if Input.is_key_pressed(KEY_SHIFT):
			var aspect_ratio: float = start_size.x / (start_size.y - 30)
			window.size.x = start_size.x + (get_global_mouse_position().x - mouse_start_drag_position.x) * aspect_ratio
			window.size.y = start_size.y + get_global_mouse_position().x - mouse_start_drag_position.x
		else:
			window.size = start_size + get_global_mouse_position() - mouse_start_drag_position
		window.clamp_window_inside_viewport()
