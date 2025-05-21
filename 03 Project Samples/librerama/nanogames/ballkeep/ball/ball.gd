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

extends CharacterBody2D


const SPEED_MAX = 345
const SPEED_START_BASE = 0.75
var _speed := Vector2()

var _has_bounced_once := false


func _physics_process(delta: float) -> void:
	var collision: KinematicCollision2D = move_and_collide(_speed * delta)
	if collision == null:
		return

	if not _has_bounced_once:
		_has_bounced_once = true

		_speed /= SPEED_START_BASE

	_speed = _speed.bounce(collision.get_normal())

	($Spark as GPUParticles2D).global_position = collision.get_position()
	($Spark as GPUParticles2D).emitting = true

	($Bounce as AudioStreamPlayer2D).play()


func direct_to(rotation_direction: float) -> void:
	_has_bounced_once = false

	_speed = Vector2(0, SPEED_MAX * SPEED_START_BASE).rotated(
			rotation_direction)
