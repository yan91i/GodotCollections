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


signal hit

const SPEED = 800

var _direction_speed := 0
# The `x` axis being the top and the `y` axis being the bottom.
var _movement_line := Vector2()


func _ready() -> void:
	area_entered.connect(_on_area_entered.unbind(1))


func _unhandled_input(_event: InputEvent) -> void:
	_direction_speed = 0

	# Use `Input` instead of the received event so multiple actions can be
	# detected at once. Not directly placed in `_physics_process()` as to not
	# capture inputs when it shouldn't.
	if Input.is_action_pressed("nanogame_up"):
		_direction_speed -= 1
	if Input.is_action_pressed("nanogame_down"):
		_direction_speed += 1

	_direction_speed *= SPEED


func _physics_process(delta: float) -> void:
	if _direction_speed == 0:
		return

	position.y += _direction_speed * delta
	position.y = clampf(position.y, _movement_line.x, _movement_line.y)


func disable_hitbox() -> void:
	($CollisionShape2D as CollisionShape2D).disabled = true


func set_movement_line(line: Vector2) -> void:
	@warning_ignore("integer_division")
	var height_half := ($Sprite2D as Sprite2D).texture.get_height() / 2 *\
			($Sprite2D as Sprite2D).scale.y
	line.x += height_half
	line.y -= height_half

	_movement_line = line


func get_height() -> int:
	return absi(($CollisionShape2D as CollisionShape2D).shape.a.y) +\
			($CollisionShape2D as CollisionShape2D).shape.b.y


func _on_area_entered() -> void:
	set_physics_process(false)

	hit.emit()
