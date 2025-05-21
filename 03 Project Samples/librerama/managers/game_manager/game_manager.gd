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

extends CanvasLayer


signal control_type_changed

signal dim_changed

signal faded_in
@warning_ignore("unused_signal")
signal faded_out

enum ControlTypes {
	AUTOMATIC,
	TOUCH,
	JOYPAD,
	JOYPAD_TOUCH,
	KEYBOARD,
}

const SETTINGS_PATH = "user://settings.ini"

const REPOSITORY_LINK = "https://codeberg.org/Librerama/librerama"

const FADE_SPEED = 0.6

const _NANOGAME_INPUT_ACTIONS: Array[String] = [
	"nanogame_up",
	"nanogame_down",
	"nanogame_left",
	"nanogame_right",
	"nanogame_action"
]

const JOYSTICK_SCROLL_SPEED = 500

var main_control: int = ControlTypes.AUTOMATIC: set = set_main_control

var dim := false: set = set_dim

var _scene_loader := Thread.new()

var _previous_scene_name := ""

var _system_locale := ""

var _is_locale_system_default := false
var _is_turning_locale_system_default := false

var _rtl_focused: RichTextLabel


func _ready() -> void:
	set_process(false)

	get_window().min_size = Vector2(133, 100)

	AudioServer.set_bus_volume_db(1, linear_to_db(0.5))
	AudioServer.set_bus_volume_db(2, linear_to_db(0.8))

	if OS.has_feature("release"):
		randomize()

	### Load Settings ###

	var config := ConfigFile.new()
	var error_code: int = config.load(SETTINGS_PATH)
	if error_code != OK:
		set_locale_system_default()

		if error_code != ERR_FILE_NOT_FOUND:
			push_error("Unable to load settings data. Error code: " +
					str(error_code))
		else:
			save_settings()

		return

	if config.has_section_key("general", "language"):
		var value: Variant = config.get_value("general", "language")
		if value is String and not value.is_empty() and\
				get_locales().has(value):
			TranslationServer.set_locale(value)
		else:
			set_locale_system_default()
	else:
		set_locale_system_default()

	if config.has_section_key("general", "fullscreen_window"):
		var value: Variant = config.get_value("general", "fullscreen_window")
		if value is bool:
			get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN\
					if value else Window.MODE_WINDOWED

	for i: String in ["pause_focus_lost",
			"mute_focus_lost", "show_community_warning"] as Array[String]:
		if config.has_section_key("general", i):
			var value: Variant = config.get_value("general", i)
			if value is bool:
				ProjectSettings.set_setting(
						"game_settings".path_join(i), value)

	if config.has_section_key("controls", "main_control"):
		var value: Variant = config.get_value("controls", "main_control")
		if value is int and value >= 0 and value < ControlTypes.size():
			set_main_control(value)

	for i: String in _NANOGAME_INPUT_ACTIONS:
		var input_events: Array[InputEvent] = InputMap.action_get_events(i)
		InputMap.action_erase_events(i)

		if config.has_section_key("controls", i + "_keyboard"):
			var value: Variant = config.get_value("controls", i + "_keyboard")
			if value is int and not OS.get_keycode_string(value).is_empty():
				input_events[0].keycode = value

		if config.has_section_key("controls", i + "_joypad"):
			var value: Variant = config.get_value("controls", i + "_joypad")
			if value is Vector2:
				if value.x >= 0 and value.x < JOY_AXIS_MAX and\
						(value.y == -1 or value.y == 1):
					input_events[1].axis = value.x
					input_events[1].axis_value = value.y
			elif value is int and value >= 0 and value <= JOY_BUTTON_MAX:
				input_events[1] = InputEventJoypadButton.new()
				input_events[1].button_index = value

		for j: InputEvent in input_events:
			InputMap.action_add_event(i, j)

	if config.has_section_key("controls", "switch_touch_controls"):
		var value: Variant =\
				config.get_value("controls", "switch_touch_controls")
		if value is bool:
			ProjectSettings.set_setting(
					"game_settings/switch_touch_controls", value)

	for i: int in AudioServer.bus_count:
		if i == 0:
			continue # Skip "Master" bus.

		var bus_name: String = AudioServer.get_bus_name(i).to_lower()

		if config.has_section_key("audio", bus_name + "_mute"):
			var value: Variant = config.get_value("audio", bus_name + "_mute")
			if value is bool:
				AudioServer.set_bus_mute(i, value)

		if config.has_section_key("audio", bus_name + "_volume"):
			var value: Variant =\
					config.get_value("audio", bus_name + "_volume")
			if value is float and value >= 0 and value <= 1:
				AudioServer.set_bus_volume_db(i, linear_to_db(value))


	save_settings()

	get_viewport().gui_focus_changed.connect(pass_focused_control_node)

	Input.joy_connection_changed.connect(
			_on_input_joy_connection_changed.unbind(2))


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_IN:
			if not OS.has_feature("mobile") and ProjectSettings.get_setting(
					"game_settings/mute_focus_lost"):
				AudioServer.set_bus_mute(0, false)

			if _is_locale_system_default and _system_locale != OS.get_locale():
				set_locale_system_default()
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			if not OS.has_feature("mobile") and ProjectSettings.get_setting(
					"game_settings/mute_focus_lost"):
				AudioServer.set_bus_mute(0, true)
		NOTIFICATION_WM_CLOSE_REQUEST:
			if _scene_loader.is_started():
				_scene_loader.wait_to_finish()
		NOTIFICATION_TRANSLATION_CHANGED:
			if not _is_turning_locale_system_default:
				_is_locale_system_default = false


func _process(delta: float) -> void:
	if _rtl_focused == null:
		set_process(false)
		return

	if Input.is_action_pressed("menu_scroll_up"):
		_rtl_focused.get_v_scroll_bar().value -= JOYSTICK_SCROLL_SPEED *\
				Input.get_action_strength("menu_scroll_up") * delta
	elif Input.is_action_pressed("menu_scroll_down"):
		_rtl_focused.get_v_scroll_bar().value += JOYSTICK_SCROLL_SPEED *\
				Input.get_action_strength("menu_scroll_down") * delta


func switch_main_scene(path: String) -> void:
	if _scene_loader.is_started():
		push_error("The game manager is already switching the main scene.")

		return

	fade_in()

	_scene_loader.start(_load_scene.bind(path))

	await faded_in
	var scene: PackedScene = _scene_loader.wait_to_finish()

	if scene != null:
		_previous_scene_name = get_tree().current_scene.get_name()

		get_tree().change_scene_to_packed(scene)

	fade_out()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("general", "language", TranslationServer.get_locale()
			if not _is_locale_system_default else "")

	config.set_value("general", "fullscreen_window",
			get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN)

	for i: String in ["pause_focus_lost",
			"mute_focus_lost", "show_community_warning"] as Array[String]:
		config.set_value("general", i,
				ProjectSettings.get_setting("game_settings".path_join(i)))

	config.set_value("controls", "main_control", main_control)

	for i: String in _NANOGAME_INPUT_ACTIONS:
		var input_events: Array[InputEvent] = InputMap.action_get_events(i)
		config.set_value(
				"controls", i + "_keyboard", input_events[0].keycode)
		config.set_value("controls", i + "_joypad", input_events[1].button_index
				if input_events[1] is InputEventJoypadButton else
				Vector2(input_events[1].axis, input_events[1].axis_value))

	config.set_value("controls", "switch_touch_controls",
			ProjectSettings.get_setting("game_settings/switch_touch_controls"))

	for i: int in AudioServer.bus_count:
		if i == 0:
			continue # Skip "Master" bus.

		var bus_name: String = AudioServer.get_bus_name(i).to_lower()
		config.set_value(
				"audio", bus_name + "_mute", AudioServer.is_bus_mute(i))
		config.set_value("audio", bus_name + "_volume",
				db_to_linear(AudioServer.get_bus_volume_db(i)))

	var error_code: int = config.save(SETTINGS_PATH)
	if error_code != OK:
		push_error("Unable to save settings data. Error code: " +
				str(error_code))


func fade_in() -> void:
	if _scene_loader.is_started():
		push_warning("The game manager has fading priority when switching " +\
				"the main scene.")

		return

	var fade := $Fade as ColorRect

	# Avoid UI interaction while the player is being blinded.
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	if fade.get_viewport().gui_get_focus_owner() != null:
		fade.get_viewport().gui_get_focus_owner().release_focus();

	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(fade, "color:a", 1, FADE_SPEED)
	tween.tween_method(_update_volume_fade, 1.0, 0, FADE_SPEED)
	tween.chain().tween_callback(emit_signal.bind("faded_in"))


func fade_out() -> void:
	if _scene_loader.is_started():
		push_warning("The game manager has fading priority when switching " +\
				"the main scene.")

		return

	var tween: Tween = create_tween().set_parallel()
	var fade := $Fade as ColorRect
	tween.tween_property(fade, "color:a", 0, FADE_SPEED)
	tween.tween_method(_update_volume_fade, 0.0, 1, FADE_SPEED)

	if fade.mouse_filter == Control.MOUSE_FILTER_STOP:
		tween.tween_callback(
				fade.set_mouse_filter.bind(Control.MOUSE_FILTER_IGNORE))

	tween.chain().tween_callback(emit_signal.bind("faded_out"))


func pass_focused_control_node(node: Control) -> void:
	_rtl_focused = node as RichTextLabel if node is RichTextLabel else null
	if _rtl_focused != null:
		set_process(true)


func set_main_control(control: int) -> void:
	if control < 0 or control >= ControlTypes.size():
		push_error('Invalid control type of index "%d".' % control)

	if control == main_control:
		return

	var control_type: int = get_control_type()

	main_control = control

	if control_type != get_control_type():
		control_type_changed.emit()


func set_dim(is_dimmed: bool) -> void:
	if dim == is_dimmed:
		return

	dim = is_dimmed
	($Dim as ColorRect).visible = is_dimmed

	dim_changed.emit()


func set_locale_system_default() -> void:
	_is_locale_system_default = true
	_is_turning_locale_system_default = true

	_system_locale = OS.get_locale()
	var locales: PackedStringArray = get_locales()
	if locales.has(_system_locale):
		TranslationServer.set_locale(_system_locale)
	else:
		TranslationServer.set_locale("en_US")

	# Wait for the translation change notification to blow off first.
	await get_tree().process_frame
	_is_turning_locale_system_default = false


func is_locale_system_default() -> bool:
	return _is_locale_system_default


func is_using_joypad() -> bool:
	var control_type: int = get_control_type()
	return control_type == ControlTypes.JOYPAD or\
			control_type == ControlTypes.JOYPAD_TOUCH


func get_nanogame_input_actions() -> Array[String]:
	return _NANOGAME_INPUT_ACTIONS.duplicate()


func get_control_type() -> int:
	if main_control != ControlTypes.AUTOMATIC:
		return main_control

	if Input.get_connected_joypads().is_empty() and\
			DisplayServer.is_touchscreen_available():
		return ControlTypes.TOUCH

	if not Input.get_connected_joypads().is_empty():
		return ControlTypes.JOYPAD_TOUCH\
				if DisplayServer.is_touchscreen_available() else\
				ControlTypes.JOYPAD

	return ControlTypes.KEYBOARD


func get_previous_scene_name() -> String:
	return _previous_scene_name


func get_locales() -> PackedStringArray:
	var locales: PackedStringArray = TranslationServer.get_loaded_locales()
	locales.append("en_US")
	locales.sort()

	return locales


func _load_scene(path: String) -> PackedScene:
	var scene: Variant = load(path)
	if scene is not PackedScene:
		push_error('Path "%s" is not a scene to be switched to.' % path)

		return null

	return scene


func _update_volume_fade(volume: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(volume))


func _on_input_joy_connection_changed() -> void:
	if main_control == ControlTypes.AUTOMATIC:
		control_type_changed.emit()


class Yielder:
	signal resumed

	var _is_active := false


	func activate() -> void:
		_is_active = true


	func resume() -> void:
		if _is_active:
			_is_active = false
			resumed.emit()


	func is_active() -> bool:
		return _is_active
