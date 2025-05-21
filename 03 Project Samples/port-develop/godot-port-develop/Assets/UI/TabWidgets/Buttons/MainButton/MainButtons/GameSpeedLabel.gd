@tool
extends LabelEx
class_name GameSpeedLabel

func _ready() -> void:
	if Engine.is_editor_hint:
		return

	call_deferred("connect_game") # waiting for Global.World to be set

func connect_game() -> void:
	Global.World.game_speed_changed.connect(_on_game_speed_changed)

func _on_game_speed_changed(new_game_speed: float) -> void:
	text = "%1.1fx" % new_game_speed
