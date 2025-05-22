class_name DropShadow extends Node2D

## 2D drop shadow system, make sure to set Z Index of global shadow manager in it's scene

static var global_drop_shadow_manager : GlobalShadowManager
const GLOBAL_SHADOW_MANAGER = preload("res://effects/drop_shadows/global_shadow_manager.tscn")

@export var is_static = true # uncheck if this is for a moving object

@export var is_global = true # uncheck if this is for casting on another shadow casting object
@export var custom_z_index_difference = -1 # if is_global is false, this determines the z index difference from the parent node

## set false if you want to choose exactly when the shadow is created
## if using Pseudo3DObjectWithCustomLayers this should be set to false
@export var create_on_ready = true 

@export var offset_amnt = 25 # distance the shadow is cast
const shadow_direction = 30 # direction the shadow is cast in degrees

@onready var shadow_offset = Vector2.RIGHT.rotated(deg_to_rad(shadow_direction))*offset_amnt

var shadow_node : Node2D 
var delete_on_tree_exit = true

func _ready():
	if !is_instance_valid(global_drop_shadow_manager):
		global_drop_shadow_manager = GLOBAL_SHADOW_MANAGER.instantiate()
		get_tree().get_root().add_child.bind(global_drop_shadow_manager).call_deferred()
	if create_on_ready:
		create_shadow()

func create_shadow():
	var parent : Node2D = get_parent()
	visibility_changed.connect(update_visibility)
	tree_exited.connect(on_tree_exit)
	
	if parent is Polygon2D:
		var p = Polygon2D.new()
		p.polygon = parent.polygon
		shadow_node = p
	elif parent is Sprite2D:
		var s = Sprite2D.new()
		s.texture = parent.texture
		s.region_enabled = parent.region_enabled
		s.flip_h = parent.flip_h
		s.flip_v = parent.flip_v
		s.hframes = parent.hframes
		s.vframes = parent.vframes
		s.frame = parent.frame
		s.region_rect = parent.region_rect
		s.offset = parent.offset
		shadow_node = s
	elif parent is AnimatedSprite2D:
		var a : AnimatedSprite2D = parent.duplicate(8)
		for c in a.get_children():
			if c is DropShadow:
				c.free()
		#a.get_node("DropShadow").free()
		shadow_node = a
	elif parent is TileMap:
		var tm = parent.duplicate()
		for c in tm.get_children():
			c.free()
		tm.z_index = 0
		tm.modulate = Color.BLACK
		shadow_node = tm
	else:
		set_process(false)
		return
	
	if is_static:
		set_process(false)
	
	update_transform()
	
	shadow_node.modulate = Color.BLACK
	if is_global:
		shadow_node.z_as_relative = true
		shadow_node.z_index = 0
		global_drop_shadow_manager.add_global_shadow_node(shadow_node)
	else:
		add_child(shadow_node)
		shadow_node.modulate = global_drop_shadow_manager.shadow_color
		update_transform()
		show_behind_parent = true
		shadow_node.show_behind_parent = true
		shadow_node.z_index = custom_z_index_difference
	update_visibility()

func _process(_delta):
	update_transform()

@export var verbose = false

func update_visibility():
	if is_instance_valid(shadow_node):
		shadow_node.visible = is_visible_in_tree()

func on_tree_exit():
	if !delete_on_tree_exit:
		return
	if is_instance_valid(shadow_node):
		shadow_node.queue_free()
		set_process(false)

func update_transform():
	var pos_vec = shadow_offset
	position = Vector2.ZERO
	if shadow_node == null:
		return
	shadow_node.global_transform = global_transform
	shadow_node.global_position = global_position + pos_vec

func set_shadow_offset(_offset_amnt):
	offset_amnt = _offset_amnt
	shadow_offset = Vector2.RIGHT.rotated(deg_to_rad(shadow_direction))*offset_amnt
