class_name ResourceGenerator
extends Resource

@export var order: int = 0
@export var color: Color = Color.BLACK
@export var sort_value: int = 0
@export var sort_value_override: float = 0.0
@export var id: String
@export var amount: int = 1
@export var cooldown: float = 1
@export var costs: Dictionary
@export var cost_scales: Dictionary
@export var worker_costs: Dictionary
@export var random_drops: Dictionary
@export var hidden: bool = false
@export var max_amount: int = -1
@export var column: int = 0
@export var dynamic_efficiency_id: String

@export var sfx_button_down: AudioStream
@export var sfx_button_success: AudioStream

var _random_drops_sum: int = -1


func is_unique() -> bool:
	return max_amount == 1


## if idle production of this resource can be increasing, e.g. (mason -> house ->) worker -> food
## currently, 'food' is the only such case with dynamic id 'worker'
func is_dynamic_efficiency() -> bool:
	return StringUtils.is_not_empty(dynamic_efficiency_id)


func is_colored() -> bool:
	return color != Color.BLACK


func get_color() -> Color:
	return color


func get_sort_value() -> float:
	if sort_value_override != 0.0:
		return sort_value_override
	return sort_value


func get_display_increment(display_amount: int) -> String:
	return ResourceGenerator.get_display_increment_of(display_amount, get_display_name())

func get_display_name() -> String:
	return Locale.get_resource_generator_display_name(id)


func get_display_info(total: String, eff: String) -> String:
	var cycle_seconds: String = "%1.1f" % SaveFile.get_cycle_seconds()
	return "{total}, {eff} / {seconds} seconds".format(
		{"total": total, "eff": eff, "seconds": cycle_seconds}
	)


func distinct_generation_count() -> int:
	return max(random_drops.size(), 1)


func generate() -> Dictionary:
	var gen_id: String = id
	if random_drops == null or random_drops.is_empty():
		return {gen_id: amount}

	if random_drops.size() == 1:
		gen_id = random_drops.keys()[0]
		return {gen_id: amount}

	_cache_random_use()
	var generated: Dictionary = {}
	for trial in range(amount):
		gen_id = RandomUtils.pick_random_weighted_item(random_drops, _random_drops_sum)
		generated[gen_id] = generated.get(gen_id, 0) + 1
	return generated


func set_random_drops(drops: Dictionary) -> void:
	random_drops = drops
	_cache_random_clear()


func get_amount() -> int:
	return amount


func get_cooldown() -> float:
	if Game.PARAMS["debug_cooldown"] != 0:
		return Game.PARAMS["debug_cooldown"]

	var has_temperance: bool = SaveFile.substances.get("temperance", 0) > 0
	if has_temperance:
		return 1.0

	return cooldown


func get_costs() -> Dictionary:
	return costs


func get_scaled_costs(level: int) -> Dictionary:
	if cost_scales.size() == 0:
		return costs
	var scaled_costs: Dictionary = {}
	for cost_id: String in costs:
		var scaled_cost_amount: int = get_scaled_cost(cost_id, level)
		scaled_costs[cost_id] = scaled_cost_amount
	return scaled_costs


func get_scaled_cost(cost_id: String, level: int) -> int:
	var base_cost: int = costs[cost_id]
	if !cost_scales.has(cost_id):
		return base_cost
	var cost_function: CostFunction = cost_scales[cost_id]
	return cost_function.get_cost(base_cost, level)


func get_worker_costs() -> Dictionary:
	return worker_costs


func get_label() -> String:
	var label: String = Locale.get_resource_generator_label(id)
	return label


func get_title() -> String:
	var title: String = Locale.get_resource_generator_title(id)
	return title


func get_info(level: int) -> String:
	var max_flavor: String = Locale.get_resource_generator_max_flavor(id)
	if ResourceManager.is_max_amount_reached(id) and StringUtils.is_not_empty(max_flavor):
		return max_flavor

	var flavor: String = Locale.get_resource_generator_flavor(id)
	var scaled_costs: Dictionary = get_scaled_costs(level)
	if scaled_costs.size() == 0 and worker_costs.size() == 0:
		return flavor

	var ui_cost: String = Locale.get_ui_label("cost")
	var info: String = ui_cost + ": "
	if scaled_costs.size() > 0:
		var display_values: Array = NumberUtils.format_number_scientific_list(scaled_costs.values())
		var display_names: Array = ResourceGenerator.get_display_names_of(scaled_costs.keys())
		info += ("%s " + (", %s ".join(display_names))) % display_values
		if worker_costs.size() > 0:
			info += ", "
	if worker_costs.size() > 0:
		var display_values: Array = NumberUtils.format_number_scientific_list(worker_costs.values())
		var display_names: Array = WorkerRole.get_display_names_of(worker_costs.keys())
		info += ("%s " + (", %s ".join(display_names))) % display_values

	if StringUtils.is_not_empty(flavor):
		info += " - " + flavor
	return info


func _cache_random_use() -> void:
	if _cache_random_is_empty():
		_cache_random_create()


func _cache_random_create() -> void:
	_random_drops_sum = random_drops.values().reduce(func(x: int, n: int) -> int: return x + n, 0)


func _cache_random_clear() -> void:
	_random_drops_sum = -1


func _cache_random_is_empty() -> bool:
	return _random_drops_sum == -1


static func get_display_name_of(rid: String) -> String:
	var resource_generator: ResourceGenerator = Resources.resource_generators.get(rid, null)
	if resource_generator == null:
		return "NULL"
	return resource_generator.get_display_name()


static func get_display_names_of(ids: Array) -> Array:
	return ids.map(func(rid: String) -> String: return ResourceGenerator.get_display_name_of(rid))


static func get_display_increment_of(display_amount: int, display_name: String) -> String:
	var amount_string: String = NumberUtils.format_number_scientific(display_amount)
	return " + {amount} {text} ".format({"amount": str(amount_string), "text": display_name})
