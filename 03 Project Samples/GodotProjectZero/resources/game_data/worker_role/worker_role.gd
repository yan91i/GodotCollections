class_name WorkerRole
extends Resource

@export var order: int = 0
@export var sort_value: int = 0
@export var id: String
@export var produce: Dictionary
@export var consume: Dictionary
@export var worker_consume: Dictionary
@export var default: bool = false
@export var column: int = 0


func get_first_produce() -> String:
	if produce.is_empty():
		return ""
	if produce.size() > 1:
		push_warning("wroker role id " + id + " produces multiple resources " + str(produce))
	return produce.keys()[0]


func get_produce() -> Dictionary:
	return produce


func get_consume() -> Dictionary:
	return consume


func get_worker_consume() -> Dictionary:
	return worker_consume


func get_title() -> String:
	return Locale.get_worker_role_title(id)


func get_info() -> String:
	var flavor: String = Locale.get_worker_role_flavor(id)
	if produce.size() == 0:
		return flavor

	var ui_produce: String = Locale.get_ui_label("produce")
	var info: String = ui_produce + ": "
	var produce_display_names: Array = ResourceGenerator.get_display_names_of(produce.keys())
	info += ("+%s " + (", +%s ".join(produce_display_names))) % produce.values()

	if consume.size() > 0:
		var resource_names: Array = ResourceGenerator.get_display_names_of(consume.keys())
		info += (", -%s " + (", -%s ".join(resource_names))) % consume.values()
	if worker_consume.size() > 0:
		var worker_names: Array = WorkerRole.get_display_names_of(worker_consume.keys())
		info += (", -%s " + (", -%s ".join(worker_names))) % worker_consume.values()

	var label_seconds = Locale.get_ui_label("seconds") # "s" #"seconds"

	var cycle_seconds: String = "%1.1f" % SaveFile.get_cycle_seconds()
	info += " / %s %s" % [cycle_seconds, label_seconds]
	if StringUtils.is_not_empty(flavor):
		info += " - " + flavor
	return info


static func get_display_name_of(wid: String) -> String:
	var worker_role: WorkerRole = Resources.worker_roles.get(wid, null)
	if worker_role == null:
		return "NULL"
	return Locale.get_worker_role_title(wid)


static func get_display_names_of(ids: Array) -> Array:
	return ids.map(func(wid: String) -> String: return WorkerRole.get_display_name_of(wid))


static func order_less_than(a: WorkerRole, b: WorkerRole) -> bool:
	return a.order < b.order


static func order_greater_than(a: WorkerRole, b: WorkerRole) -> bool:
	return a.order > b.order
