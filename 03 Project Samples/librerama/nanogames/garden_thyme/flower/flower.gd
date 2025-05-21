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
	area_entered.connect(_on_area_entered)


func get_hitbox_extents() -> Vector2:
	return (($CollisionShape2D as CollisionShape2D).shape
			as RectangleShape2D).size


func _on_area_entered(_area: Area2D) -> void:
	# Defer it, to avoid error about flushing queries in physical objects.
	($CollisionShape2D as CollisionShape2D).set_deferred("disabled", true)

	($Blossom as AudioStreamPlayer2D).play()
	($AnimationPlayer as AnimationPlayer).play("blossom")
