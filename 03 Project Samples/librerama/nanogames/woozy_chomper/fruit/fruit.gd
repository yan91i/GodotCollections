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


func _ready() -> void:
	# Randomly flip the sprite to add variation.
	($Sprite2D as Sprite2D).flip_h = bool(randi() % 2)
	($Sprite2D as Sprite2D).flip_v = bool(randi() % 2)


func burst() -> void:
	($Hint as GPUParticles2D).emitting = false
	($Burst as GPUParticles2D).emitting = true

	($CollisionShape2D as CollisionShape2D).disabled = false

	($AnimationPlayer as AnimationPlayer).play("burst")
	($AnimationPlayer as AnimationPlayer).queue("idle")


func eat() -> void:
	# Defer it, to avoid error about flushing queries in physical objects.
	($CollisionShape2D as CollisionShape2D).set_deferred("disabled", true)

	($AnimationPlayer as AnimationPlayer).play("remove")


func get_hitbox_radius() -> float:
	return (($CollisionShape2D as CollisionShape2D).shape as CircleShape2D).\
			radius
