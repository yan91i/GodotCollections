class_name ExperienceController
extends Node

###############
## overrides ##
###############


func _ready() -> void:
	_connect_signals()


#############
## signals ##
#############


func _connect_signals() -> void:
	SignalBus.progress_button_paid.connect(_on_progress_button_paid)


func _on_progress_button_paid(_resource_generator: ResourceGenerator, _source: String) -> void:
	SignalBus.resource_generated.emit("experience", 1, name)
