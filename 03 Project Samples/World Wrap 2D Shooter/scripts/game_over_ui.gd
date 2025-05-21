extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"CenterContainer/VBoxContainer/Your Score".text = "Score : " + str(Global.score)



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		get_tree().change_scene_to_file("res://scenes/level.tscn")
	if event.is_action_pressed("exit"):
		get_tree().quit()
