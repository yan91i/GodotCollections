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


const SPEED = 250

@export var flipped := false

var _direction_speed := 0


func _ready() -> void:
	set_physics_process(false)

	if flipped:
		($CollisionShape2D/Sprite2D as Sprite2D).offset.x *= -1
		($CollisionShape2D/Sprite2D as Sprite2D).flip_h = true

	area_entered.connect(_on_area_entered.unbind(1))


func _physics_process(delta: float) -> void:
	if _direction_speed != 0:
		position.x += _direction_speed * delta


func jump(direction: int) -> void:
	_direction_speed = clampi(direction, -1, 1) * SPEED

	set_physics_process(true)

	($AnimationPlayer as AnimationPlayer).play("jump")
	($AnimationPlayer as AnimationPlayer).queue("idle")


func _on_area_entered() -> void:
	set_physics_process(false)

	($AnimationPlayer as AnimationPlayer).play("fall")
