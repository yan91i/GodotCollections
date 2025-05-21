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

@tool
extends TabModal


@onready var _input_modal := $InputModal as Modal

@onready var _inputs_group: ButtonGroup =\
		($Controls/InputsSection/Up as Button).button_group


func _ready() -> void:
	super()

	if Engine.is_editor_hint():
		return

	var is_mobile: bool = OS.has_feature("mobile")

	### General ###

	var locales := %Locales as OptionButton
	var is_locale_system_default: bool = GameManager.is_locale_system_default()
	var selected_id := 2 # Skip the "System Default" and the separator IDs.
	for i: String in GameManager.get_locales():
		var item_name: String = TranslationServer.get_locale_name(i)

		if i == "en_US":
			item_name = item_name.split(",")[0]
		else:
			var locale_name: String = TranslationServer.\
					get_translation_object(i).get_message(item_name)
			if not locale_name.is_empty():
				item_name = locale_name

		locales.add_item(item_name)
		locales.set_item_metadata(-1, i)

		if is_locale_system_default or locales.selected != -1:
			continue

		if i == TranslationServer.get_locale():
			locales.selected = selected_id
		else:
			selected_id += 1
	if is_locale_system_default:
		locales.selected = 0

	if is_mobile:
		($General/Fullscreen as CheckBox).hide()
	else:
		($General/Fullscreen as CheckBox).button_pressed =\
				get_tree().root.mode == Window.MODE_EXCLUSIVE_FULLSCREEN

	($General/PauseFocusLost as CheckBox).button_pressed =\
			ProjectSettings.get_setting("game_settings/pause_focus_lost")

	if is_mobile:
		($General/MuteFocusLost as CheckBox).hide()
	else:
		($General/MuteFocusLost as CheckBox).button_pressed =\
				ProjectSettings.get_setting("game_settings/mute_focus_lost")

	($General/CommunityWarning as CheckBox).button_pressed =\
			ProjectSettings.get_setting("game_settings/show_community_warning")


	### Controls ###

	if is_mobile:
		# Remove "Keyboard and Mouse".
		($Controls/MainControl/ControlTypes as OptionButton).remove_item(5)

	var main_control: int = GameManager.main_control
	# Skip the separator's index if necessary.
	($Controls/MainControl/ControlTypes as OptionButton).selected =\
			main_control if main_control == 0 else main_control + 1

	($Controls/SwitchTouchControls as CheckBox).button_pressed =\
			ProjectSettings.get_setting("game_settings/switch_touch_controls")

	GameManager.control_type_changed.connect(_update_inputs_section)
	_update_inputs_section()


	### Volume ###

	var everything_toggle := $Volume/Everything/EverythingToggle as CheckButton
	everything_toggle.button_pressed =\
			not AudioServer.is_bus_mute(everything_toggle.get_meta("bus"))
	everything_toggle.toggled.connect(
			_on_volume_toggle_toggled.bind(everything_toggle))
	($Volume/EverythingSlider as HSlider).value_changed.connect(
			_on_volume_slider_value_changed.bind(everything_toggle))
	($Volume/EverythingSlider as HSlider).value = db_to_linear(AudioServer.
			get_bus_volume_db(everything_toggle.get_meta("bus")))

	var music_toggle := $Volume/Music/MusicToggle as CheckButton
	music_toggle.button_pressed =\
			not AudioServer.is_bus_mute(music_toggle.get_meta("bus"))
	music_toggle.toggled.connect(
			_on_volume_toggle_toggled.bind(music_toggle))
	($Volume/MusicSlider as HSlider).value_changed.connect(
			_on_volume_slider_value_changed.bind(music_toggle))
	($Volume/MusicSlider as HSlider).value = db_to_linear(AudioServer.
			get_bus_volume_db(everything_toggle.get_meta("bus")))

	var effects_toggle := $Volume/Effects/EffectsToggle as CheckButton
	effects_toggle.button_pressed =\
			not AudioServer.is_bus_mute(effects_toggle.get_meta("bus"))
	effects_toggle.toggled.connect(
			_on_volume_toggle_toggled.bind(effects_toggle))
	($Volume/EffectsSlider as HSlider).value_changed.connect(
			_on_volume_slider_value_changed.bind(effects_toggle))
	($Volume/EffectsSlider as HSlider).value = db_to_linear(AudioServer.
			get_bus_volume_db(everything_toggle.get_meta("bus")))


func _notification(what: int) -> void:
	if is_node_ready() and not Engine.is_editor_hint() and\
			what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_inputs_section()


func _update_inputs_section() -> void:
	var control_type: int = GameManager.get_control_type()

	($Controls/SwitchTouchControls as CheckBox).visible =\
			control_type == GameManager.ControlTypes.TOUCH

	($Controls/InputsSection as GridContainer).visible =\
			control_type != GameManager.ControlTypes.TOUCH
	if not ($Controls/InputsSection as GridContainer).visible:
		return

	var has_joypad: bool = GameManager.is_using_joypad()
	for i: Button in _inputs_group.get_buttons():
		for j: InputEvent in InputMap.action_get_events(i.get_meta("action")):
			if has_joypad:
				if j is not InputEventJoypadButton and\
						j is not InputEventJoypadMotion:
					continue

				i.text = _input_modal.format_joypad_input_text(j)

				break
			elif j is InputEventKey:
				i.text = j.as_text_keycode()

				if i.text == "Space":
					i.text = tr("Space", "Keyboard")

				break


func _update_volume_toggle_percentage(toggle: CheckButton) -> void:
	toggle.text = str(int(db_to_linear(AudioServer.get_bus_volume_db(
			toggle.get_meta("bus"))) * 100)) + "%"


func _on_languages_item_selected(index: int) -> void:
	if index == 0:
		GameManager.set_locale_system_default()
	else:
		# Change ID to ignore the "System Default" and separator items.
		TranslationServer.set_locale(
				(%Locales as OptionButton).get_item_metadata(index))

	GameManager.save_settings()


func _on_fullscreen_toggled(button_pressed: bool) -> void:
	get_tree().root.mode = Window.MODE_EXCLUSIVE_FULLSCREEN if button_pressed\
			else Window.MODE_WINDOWED

	GameManager.save_settings()


func _on_pause_focus_lost_toggled(button_pressed: bool) -> void:
	ProjectSettings.set_setting(
			"game_settings/pause_focus_lost", button_pressed)

	GameManager.save_settings()


func _on_mute_focus_lost_toggled(button_pressed: bool) -> void:
	ProjectSettings.set_setting(
			"game_settings/mute_focus_lost", button_pressed)

	GameManager.save_settings()


func _on_community_warning_toggled(button_pressed: bool) -> void:
	ProjectSettings.set_setting(
			"game_settings/show_community_warning", button_pressed)

	GameManager.save_settings()


func _on_control_types_item_selected(index: int) -> void:
	# Change index to ignore the separator item.
	if index != GameManager.ControlTypes.AUTOMATIC:
		index -= 1

	GameManager.main_control = index

	_update_inputs_section()

	GameManager.save_settings()


func _on_switch_touch_controls_toggled(button_pressed: bool) -> void:
	ProjectSettings.set_setting(
			"game_settings/switch_touch_controls", button_pressed)

	GameManager.save_settings()


func _on_volume_toggle_toggled(
			button_pressed: bool, toggle: CheckButton) -> void:
	AudioServer.set_bus_mute(toggle.get_meta("bus"), not button_pressed)

	GameManager.save_settings()


func _on_volume_slider_value_changed(
		value: float, toggle: CheckButton) -> void:

	AudioServer.set_bus_volume_db(toggle.get_meta("bus"), linear_to_db(value))

	_update_volume_toggle_percentage(toggle)

	GameManager.save_settings()


func _on_input_modal_ok_pressed() -> void:
	var input_button: Button = _inputs_group.get_pressed_button()

	var action_name: String = input_button.get_meta("action")
	if GameManager.get_control_type() == GameManager.ControlTypes.KEYBOARD:
		var events: Array[InputEvent] = InputMap.action_get_events(action_name)
		InputMap.action_erase_events(action_name)

		events[0].keycode = _input_modal.get_input().keycode
		for i: InputEvent in events:
			InputMap.action_add_event(action_name, i)
	else:
		InputMap.action_erase_event(
				action_name, InputMap.action_get_events(action_name)[1])
		InputMap.action_add_event(action_name, _input_modal.get_input())

	input_button.text = _input_modal.get_input_name()

	GameManager.save_settings()


func _on_input_modal_closed() -> void:
	_inputs_group.get_pressed_button().button_pressed = false
