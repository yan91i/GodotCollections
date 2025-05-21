extends PlayerState

@export var jump_initial_impulse := 10.0

func physics_process(delta: float) -> void:
	_parent.physics_process(delta)
	if _parent.velocity.y <= 0:
		_state_machine.transition_to("Move/Fall")

func enter(msg: = {}) -> void:
	_parent.velocity.y = jump_initial_impulse
	player.model.move_to_jumping()
	_parent.enter(msg)


func exit() -> void:
	_parent.exit()
