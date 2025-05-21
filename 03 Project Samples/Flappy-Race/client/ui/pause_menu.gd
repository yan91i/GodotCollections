extends PopupPanel


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		get_tree().set_input_as_handled()
		if visible:
			disable_pause_menu()
		else:
			enable_pause_menu()


func enable_pause_menu() -> void:
	# Only allow the game to be paused in singleplayer
	if Network.Client.is_singleplayer:
		get_tree().paused = true
	# Should only be shown to the host player
	$VBoxContainer/NewRaceButton.visible = Network.Client.is_host()
	self.popup()


func disable_pause_menu() -> void:
	self.hide()
	get_tree().paused = false


func _on_ResumeButton_pressed() -> void:
	disable_pause_menu()


func _on_NewRaceButton_pressed() -> void:
	get_tree().paused = false
	Network.Client.send_change_to_setup_request()


func _on_MainMenuButton_pressed() -> void:
	Network.stop_networking()
	get_tree().paused = false
	Network.Client.change_scene_to_title_screen()


func _on_QuitButton_pressed() -> void:
	get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)
