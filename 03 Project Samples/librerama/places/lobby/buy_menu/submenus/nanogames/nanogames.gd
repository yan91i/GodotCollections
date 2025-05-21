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


signal purchase_requested(item_name: String, cost: int, callback: Callable)

const COST_RANDOM = 50
const COST_TYPE = COST_RANDOM * 1.5
const COST_SPECIFIC = COST_RANDOM * 2

var _nanogames_available: Array[Nanogame] = []

var _nanogame_in_purchase: Nanogame


func _ready() -> void:
	_update_buttons()
	_update_text()

	_nanogames_available = ArcadeManager.get_official_nanogames()
	_nanogames_available.shuffle()

	var nanogame_types: Array[Array] = []
	for i: int in Nanogame.Inputs.size():
		nanogame_types.append([])
		for j: int in Nanogame.Timers.size():
			nanogame_types[i].append(0)

	# Cache the nanogames available for purchase and set the input/timer count
	# at the start, to avoid doing it every time the player buys one.
	var nanogames_owned: Array[Nanogame] =\
			ArcadeManager.get_owned_official_nanogames()
	var index := 0
	while true:
		var nanogame: Nanogame = _nanogames_available[index]
		if nanogames_owned.has(nanogame):
			_nanogames_available.remove_at(index)
		else:
			nanogame_types[nanogame.get_input()][nanogame.get_timer()] += 1

			index += 1

		if index == _nanogames_available.size():
			break

	var type_modal := $TypeModal as Modal
	for i: int in nanogame_types.size():
		for j: int in nanogame_types[i].size():
			type_modal.set_type_quantity(i, j, nanogame_types[i][j])

	($SpecificModal as Modal).set_nanogames(_nanogames_available.duplicate())

	ArcadeManager.tickets_removed.connect(_on_arcade_manager_tickets_removed)
	_on_arcade_manager_tickets_removed()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if visible and is_node_ready():
				(%BuyRandom as Button).grab_focus()
		NOTIFICATION_TRANSLATION_CHANGED:
			# Defer it, so the result doesn't get wiped out.
			_update_text.call_deferred()


func confirm_purchase() -> void:
	_nanogames_available.erase(_nanogame_in_purchase)

	($TypeModal as Modal).decrease_from_type(
			_nanogame_in_purchase.get_input(),
			_nanogame_in_purchase.get_timer())

	($SpecificModal as Modal).remove_nanogame(_nanogame_in_purchase)

	ArcadeManager.own_official_nanogame(_nanogame_in_purchase)

	_update_buttons()


func _update_buttons() -> void:
	if ArcadeManager.get_owned_official_nanogames().size() <\
			ArcadeManager.get_official_nanogames().size():
		return

	(%BuyRandom as Button).hide()
	($Buttons/BuyType as Button).hide()
	($Buttons/BuySpecific as Button).hide()

	($Buttons/AllNanogamesBought as Label).show()

	($TypeModal as Modal).hide()
	($SpecificModal as Modal).hide()


func _update_text() -> void:
	if ($Buttons/AllNanogamesBought as Label).visible:
		return

	var random_info := $Buttons/BuyRandom/HBoxContainer/Info as RichTextLabel
	random_info.clear()
	random_info.push_bold()
	random_info.add_text(tr("Buy a Random Nanogame"))
	random_info.pop()
	random_info.newline()
	random_info.add_text(tr("For those who aren't picky."))
	random_info.newline()
	random_info.push_paragraph(HORIZONTAL_ALIGNMENT_RIGHT)
	random_info.append_text(tr("Cost: [b]%d[/b]") % COST_RANDOM)

	var type_info := $Buttons/BuyType/HBoxContainer/Info as RichTextLabel
	type_info.clear()
	type_info.push_bold()
	type_info.add_text(tr("Buy a Type of Nanogame"))
	type_info.pop()
	type_info.newline()
	type_info.add_text(tr("Everybody has a type, you know?"))
	type_info.newline()
	type_info.push_paragraph(HORIZONTAL_ALIGNMENT_RIGHT)
	type_info.append_text(tr("Cost: [b]%d[/b]") % COST_TYPE)

	var specific_info :=\
			$Buttons/BuySpecific/HBoxContainer/Info as RichTextLabel
	specific_info.clear()
	specific_info.push_bold()
	specific_info.add_text(tr("Buy a Specific Nanogame"))
	specific_info.pop()
	specific_info.newline()
	specific_info.add_text(tr("But I want THAT one!"))
	specific_info.newline()
	specific_info.push_paragraph(HORIZONTAL_ALIGNMENT_RIGHT)
	specific_info.append_text(tr("Cost: [b]%d[/b]") % COST_SPECIFIC)


func _on_buy_random_pressed() -> void:
	_nanogame_in_purchase = _nanogames_available.front()

	purchase_requested.emit(
			tr("A Random Nanogame"), COST_RANDOM, confirm_purchase)


func _on_type_modal_ok_pressed() -> void:
	var input: int = ($TypeModal as Modal).get_input()
	var timer: int = ($TypeModal as Modal).get_timer()
	for i: Nanogame in _nanogames_available:
		if i.get_input() == input and i.get_timer() == timer:
			_nanogame_in_purchase = i

			break

	purchase_requested.emit(
			tr("A Type of Nanogame"), COST_TYPE, confirm_purchase)


func _on_specific_modal_nanogame_selected(nanogame: Nanogame) -> void:
	_nanogame_in_purchase = nanogame

	purchase_requested.emit(_nanogame_in_purchase.get_nanogame_name(true),
			COST_SPECIFIC, confirm_purchase)


func _on_arcade_manager_tickets_removed() -> void:
	if ArcadeManager.tickets < COST_SPECIFIC:
		($Buttons/BuySpecific as Button).disabled = true

		if ArcadeManager.tickets < COST_TYPE:
			($Buttons/BuyType as Button).disabled = true

			if ArcadeManager.tickets < COST_RANDOM:
				(%BuyRandom as Button).disabled = true
