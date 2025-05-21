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

var _enemy_jumps := 0

var _direction_previous := 0

var _is_showing_arrows := false

var _difficulty: int


func nanogame_prepare(difficulty: int, debug_code: int) -> void:
	_difficulty = difficulty

	if difficulty > 1:
		($Enemy as InstancePlaceholder).create_instance(true)
		($Enemy2 as InstancePlaceholder).create_instance(true)

		_is_showing_arrows = true
		($ArrowLeft as Sprite2D).show()
		($ArrowRight as Sprite2D).show()

	if debug_code == 1:
		($Jumper as Area2D).disable_hitbox()


func nanogame_start() -> void:
	($RopeAnimation as AnimationPlayer).play("move")


func _make_enemies_jump() -> void:
	if _difficulty == 1:
		return

	var direction: int
	match _difficulty:
		2:
			# Jump four times towards a random direction (which even number
			# jumps standing still), jump four times back to the center (same
			# rules), repeat.
			if _enemy_jumps % 2 == 0:
				if _enemy_jumps % 8 == 0:
					_direction_previous = 1 if randi() % 2 == 0 else -1
				elif _enemy_jumps % 4 == 0:
					_direction_previous = _direction_previous * -1

				direction = 0
			else:
				direction = _direction_previous
		3:
			# Jump two times towards a random direction, jump two times back to
			# the center, repeat.
			if _enemy_jumps % 2 == 0:
				if _enemy_jumps % 4 == 0:
					direction = 1 if randi() % 2 == 0 else -1
				else:
					direction = _direction_previous * -1

				_direction_previous = direction
			else:
				direction = _direction_previous

	_enemy_jumps += 1

	($Enemy as Area2D).jump(direction)
	($Enemy2 as Area2D).jump(direction)


func _hide_arrows() -> void:
	if _is_showing_arrows:
		_is_showing_arrows = false
		($ArrowsAnimation as AnimationPlayer).play("hide")


func _on_jumper_hit() -> void:
	# Defer it, to avoid error about flushing queries in physical objects.
	($RopeCollision/CollisionShape2D).set_deferred("disabled", true)

	($RopeAnimation as AnimationPlayer).play("pre_idle")
	($RopeAnimation as AnimationPlayer).queue("idle")

	($BoomBoxAnimation as AnimationPlayer).play("stop")

	_hide_arrows()

	ended.emit(false)


func _on_jumper_jumped() -> void:
	if _is_showing_arrows:
		($ArrowsAnimation as AnimationPlayer).stop()
		($ArrowsAnimation as AnimationPlayer).play("animate")
