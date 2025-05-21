extends Control

@onready var container := $VBoxContainer as VBoxContainer

const scenes := {
	"Texture viewer": "res://scenes/txd.tscn",
	"Flycam test": "res://scenes/flycam/flycam.tscn",
	"DFF Test": "res://scenes/model_test.tscn",
	"Map loader test": "res://scenes/map_test.tscn", }

func _ready() -> void:
	for k in scenes:
		var button := Button.new()
		button.text = k
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(func _load_scene():
			get_tree().change_scene_to_file(scenes[k]) )
		container.add_child(button)
