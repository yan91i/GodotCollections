extends Area2D
# Class variables
var areas_to_wrap = []
var processing_exit = false
func _physics_process(delta: float) -> void:
	if not areas_to_wrap.is_empty():
		var area_to_wrap = areas_to_wrap.pop_front()
		if is_instance_valid(area_to_wrap):
			var limitx = $CollisionShape2D.shape.size.x / 2
			var limity = $CollisionShape2D.shape.size.y / 2
			area_to_wrap.global_transform = Transform2D(area_to_wrap.global_rotation, Vector2(wrapf(area_to_wrap.position.x,-limitx,limitx), wrapf(area_to_wrap.position.y,-limity,limity)))
			area_to_wrap.sleeping = false
		
func _on_wrap_boundary_meteroid_body_exited(body: Node2D) -> void:
	
	if body.isfake:
		return
	#print("meteor bound")
	areas_to_wrap.append(body)
