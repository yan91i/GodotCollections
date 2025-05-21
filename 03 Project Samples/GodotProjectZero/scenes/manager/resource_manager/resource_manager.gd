class_name ResourceManager
extends Node

###############
## overrides ##
###############


func _ready() -> void:
	_connect_signals()


##############
## handlers ##
##############


func _handle_on_resource_generated(id: String, amount: int, source_id: String) -> void:
	# shadows boost net resource income
	if source_id != "NO_SHADOW":
		amount = SaveFile.scale_by_shadows(id, amount)

	# [WORKAROUND]
	# worker resource represents total population, we want to apply the limit on peasant's instead
	# (perhaps worker roles should have been just resources, to avoid edge cases like this one !!)
	var total: int = SaveFile.resources.get(id, 0)
	if id == Game.WORKER_RESOURCE_ID:
		total = total - SaveFile.resources.get("swordsman", 0)
	amount = Limits.safe_add_factor(total, amount)

	# update amount in save file
	SaveFile.resources[id] = SaveFile.resources.get(id, 0) + amount
	if SaveFile.resources[id] < 0:
		push_warning("[WARN] Resource", id, "went negative:", SaveFile.resources[id])
		SaveFile.resources[id] = 0

	# update total spent statistic counter
	if amount < 0:
		var spent_id: String = ResourceManager.make_spent_id(id)
		SaveFile.resources[spent_id] = SaveFile.resources.get(spent_id, 0) - amount
	SignalBus.resource_updated.emit(id, SaveFile.resources.get(id, 0), amount, source_id)

	# worker amounts are backed up by resource amounts
	if Game.WORKER_ROLE_RESOURCE.has(id):
		SignalBus.worker_generated.emit(id, amount, name)

	# some resource generators have a max amount
	if ResourceManager.is_max_amount_reached(id):
		SignalBus.progress_button_disabled.emit(id)

	if id == "soul" and amount > 0:
		SaveFile.autosave_timer.stop()
		SignalBus.soul.emit()


#############
## signals ##
#############


func _connect_signals() -> void:
	SignalBus.resource_generated.connect(_on_resource_generated)


func _on_resource_generated(id: String, amount: int, source_id: String) -> void:
	_handle_on_resource_generated(id, amount, source_id)


############
## static ##
############


static func is_max_amount_reached(id: String) -> bool:
	var resource_generator: ResourceGenerator = Resources.resource_generators[id]
	var max_amount: int = resource_generator.max_amount
	return max_amount > -1 and SaveFile.resources.get(id, 0) >= max_amount


static func get_total_generated(id: String) -> int:
	return (
		SaveFile.resources.get(id, 0) + SaveFile.resources.get(ResourceManager.make_spent_id(id), 0)
	)


static func make_spent_id(id: String) -> String:
	return "spent_" + id
