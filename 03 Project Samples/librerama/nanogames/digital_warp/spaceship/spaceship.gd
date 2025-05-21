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

const SPEED = 4

const MOVE_FADE_LENTGH = 0.1

var _direction_speed := 0

var _has_moved := false
var _tween: Tween

@onready var _move := $CollisionShape2D/Move as AudioStreamPlayer2D


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _unhandled_input(_event: InputEvent) -> void:
	# Use `Input` instead of the received event so multiple actions can be
	# detected at once. Not directly placed in `_physics_process()` as to not
	# capture inputs when it shouldn't.
	_direction_speed = int(Input.get_axis("nanogame_right", "nanogame_left"))

	# Toggle particles and fade in/out the movement volume.
	if not _has_moved:
		if _direction_speed != 0:
			_has_moved = true

			_update_move_volume(1)

			($CollisionShape2D/Trail as GPUParticles2D).emitting = true
	elif _direction_speed == 0:
		_has_moved = false

		_update_move_volume(0)

		($CollisionShape2D/Trail as GPUParticles2D).emitting = false

	_direction_speed *= SPEED


func _physics_process(delta: float) -> void:
	if _direction_speed != 0:
		rotation += _direction_speed * delta


func disable_hitbox() -> void:
	($CollisionShape2D as CollisionShape2D).disabled = true


func _update_move_volume(volume: float) -> void:
	if _tween != null:
		_tween.kill()

	var set_volume := func(new_volume: float) -> void:
		_move.volume_db = linear_to_db(new_volume)

	_tween = create_tween()
	_tween.tween_method(set_volume, db_to_linear(_move.volume_db), volume,
			MOVE_FADE_LENTGH)
	hit.connect(_tween.kill)


func _on_area_entered(_area: Area2D) -> void:
	_direction_speed = 0

	# Defer it, to avoid error about flushing queries in physical objects.
	($CollisionShape2D as CollisionShape2D).set_deferred("disabled", true)

	($CollisionShape2D/Trail as GPUParticles2D).emitting = true

	_move.stop()

	($CollisionShape2D/Die as AudioStreamPlayer2D).play()
	($AnimationPlayer as AnimationPlayer).play("die")

	hit.emit()
