extends Area2D

func _on_body_exited(body: Node2D) -> void:
	print("body exited",body)
	var limitx = $WorldWrapCollisionShape2D.shape.size.x / 2
	var limity = $WorldWrapCollisionShape2D.shape.size.y / 2
	body.global_transform = Transform2D(body.global_rotation, Vector2(wrapf(body.global_position.x,-limitx,limitx), wrapf(body.global_position.y,-limity,limity)))
	body.sleeping = false
