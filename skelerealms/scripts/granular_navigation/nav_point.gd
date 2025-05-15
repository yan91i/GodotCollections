class_name NavPoint
extends RefCounted
## Point in a world.


var position:Vector3
var world:String


func _init(w:String, pos:Vector3) -> void:
	world = w
	position = pos
