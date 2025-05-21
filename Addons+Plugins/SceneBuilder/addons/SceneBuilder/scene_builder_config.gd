extends Resource
class_name SceneBuilderConfig

@export var root_dir: String = "res://Data/SceneBuilder/"

@export_group("For use with the Alt modifier")

# Instantiate
@export var instantiate_in_a_row_1: Key = KEY_L
@export var instantiate_in_a_row_2: Key = KEY_SEMICOLON
@export var instantiate_in_a_row_5: Key = KEY_APOSTROPHE

# Name
@export var alphabetize_nodes: Key = KEY_0
@export var reset_node_name: Key = KEY_N

# Node
@export var change_places: Key = KEY_C
@export var find_mismatched_types: Key = KEY_9
@export var swap_nodes: Key = KEY_S

# Transform
@export var reset_transform: Key = KEY_T
@export var reset_transform_rotation: Key = KEY_R
@export var push_to_grid: Key = KEY_P
@export var push_parent_offset_to_child: Key = KEY_O

# Resources
@export var create_audio_stream_player_3d: Key = KEY_COMMA
@export var create_scene_builder_items: Key = KEY_SLASH
@export var create_standard_material_3d: Key = KEY_M

# Debug
@export var temporary_debug: Key = KEY_PERIOD
