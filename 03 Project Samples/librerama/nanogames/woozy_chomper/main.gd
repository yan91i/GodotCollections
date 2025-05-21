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

const FRUIT_GOAL = 3
const Fruit := preload("fruit/fruit.tscn")

var _fruit_eaten := 0
var _fruit_queue: Array[Area2D] = []


func nanogame_prepare(difficulty: int, debug_code: int) -> void:
	if difficulty > 1:
		($Woozy as Area2D).double_segment_gain = true

		if difficulty == 3:
			($ArrowUp as Sprite2D).hide()
			($ArrowDown as Sprite2D).hide()
			($ArrowLeft as Sprite2D).hide()
			($ArrowRight as Sprite2D).hide()

			($WallUp as TextureRect).show()
			($WallDown as TextureRect).show()
			($WallLeft as TextureRect).show()
			($WallRight as TextureRect).show()

			($Woozy as Area2D).restrict_outside()

	if debug_code == 1:
		($Woozy as Area2D).damage_enabled = false

	_queue_fruit()


func nanogame_start() -> void:
	_fruit_queue.front().burst()
	_queue_fruit()

	($Woozy as Area2D).start_movement()


func _queue_fruit() -> void:
	# Avoid error about flushing queries in physical objects.
	await get_tree().process_frame

	var fruit := Fruit.instantiate() as Area2D
	add_child(fruit)

	var fruit_radius: float = fruit.get_hitbox_radius()
	var fruit_area: Vector2 =\
			NanogamePlayer.VIEW_SIZE - Vector2(fruit_radius, fruit_radius) * 2

	var spawn_position := Vector2()
	var woozy := $Woozy as Area2D
	var segments: Array[Node] = woozy.get_segments()
	var segment_radius: float = segments.front().get_hitbox_radius()
	while true:
		# Choose a random location for it to spawn.
		spawn_position.x = randi() % int(fruit_area.x) + fruit_radius
		spawn_position.y = randi() % int(fruit_area.y) + fruit_radius

		if spawn_position.distance_to(woozy.position) <\
				woozy.HEAD_RADIUS + fruit_radius * 2:
			continue

		if not _fruit_queue.is_empty() and spawn_position.distance_to(
				_fruit_queue.front().position) < fruit_radius * 3:
			continue

		var _is_position_valid := true
		for i: Node in segments:
			if spawn_position.distance_to(i.position) <\
					segment_radius + fruit_radius:
				_is_position_valid = false

				break

		if _is_position_valid:
			break

	fruit.position = spawn_position
	_fruit_queue.append(fruit)


func _on_woozy_eat() -> void:
	_fruit_eaten += 1
	if _fruit_eaten == FRUIT_GOAL:
		ended.emit(true)

		return

	if _fruit_eaten == FRUIT_GOAL - 1:
		($Woozy as Area2D).last_fruit = true

	_fruit_queue.pop_front()
	_fruit_queue.front().burst()
	if _fruit_eaten < FRUIT_GOAL - 1:
		_queue_fruit()


func _on_woozy_damaged() -> void:
	ended.emit(false)
