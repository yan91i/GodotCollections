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

const HIT_OBJECTIVE = 6

var _hit_count := 0

var _difficulty := 0


func nanogame_prepare(difficulty: int, _debug_code: int) -> void:
	_difficulty = difficulty


func nanogame_start() -> void:
	_renew_targets()

	($RenewTargets as Timer).start()


func _renew_targets() -> void:
	var index := 0
	var target_sample := $ShelfTop/Target as Node2D

	var targets_top: Array[Node] = ($ShelfTop as TextureRect).get_children()
	targets_top.shuffle()
	while true:
		if index < 2:
			targets_top.pop_front().renew_target(target_sample.Types.GOOD)

		elif _difficulty == 1:
			break
		elif index < 3:
			targets_top.pop_front().renew_target(target_sample.Types.BAD)

			break

		index += 1

	index = 0

	var targets_bottom: Array[Node] =\
			($ShelfBottom as TextureRect).get_children()
	targets_bottom.shuffle()
	while true:
		if index < 2:
			targets_bottom.pop_front().renew_target(target_sample.Types.GOOD)

		elif _difficulty == 1:
			break
		elif index < 3:
			targets_bottom.pop_front().renew_target(target_sample.Types.BAD)

			break

		index += 1

	if _difficulty < 3:
		for i: Node in targets_top + targets_bottom:
			i.renew_target(target_sample.Types.NONE)
	else:
		for i: Node in targets_top + targets_bottom:
			i.renew_target(target_sample.Types.UGLY)

	($Effects as AudioStreamPlayer).play()


func _on_target_hit(type: int) -> void:
	var target_sample := $ShelfTop/Target as Node2D
	match type:
		target_sample.Types.GOOD:
			_hit_count += 1

			if _hit_count == HIT_OBJECTIVE:
				($RenewTargets as Timer).stop()

				($Effects as AudioStreamPlayer).stream =\
						preload("_assets/bell.wav")
				($Effects as AudioStreamPlayer).play()

				($AnimationPlayer as AnimationPlayer).play("blink_lights")

				ended.emit(true)
		target_sample.Types.BAD:
			if _hit_count > 0:
				_hit_count -= 1
		target_sample.Types.UGLY:
			_hit_count = 0

	($Score/Lights as TextureRect).size.x =\
			($Score as TextureRect).size.x / HIT_OBJECTIVE * _hit_count
