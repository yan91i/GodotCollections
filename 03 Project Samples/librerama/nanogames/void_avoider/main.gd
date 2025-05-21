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

const SmallHole = preload("black_holes/small_hole/small_hole.tscn")
const BigHole = preload("black_holes/big_hole/big_hole.tscn")

const SPAWN_RADIUS_DISTANCE = 5
const SPAWN_BIG_HOLE_INTERVAL = 2

var _interval_current := 0

var _difficulty := 0


func nanogame_prepare(difficulty: int, debug_code: int) -> void:
	_difficulty = difficulty

	match difficulty:
		2:
			($BlackHoleSpawn as Timer).wait_time /= 1.5
		3:
			($BlackHoleSpawn as Timer).wait_time /= 2

	if debug_code == 1:
		($Spaceship as Area2D).disable_hitbox()


func nanogame_start() -> void:
	_spawn_black_hole()

	($BlackHoleSpawn as Timer).start()


func _spawn_black_hole() -> void:
	var black_hole: Area2D
	if _interval_current < SPAWN_BIG_HOLE_INTERVAL:
		black_hole = SmallHole.instantiate() as Area2D

		if _difficulty == 3:
			_interval_current += 1
	else:
		black_hole = BigHole.instantiate() as Area2D

		_interval_current = 0

	add_child(black_hole)

	var spawn_position := Vector2()
	var spaceship := $Spaceship as Area2D
	var no_spawn_radius: float = spaceship.get_hitbox_radius() *\
			SPAWN_RADIUS_DISTANCE + black_hole.get_hitbox_radius()
	while true:
		# Choose a random location for it to spawn.
		spawn_position.x = randi() % int(NanogamePlayer.VIEW_SIZE.x)
		spawn_position.y = randi() % int(NanogamePlayer.VIEW_SIZE.y)

		# Avoid spawning it right where the player is.
		if not Geometry2D.is_point_in_circle(
				spawn_position, spaceship.position, no_spawn_radius):
			break
	black_hole.position = spawn_position

	black_hole.set_target_position(spaceship.position)


func _on_spaceship_hit() -> void:
	ended.emit(false)
