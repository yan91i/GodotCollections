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

var _difficulty := 0


func nanogame_prepare(difficulty: int, _debug_code: int) -> void:
	_difficulty = difficulty

	match difficulty:
		2:
			($Paddle as StaticBody2D).enable_shorter_mode()
		3:
			($Paddle as StaticBody2D).disable_bottom()
			($Paddle as StaticBody2D).enable_shorter_mode()


func nanogame_start() -> void:
	match _difficulty:
		1, 2:
			($Ball as CharacterBody2D).direct_to(randf_range(0, TAU))
		3:
			($Ball as CharacterBody2D).direct_to(randf_range(PI / 2, PI * 1.5))


func _on_stay_body_exited() -> void:
	# Avoid error when stopping mid-game.
	if not ($Alarm as AudioStreamPlayer).is_inside_tree():
		return

	# Avoid it spinning wildly if the player is still moving them.
	($Paddle as StaticBody2D).set_physics_process(false)

	($Alarm as AudioStreamPlayer).play()
	($AnimationPlayer as AnimationPlayer).play("alarm")

	ended.emit(false)
