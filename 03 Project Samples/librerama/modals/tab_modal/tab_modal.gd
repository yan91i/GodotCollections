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
class_name TabModal
extends Modal


var current_tab := 0: set = set_current_tab

@onready var _tab_bar := $TabBar as TabBar


func _ready() -> void:
	super()

	child_exiting_tree.connect(_on_child_exiting_tree)


func _input(event: InputEvent) -> void:
	super(event)

	var tab_direction := 0
	if event.is_action_pressed(&"menu_page_previous"):
		tab_direction -= 1
	elif event.is_action_pressed(&"menu_page_next"):
		tab_direction += 1

	if tab_direction != 0:
		_tab_bar.current_tab = wrapi(
				_tab_bar.current_tab + tab_direction, 0, _tab_bar.tab_count)


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = [
		{
			"name": "current_tab",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0," + str(maxi(_tab_bar.tab_count - 1, 0)
					if _tab_bar != null else 0)
		}
	]

	return properties


func set_current_tab(index: int) -> void:
	if current_tab == index:
		return

	current_tab = index

	sort_children()

	if not Engine.is_editor_hint():
		# Defer it, so it's called after the children are sorted.
		update_focused_control.call_deferred()


func set_tab_title(index: int, tab_title: String) -> void:
	# Avoid modifications when opened in the editor.
	if is_part_of_edited_scene():
		return

	if _tab_bar.tab_count == 0 or index < 0 or index >= _tab_bar.tab_count:
		push_error('Invalid tab index "' + str(index) +
				'" to be renamed in `TabModal`.')

		return

	_tab_bar.set_tab_title(index, tab_title)

	# Wait for the children to be settled first, as this method will be called
	# mostly when the modal just finished being ready.
	await get_tree().process_frame
	var child: Control = _tab_bar.get_tab_metadata(index)

	if child.name == tab_title:
		if child.has_meta(&"tab_title"):
			child.remove_meta(&"tab_title")
	else:
		child.set_meta(&"tab_title", tab_title)


func _sort_children_custom(children: Array[Node], control_rect: Rect2) -> void:
	if _tab_bar == null:
		return

	var stylebox: StyleBox = get_theme_stylebox("panel", "Modal")
	_tab_bar.position = control_rect.position - Vector2(
			stylebox.get_margin(SIDE_TOP), stylebox.get_margin(SIDE_LEFT))
	_tab_bar.size.x = control_rect.size.x + stylebox.get_margin(SIDE_LEFT) +\
			stylebox.get_margin(SIDE_RIGHT)

	_tab_bar.set_block_signals(true)
	_tab_bar.clear_tabs()

	children.erase(_tab_bar)
	# Add tabs first, so the height of the `TabBar` can be calculated.
	for i: Node in children:
		if i is Control and not i.top_level:
			i.hide()

			_tab_bar.add_tab(i.name if not i.has_meta(&"tab_title")
					else i.get_meta(&"tab_title"))
			_tab_bar.set_tab_metadata(_tab_bar.tab_count - 1, i)

	if current_tab > 0 and current_tab >= _tab_bar.tab_count:
		current_tab = maxi(_tab_bar.tab_count - 1, 0)
	elif _tab_bar.tab_count > 0:
		_tab_bar.current_tab = current_tab

	_tab_bar.set_block_signals(false)

	if not children.is_empty():
		control_rect.position.y += _tab_bar.size.y
		control_rect.size.y -= _tab_bar.size.y

		var tab_index: int = _tab_bar.get_index() + current_tab + 1
		for i: Node in children:
			if i is not Control or i.top_level:
				continue

			i.position = control_rect.position
			i.size = control_rect.size

			if i.get_index() == tab_index:
				i.show()


func _on_child_exiting_tree(node: Node) -> void:
	if node.has_meta(&"tab_title"):
		node.remove_meta(&"tab_title")


func _on_tab_bar_background_draw() -> void:
	($TabBar/TabBarBackground as Control).draw_style_box(
			get_theme_stylebox("tabbar_background", "TabContainer"),
			Rect2(Vector2.ZERO, _tab_bar.size))
