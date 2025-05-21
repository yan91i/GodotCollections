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


func show_segment(is_skipping_animation:=false) -> void:
	if is_skipping_animation:
		($Sprite2D as Sprite2D).scale = Vector2(1, 1)
		($CollisionShape2D as CollisionShape2D).disabled = false

		return

	($AnimationPlayer as AnimationPlayer).play("show")


func bloat() -> void:
	($AnimationPlayer as AnimationPlayer).play("bloat")


func get_hitbox_radius() -> float:
	return (($CollisionShape2D as CollisionShape2D).shape as CircleShape2D).\
			radius
