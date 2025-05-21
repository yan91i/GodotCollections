extends CanvasLayer
static var image = load("res://assets/kenney_space-shooter-redux/PNG/UI/playerLife1_blue.png")
var time_elapsed := 0
func set_health(amount):
	print("amount",amount)
	for child in $MarginContainer2/HBoxContainer.get_children():
		child.queue_free()
	for i in amount:
		var text_rect = TextureRect.new()
		text_rect.texture = image
		$MarginContainer2/HBoxContainer.add_child(text_rect)


func _on_score_timer_timeout() -> void:
	time_elapsed += 1
	$MarginContainer/Score.text = str(time_elapsed)
	Global.score = time_elapsed
