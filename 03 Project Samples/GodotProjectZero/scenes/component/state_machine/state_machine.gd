class_name StateMachine extends Node

@export var default_state: StateMachineState

var states: Dictionary
var current: StateMachineState

###############
## overrides ##
###############


func _ready() -> void:
	for child in get_children():
		states[child.name] = child
		child.on_ready()

	await owner.ready
	transition_to(default_state.name)


func _input(event: InputEvent) -> void:
	current.on_input(event)


func _process(delta: float) -> void:
	current.on_process(delta)


func _physics_process(delta: float) -> void:
	current.on_physics_process(delta)


#############
## methods ##
#############


func transition_to(state_name: StringName) -> void:
	if current:
		current.on_state_exit()
	current = states[state_name]
	current.on_state_enter()
