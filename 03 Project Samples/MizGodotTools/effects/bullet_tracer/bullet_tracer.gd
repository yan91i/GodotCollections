extends Node2D

# don't show tracer line if end_pos within this distance
var min_distance_to_show = 150.0 

 #  apply random offset to start position of tracer
var min_offset = 50.0
var max_offset = 150.0

# base length of tracer sprite
var base_len = 130

@onready var sprite_2d = $Sprite2D

func display_line(start_pos: Vector2, end_pos: Vector2):
	var dist = start_pos.distance_to(end_pos)
	if dist < min_distance_to_show:
		hide()
		queue_free()
	global_position = start_pos
	look_at(end_pos)
	
	var offset = randf_range(min_offset, max_offset)
	global_position += global_transform.x * offset / 2
	scale.x = (dist-offset) / base_len
	#sprite_2d.position.x += randf_range(0.0, max_rand_offset)
