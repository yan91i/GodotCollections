###############################################################################
# Librerama                                                                   #
# Copyright (C) 2023 Michael Alexsander                                       #
#-----------------------------------------------------------------------------#
# This file is part of Librerama.                                             #
#                                                                             #
# Librerama is free software: you can redistribute it and/or modify           #
# it under the terms of the GNU General Public License as published by        #
# the Free Software Foundation, either version 3 of the License, or           #
# (at your option) any later version.                                         #
#                                                                             #
# Librerama is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of              #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               #
# GNU General Public License for more details.                                #
#                                                                             #
# You should have received a copy of the GNU General Public License           #
# along with Librerama.  If not, see <http://www.gnu.org/licenses/>.          #
###############################################################################

extends Control


const DAY_MINUTES = 1_440
const DAY_COLOR = preload("_resources/day_color.tres")

const DAY_HOUR_START = 6
const NIGHT_HOUR_START = 18

const SPEAK_LETTER_TIME_VALUE = 0.02

const ASSISTANT_FADE_LENGTH = 1.0

var _assistant_name := ""
var _assistant_path := ""

var _is_dialog_happening := false
var _can_talk := true

var _was_purchase_made := false

var _dialog_text_current := ""

var _yielder := GameManager.Yielder.new()
var _dialog_tree: Dictionary

@onready var _music := $Music as AudioStreamPlayer


func _ready() -> void:
	set_process_input(false)

	_update_day_state()

	var nanogames_owned: int =\
			ArcadeManager.get_owned_official_nanogames().size()

	if nanogames_owned == 0:
		var arcade := %Arcade as Button
		arcade.text = tr("Locked")
		arcade.disabled = true
		arcade.theme_type_variation = "ButtonLocked"
	else:
		(%Arcade as Button).theme_type_variation = "ButtonPositiveHighlight"\
				if ArcadeManager.has_highlighted_owned_nanogames() or\
				ArcadeManager.is_statistics_highlighted() else "ButtonPositive"

	# TODO: Uncomment once the feature is implemented.
#	if nanogames_owned < ArcadeManager.PRIZES_UNLOCK_NANOGAME_QUANTITY:
	if true:
		var backpack := $Menu/Play/Backpack as Button
		backpack.text = tr("Coming Soon")
		backpack.disabled = true
		backpack.theme_type_variation = "ButtonLocked"

	if OS.has_feature("web"):
		($Menu/Quit as Button).hide()

	if GameManager.get_previous_scene_name() == "Intro":
		($Door as AudioStreamPlayer).play()

	GameManager.control_type_changed.connect(
			_on_game_manager_control_type_changed)
	_on_game_manager_control_type_changed()

	GameManager.dim_changed.connect(($MenuNoise as AudioStreamPlayer).play)
	GameManager.faded_out.connect(_on_game_manager_faded_out)

	ArcadeManager.tickets_removed.connect(set.bind("_was_purchase_made", true))


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_TRANSLATION_CHANGED:
			(%Text as RichTextLabel).text = tr(_dialog_text_current)
		NOTIFICATION_LAYOUT_DIRECTION_CHANGED:
			(%Assistant as Sprite2D).flip_h = is_layout_rtl()


# Only active when yielding is forced in the last bit of dialog.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventKey or\
			event is InputEventJoypadButton:
		set_process_input(false)

		_yielder.resume()


func _update_day_state() -> void:
	var time: Dictionary = Time.get_time_dict_from_system()
	($DayColor as ColorRect).color = DAY_COLOR.sample(
			1.0 / DAY_MINUTES * (time.hour * 60 + time.minute))

	# TODO: Handle multiple staff once they are available.
	var assistant_name: String = "placeholder"
	if assistant_name == _assistant_name:
		return

	_assistant_path =\
			"res://places/lobby/assistants".path_join(assistant_name)

	var file: FileAccess = FileAccess.open(
			_assistant_path.path_join("dialog.json"), FileAccess.READ)
	_dialog_tree = JSON.parse_string(file.get_as_text())
	file.close()

	_can_talk = true
	(%Talk as Button).show()

	var assistant := %Assistant as Sprite2D

	# Update assistant immediately if there's no name set, as that means
	# none was loaded before.
	if _assistant_name.is_empty():
		_assistant_name = assistant_name

		assistant.texture =\
				load(_assistant_path.path_join("_assets/poses/idle.png"))
		assistant.offset.y = -assistant.texture.get_height() / 2.0

		_music.stream = load(_assistant_path.path_join("_assets/music.ogg"))
		_music.play()

		(($AssistantNoise as AudioStreamPlayer).
				stream as AudioStreamRandomizer).set_stream(0,
						load(_assistant_path.path_join("_assets/noise.wav")))

		return

	# TODO: Uncomment once there's more staff.
#	_assistant_name = assistant_name
#
#	_yielder.resume()
#	($Speech as VBoxContainer).hide()
#
#	var tween := $Tween as Tween
#	tween.interpolate_method(
#			assistant, "self_modulate:a", 1, 0, ASSISTANT_FADE_LENGTH)
#	tween.interpolate_callback(assistant, ASSISTANT_FADE_LENGTH,
#			"set_texture", load(_assistant_path + "_assets/poses/idle.png"))
#	tween.interpolate_method(assistant, "self_modulate:a", 0, 1,
#			ASSISTANT_FADE_LENGTH, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT,
#			ASSISTANT_FADE_LENGTH)
#
#	tween.interpolate_method(
#			self, "_set_volume_music", 1, 0, ASSISTANT_FADE_LENGTH)
#	tween.interpolate_callback(_music, ASSISTANT_FADE_LENGTH, "set_stream",
#			load(_assistant_path + "_assets/music.ogg"))
#	tween.interpolate_method(self, "_set_volume_music", 0, 1,
#			ASSISTANT_FADE_LENGTH, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT,
#			ASSISTANT_FADE_LENGTH)
#
#	tween.interpolate_callback(
#			self, ASSISTANT_FADE_LENGTH, "_start_dialog", "replacedAssistant")
#	tween.interpolate_callback(
#			$Speech as VBoxContainer, ASSISTANT_FADE_LENGTH, "show")


func _start_dialog(topic: String, is_leaving:=false) -> void:
	var next := $Speech/Next as Button

	# Finish off the previous dialog if it's in an `await` state.
	if _is_dialog_happening:
		_is_dialog_happening = false

		if _yielder.is_active():
			_yielder.resume()
		elif next.visible:
			next.pressed.emit()

	_is_dialog_happening = true

	(%Buy as Button).hide()
	(%Talk as Button).hide()

	var dialog: Array =\
			_dialog_tree[topic][randi() % _dialog_tree[topic].size()]
	var dialog_size: int = dialog.size()

	var assistant := %Assistant as Sprite2D
	var skip := $Speech/Skip as Button
	skip.hide()
	next.hide()

	for i: int in dialog_size:
		var element: Variant = dialog[i]
		var text := ""

		# Check if the dialog element is a string, otherwise it has to be a
		# dictionary.
		if element is String:
			text = element

			if i == 0:
				assistant.texture = load(
						_assistant_path.path_join("_assets/poses/idle.png"))
		else:
			text = element["text"]

			assistant.texture = load(_assistant_path.path_join(
					"_assets/poses/").path_join(element["sprite"] + ".png"))

		if i < dialog_size - 1:
			skip.show()
			skip.grab_focus()

			await _speak_dialog_text(text)
			if not _is_dialog_happening:
				return

			next.show()
			if skip.has_focus():
				next.grab_focus()
			skip.hide()

			await next.pressed
			if not _is_dialog_happening:
				return
		elif is_leaving:
			set_process_input(true)

			await _speak_dialog_text(text)
			set_process_input(false)

			if not _is_dialog_happening:
				return
		else:
			_speak_dialog_text(text)

		skip.hide()
		next.hide()

	_is_dialog_happening = false


func _speak_dialog_text(text: String) -> void:
	if _yielder.is_active():
		_yielder.resume()

	_dialog_text_current = text

	var text_node := %Text as RichTextLabel
	text_node.text = tr(text)

	var tween: Tween = create_tween()
	tween.tween_property(text_node, "visible_ratio", 1,
			text.length() *  SPEAK_LETTER_TIME_VALUE).from(0.0)

	($AssistantNoise as AudioStreamPlayer).play()
	($AssistantPlayer as AnimationPlayer).play("speak")

	tween.finished.connect(_yielder.resume, CONNECT_ONE_SHOT)
	_yielder.resumed.connect(tween.kill, CONNECT_ONE_SHOT)

	_yielder.activate()
	# Wait for assistant to finish speaking, or for the player to skip it.
	# Either will resume the yield.
	await _yielder.resumed

	($AssistantPlayer as AnimationPlayer).play("speak_end")

	text_node.visible_ratio = 1


func _update_volume_music(volume: float) -> void:
	_music.volume_db = linear_to_db(volume)


func _on_text_meta_clicked(meta: String) -> void:
	OS.shell_open(meta)


func _on_skip_pressed() -> void:
	_yielder.resume()


func _on_buy_pressed() -> void:
	($Speech as VBoxContainer).hide()
	($Menu as HBoxContainer).hide()

	($BuyMenu as Control).show()

	($MenuNoise as AudioStreamPlayer).play()


func _on_talk_pressed() -> void:
	_can_talk = false

	await _start_dialog("talkGeneric")

	(%Buy as Button).show()
	(%Buy as Button).grab_focus()


func _on_arcade_pressed() -> void:
	($Menu as HBoxContainer).hide()

	await _start_dialog("cutoffMidSpeech" if _is_dialog_happening
			else "goingToPlay", true)

	GameManager.switch_main_scene(
			"res://places/arcade_machine/arcade_machine.tscn")


func _on_backpack_pressed() -> void:
	pass
	# TODO: Uncomment when the backpack is implemented.
#	($Menu as HBoxContainer).hide()
#
#	await _start_dialog("cutoffMidSpeech" if _is_dialog_happening
#			else "goingToPlay", true)
#
#	GameManager.switch_main_scene("res://places/backpack/backpack.tscn")


func _on_quit_pressed() -> void:
	($Menu as HBoxContainer).hide()
	($Door as AudioStreamPlayer).play()

	await _start_dialog(
			"cutoffMidSpeech" if _is_dialog_happening else "goodbye", true)

	GameManager.fade_in()

	await GameManager.faded_in
	get_tree().quit()


func _on_buy_menu_hidden() -> void:
	if _was_purchase_made:
		_was_purchase_made = false

		_start_dialog("purchaseMade")

		(%Arcade as Button).theme_type_variation = "ButtonPositiveHighlight"\
				if ArcadeManager.has_highlighted_owned_nanogames() or\
				ArcadeManager.is_statistics_highlighted() else "ButtonPositive"

		(%Buy as Button).show()
		if _can_talk:
			(%Talk as Button).show()

	($Speech as VBoxContainer).show()
	($Menu as HBoxContainer).show()

	($MenuNoise as AudioStreamPlayer).play()

	await get_tree().process_frame
	(%Buy as Button).grab_focus()


func _on_assistant_noise_finished() -> void:
	# Keep playing the sound if the assistant hasn't finshed speaking.
	if (%Text as RichTextLabel).visible_ratio < 1:
		($AssistantNoise as AudioStreamPlayer).play()


func _on_game_manager_faded_out() -> void:
	($Speech as VBoxContainer).show()

	var arcade := %Arcade as Button

	if GameManager.get_previous_scene_name() == "Intro":
		# Start the introductory stuff if no nanogames are owned, as it's the
		# very first play. Otherwise, business as usual.
		if ArcadeManager.get_owned_official_nanogames().is_empty():
			await _start_dialog("firstTimePlaying")

			arcade.text = "Arcade"
			arcade.disabled = false
			arcade.theme_type_variation = "ButtonPositive"
			arcade.grab_focus()

			return

		# Don't let the welcome dialog get in the player's way every time,
		# so no awaiting.
		_start_dialog("welcomeGeneric")
	else:
		_start_dialog("cameBack")

	($Speech/Buy as Button).show()
	(%Talk as Button).show()

	arcade.grab_focus()


func _on_game_manager_control_type_changed() -> void:
	if GameManager.is_using_joypad():
		var focus_joypad: StyleBox =\
				theme.get_stylebox("focus_joypad", "Focus")
		theme.set_stylebox("focus", "Button", focus_joypad)
		theme.set_stylebox("focus", "LineEdit", focus_joypad)
		theme.set_stylebox("focus", "RichTextLabel", focus_joypad)
	else:
		var style_empty := StyleBoxEmpty.new()

		if not OS.has_feature("mobile"):
			theme.set_stylebox(
					"focus", "Button", theme.get_stylebox("focus", "Focus"))
		else:
			theme.set_stylebox("focus", "Button", style_empty)

		# Use the empty style, as the blinking caret is enough to indicate that
		# it's focused.
		theme.set_stylebox("focus", "LineEdit", style_empty)

		theme.set_stylebox("focus", "RichTextLabel", style_empty)
