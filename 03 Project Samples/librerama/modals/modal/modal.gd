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
class_name Modal
extends Window


signal closed
signal ok_pressed

@export var confirmation_mode := false: set = set_confirmation_mode
@export var ok_enabled := true: set = set_ok_enabled
@export var hide_on_ok_pressed := true

static var _modal_stack: Array[Modal] = []

var _control_rect := Rect2()

var _is_sort_queued := false


func _ready() -> void:
	_update_panel()

	if Engine.is_editor_hint():
		set_process_input(false)
	else:
		get_tree().root.size_changed.connect(_on_root_size_changed)

		get_viewport().gui_focus_changed.connect(
				GameManager.pass_focused_control_node)


func _notification(what: int) -> void:
	if not is_inside_tree():
		return

	match what:
		NOTIFICATION_CHILD_ORDER_CHANGED:
			sort_children()
		NOTIFICATION_THEME_CHANGED:
			_update_panel()
		NOTIFICATION_VISIBILITY_CHANGED:
			if Engine.is_editor_hint():
				return

			if visible:
				set_process_input(true)

				_modal_stack.append(self)

				unfocusable = false
				grab_focus()

				# Defer it, so it's called after the children are sorted.
				update_focused_control.call_deferred()

				GameManager.dim = true

				return

			set_process_input(false)

			_modal_stack.erase(self)

			closed.emit()

			if _modal_stack.is_empty():
				GameManager.dim = false
			else:
				_modal_stack.back().unfocusable = false
				_modal_stack.back().grab_focus()
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			if Engine.is_editor_hint() or _modal_stack.is_empty():
				return

			if _modal_stack.back() == self:
				# Grab the focus back if this `Modal` is the last one in the
				# stack, unless it's just a `Popup`.
				var subwindows: Array[Window] =\
						get_tree().root.get_embedded_subwindows()
				if not subwindows.is_empty() and\
						subwindows.back() is not Popup:
					grab_focus.call_deferred()
			else:
				unfocusable = true


func _input(event: InputEvent) -> void:
	if not has_focus():
		return

	# Allow to focus to/away from the "Cancel" and "Close/OK" buttons. Since
	# the neighbor focus system ignores simbling nodes when in a non-`Control`
	# parent, some workarounds are necessary.
	if event.is_action_pressed("ui_down"):
		set_input_as_handled()

		var focused: Control = gui_get_focus_owner()
		if focused != null:
			if focused == (%Cancel as Button) or\
					focused == (%CloseOK as Button):
				return

			var next_focus: Control =\
					focused.find_valid_focus_neighbor(SIDE_BOTTOM)
			if next_focus != null:
				next_focus.grab_focus()
				return

		if confirmation_mode:
			(%Cancel as Button).grab_focus()
		else:
			(%CloseOK as Button).grab_focus()
	elif event.is_action_pressed("ui_up"):
		var focused: Control = gui_get_focus_owner()
		if focused != (%Cancel as Button) and focused != (%CloseOK as Button):
			return

		set_input_as_handled()

		var internal_limit: int = ($Buttons as HBoxContainer).get_index()
		for i: int in range(get_child_count() - 1, internal_limit, -1):
			var node: Node = get_child(i)
			if node is not Control:
				continue

			var control := node as Control
			if control.top_level and not control.is_visible_in_tree():
				continue

			if control.focus_mode == Control.FOCUS_ALL:
				control.grab_focus()
				break

			control = control.find_prev_valid_focus()
			if control != null:
				control.grab_focus()
				break
	elif event.is_action_pressed("menu_back"):
		hide()


func update_focused_control() -> void:
	if has_method("override_focused_control") and\
			call("override_focused_control"):
		return

	for i: int in range(($Buttons as HBoxContainer).get_index() + 1,
			get_child_count()):
		var node: Node = get_child(i)
		if node is not Control:
			continue

		var control := node as Control
		if control.top_level or not control.is_visible_in_tree():
			continue

		if control.focus_mode == Control.FOCUS_ALL:
			control.grab_focus()
			return

		control = control.find_next_valid_focus()
		if control != null:
			control.grab_focus()
			return

	give_close_focus()


func sort_children() -> void:
	if not _is_sort_queued:
		_is_sort_queued = true

		_sort_children.call_deferred()


func give_close_focus() -> void:
	if not is_inside_tree():
		return
	if not is_node_ready():
		await ready

	if confirmation_mode:
		(%Cancel as Button).grab_focus()
	else:
		(%CloseOK as Button).grab_focus()


func set_confirmation_mode(is_enabled: bool) -> void:
	confirmation_mode = is_enabled

	(%Cancel as Button).visible = is_enabled
	($Buttons/Space as Control).visible = is_enabled

	(%CloseOK as Button).text = tr("Close") if not is_enabled else tr("OK")
	(%CloseOK as Button).disabled =\
			not ok_enabled if confirmation_mode else false


func set_ok_enabled(is_enabled: bool) -> void:
	ok_enabled = is_enabled

	if confirmation_mode:
		(%CloseOK as Button).disabled = not is_enabled


func _update_panel() -> void:
	var stylebox: StyleBox = get_theme_stylebox("panel", "Modal")
	var buttons := $Buttons as HBoxContainer

	var control_position := Vector2(
			stylebox.get_margin(SIDE_LEFT), stylebox.get_margin(SIDE_TOP))
	var control_size: Vector2 = size
	control_size.x -=\
			stylebox.get_margin(SIDE_LEFT) + stylebox.get_margin(SIDE_RIGHT)
	control_size.y -= stylebox.get_margin(SIDE_TOP) + stylebox.get_margin(
			SIDE_BOTTOM) * 2 + buttons.get_combined_minimum_size().y

	var panel := $Panel as Panel
	panel.position = Vector2.ZERO
	panel.size = size

	if stylebox is StyleBoxFlat:
		var shadow_size: int = (stylebox as StyleBoxFlat).shadow_size
		# Shrink the panel and contents to accomodade the panel's shadow.
		if shadow_size != 0:
			var shadow_rect := Rect2(Vector2(shadow_size, shadow_size),
					Vector2(shadow_size, shadow_size))
			var shadow_offset: Vector2 =\
					(stylebox as StyleBoxFlat).shadow_offset
			shadow_rect.position.x -= maxf(0, shadow_offset.x)
			shadow_rect.position.y -= maxf(0, shadow_offset.y)
			shadow_rect.size.x += maxf(0, shadow_offset.x)
			shadow_rect.size.y += maxf(0, shadow_offset.y)

			panel.position += shadow_rect.position
			panel.size -= shadow_rect.position + shadow_rect.size
			control_position += shadow_rect.position
			control_size -= shadow_rect.position + shadow_rect.size

	buttons.position = control_position
	buttons.position.y += control_size.y + stylebox.get_margin(SIDE_BOTTOM)
	buttons.size.x = control_size.x

	_control_rect = Rect2(control_position, control_size)
	sort_children()


func _sort_children() -> void:
	var children: Array[Node] = get_children()
	children.erase($Panel as Panel)
	children.erase($Buttons as HBoxContainer)

	if has_method("_sort_children_custom"):
		call("_sort_children_custom", children, _control_rect)
	else:
		for i: Node in children:
			if i is Control and not i.top_level:
				i.position = _control_rect.position
				i.size = _control_rect.size

	_is_sort_queued = false


func _on_close_ok_pressed() -> void:
	if confirmation_mode:
		ok_pressed.emit()

		if not hide_on_ok_pressed:
			return

	hide()


func _on_root_size_changed() -> void:
	if visible:
		# Keep the modal centered on the screen.
		position =\
				(get_tree().root.get_visible_rect().size - Vector2(size)) / 2
