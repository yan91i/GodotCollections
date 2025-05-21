#=============================================================================#
# Librerama                                                                   #
# Copyright (c) 2020-present Michael Alexsander.                              #
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
#=============================================================================#

@tool
extends Modal


@warning_ignore("unused_signal")
signal nanogame_selected(nanogame: Nanogame)

const LIST_QUANTITY = 4

var _nanogames: Array[Nanogame] = []
var _nanogames_filtered: Array[Nanogame] = []

var _page_current := 0

var _is_updating_nanogame_buttons := false


func _notification(what: int) -> void:
	if Engine.is_editor_hint():
		return

	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			set_process_input(visible)
		NOTIFICATION_TRANSLATION_CHANGED:
			_sort_nanogames()


func _input(event: InputEvent) -> void:
	super(event)

	if event.is_action_pressed(&"menu_search"):
		# Delay focus grab to avoid entering the typed key into the search box.
		await get_tree().process_frame
		(%Search as LineEdit).grab_focus()
	elif event.is_action_pressed(&"menu_page_first"):
		# Program the shortcut manually, as the `shortcut` property isn't
		# working for this.
		_on_first_pressed()
	elif event.is_action_pressed(&"menu_page_last"):
		_on_last_pressed() # Same as above.


func set_nanogames(nanogames: Array[Nanogame]) -> void:
	_nanogames = nanogames
	_sort_nanogames()


func remove_nanogame(nanogame: Nanogame) -> void:
	if not _nanogames.has(nanogame):
		push_error('The nanogame "' + nanogame.get_nanogame_name() +
				'" is not present at the list of specific nanogames to buy.')

		return

	_nanogames.erase(nanogame)
	_nanogames_filtered.erase(nanogame)
	_update_nanogame_list()


func override_focused_control() -> bool:
	if GameManager.get_control_type() != GameManager.ControlTypes.KEYBOARD and\
			(%NanogameList as VBoxContainer).get_child_count() > 0:
		((%NanogameList as VBoxContainer).get_child(0) as Button).grab_focus()

		return true

	return false


func _sort_nanogames() -> void:
	var nanogames_sorted: Array[Nanogame] = []

	for i: Nanogame in _nanogames:
		var nanogame: Nanogame = i
		var nanogame_name: String = tr(nanogame.get_nanogame_name()).to_lower()
		var is_inserted := false

		for j: int in nanogames_sorted.size():
			if nanogame_name <\
					tr(nanogames_sorted[j].get_nanogame_name()).to_lower():
				nanogames_sorted.insert(j, nanogame)
				is_inserted = true

				break

		if not is_inserted:
			nanogames_sorted.append(nanogame)

	_nanogames = nanogames_sorted

	_update_filtered_nanogames()


func _update_filtered_nanogames() -> void:
	_nanogames_filtered = _nanogames.duplicate()

	var has_nanogames := not _nanogames_filtered.is_empty()
	if has_nanogames:
		var search_text: String = (%Search as LineEdit).text.to_lower()
		if not search_text.is_empty():
			var nanogame_index := 0
			while true:
				if _nanogames_filtered[nanogame_index].get_nanogame_name(
						true).to_lower().find(search_text) == -1:
					_nanogames_filtered.remove_at(nanogame_index)
				else:
					nanogame_index += 1

				if nanogame_index > _nanogames_filtered.size() - 1:
					break

	# Defer it, to avoid wrong button handling when typing too fast.
	_update_nanogame_list.call_deferred()


func _update_nanogame_list() -> void:
	# Avoid visual glitches when updating at the same frame.
	if _is_updating_nanogame_buttons:
		return

	var nanogame_list := %NanogameList as VBoxContainer
	var had_focus := false

	for i: Node in nanogame_list.get_children():
		if i.has_focus():
			had_focus = true

		i.queue_free()

	_is_updating_nanogame_buttons = true

	# Wait for the buttons to be freed.
	await get_tree().process_frame

	_is_updating_nanogame_buttons = false

	var page_max :=\
			int(ceili(_nanogames_filtered.size() / float(LIST_QUANTITY)))
	if _page_current == -1 or _page_current > page_max - 1:
		_page_current = page_max
		if page_max > 0:
			_page_current -= 1

	($Contents/PageButtons/First as Button).disabled = _page_current == 0
	($Contents/PageButtons/Previous as Button).disabled = _page_current == 0
	($Contents/PageButtons/Next as Button).disabled =\
			_page_current >= page_max - 1
	($Contents/PageButtons/Last as Button).disabled =\
			_page_current >= page_max - 1
	($Contents/PageButtons/Pages as Label).text = str(_page_current + 1
			if page_max > 0 else _page_current) + " / " + str(page_max)

	if _nanogames_filtered.is_empty():
		($Contents/Panel/EmptyMessage as Label).show()

		if had_focus:
			update_focused_control()

		return

	($Contents/Panel/EmptyMessage as Label).hide()

	var nanogame_index: int = _page_current * LIST_QUANTITY
	var nanogame_index_max := int(mini(_nanogames_filtered.size(),
			(_page_current + 1) * LIST_QUANTITY)) - 1
	while true:
		var new_button := Button.new()
		var nanogame: Nanogame = _nanogames_filtered[nanogame_index]

		new_button.icon = nanogame.get_icon()
		new_button.expand_icon = true
		new_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		nanogame_list.add_child(new_button)

		# Use a `Label` node instead of the button's own text so the name is
		# fully centered.
		var label := Label.new()
		label.text = nanogame.get_nanogame_name(true)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		new_button.add_child(label)

		new_button.pressed.connect(
				emit_signal.bind("nanogame_selected", nanogame))

		if nanogame_index == nanogame_index_max:
			break

		nanogame_index += 1

	# Add spacers to keep the buttons at the same size in the list.
	while nanogame_list.get_child_count() < LIST_QUANTITY:
		var space := Control.new()
		space.size_flags_vertical = Control.SIZE_EXPAND_FILL
		nanogame_list.add_child(space)

	if had_focus:
		update_focused_control()


func _on_first_pressed() -> void:
	_page_current = 0

	_update_nanogame_list()


func _on_previous_pressed() -> void:
	_page_current -= 1

	_update_nanogame_list()


func _on_next_pressed() -> void:
	_page_current += 1

	_update_nanogame_list()


func _on_last_pressed() -> void:
	_page_current = -1

	_update_nanogame_list()
