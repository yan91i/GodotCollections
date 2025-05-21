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


signal broke

const HITS_TO_BREAK = 6
@export_range(0, HITS_TO_BREAK - 1) var hit_sways := 0: set = set_hit_sways

var _hit_count := 0
var _sway_states: Array[bool] = []

var _can_be_hit := true


func _ready() -> void:
	for i: int in hit_sways:
		_sway_states.append(true)
	for i: int in HITS_TO_BREAK - hit_sways:
		_sway_states.append(false)
	_sway_states.shuffle()

	# Make sure that the final hit isn't a sway, as it would be ignored.
	if _sway_states.back():
		_sway_states[HITS_TO_BREAK - 1] = false
		_sway_states[_sway_states.find(false)] = true


func hit() -> bool:
	if not _can_be_hit:
		return false

	_hit_count += 1

	($AnimationPlayer as AnimationPlayer).stop()

	if _hit_count < HITS_TO_BREAK:
		if _sway_states[_hit_count - 1]:
			_can_be_hit = false
			($AnimationPlayer as AnimationPlayer).play("flinch_away")
		else:
			($AnimationPlayer as AnimationPlayer).play("flinch")
	else:
		_can_be_hit = false

		($AnimationPlayer as AnimationPlayer).play("break")
		broke.emit()

	return true


func set_hit_sways(sways: int) -> void:
	if sways < 0:
		push_error('Sway value must be above or equal to "0".')
		return
	if sways >= HITS_TO_BREAK:
		push_error('Sway value must be below "%d".' % HITS_TO_BREAK)
		return

	hit_sways = sways


func get_hit_count() -> int:
	return _hit_count


func _on_animation_player_animation_finished(anim_name: String) -> void:
	if anim_name == "flinch_away":
		_can_be_hit = true
