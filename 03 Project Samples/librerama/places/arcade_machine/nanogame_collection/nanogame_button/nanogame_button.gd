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

extends Button


# Emitted by a signal from the "AboutNanogame" button.
@warning_ignore("unused_signal")
signal about_nanogame_pressed

var nanogame: Nanogame: set = set_nanogame

var author_visible := true: set = set_author_visible

var highlight := false: set = set_highlight

var _is_ignoring_theme_notification := false


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			if highlight and not _is_ignoring_theme_notification:
				_update_styleboxes()
		NOTIFICATION_TRANSLATION_CHANGED:
			set_nanogame(nanogame)


func set_nanogame(new_nanogame: Nanogame) -> void:
	if new_nanogame == null or not new_nanogame.has_data():
		return

	nanogame = new_nanogame

	($Contents/Icon as TextureRect).texture = new_nanogame.get_icon()\
			if new_nanogame.get_icon() != null else\
			preload("res://places/_assets/unknown.svg")

	($Contents/Information/Main/Text/Name as Label).text =\
			new_nanogame.get_nanogame_name(true)\
			if not new_nanogame.get_nanogame_name().is_empty() else\
			tr("[No Name]")
	($Contents/Information/Main/Text/Name as Label).modulate =\
			Color.WHITE if not new_nanogame.get_nanogame_name().is_empty()\
			else Color.SILVER

	($Contents/Information/Main/Text/Kickoff as Label).text = tr('"%s"') %\
			tr(new_nanogame.get_kickoff(true)) if not new_nanogame.\
			get_kickoff().is_empty() else tr("[No Kickoff]")
	($Contents/Information/Main/Text/Kickoff as Label).modulate =\
			Color.WHITE if not new_nanogame.get_kickoff().is_empty()\
			else Color.SILVER

	(%Author as Label).text = (tr("By %s") % new_nanogame.get_author())\
			if not new_nanogame.get_author().is_empty() else tr("[No Author]")
	(%Author as Label).modulate =\
			Color.WHITE if not new_nanogame.get_author().is_empty()\
			else Color.SILVER

	### Input Icon ###

	var input_icon: CompressedTexture2D
	match new_nanogame.get_input():
		Nanogame.Inputs.NAVIGATION:
			input_icon = preload(
					"res://places/_assets/input_types_small/navigation.svg")
		Nanogame.Inputs.ACTION:
			input_icon = preload(
					"res://places/_assets/input_types_small/action.svg")
		Nanogame.Inputs.NAVIGATION_ACTION:
			input_icon = preload("res://places/_assets/input_types_small/" +\
					"navigation_action.svg")
		Nanogame.Inputs.DRAG_DROP:
			input_icon = preload(
					"res://places/_assets/input_types_small/drag_drop.svg")

	($Contents/Information/Extra/Input as TextureRect).texture = input_icon
	($Contents/Information/Extra/Input as TextureRect).tooltip_text =\
			tr("Input: %s") % tr(Nanogame.get_input_name(
					new_nanogame.get_input()))


	### Timer Icons ###

	var timer_icon: CompressedTexture2D
	match new_nanogame.get_timer():
		Nanogame.Timers.OBJECTIVE:
			timer_icon = preload("res://places/_assets/timer_objective.svg")
		Nanogame.Timers.SURVIVAL:
			timer_icon = preload("res://places/_assets/timer_survival.svg")

	($Contents/Information/Extra/Timer as TextureRect).texture = timer_icon
	($Contents/Information/Extra/Timer as TextureRect).tooltip_text =\
			tr("Timer: %s") % tr(Nanogame.get_timer_name(
					new_nanogame.get_timer()))


func set_author_visible(is_author_visible: bool) -> void:
	author_visible = is_author_visible

	(%Author as Label).visible = is_author_visible


func set_highlight(is_highlighted: bool) -> void:
	highlight = is_highlighted
	_update_styleboxes()


func _update_styleboxes() -> void:
	_is_ignoring_theme_notification = true

	add_theme_stylebox_override(
			"normal", get_theme_stylebox("normal", "ButtonHighlight")
			if highlight else null)
	add_theme_stylebox_override(
			"hover", get_theme_stylebox("hover", "ButtonHighlight")
			if highlight else null)
	add_theme_stylebox_override(
			"pressed", get_theme_stylebox("pressed", "ButtonHighlight")
			if highlight else null)
	add_theme_stylebox_override(
			"disabled", get_theme_stylebox("disabled", "ButtonHighlight")
			if highlight else null)

	_is_ignoring_theme_notification = false
