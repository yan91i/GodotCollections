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


signal punched
signal punch_missed

var _can_punch := true

var _is_waiting_hit_status := false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("nanogame_action") or not _can_punch:
		return

	_can_punch = false

	var anim_player := $AnimationPlayer as AnimationPlayer
	anim_player.stop()
	anim_player.play("punch")


func celebrate() -> void:
	_can_punch = false

	_is_waiting_hit_status = false

	($AnimationPlayer as AnimationPlayer).play("win")


func set_punch_hit(has_hit: bool) -> void:
	if not _is_waiting_hit_status:
		return

	_is_waiting_hit_status = false

	if has_hit:
		_can_punch = true

		($AnimationPlayer as AnimationPlayer).queue("idle")
	else:
		($Effects as AudioStreamPlayer).play()
		($AnimationPlayer as AnimationPlayer).play("punch_fail")

		punch_missed.emit()


func _punch() -> void:
	_can_punch = false

	_is_waiting_hit_status = true

	punched.emit()


func _on_AnimationPlayer_finished(anim_name: String) -> void:
	if anim_name == "punch_fail":
		_can_punch = true

		($AnimationPlayer as AnimationPlayer).play("idle")
