class_name Pseudo3DObjectWithCustomLayers extends Pseudo3DObject

## Pseudo3DObject with unique layers
## must be the child of another node if check_parent_to_place_things_on_top_layer is set to true
## any sibling nodes that are not part of this nodes original scene will be moved to top layer
## e.g. you make a table scene like so :
## StaticBody2D
## - CollisionShape2D
## - Pseudo3DObjectWithCustomLayers
## -- CustomLayers
## --- Layer1
## --- Layer2
## 
## Then in another scene instance the table and add a child:
## Table
## - Plate
##
## the plate will be moved to the top pseudo3d layer and appear to be on top of the table


@onready var custom_layers = $CustomLayers.get_children()
@export var delete_hidden_layers = true
@export var check_parent_to_place_things_on_top_layer = false
@export var custom_top_layer_to_place_things_on = -999 # super high negative number means choose top layer
@export var auto_set_bottom_layer_to_higher_z_index = true # set false if drop shadow should affect bottom layer

func _ready():
	await super()
	
	if is_duplicate_instance:
		return
	
	if check_parent_to_place_things_on_top_layer and custom_top_layer_to_place_things_on != 0:
		if custom_top_layer_to_place_things_on < -900: # arbitrary low number
			custom_top_layer_to_place_things_on = custom_layers.size() - 2 # have to sub 2 since layer 1 is index 0
		else:
			custom_top_layer_to_place_things_on -= 1 # index 0 is actually layer 1 so sub 1
		var p = get_parent()
		for c in p.get_children():
			if c is Pseudo3DObjectWithCustomLayers: # if placing a pseudo 3d object it should handle it's layers on it's own
				continue
			if c.owner != p:
				var ds = c.find_children("", "DropShadow")
				for drop_shadow : DropShadow in ds:
					drop_shadow.delete_on_tree_exit = false
				
				var top_layer = layer_instances[custom_top_layer_to_place_things_on]
				c.reparent(top_layer)
				if c.z_index == 0:
					c.z_index = 1
				
				for drop_shadow : DropShadow in ds:
					drop_shadow.delete_on_tree_exit = true
	
	set_custom_layer_visibile(0)
	if auto_set_bottom_layer_to_higher_z_index:
		custom_layers[0].z_index = 400
		custom_layers[0].z_as_relative = 400
	var ind = 1
	for layer in layer_instances:
		layer.set_custom_layer_visibile(ind)
		ind += 1


func set_custom_layer_visibile(ind: int):
	for custom_layer in custom_layers:
		custom_layer.hide()
	if custom_layers.size() <= ind:
		if ind != 0:
			queue_free()
		return
	custom_layers[ind].show()
	
	if delete_hidden_layers:
		for custom_layer in custom_layers:
			if !custom_layer.visible:
				custom_layer.queue_free()

func create_duplicate():
	var dup = super()
	for drop_shadow : DropShadow in dup.find_children("", "DropShadow"):
		drop_shadow.queue_free()
	return dup
