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

extends Node2D


signal ended(has_won: bool)

const OBSTACLE_DISTANCE = 0.5
const Obstacle = preload("res://nanogames/digital_warp/obstacle/obstacle.tscn")

var _difficulty := 0

var _has_ended := false


func nanogame_prepare(difficulty: int, debug_code: int) -> void:
	_difficulty = difficulty

	if debug_code == 1:
		($Spaceship as Area2D).disable_hitbox()


func nanogame_start() -> void:
	_spawn_obstacle()


func _spawn_obstacle() -> void:
	if _has_ended:
		return

	var camera_position: Vector2 = ($Camera2D as Camera2D).position
	var past_rotations: Array[float] = []
	for i: int in _difficulty:
		var obstacle := Obstacle.instantiate() as Area2D
		add_child(obstacle)
		obstacle.position = camera_position

		var travel_rotation := 0.0
		# Make the first one always focus around the player.
		if i == 0:
			travel_rotation = wrapf(($Spaceship as Area2D).rotation +\
					randf_range(-OBSTACLE_DISTANCE, OBSTACLE_DISTANCE), 0, TAU)

			obstacle.traveled.connect(_spawn_obstacle)
		else:
			while true:
				travel_rotation = TAU * randf()

				var is_colliding := false
				for j: float in past_rotations:
					if absf(travel_rotation - j) < OBSTACLE_DISTANCE:
						is_colliding = true

						break

					var min_rotation_decreased: float =\
							minf(travel_rotation, j) - OBSTACLE_DISTANCE
					# Check if the distance is still enough if the lowest value
					# is wrapped around.
					if min_rotation_decreased < 0 and\
							wrapf(min_rotation_decreased, 0, TAU) <\
							maxf(travel_rotation, j):
						is_colliding = true

						break

				if not is_colliding:
					break

		obstacle.travel(travel_rotation)
		past_rotations.append(travel_rotation)


func _on_spaceship_hit() -> void:
	_has_ended = true

	ended.emit(false)
