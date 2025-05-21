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


const SPEED = 450

var _direction_speed := Vector2()
var _movement_area := Rect2()


func _unhandled_input(_event: InputEvent) -> void:
	# TODO: Use this instead once the function works with `TouchScreenButton`s.
	#_direction_speed = Input.get_vector("nanogame_left", "nanogame_right",
	#		"nanogame_up", "nanogame_down").normalized() * SPEED

	_direction_speed = Vector2.ZERO

	# Use 'Input' instead of the received event so multiple actions can be
	# detected at once. Not directly placed in '_physics_process()' as to not
	# capture inputs when it shouldn't.
	if Input.is_action_pressed("nanogame_left"):
		_direction_speed.x -= 1
	if Input.is_action_pressed("nanogame_right"):
		_direction_speed.x += 1
	if Input.is_action_pressed("nanogame_up"):
		_direction_speed.y -= 1
	if Input.is_action_pressed("nanogame_down"):
		_direction_speed.y += 1

	_direction_speed = _direction_speed.normalized() * SPEED


func _physics_process(delta: float) -> void:
	if _direction_speed == Vector2.ZERO:
		return

	position += _direction_speed * delta
	position = position.clamp(_movement_area.position, _movement_area.end)


func disappear() -> void:
	# Defer it, to avoid error about flushing queries in physical objects.
	($CollisionShape2D as CollisionShape2D).set_deferred("disabled", true)

	($AnimationPlayer as AnimationPlayer).play_backwards("tilt")


func set_movement_area(area: Rect2) -> void:
	var hitbox_extents: Vector2 = (($CollisionShape2D as CollisionShape2D).
			shape as RectangleShape2D).size
	area.position.x += hitbox_extents.x
	area.position.y += hitbox_extents.y
	area.size.x -= hitbox_extents.x * 2
	area.size.y -= hitbox_extents.y * 2

	_movement_area = area


func get_hitbox_extents() -> Vector2:
	return (($CollisionShape2D as CollisionShape2D).
			shape as RectangleShape2D).size
