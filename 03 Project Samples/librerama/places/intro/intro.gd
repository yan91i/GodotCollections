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


var _warnings: Array[String] = []
var _warning_index := 0


func _ready() -> void:
	GameManager.fade_out()

	_update_warnings()

	($Contents/OK as Button).grab_focus()

	GameManager.control_type_changed.connect(
			_on_GameManager_control_type_changed)
	_on_GameManager_control_type_changed()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_warnings()


func _update_warnings() -> void:
	_warnings.clear()

	var text: String = tr("[center][b]THIS IS A WORK IN PROGRESS![/b]" +
			"[/center]\n\nIt's unfinished, has a very small catalog of " +
			"nanogames, and it's rough around the edges. Please take this " +
			"into consideration before judging it.\n\n...\nYou are going to " +
			"ignore everything I just wrote, aren’t you?")
	_warnings.append(text)

	($Contents/Warning as RichTextLabel).text = text

	if not OS.is_userfs_persistent():
		text = tr("[center][b]Can't Access User Data Directory![/b][/center]" +
				"\n\nThe user data directory is non-persistent, this means " +
				"that [b]saving data will not be possible[/b].")

		if OS.has_feature("web"):
			text += "\n\n" + tr("Make sure that you have third-party " +
					"cookies enabled and that you're not in privacy mode.")

		_warnings.append(text)

	($Contents/Warning as RichTextLabel).text = _warnings[_warning_index]


func _on_ok_pressed() -> void:
	if _warning_index == _warnings.size() - 1:
		GameManager.switch_main_scene("res://places/lobby/lobby.tscn")

		return

	($Contents/Warning as RichTextLabel).text = _warnings[_warning_index]
	_warning_index += 1


func _on_GameManager_control_type_changed() -> void:
	if GameManager.is_using_joypad():
		var focus_joypad: StyleBox =\
				theme.get_stylebox("focus_joypad", "Focus")
		theme.set_stylebox("focus", "Button", focus_joypad)
		theme.set_stylebox("focus", "RichTextLabel", focus_joypad)
	else:
		var style_empty := StyleBoxEmpty.new()

		if not OS.has_feature("mobile"):
			theme.set_stylebox(
					"focus", "Button", theme.get_stylebox("focus", "Focus"))
		else:
			theme.set_stylebox("focus", "Button", style_empty)

		theme.set_stylebox("focus", "RichTextLabel", style_empty)
