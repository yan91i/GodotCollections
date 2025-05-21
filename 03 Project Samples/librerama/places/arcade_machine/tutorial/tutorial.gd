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

extends PanelContainer


func _ready() -> void:
	_update_page_buttons()


func _notification(what: int) -> void:
	if what != NOTIFICATION_VISIBILITY_CHANGED:
		return

	if is_visible_in_tree():
		if not ($Contents/PageButtons/Next as Button).disabled:
			($Contents/PageButtons/Next as Button).grab_focus()
		else:
			($Contents/PageButtons/Previous as Button).grab_focus()


func _update_page_buttons() -> void:
	var pages := $Contents/Pages as TabContainer
	($Contents/PageButtons/Previous as Button).disabled =\
			pages.current_tab == 0
	($Contents/PageButtons/Next as Button).disabled =\
			pages.current_tab == pages.get_child_count() - 1


func _on_Previous_pressed() -> void:
	($Contents/Pages as TabContainer).current_tab -= 1

	_update_page_buttons()


func _on_Next_pressed() -> void:
	($Contents/Pages as TabContainer).current_tab += 1

	_update_page_buttons()
