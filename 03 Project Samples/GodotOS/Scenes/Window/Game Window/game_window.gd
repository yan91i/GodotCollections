extends SubViewport

## The game window, used to show games.

@onready var window: FakeWindow = $"../../.."
@onready var game_pause_manager: GamePauseManager = %"GamePauseManager"

func _ready() -> void:
	window.minimized.connect(_handle_window_minimized)
	window.selected.connect(_handle_window_selected)
	
	# WIP: Making game scene resolution not tied to screen scale
	#await get_tree().process_frame
	#$"../..".scale /= get_window().content_scale_factor
	#$"../..".size *= get_window().content_scale_factor

func _handle_window_minimized(is_minimized: bool) -> void:
	if game_pause_manager.is_paused:
		return
	
	if is_minimized:
		get_child(0).process_mode = Node.PROCESS_MODE_DISABLED
	else:
		get_child(0).process_mode = Node.PROCESS_MODE_INHERIT

## Disables input if the window isn't selected.
func _handle_window_selected(is_selected: bool) -> void:
	# TODO check if this wrecks performance
	#handle_input_locally = false
	set_input(self, is_selected)

# WARNING recursively loops on every node in the game. Probably a bad idea.
func set_input(node: Node, can_input: bool) -> void:
	node.set_process_input(can_input)
	for n in node.get_children():
		set_input(n, can_input)
