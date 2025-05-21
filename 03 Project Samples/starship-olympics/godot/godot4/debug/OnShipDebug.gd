extends Node2D

"""
Debug node for movement and vectors
"""
@export var host : Ship

# GDquest colors
var colors = {
	WHITE = Color(1.0, 1.0, 1.0),
	YELLOW = Color(1.0, .757, .027),
	GREEN = Color(.282, .757, .255),
	BLUE = Color(.098, .463, .824),
	PINK = Color(.914, .118, .388),
	ORANGE = Color(1, 0.467, 0)
}

const WIDTH = 8
const MUL = 0.5
const VELOCITY_SCALE = 0.5

func _draw():
	if not visible:
		return
	
	# draw direction vector
	draw_vector(Vector2.RIGHT.rotated(host.global_rotation)*400, Vector2(), colors['BLUE'])
	
	# draw linear velocity
	draw_vector(host.linear_velocity*VELOCITY_SCALE, Vector2(), colors['ORANGE'])
	
	# draw drift vector
	#draw_vector(host.drift, Vector2(), colors['WHITE'] if host.drift.length() > 400 else colors['BLUE'])
	
	#draw_vector(host.target_pos*0.5, Vector2(), colors['PINK'])
	
	# draw_vector(host.last_target_pos, Vector2(), colors['WHITE'])
	#var i = 0
	#for r in parent.hit_pos:
	#	draw_vector(r, Vector2(), colors['WHITE'].darkened(0.3))
	#	i += 1
	#draw_vector(host.velocity.normalized()*5, Vector2(), colors['YELLOW'])


func draw_vector(vector, offset, _color):
	if vector == Vector2() or not vector:
		return
	draw_line(offset * MUL, vector * MUL, _color, WIDTH)
	var dir = vector.normalized()
	draw_triangle_equilateral(vector * MUL, dir, 30, _color)
	draw_circle(offset, 6, _color)


func draw_triangle_equilateral(center=Vector2(), direction=Vector2(), radius=50, _color=colors.WHITE):
	var point_1 = center + direction * radius
	var point_2 = center + direction.rotated(2*PI/3) * radius
	var point_3 = center + direction.rotated(4*PI/3) * radius

	var points = [point_1, point_2, point_3]
	draw_polygon(points, ([_color]))


func _process(_delta):
	if not visible:
		return
		
	rotation = -host.rotation
	#if host and host.cpu:
	#	$Label.text = host.behaviour_mode
	
	$Trajectory.add_point(host.global_position)
	$VelocityComb.add_points_pair(host.global_position, host.linear_velocity*0.5*0.5)
	$DirectionComb.add_points_pair(host.global_position, Vector2.RIGHT.rotated(host.global_rotation)*400*0.5)
	
	queue_redraw()
