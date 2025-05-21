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

extends StaticBody2D


const SPEED = 4

var _direction_speed := 0

var _is_short := false

var _is_bottom_disabled := false

var _was_moved := false


func _unhandled_input(_event: InputEvent) -> void:
	# Use `Input` instead of the received event so multiple actions can be
	# detected at once. Not directly placed in `_physics_process()` as to not
	# capture inputs when it shouldn't.
	_direction_speed = int(Input.get_axis("nanogame_left", "nanogame_right"))

	if not _was_moved and _direction_speed != 0:
		_was_moved = true

		($AnimationPlayer as AnimationPlayer).play("hide_arrows")

	_direction_speed *= SPEED


func _physics_process(delta: float) -> void:
	if _direction_speed != 0:
		rotation += _direction_speed * delta


func enable_shorter_mode() -> void:
	if _is_short:
		return

	_is_short = true

	($ArrowLeft as Sprite2D).rotation /= 1.6
	($ArrowRight as Sprite2D).rotation /= 1.6

	var vertices: Array = ($Top as CollisionPolygon2D).polygon
	vertices.resize(8)
	vertices.remove_at(4)
	vertices.remove_at(3)
	($Top as CollisionPolygon2D).polygon = vertices

	($Top/Sprite2D as Sprite2D).frame = 1

	if _is_bottom_disabled:
		return

	vertices = ($Bottom as CollisionPolygon2D).polygon
	vertices.resize(8)
	vertices.remove_at(4)
	vertices.remove_at(3)
	($Bottom as CollisionPolygon2D).polygon = vertices

	($Bottom/Sprite2D as Sprite2D).frame = 1


func disable_bottom() -> void:
	if _is_bottom_disabled:
		return

	_is_bottom_disabled = true

	($Bottom as CollisionPolygon2D).disabled = true
	($Bottom as CollisionPolygon2D).hide()
