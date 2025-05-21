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


const SPEED_MAX = 75
var _speed_current := 0.0

var _direction_speed := Vector2()

@onready var visibility_rect: Rect2 =\
		($VisibleOnScreenNotifier2D as VisibleOnScreenNotifier2D).rect


func _ready() -> void:
	($Spawn as AudioStreamPlayer2D).play()


func _physics_process(delta: float) -> void:
	if _speed_current < SPEED_MAX:
		# Accelerate gradually, to give more time for the player to react.
		_speed_current =\
				clampf(_speed_current + SPEED_MAX * delta, 0, SPEED_MAX)
		position += _direction_speed *\
				smoothstep(0, SPEED_MAX, _speed_current) * delta
	else:
		position += _direction_speed * delta

	if visibility_rect.position.x + visibility_rect.size.x + position.x < 0 or\
			visibility_rect.position.x + position.x >\
			NanogamePlayer.VIEW_SIZE.x:
		queue_free()


func set_target_position(target_position: Vector2) -> void:
	_direction_speed = position.direction_to(target_position) * SPEED_MAX


func get_hitbox_radius() -> float:
	return (($CollisionShape2D as CollisionShape2D).
			shape as CircleShape2D).radius


func _on_animation_player_animation_finished() -> void:
	($AnimationPlayer as AnimationPlayer).play("pulse")
