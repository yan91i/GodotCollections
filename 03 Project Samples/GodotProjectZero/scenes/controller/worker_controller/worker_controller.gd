class_name WorkerController extends Node

signal none

@onready var timer: Timer = $Timer

###############
## overrides ##
###############


func _ready() -> void:
	_initialize()
	_connect_signals()


############
## public ##
############


func get_efficiencies() -> Dictionary:
	return _calculate_generated_amounts()


#############
## helpers ##
#############


func _initialize() -> void:
	_reset_timer()


func _reset_timer() -> void:
	timer.wait_time = SaveFile.get_cycle_seconds()
	timer.start()


func _generate(generate: bool = true) -> void:
	var efficiencies: Dictionary = _calculate_generated_amounts()

	if generate:
		var generated_resources: Dictionary = efficiencies["resources"]
		for resource_id: String in generated_resources:
			var amount: int = generated_resources[resource_id]
			SignalBus.resource_generated.emit(resource_id, amount, name)

		var generated_workers: Dictionary = efficiencies["workers"]
		for worker_id: String in generated_workers:
			var amount: int = generated_workers[worker_id]
			SignalBus.worker_generated.emit(worker_id, amount, name)

		SaveFile.check_backward_corrupt_worker_role({})

	SignalBus.worker_efficiency_set.emit(efficiencies, generate)


func _calculate_generated_worker_resource_from_houses(resources: Dictionary) -> int:
	var house_workers: int = SaveFile.get_house_workers()
	var house: int = resources.get("house", 0)
	var resource_id: String = Game.WORKER_RESOURCE_ID
	# [WORKAROUND] : safe_mult uses factor = 2 for reasons beyond your comprehension
	var max_workers: int = Limits.safe_mult(house_workers, house, 2) + resources.get("firepit", 0)
	var current_workers: int = resources.get(resource_id, 0)

	var new_workers: int = 1 + int((max_workers - current_workers - 1) / house_workers)
	var is_infinite_house: bool = house >= Limits.GLOBAL_MAX_AMOUNT
	if is_infinite_house:
		new_workers = max_workers
	elif current_workers + new_workers > max_workers:
		new_workers = max_workers - current_workers
	return new_workers


func _calculate_generated_amounts() -> Dictionary:
	var resources: Dictionary = SaveFile.resources.duplicate(true)
	var generated_resources: Dictionary = {}
	var generated_workers: Dictionary = {}
	var total_eff: Dictionary = {}

	var worker_roles: Array = SaveFile.workers.keys().map(
		func(id: String) -> WorkerRole: return Resources.worker_roles[id]
	)
	worker_roles.sort_custom(WorkerRole.order_less_than)

	for worker_role: WorkerRole in worker_roles:
		var worker_role_id: String = worker_role.id
		var count: int = SaveFile.workers[worker_role_id]

		var r_consume: Dictionary = worker_role.get_consume()
		var w_consume: Dictionary = worker_role.get_worker_consume()
		var produces: Dictionary = worker_role.get_produce()

		#for pid: String in produces: # handle near "Infinity" edge case ?
		#	var produce: int = produces[pid]
		#	var room_left: int = max(0, Limits.GLOBAL_MAX_AMOUNT - resources.get(pid, 0))
		#	count = min(count, room_left)

		var resources_eff: int = WorkerController.get_efficiency(count, r_consume, resources)
		var workers_eff: int = WorkerController.get_efficiency(count, w_consume, SaveFile.workers)
		var efficiency: int = min(resources_eff, workers_eff)

		_generate_from(resources, -efficiency, generated_resources, r_consume, -count, total_eff)
		_generate_from(resources, -efficiency, generated_workers, w_consume, -count, total_eff)
		_generate_from(resources, efficiency, generated_resources, produces, count, total_eff)

	var resource_id: String = Game.WORKER_RESOURCE_ID
	var new_workers: int = _calculate_generated_worker_resource_from_houses(resources)
	if new_workers != 0:
		generated_resources[resource_id] = Limits.safe_add(
			generated_resources.get(resource_id, 0), new_workers
		)
		total_eff[resource_id] = Limits.safe_add(total_eff.get(resource_id, 0), new_workers)

	return {
		"storage": resources,
		"resources": generated_resources,
		"workers": generated_workers,
		"total_efficiency": total_eff
	}


func _generate_from(
	resources: Dictionary,
	eff: int,
	generated: Dictionary,
	ids: Dictionary,
	count: int,
	total_eff: Dictionary
) -> void:
	for id: String in ids:
		var base_amount: int = ids[id]
		var amount: int = Limits.safe_mult(eff, base_amount)
		generated[id] = Limits.safe_add(generated.get(id, 0), amount)
		resources[id] = Limits.safe_add(resources.get(id, 0), amount)
		var max_amount: int = Limits.safe_mult(count, base_amount)
		total_eff[id] = Limits.safe_add(total_eff.get(id, 0), max_amount)


#############
## signals ##
#############


func _connect_signals() -> void:
	timer.timeout.connect(_on_timeout)
	owner.ready.connect(_on_owner_ready)
	SignalBus.worker_updated.connect(_on_worker_updated)
	SignalBus.substance_updated.connect(_on_substance_updated)


func _on_timeout() -> void:
	_generate()
	_generate(false)
	_generate(false)


func _on_owner_ready() -> void:
	_generate(false)


func _on_worker_updated(_id: String, _total: int, _amount: int) -> void:
	_generate(false)


func _on_substance_updated(id: String, total_amount: int, _source_id: String) -> void:
	if id == "the_empress" and total_amount > 0:
		_reset_timer()


############
## static ##
############


static func get_efficiency(worker_count: int, consumes: Dictionary, items: Dictionary) -> int:
	var max_efficiency: int = worker_count
	for consume_id: String in consumes:
		var consume_amount: int = consumes[consume_id]
		var resource_amount: int = items.get(consume_id, 0)
		var efficiency: int = min(resource_amount / consume_amount, worker_count)
		max_efficiency = min(efficiency, max_efficiency)
	return max_efficiency
