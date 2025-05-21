class_name Powerup extends Node2D

var player: CommonPlayer

func _ready() -> void:
	player = get_parent()


func activate_item(time: int) -> void:
	# Timer not running yet so activate, otherwise just restart timer
	if $Timer.time_left == 0:
		_activate()
	if time > 0:
		# Only use the timer if item has a time duration
		$Timer.start(time)


func _activate() -> void:
	push_error("_activate not implemented!")


func _deactivate() -> void:
	push_error("_deactivate not implemented!")


func _on_Timer_timeout() -> void:
	_deactivate()
