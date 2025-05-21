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

extends Area2D


signal traveled

const TRAVEL_DISTANCE = 340


func travel(travel_rotation: float) -> void:
	var tween: Tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "position", position + Vector2.DOWN.rotated(
			travel_rotation) * TRAVEL_DISTANCE, ($AnimationPlayer as
					AnimationPlayer).get_animation("travel").length)

	($Sprite2D as Sprite2D).rotation = travel_rotation

	# Randomly flip the sprite and particles to add variation.
	if randi() % 2 == 0:
		($Sprite2D as Sprite2D).flip_h = true
		($Sprite2D/Trail as GPUParticles2D).scale.x = -1

	($AnimationPlayer as AnimationPlayer).play("travel")


func _on_animation_player_animation_finished() -> void:
	traveled.emit()

	queue_free()
