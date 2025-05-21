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


var _nanogame_types: Array[Array] = []


func _ready() -> void:
	super()

	if Engine.is_editor_hint():
		return

	for i: int in Nanogame.Inputs.size():
		_nanogame_types.append([])
		for j: int in Nanogame.Timers.size():
			_nanogame_types[i].append(0)


func set_type_quantity(
		input: Nanogame.Inputs, timer: Nanogame.Timers, quantity: int) -> void:
	if input < 0 or input >= Nanogame.Inputs.size():
		push_error('Invalid input type of value "' + str(input) +
				'". Value must be between "0" and "' +
				str(Nanogame.Inputs.size() - 1) + '".')

		return
	if timer < 0 or timer >= Nanogame.Inputs.size():
		push_error('Invalid timer type of value "' + str(timer) +
				'". Value must be between "0" and "' +
				str(Nanogame.Timers.size() - 1) + '".')

		return
	if quantity < 0:
		push_error('Invalid quantity for types of value "' + str(quantity) +
				'", Value must be above or equal to "0"')

		return

	_nanogame_types[input][timer] = quantity
	_update_all_items()


func decrease_from_type(
		input: Nanogame.Inputs, timer: Nanogame.Timers) -> void:
	if input < 0 or input >= Nanogame.Inputs.size():
		push_error('Invalid input type of value "' + str(input) +
				'". Value must be between "0" and "' +
				str(Nanogame.Inputs.size() - 1) + '".')

		return
	if timer < 0 or timer >= Nanogame.Inputs.size():
		push_error('Invalid timer type of value "' + str(timer) +
				'". Value must be between "0" and "' +
				str(Nanogame.Timers.size() - 1) + '".')

		return
	if _nanogame_types[input][timer] - 1 < 0:
		push_error('Quantity for input "' + str(input) + '" and timer "' +
				str(timer) + '" types is already empty.')

		return

	_nanogame_types[input][timer] -= 1
	_update_all_items()


func get_input() -> int:
	return (%Inputs as OptionButton).selected


func get_timer() -> int:
	return ($VBoxContainer/Timers as OptionButton).selected


func _update_all_items() -> void:
	var inputs := %Inputs as OptionButton
	for i: int in _nanogame_types.size():
		var is_empty := true
		for j: int in _nanogame_types[i]:
			if j > 0:
				is_empty = false

				break

		inputs.set_item_disabled(i, is_empty)

	_update_timer_items()


func _update_timer_items() -> void:
	var nanogame_type: Array =\
			_nanogame_types[(%Inputs as OptionButton).selected]
	var timers := $VBoxContainer/Timers as OptionButton
	var should_change_selected: bool = nanogame_type[timers.selected] == 0
	for i: int in nanogame_type.size():
		var is_empty: bool = nanogame_type[i] == 0
		timers.set_item_disabled(i, is_empty)

		if should_change_selected and not is_empty:
			timers.select(i)
