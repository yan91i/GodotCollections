extends MarginContainer

const TAB_DATA_ID: String = "unknown"

@onready var grid_container: GridContainer = %GridContainer

###############
## overrides ##
###############


func _ready() -> void:
	_initialize()
	_connect_signals()
	_load_from_save_file()



#############
## helpers ##
#############


func _initialize() -> void:
	pass


func _load_from_save_file() -> void:
	pass


#############
## signals ##
#############


func _connect_signals() -> void:
	SignalBus.tab_changed.connect(_on_tab_changed)


func _on_tab_changed(tab_data: TabData) -> void:
	if tab_data.id == TAB_DATA_ID:
		visible = true
	else:
		visible = false
