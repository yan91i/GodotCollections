class_name PerceptionFSM_Unaware
extends FSMState
## In this state, the NPC is processing what it's seeing.


var detection_timer_max: float = 1
var _npc:NPCComponent
var detection_speed:float = 1
var detection_timer:float = 0


func _get_state_name() -> String:
	return "Unaware"


func on_ready() -> void:
	_npc = owner as NPCComponent


func update(delta:float) -> void:
	detection_timer += detection_speed * (state_machine as PerceptionFSM_Machine).visibility * delta
	if detection_timer >= detection_timer_max:
		state_machine.transition("AwareVisible")
		return
	if (state_machine as PerceptionFSM_Machine).visibility <= _npc.visibility_threshold:
		(state_machine as PerceptionFSM_Machine).remove_fsm()


func enter(message:Dictionary) -> void:
	# if we are tracking an item, skip right to aware visible
	if SKEntityManager.instance.get_entity((state_machine as PerceptionFSM_Machine).tracked).get_component("ItemComponent"):
		state_machine.transition("AwareVisible")
