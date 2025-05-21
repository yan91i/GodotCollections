class_name HoldableDataComponent
extends ItemDataComponent


## Whether this is held in both hands.
@export var two_handed:bool


func get_type() -> String:
	return "HoldableDataComponent"
