class_name GlobalShadowManager extends Node2D

## Set z index on this node to determine what layer shadows are rendered to

@onready var canvas_group = $CanvasGroup

@export var shadow_color = Color.BLACK

func _ready():
	canvas_group.self_modulate.a = shadow_color.a

func add_global_shadow_node(shadow_obj: Node2D):
	if !is_instance_valid(canvas_group):
		canvas_group = $CanvasGroup
	canvas_group.add_child(shadow_obj)
	shadow_obj.add_to_group("instanced")
