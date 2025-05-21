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

const FLY_GOAL = 4
const FLY_POISON_QUANTITY = 2

const Fly = preload("res://nanogames/buzzing_lunch/flies/fly/fly.tscn")
const FlyPoison = preload(\
		"res://nanogames/buzzing_lunch/flies/fly_poison/fly_poison.tscn")

var _flies_eaten := 0


func nanogame_prepare(difficulty: int, _debug_code: int) -> void:
	var flies: Array[CharacterBody2D] = []
	for i: int in FLY_GOAL:
		flies.append(Fly.instantiate())

	match difficulty:
		2:
			for i: int in FLY_POISON_QUANTITY:
				flies.append(FlyPoison.instantiate())
		3:
			for i: int in FLY_POISON_QUANTITY * 2:
				flies.append(FlyPoison.instantiate())

	var spawn_area :=\
			Vector2(NanogamePlayer.VIEW_SIZE.x, NanogamePlayer.VIEW_SIZE.y / 2)

	# Use a single radius value, as both fly types have it at the same size.
	var fly_radius: float = flies[0].get_hitbox_radius()
	var spawn_area_adjusted := spawn_area - Vector2(fly_radius, fly_radius) * 2
	for i: CharacterBody2D in flies:
		var spawn_position := Vector2()
		while true:
			# Choose a random location for it to spawn.
			spawn_position.x =\
					fly_radius + randi() % int(spawn_area_adjusted.x)
			spawn_position.y =\
					fly_radius + randi() % int(spawn_area_adjusted.y)

			var is_valid := true
			# Avoid spawning it inside other flies.
			for j: CharacterBody2D in flies:
				if j == i:
					break

				if spawn_position.distance_to(j.position) <= fly_radius * 2:
					is_valid = false

					break

			if is_valid:
				break

		add_child(i)
		i.set_movement_area(Rect2(Vector2.ZERO, spawn_area))
		i.position = spawn_position


func _on_frog_eat() -> void:
	_flies_eaten += 1

	if _flies_eaten == FLY_GOAL:
		ended.emit(true)
	elif _flies_eaten == FLY_GOAL - 1:
		($Frog as Node2D).last_fly = true
