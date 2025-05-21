# Handles the input that brings up the minimap or the quit menu.
extends CanvasLayer

@onready var screen_fader: TextureRect = $ScreenFader
@onready var map: TextureRect = $MapDisplay
@onready var upgrade_menu := $UpgradeUI
@onready var quit_menu := $QuitMenu


func _ready() -> void:
	Events.player_died.connect(reset.bind(true))
	Events.quit_requested.connect(quit)
	Events.upgrade_unlocked.connect(upgrade_menu.open)
	screen_fader.fade_in()


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return

	if event.is_action_pressed("ui_cancel"):
		quit_menu.open()
	if event.is_action_pressed("toggle_map") and not map.is_animating():
		map.toggle()


func quit() -> void:
	get_tree().quit()


func reset(with_delay: bool) -> void:
	screen_fader.fade_out(with_delay)
	await screen_fader.animation_finished
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
