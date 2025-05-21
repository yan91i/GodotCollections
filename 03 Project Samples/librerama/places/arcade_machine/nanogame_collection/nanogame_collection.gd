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


signal start_status_updated(is_disabled: bool)

signal practice_mode_started(nanogame: Nanogame, difficulty: int)

const NANOGAME_BUTTON_WIDTH = 480

const NanogameButton = preload("nanogame_button/nanogame_button.tscn")

var _is_start_ready := false
var _start_quantity := 1

var _page_current := 0

var _is_updating_nanogame_buttons := false

var _nanogames_filtered: Array[Nanogame] = []
var _nanogames_selected: Array[Nanogame] = []


func _ready() -> void:
	set_process_input(false)

	### Filter Setup ###

	var filter_popup: PopupMenu = (%Filter as MenuButton).get_popup()
	filter_popup.hide_on_checkable_item_selection = false

	var inputs_size: int = Nanogame.Inputs.size()

	filter_popup.add_separator(tr("Inputs"))
	for i: int in inputs_size:
		filter_popup.add_check_item(Nanogame.get_input_name(i))
		filter_popup.set_item_checked(i + 1, true)

	filter_popup.add_separator(tr("Timers"))
	for i: int in Nanogame.Timers.size():
		filter_popup.add_check_item(Nanogame.get_timer_name(i))
		filter_popup.set_item_checked(i + inputs_size + 2, true)

	filter_popup.index_pressed.connect(_on_filter_index_pressed)


	_nanogames_filtered = ArcadeManager.get_owned_official_nanogames()\
			if not ArcadeManager.community_mode else\
			ArcadeManager.get_community_nanogames()
	update_filtered_nanogames()

	ArcadeManager.community_mode_changed.connect(
			_on_arcade_manager_community_mode_changed)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			set_process_input(visible)

			if not is_visible_in_tree():
				return

			_update_column_quantity()
			_focus_correct_ui_element()

			start_status_updated.emit(_nanogames_selected.is_empty() or
					_nanogames_selected.size() < mini(
							ArcadeManager.get_owned_official_nanogames().size()
							if not ArcadeManager.community_mode else
							ArcadeManager.get_community_nanogames().size(),
							_start_quantity))
		NOTIFICATION_TRANSLATION_CHANGED:
			if is_node_ready():
				update_filtered_nanogames()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_search"):
		# Delay focus grab to avoid entering the typed key into the search box.
		await get_tree().process_frame
		($HBoxContainer/NanogameSelector/VBoxContainer/TopBar/Search as
				LineEdit).grab_focus()


func clear_selected_highlight() -> void:
	var has_highlight := false
	for i: Nanogame in _nanogames_selected:
		if i.has_meta("highlight"):
			i.remove_meta("highlight")

			has_highlight = true

	if has_highlight:
		ArcadeManager.sort_owned_official_nanogames()
		update_filtered_nanogames()


func update_filtered_nanogames() -> void:
	_nanogames_filtered = ArcadeManager.get_owned_official_nanogames()\
			if not ArcadeManager.community_mode else\
			ArcadeManager.get_community_nanogames()

	var has_nanogames := not _nanogames_filtered.is_empty()
	if has_nanogames:
		var are_inputs_all_checked := true
		for i: int in Nanogame.Inputs.size():
			if not _is_filter_checked(Nanogame.Inputs, i):
				are_inputs_all_checked = false

		var are_timers_all_checked := true
		for i: int in Nanogame.Timers.size():
			if not _is_filter_checked(Nanogame.Timers, i):
				are_timers_all_checked = false

		var search_list: PackedStringArray =\
				($HBoxContainer/NanogameSelector/VBoxContainer/TopBar/Search\
						as LineEdit).text.to_lower().split(",", false)
		if not search_list.is_empty() or not are_inputs_all_checked or\
				not are_timers_all_checked:
			var nanogame_index := 0
			while true:
				var nanogame: Nanogame = _nanogames_filtered[nanogame_index]
				var match_count := 0
				var negative_unmatch_count := 0
				var is_full_match_obligatory := false

				var empty_entries := 0
				if not search_list.is_empty():
					var name_lower: String =\
							nanogame.get_nanogame_name(true).to_lower()
					var kickoff_lower: String =\
							nanogame.get_kickoff(true).to_lower()
					var tags_lower: String = nanogame.get_tags(
							ArcadeManager.community_mode or TranslationServer.\
							get_locale() != "en_US").to_lower()
					var author_lower: String = nanogame.get_author().to_lower()

					for i: String in search_list:
						var is_filter_negative: bool = i.begins_with("-")
						var is_filter_obligatory: bool = i.begins_with("*")
						if is_filter_negative or is_filter_obligatory:
							i.erase(0, 1)
							if i.is_empty():
								empty_entries += 1

								continue

						# Find if anything matches.
						if name_lower.find(i) != -1 or\
								kickoff_lower.find(i) != -1 or\
								tags_lower.find(i) != -1 or\
								(ArcadeManager.community_mode and\
										author_lower.find(i) != -1):
							if is_filter_negative:
								match_count = 0

								break

							match_count += 1
						elif is_filter_obligatory:
							is_full_match_obligatory = true

							break
						elif is_filter_negative:
							negative_unmatch_count += 1

				var search_list_size_adjusted: int =\
						search_list.size() - empty_entries

				# Allow for the nanogame to be present if the search terms
				# where all negatives and none matched.
				if match_count == 0 and\
						negative_unmatch_count == search_list_size_adjusted:
					match_count = search_list_size_adjusted

				if ((is_full_match_obligatory and
						match_count == search_list_size_adjusted) or
						(not is_full_match_obligatory and
								(search_list_size_adjusted == 0 or
										match_count > 0))) and\
						_is_filter_checked(Nanogame.Inputs,
								nanogame.get_input()) and _is_filter_checked(
										Nanogame.Timers, nanogame.get_timer()):
					nanogame_index += 1
				else:
					_nanogames_filtered.remove_at(nanogame_index)

				if nanogame_index > _nanogames_filtered.size() - 1:
					break

	# Defer it, to avoid wrong button handling when typing too fast.
	_update_nanogame_available_buttons.call_deferred()


	### Empty State ###

	($HBoxContainer/NanogameSelector/VBoxContainer/TopBar/Search as LineEdit).\
			editable = has_nanogames
	(%Filter as MenuButton).disabled = not has_nanogames
	($HBoxContainer/NanogameSelector/VBoxContainer/TopBar/Randomize\
			as Button).disabled = not has_nanogames

	var empty_message := $HBoxContainer/NanogameSelector/VBoxContainer/Panel/\
			EmptyMessage as RichTextLabel
	empty_message.visible = _nanogames_filtered.is_empty()

	if not empty_message.visible:
		return

	empty_message.clear()
	empty_message.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)

	if has_nanogames:
		empty_message.add_text(tr("No nanogames found."))
	else:
		empty_message.add_text(tr("No nanogames available."))
		empty_message.newline()

		if ArcadeManager.community_mode and OS.has_feature("pc"):
			empty_message.append_text(tr(
					'Place them in the "[url=%s]%s[/url]" directory,' +
					"\nthen restart the game.") % [
							ProjectSettings.globalize_path(ArcadeManager.\
									COMMUNITY_NANOGAMES_PATH_USER),
							ArcadeManager.COMMUNITY_NANOGAMES_PATH_USER.\
							get_base_dir().get_file()])

	empty_message.pop()


func set_start_quantity(value: int) -> void:
	if value <= 0:
		push_error('Start quantity for selected nanogames must be above "0".')

		return

	_start_quantity = value

	_update_nanogame_spots()

	if _nanogames_selected.is_empty():
		return

	var nanogames_selected_size: int = _nanogames_selected.size()
	_nanogames_selected.clear()

	_update_start_ready_status()

	var nanogames_available := %NanogamesAvailable as GridContainer
	for i: int in nanogames_available.get_child_count():
		if nanogames_available.get_child(i).pressed:
			nanogames_available.get_child(i).button_pressed = false

			nanogames_selected_size -= 1
			if nanogames_selected_size == 0:
				break

	for i: Node in (%NanogamesActive as VBoxContainer).get_children():
		i.queue_free()


func get_nanogames_selected() -> Array:
	return _nanogames_selected.duplicate()


func _add_nanogame_selected(nanogame: Nanogame) -> void:
	_nanogames_selected.append(nanogame)

	var button := TextureButton.new()
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_normal = nanogame.get_icon() if nanogame.get_icon() != null\
			else preload("res://places/_assets/unknown.svg")
	button.tooltip_text = nanogame.get_nanogame_name(true)\
			if not nanogame.get_nanogame_name(true).is_empty() else\
			tr("[No Name]")

	# Make the button a perfect square.
	button.custom_minimum_size.y = (%NanogamesActive as VBoxContainer).size.x
	(%NanogamesActive as VBoxContainer).add_child(button)

	button.pressed.connect(_on_nanogame_selected_button_pressed.bind(button))

	button.button_down.connect(
			button.set_self_modulate.bind(Color.DARK_RED))

	button.focus_entered.connect(
			button.set_self_modulate.bind(Color.TOMATO))
	button.mouse_entered.connect(
			button.set_self_modulate.bind(Color.TOMATO))

	button.focus_exited.connect(
			button.set_self_modulate.bind(Color.WHITE))
	button.mouse_exited.connect(
			button.set_self_modulate.bind(Color.WHITE))

	_update_nanogame_spots()
	_update_start_ready_status()


func _focus_correct_ui_element() -> void:
	if GameManager.get_control_type() == GameManager.ControlTypes.KEYBOARD:
		($HBoxContainer/NanogameSelector/VBoxContainer/TopBar/Search\
					as LineEdit).grab_focus()
	elif (%NanogamesAvailable as GridContainer).get_child_count() > 0:
		(%NanogamesAvailable as GridContainer).get_child(0).grab_focus()


func _update_nanogame_available_buttons() -> void:
	# Avoid visual glitches when updating at the same frame.
	if _is_updating_nanogame_buttons:
		return

	var had_focus := false

	var nanogames_available := %NanogamesAvailable as GridContainer
	for i: Node in nanogames_available.get_children():
		if i.has_focus():
			had_focus = true

		nanogames_available.remove_child(i)
		i.queue_free()

	_is_updating_nanogame_buttons = true

	_is_updating_nanogame_buttons = false

	var page_quantity: int = nanogames_available.columns * 2
	var page_max := ceili(_nanogames_filtered.size() / float(page_quantity))
	if _page_current == -1 or _page_current > page_max - 1:
		_page_current = page_max
		if page_max > 0:
			_page_current -= 1

	($HBoxContainer/NanogameSelector/VBoxContainer/PageButtons/First\
			as Button).disabled = _page_current == 0
	($HBoxContainer/NanogameSelector/VBoxContainer/PageButtons/Previous\
			as Button).disabled = _page_current == 0
	($HBoxContainer/NanogameSelector/VBoxContainer/PageButtons/Next\
			as Button).disabled = _page_current >= page_max - 1
	($HBoxContainer/NanogameSelector/VBoxContainer/PageButtons/Last\
			as Button).disabled = _page_current >= page_max - 1

	($HBoxContainer/NanogameSelector/VBoxContainer/PageButtons/Pages\
			as Label).text = str(_page_current + 1 if page_max > 0
			else _page_current) + " / " + str(page_max)

	if _nanogames_filtered.is_empty():
		if had_focus:
			_focus_correct_ui_element()

		return

	var nanogame_index: int = _page_current * page_quantity
	var nanogame_index_max := mini(_nanogames_filtered.size(),
			(_page_current + 1) * page_quantity) - 1
	while true:
		var new_button := NanogameButton.instantiate() as Button
		var nanogame: Nanogame = _nanogames_filtered[nanogame_index]
		new_button.nanogame = nanogame

		if not ArcadeManager.community_mode:
			new_button.author_visible = false

		if nanogame.has_meta("highlight"):
			new_button.highlight = true

		if _nanogames_selected.has(nanogame):
			new_button.button_pressed = true
		elif _nanogames_selected.size() ==\
				mini(_start_quantity, _nanogames_filtered.size()):
			new_button.disabled = true

		nanogames_available.add_child(new_button)

		new_button.toggled.connect(
				_on_nanogame_available_button_toggled.bind(nanogame))
		new_button.about_nanogame_pressed.connect(($AboutNanogameModal
				as TabModal).popup_nanogame.bind(nanogame))

		if nanogame_index == nanogame_index_max:
			break

		nanogame_index += 1

	# Add spacers to keep the buttons aligned in the grid.
	while nanogames_available.get_child_count() <= nanogames_available.columns:
		var space := Control.new()
		space.size_flags_horizontal = SIZE_EXPAND_FILL
		space.size_flags_vertical = SIZE_EXPAND_FILL
		nanogames_available.add_child(space)

	if had_focus:
		_focus_correct_ui_element()


func _update_column_quantity() -> void:
	if not is_visible_in_tree():
		return

	var nanogames_available := %NanogamesAvailable as GridContainer
	var columns_old: int = nanogames_available.columns

	nanogames_available.columns =\
			maxi(1, floori((nanogames_available.size.x - nanogames_available.
					get_theme_constant("h_separation") - get_theme_stylebox(
							"grabber", "VScrollBar").get_minimum_size().x) /
					(NANOGAME_BUTTON_WIDTH + nanogames_available.
							get_theme_constant("h_separation"))))

	if nanogames_available.columns != columns_old:
		_update_nanogame_available_buttons()


func _update_nanogame_spots() -> void:
	var nanogame_spots :=\
			$HBoxContainer/NanogamesSelected/Panel/NanogameSpots as TextureRect
	nanogame_spots.position.y =\
			_nanogames_selected.size() * nanogame_spots.texture.get_height()

	var height: float =\
			(mini(ArcadeManager.get_owned_official_nanogames().size()
					if not ArcadeManager.community_mode else
					ArcadeManager.get_community_nanogames().size(),
					_start_quantity) - _nanogames_selected.size()) *\
			nanogame_spots.texture.get_height()
	if height > 0:
		nanogame_spots.size.y = height
		nanogame_spots.show()
	else:
		nanogame_spots.hide()


func _update_start_ready_status() -> void:
	if _nanogames_selected.size() < mini(
			ArcadeManager.get_owned_official_nanogames().size()
			if not ArcadeManager.community_mode else
			ArcadeManager.get_community_nanogames().size(), _start_quantity):
		if _is_start_ready:
			# Re-enable the nanogame buttons if they were disabled.
			for i: Node in (%NanogamesAvailable as GridContainer).\
					get_children():
				if i is not Button:
					break

				i.disabled = false

			_is_start_ready = false
	else:
		for i: Node in (%NanogamesAvailable as GridContainer).get_children():
			if i is not Button:
				break

			if not i.button_pressed:
				i.disabled = true

		_is_start_ready = true

	if is_visible_in_tree():
		start_status_updated.emit(not _is_start_ready)


func _is_filter_checked(type: Dictionary, index: int) -> bool:
	var filter_popup: PopupMenu = (%Filter as MenuButton).get_popup()
	match type:
		Nanogame.Inputs:
			return filter_popup.is_item_checked(index + 1)
		Nanogame.Timers:
			return filter_popup.is_item_checked(
					index + Nanogame.Inputs.size() + 2)
		_:
			return false


func _on_nanogame_available_button_toggled(
		button_pressed: bool, nanogame: Nanogame) -> void:
	if button_pressed:
		_add_nanogame_selected(nanogame)

		return

	var nanogame_index: int = _nanogames_selected.find(nanogame)
	var selected_button: TextureButton =\
			(%NanogamesActive as VBoxContainer).get_child(nanogame_index)
	(%NanogamesActive as VBoxContainer).remove_child(selected_button)
	selected_button.queue_free()

	_nanogames_selected.remove_at(nanogame_index)

	_update_nanogame_spots()
	_update_start_ready_status()


func _on_nanogame_selected_button_pressed(button: TextureButton) -> void:
	var nanogame_index: int = button.get_index()
	var button_found := false
	for i: Node in (%NanogamesAvailable as GridContainer).get_children():
		if i is not Button:
			break

		if i.nanogame == _nanogames_selected[nanogame_index]:
			button_found = true

			i.button_pressed = false

			break

	if not button_found:
		_nanogames_selected.remove_at(nanogame_index)

		button.get_parent().remove_child(button)
		button.queue_free()

		_update_nanogame_spots()
		_update_start_ready_status()

	if nanogame_index <= _nanogames_selected.size() - 1:
		(%NanogamesActive as VBoxContainer).\
				get_child(nanogame_index).grab_focus()
	elif nanogame_index > 0:
		(%NanogamesActive as VBoxContainer).\
				get_child(nanogame_index - 1).grab_focus()
	else:
		_focus_correct_ui_element()


func _on_search_text_changed(new_text: String) -> void:
	update_filtered_nanogames()

	($HBoxContainer/NanogameSelector/VBoxContainer/TopBar/Search/Help\
			as Button).visible = new_text.is_empty()


func _on_filter_index_pressed(index: int) -> void:
	(%Filter as MenuButton).get_popup().set_item_checked(index,
			not (%Filter as MenuButton).get_popup().is_item_checked(index))

	update_filtered_nanogames()


func _on_randomize_pressed() -> void:
	var nanogames_available_buttons: Array[Node] =\
			(%NanogamesAvailable as GridContainer).get_children()

	# Ramdomize all nanogames if all spots are taken.
	if _nanogames_selected.size() == _start_quantity:
		for i: Node in nanogames_available_buttons:
			if i is not Button:
				break

			i.disabled = false
			i.button_pressed = false

		_nanogames_selected.clear()

		for i: Node in (%NanogamesActive as VBoxContainer).get_children():
			i.queue_free()

	var nanogames_present: Array[Nanogame] = _nanogames_filtered.duplicate()
	nanogames_present.shuffle()

	var spots_remaining: int = _start_quantity - _nanogames_selected.size()
	for i: Nanogame in nanogames_present:
		if _nanogames_selected.has(i):
			continue

		var button_found := false
		for j: Node in nanogames_available_buttons:
			if j is not Button:
				break

			if j.nanogame == i:
				button_found = true

				j.button_pressed = true

				break

		if not button_found:
			_add_nanogame_selected(i)

		spots_remaining -= 1
		if spots_remaining == 0:
			return

	# Add nanogames that didn't match the filtering if not enough that did were
	# available.
	nanogames_present = ArcadeManager.get_owned_official_nanogames()\
			if not ArcadeManager.community_mode else\
			ArcadeManager.get_community_nanogames()
	nanogames_present.shuffle()

	for i: Nanogame in nanogames_present:
		if _nanogames_selected.has(i) or _nanogames_filtered.has(i):
			continue

		_add_nanogame_selected(i)

		spots_remaining -= 1
		if spots_remaining == 0:
			return


func _on_empty_message_meta_clicked(meta: String) -> void:
	OS.shell_open(meta)


func _on_first_pressed() -> void:
	_page_current = 0

	_update_nanogame_available_buttons()


func _on_previous_pressed() -> void:
	_page_current -= 1

	_update_nanogame_available_buttons()


func _on_next_pressed() -> void:
	_page_current += 1

	_update_nanogame_available_buttons()


func _on_last_pressed() -> void:
	_page_current = -1

	_update_nanogame_available_buttons()


func _on_about_nanogame_modal_practice_mode_started(
		nanogame: Nanogame, difficulty: int) -> void:
	practice_mode_started.emit(nanogame, difficulty)


func _on_arcade_manager_community_mode_changed() -> void:
	_nanogames_selected.clear()

	_page_current = 0

	for i: Node in (%NanogamesActive as VBoxContainer).get_children():
		i.queue_free()

	update_filtered_nanogames()
	_update_nanogame_spots()
