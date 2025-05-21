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


const SPEED = 200

const EASTER_EGG_CHANCE = 15

var _direction_speed := Vector2()
var _movement_area := Rect2()


func _ready() -> void:
	set_physics_process(false)

	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += _direction_speed * delta

	if position.x < _movement_area.position.x:
		position.x = _movement_area.position.x

		_direction_speed.x *= -1
	elif position.x > _movement_area.end.x:
		position.x = _movement_area.end.x

		_direction_speed.x *= -1
	if position.y < _movement_area.position.y:
		position.y = _movement_area.position.y

		_direction_speed.y *= -1
	elif position.y > _movement_area.end.y:
		position.y = _movement_area.end.y

		_direction_speed.y *= -1


func _show_growl_frame() -> void:
	($Sprite2D as Sprite2D).frame = 2 if randi() % EASTER_EGG_CHANCE > 0 else 3


func enable_walk(movement_area: Rect2) -> void:
	($Sprite2D as Sprite2D).frame = 1

	($Sleep as GPUParticles2D).restart()
	($Sleep as GPUParticles2D).emitting = false

	var hitbox_extents: Vector2 = (($CollisionShape2D as CollisionShape2D).
			shape as RectangleShape2D).size
	movement_area.position.x += hitbox_extents.x
	movement_area.position.y += hitbox_extents.y
	movement_area.size.x -= hitbox_extents.x * 2
	movement_area.size.y -= hitbox_extents.y * 2

	_movement_area = movement_area

	set_physics_process(true)

	($ChangeDirection as Timer).start()
	_on_change_direction_timeout()

	($AnimationPlayer as AnimationPlayer).play("walk")


func disable_hitbox() -> void:
	($CollisionShape2D as CollisionShape2D).disabled = true


func get_hitbox_extents() -> Vector2:
	return (($CollisionShape2D as CollisionShape2D).
			shape as RectangleShape2D).size


func _on_area_entered(_area: Area2D):
	set_physics_process(false)

	($Sprite2D as Sprite2D).flip_h = _direction_speed.x < 0\
			if _direction_speed.x != 0 else randi() % 2 == 0

	# Defer it, to avoid error about flushing queries in physical objects.
	($CollisionShape2D as CollisionShape2D).set_deferred("disabled", true)

	($AnimationPlayer as AnimationPlayer).play("growl")


func _on_change_direction_timeout() -> void:
	_direction_speed = Vector2.UP.rotated(TAU * randf()) * SPEED
