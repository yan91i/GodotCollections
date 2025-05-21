extends Camera2D

@onready var player: BitBoyPlayer = $"../Player"

func _ready() -> void:
	make_current()

func _physics_process(_delta: float) -> void:
	# Yes I know this isn't how you're supposed to use lerp but it works alright
	global_position = lerp(global_position, player.global_position, 0.1)
