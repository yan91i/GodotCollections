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


var _purchase_cost := 0
var _purchase_callback: Callable


func _ready() -> void:
	set_process_input(false)

	($VBoxContainer/TopBar/Space as Control).custom_minimum_size.x =\
			($VBoxContainer/TopBar/Back as Button).get_minimum_size().x

	($VBoxContainer/TopBar/Space/Tickets/Quantity as Label).text =\
			str(ArcadeManager.tickets)

	# TODO: Uncomment once the feature is implemented.
#	var nanogames_owned: int =\
#			ArcadeManager.get_owned_official_nanogames().size()

#	if nanogames_owned < ArcadeManager.PRIZES_UNLOCK_NANOGAME_QUANTITY:
	if true:
		($VBoxContainer/Shadow/TabContainer as TabContainer).set_tab_disabled(
				1, true)
		($VBoxContainer/Shadow/TabContainer as TabContainer).set_tab_title(
				1, tr("Coming Soon"))

	# Same as above.
#	if nanogames_owned < ArcadeManager.THEMES_UNLOCK_NANOGAME_QUANTITY:
	if true:
		($VBoxContainer/Shadow/TabContainer as TabContainer).set_tab_disabled(
				2, true)
		($VBoxContainer/Shadow/TabContainer as TabContainer).set_tab_title(
				2, tr("Coming Soon"))


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_process_input(visible)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back"):
		hide()


func _on_purchase_requested(
		item_name: String, cost: int, callback: Callable) -> void:
	_purchase_cost = cost
	_purchase_callback = callback

	($ConfirmPurchase/RichTextLabel as RichTextLabel).text = tr(
			"[center][b]Confirm Purchase[/b][/center]\n\nDo you want to buy " +
			'[b]"%s"[/b] for the price of [b]%d[/b] tickets? This will ' +
			"leave you with [b]%s[/b] tickets to spare.") % [item_name,
					_purchase_cost, ArcadeManager.tickets - _purchase_cost]

	($ConfirmPurchase as Modal).popup_centered()


func _on_confirm_purchase_ok_pressed() -> void:
	ArcadeManager.tickets -= _purchase_cost
	($VBoxContainer/TopBar/Space/Tickets/Quantity as Label).text =\
			str(ArcadeManager.tickets)

	_purchase_callback.call()

	ArcadeManager.save_data()

	($BuyNoise as AudioStreamPlayer).play()
	($AnimationPlayer as AnimationPlayer).play("tickets_spent")
