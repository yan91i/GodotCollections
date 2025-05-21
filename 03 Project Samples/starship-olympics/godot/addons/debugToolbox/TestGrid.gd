@tool
extends Node2D

@export var rows := 52
@export var columns := 52
@export var dx := 50
@export var dy := 50
@export var color := Color('#3c8bc7')
@export var border_color := Color('#8ac4ff')
@export var major_line_every := 2

func _ready():
	position = Vector2(-columns*dx/2.0, -rows*dy/2.0)

func _draw():
	for j in range(1,columns):
		draw_line(Vector2(j*dx, 0.0), Vector2(j*dx, rows*dy), Color(color, 0.2) if j % major_line_every else color, 1.0, true)
		
	for i in range(1,rows):
		draw_line(Vector2(0.0, i*dy), Vector2(columns*dx, i*dy), Color(color, 0.2) if i % major_line_every else color, 1.0, true)
	
	draw_rect(Rect2(0.0, 0.0, columns*dx, rows*dy), border_color, false, 4.0)
