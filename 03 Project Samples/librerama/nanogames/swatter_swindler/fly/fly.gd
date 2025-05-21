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

const SPEED_MAX = 150
const SPEED_LERP_WEIGHT = 5

const ROTATION_LERP_WEIGHT = 10

var _direction_speed := Vector2()

var _position_target := Vector2()
var _position_motion := Vector2()

var _movement_area := Rect2()

var _is_flying := false

var _tween: Tween

@onready var _buzz := $Buzz as AudioStreamPlayer2D


func _ready() -> void:
	_position_target = position

	var hitbox_radius: float = (($CollisionShape2D as CollisionShape2D).shape
			as CircleShape2D).radius
	_movement_area.position.x = hitbox_radius
	_movement_area.position.y = hitbox_radius
	_movement_area.size = NanogamePlayer.VIEW_SIZE
	_movement_area.size.x -= hitbox_radius * 2
	_movement_area.size.y -= hitbox_radius * 2

	area_entered.connect(_on_area_entered.unbind(1))


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

	_direction_speed = _direction_speed.normalized() * SPEED_MAX


func _physics_process(delta: float) -> void:
	if _direction_speed == Vector2.ZERO:
		if _is_flying:
			_is_flying = false
			($AnimationPlayer as AnimationPlayer).play("land")

		if _position_motion.is_zero_approx():
			return
	else:
		if _direction_speed.x != 0:
			_position_target.x = position.x + _direction_speed.x
		if _direction_speed.y != 0:
			_position_target.y = position.y + _direction_speed.y

		if not _is_flying:
			_is_flying = true
			($AnimationPlayer as AnimationPlayer).play("fly")

	position = position.lerp(_position_target, SPEED_LERP_WEIGHT * delta).\
			clamp(_movement_area.position, _movement_area.end)
	_position_motion = position - _position_target

	if _direction_speed != Vector2.ZERO:
		rotation = lerp_angle(rotation, _direction_speed.angle() + PI / 2,
				ROTATION_LERP_WEIGHT * delta)


func disable_hitbox() -> void:
	($CollisionShape2D as CollisionShape2D).disabled = true


func _update_move_volume(volume: float, duration: float) -> void:
	if _tween != null:
		_tween.kill()

	var set_volume := func(new_volume: float) -> void:
		_buzz.volume_db = linear_to_db(new_volume)

	_tween = create_tween()
	_tween.tween_method(
			set_volume, db_to_linear(_buzz.volume_db), volume, duration)
	hit.connect(_tween.kill)


func _on_area_entered() -> void:
	set_physics_process(false)

	_buzz.stop()

	($AnimatedSprite2D as AnimatedSprite2D).scale = Vector2.ONE
	($AnimatedSprite2D as AnimatedSprite2D).play("die")

	# Defer it, to avoid error about flushing queries in physical objects.
	($CollisionShape2D as CollisionShape2D).set_deferred("disabled", true)

	hit.emit()
