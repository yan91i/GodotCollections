class_name Pseudo3DLayerManager extends Node2D

const MAX_UPWARDS_LAYERS = 6
const MAX_DOWNWARDS_LAYERS = 12

const BASE_Z_INDEX = 900

var upwards_layers = []
var downwards_layers = []

const LAYER_SCALE_INCREMENT = 0.06
const LAYER_SCALE_INC_PERCENT_AT_BOTTOM = 0.8

const UPWARDS_TOP_COLOR : Color = Color("424242")
const DOWNWARDS_BOT_COLOR : Color = Color("070707")

const LAYER_BASE_MODULATE_NAME = "LayerBaseModulate"

var initialized = false

func _ready():
	name = "Pseudo3DLayerManager"
	z_index = BASE_Z_INDEX
	for i in range(-MAX_DOWNWARDS_LAYERS, MAX_UPWARDS_LAYERS+1):
		if i == 0:
			continue
		var canvas_layer = CanvasLayer.new()
		canvas_layer.layer = i
		canvas_layer.follow_viewport_enabled = true
		var increment = LAYER_SCALE_INCREMENT
		
		if i < 0:
			var w = abs(i) / float(MAX_DOWNWARDS_LAYERS)
			var sc = lerp(1.0, LAYER_SCALE_INC_PERCENT_AT_BOTTOM, w)
			increment *= sc
		
		canvas_layer.follow_viewport_scale = 1.0 + increment * i
		canvas_layer.name = "Pseudo3DLayer_%s" % i
		var layer_base = Node2D.new()
		layer_base.name = "LayerBase"
		var layer_base_modulate = Node2D.new()
		layer_base_modulate.name = LAYER_BASE_MODULATE_NAME
		canvas_layer.add_child(layer_base)
		layer_base.add_child(layer_base_modulate)
		
		var max_layer_color = UPWARDS_TOP_COLOR
		var t = float(i) / (MAX_UPWARDS_LAYERS+1)
		if i < 0:
			max_layer_color = DOWNWARDS_BOT_COLOR
			t = float(i) / -MAX_DOWNWARDS_LAYERS
		
		layer_base_modulate.modulate = Color.WHITE.lerp(max_layer_color, t)
		
		add_child(canvas_layer)
		if i > 0:
			upwards_layers.append(layer_base)
		else:
			downwards_layers.push_front(layer_base)
	initialized = true

func add_node_to_layer(node_2d: Node2D, layer: int, apply_modulate=true):
	if layer == 0:
		print_debug("incorrectly tried to set layer 0") # layer 0 should never be set
	
	var layer_arr = upwards_layers
	var layer_ind = layer
	
	if layer < 0:
		layer_arr = downwards_layers
		layer_ind = abs(layer)
	layer_ind -= 1
	
	if layer > layer_arr.size():
		print_debug("cannot set layer %s, does not exist" % layer)
		return
	var layer_base = layer_arr[layer_ind]
	if apply_modulate:
		layer_base = layer_base.get_node(LAYER_BASE_MODULATE_NAME)
	layer_base.add_child(node_2d)
	node_2d.add_to_group("instanced")

static func get_top_layer_scale():
	return 1.0 + LAYER_SCALE_INCREMENT * MAX_UPWARDS_LAYERS

static func get_layer_scale(layer_ind: int):
	if layer_ind >= 0:
		return 1.0 + LAYER_SCALE_INCREMENT * layer_ind
	else:
		var w = abs(layer_ind) / float(MAX_DOWNWARDS_LAYERS)
		var sc = lerp(1.0, LAYER_SCALE_INC_PERCENT_AT_BOTTOM, w)
		return 1.0 + LAYER_SCALE_INCREMENT * sc * layer_ind
