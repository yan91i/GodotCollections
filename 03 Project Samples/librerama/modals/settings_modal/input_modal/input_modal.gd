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
extends Modal


var _is_waiting_input := false

var _has_joypad := false

var _input_name := ""
var _event: InputEvent


func _notification(what: int) -> void:
	if Engine.is_editor_hint():
		return

	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if visible:
				_is_waiting_input = true

				_has_joypad = GameManager.is_using_joypad()

				_input_name = ""
				_event = null

				_update_text()

				set_ok_enabled(false)
			else:
				_is_waiting_input = false
		NOTIFICATION_TRANSLATION_CHANGED:
			_update_text()


func _input(event: InputEvent) -> void:
	super(event)

	if not _is_waiting_input or not visible:
		return

	if _has_joypad:
		if event is not InputEventJoypadButton and\
				event is not InputEventJoypadMotion:
			return
	elif event is not InputEventKey:
		return

	if event.is_action("pause"):
		_update_text(true)

		return

	gui_release_focus()

	if event is InputEventJoypadMotion:
		if absf(event.axis_value) < NanogamePlayer.JOYSTICK_DEADZONE:
			return

		event.axis_value = -1 if event.axis_value < 0 else 1
	else:
		event.pressed = true

	_is_waiting_input = false

	_event = event

	_update_text()

	set_ok_enabled(true)
	give_close_focus.call_deferred()


func _update_text(is_invalid:=false) -> void:
	var instructions := ""
	if is_invalid:
		instructions = tr("Invalid input, try another.")
	elif _event == null:
		instructions = tr("Press the desired new input in your joypad.")\
				if _has_joypad else\
				tr("Press the desired new input in your keyboard.")
	else:
		instructions = tr("Is this the new desired input?")

	var input_status := ""
	if is_invalid:
		input_status = "[color=#%s]%s[/color]" %\
				[Color.TOMATO.to_html(), tr("[Invalid Input]")]
	elif _event == null:
		input_status = "[color=silver]%s[/color]" % tr("[None Selected]")
	else:
		if GameManager.is_using_joypad():
			input_status = format_joypad_input_text(_event)
		elif _event is InputEventKey:
			input_status = _event.as_text_keycode()

			if input_status == "Space":
				input_status = tr("Space", "Keyboard")

		_input_name = input_status

	($InputStatus as RichTextLabel).text =\
			"[center]%s\n\n[b]%s[/b][/center]" %\
			[tr(instructions), tr(input_status)]


func format_joypad_input_text(event: InputEvent) -> String:
	if event is not InputEventJoypadButton and\
			event is not InputEventJoypadMotion:
		return ""

	var input_text: String = event.as_text()
	input_text = input_text.substr(input_text.find("(") + 1)

	var end: int = input_text.find(",")
	if end == -1:
		end = input_text.find(")")
	input_text = input_text.split(input_text[end])[0]

	return input_text


func get_input() -> InputEvent:
	return _event


func get_input_name() -> String:
	return _input_name
