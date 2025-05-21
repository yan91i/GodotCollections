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

const DIRECTION_WEIGHT_MAX = 2

const _OBSTACLE_EASY = preload("obstacles/easy/obstacle.tscn")
const _OBSTACLES_MEDIUM: Array[PackedScene] = [
	preload("obstacles/medium/obstacle_1.tscn"),
	preload("obstacles/medium/obstacle_2.tscn"),
]
const _OBSTACLES_HARD: Array[PackedScene] = [
	preload("obstacles/hard/obstacle_1.tscn"),
	preload("obstacles/hard/obstacle_2.tscn"),
]

var _direction_weight := 0

var _difficulty := 0


func nanogame_prepare(difficulty: int, debug_code: int) -> void:
	_difficulty = difficulty

	if debug_code == 1:
		($Robot as Area2D).disable_hitbox()


func nanogame_start() -> void:
	_spawn_obstacle()
	($ObstacleSpawn as Timer).start()


func _spawn_obstacle() -> void:
	var obstacle: Area2D
	match _difficulty:
		1:
			obstacle = _OBSTACLE_EASY.instantiate() as Area2D
		2:
			obstacle = _OBSTACLES_MEDIUM[\
					randi() % _OBSTACLES_MEDIUM.size()].instantiate() as Area2D
		3:
			obstacle = _OBSTACLES_HARD[\
					randi() % _OBSTACLES_HARD.size()].instantiate() as Area2D

	add_child(obstacle)
	obstacle.position = ($ObstaclePosition as Marker2D).position

	# Randomly switch rotation so the obstacle comes from the top or bottom,
	# or the opposite of the last direction if it happened too many times.
	if randi() % 2 == 0 and _direction_weight != -DIRECTION_WEIGHT_MAX or\
			_direction_weight == DIRECTION_WEIGHT_MAX:
		if _direction_weight > 0:
			_direction_weight = 0
		_direction_weight -= 1

		obstacle.rotation = PI
	else:
		if _direction_weight < 0:
			_direction_weight = 0
		_direction_weight += 1

	obstacle.activate()


func _on_robot_hit() -> void:
	# Make the robot's scrap be shown above the foreground elements.
	var robot := $Robot as Area2D
	remove_child(robot)
	($Foreground/RobotPivot as Control).add_child(robot)

	ended.emit(false)
