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

extends Node2D


signal ended(has_won: bool)

const SHUFFLE_MAX = 6
const SHUFFLE_DURATION = 0.5

var _shuffle_current := 0

var _difficulty := 0

var _card_correct: Area2D


func nanogame_prepare(difficulty: int, debug_code: int) -> void:
	_difficulty = difficulty

	var cards: Array[Node] = ($Cards as Node2D).get_children()
	cards.shuffle()

	_card_correct = cards.front()
	_card_correct.make_correct()
	_card_correct.flip_card(false)
	_card_correct.animation_flip_ended.connect(shuffle_cards, CONNECT_ONE_SHOT)

	if debug_code == 1:
		_card_correct.modulate = Color.GREEN


func nanogame_start() -> void:
	_card_correct.flip_card()


func shuffle_cards() -> void:
	var cards: Array[Node] = ($Cards as Node2D).get_children()
	cards.shuffle()

	# Reset all z indexes, as a higher value is set for those that are
	# shuffling to be above others.
	for i: Node in cards:
		i.z_index = 0

	var card_index := 0
	var tween: Tween = create_tween().set_parallel()
	for j: int in _difficulty:
		var card_1 := cards[card_index] as Area2D
		card_1.z_index = 1

		var card_2 := cards[card_index + 1] as Area2D
		card_2.z_index = 1

		tween.tween_property(
				card_1, "position", card_2.position, SHUFFLE_DURATION)
		tween.tween_property(
				card_2, "position", card_1.position, SHUFFLE_DURATION)

		card_index += 2

	tween.finished.connect(_on_tween_finished)

	($Effects as AudioStreamPlayer).play()


func _on_tween_finished() -> void:
	if _shuffle_current == SHUFFLE_MAX:
		for i: Node in ($Cards as Node2D).get_children():
			i.set_selection(true)

		return

	_shuffle_current += 1

	shuffle_cards()


func _on_card_selected(index: int) -> void:
	for i: Node in ($Cards as Node2D).get_children():
		i.set_selection(false)

	if index == _card_correct.get_index():
		var effects := $Effects as AudioStreamPlayer
		effects.stop()
		effects.stream = preload("_assets/victory.wav")
		effects.play()

		ended.emit(true)
	else:
		($Cards as Node2D).get_child(index).animation_flip_ended.connect(
				set.bind("_card_correct", "flip_card"))

		ended.emit(false)
