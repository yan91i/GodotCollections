extends CostFunction


func get_cost(base_cost: int, level: int) -> int:
	return PowUtils.pow_int(base_cost, level)
