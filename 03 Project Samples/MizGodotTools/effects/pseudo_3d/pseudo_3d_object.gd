class_name Pseudo3DObject extends Node2D

static var pseudo_3d_layer_manager : Pseudo3DLayerManager

@export var min_layer = 0#-Pseudo3DLayerManager.MAX_DOWNWARDS_LAYERS
@export var max_layer = Pseudo3DLayerManager.MAX_UPWARDS_LAYERS

var layer_instances = []
var is_duplicate_instance = false

@export var auto_modulate = true # get darker towards the top and bottom layers
@export var zero_upper_layer_z_index = false # zeroes the z index of other layer instances

func _ready():
	if max_layer < 0: # if below floor completely disable collision
		disable_collision(self)
	if is_duplicate_instance:
		if is_in_group("serializable"):
			remove_from_group("serializable")
		return
	
	# this code is only run on the base instance
	for child in get_children():
		if child.owner != self and "z_index" in child and child.z_index == 0:
			child.z_index = 2
	
	if pseudo_3d_layer_manager == null:
		pseudo_3d_layer_manager = Pseudo3DLayerManager.new()
		get_tree().get_root().add_child.bind(pseudo_3d_layer_manager).call_deferred()
	
	while !pseudo_3d_layer_manager.initialized:
		await get_tree().process_frame
	
	var hide_base = true
	for i in range(min_layer, max_layer+1):
		if i == 0:
			hide_base = false
			continue
			
		var dup = create_duplicate()
		dup.global_transform = global_transform
		pseudo_3d_layer_manager.add_node_to_layer(dup, i, auto_modulate)
		layer_instances.append(dup)
	
	if hide_base:
		hide()

func disable_collision(obj):
	if obj is TileMapLayer:
		obj.tile_set = obj.tile_set.duplicate()
		obj.tile_set.set_physics_layer_collision_layer(0, 0)
		obj.tile_set.set_physics_layer_collision_mask(0, 0)
	if "collision_layer" in obj:
		obj.set("collision_layer", 0)
	if "collision_mask" in obj:
		obj.set("collision_mask", 0)

func create_duplicate():
	var dup = duplicate(DUPLICATE_USE_INSTANTIATION)
	if dup is Pseudo3DObject:
		dup.is_duplicate_instance = true
	if zero_upper_layer_z_index:
		dup.z_index = 0
		dup.z_as_relative = 0
	disable_collision(dup)
	return dup
