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

var _flowers_watered := 0


func nanogame_prepare(difficulty: int, debug_code: int) -> void:
	var fence_height: float = ($Background/Fence as TextureRect).size.y
	var playable_area :=\
			Rect2(Vector2(0, fence_height), Vector2(NanogamePlayer.VIEW_SIZE.x,
					NanogamePlayer.VIEW_SIZE.y - fence_height))

	($Sort/WateringCan as Area2D).set_movement_area(playable_area)

	# Avoid any other stuff entering the start area.
	playable_area.size.y -= fence_height

	var flowers: Array[Node] = ($Flowers as Node2D).get_children()
	var avoidables: Array[Node] = flowers.duplicate()

	if difficulty > 1:
		var dog := ($Sort/Dog as InstancePlaceholder).\
				create_instance(true) as Area2D

		# Connect signals in-script, as `InstancePlaceholder`s don't store
		# connections for later.
		dog.area_entered.connect(_on_dog_area_entered.unbind(1))

		var dog_extents: Vector2 = dog.get_hitbox_extents()
		var dog_spawn_area: Vector2 = playable_area.size / 1.7
		# Choose a random location for it to spawn.
		dog.position.x = randi() % int(dog_spawn_area.x - dog_extents.x)
		dog.position.y = randi() % int(dog_spawn_area.y - dog_extents.y)
		dog.position +=\
				dog_spawn_area / 2 + playable_area.position + dog_extents / 2

		if difficulty == 3:
			dog.enable_walk(Rect2(dog_spawn_area / 2 + playable_area.position,
					dog_spawn_area))
		else:
			# Place it at the front, so it isn't skipped.
			avoidables.insert(0, dog)

		if debug_code == 1:
			dog.disable_hitbox()

	var flower_extents: Vector2 = flowers[0].get_hitbox_extents()
	var flower_spawn_area: Vector2 = playable_area.size - flower_extents
	var avoidable_distance: Vector2 = flower_extents * 1.5
	for i: Node in flowers:
		var spawn_position := Vector2()
		while true:
			# Choose a random location for it to spawn.
			spawn_position.x = randi() % int(flower_spawn_area.x)
			spawn_position.y = randi() % int(flower_spawn_area.y)

			spawn_position += playable_area.position + flower_extents / 2

			var is_valid := true
			# Avoid spawning it inside other stuff.
			for j: Node in avoidables:
				if j == i:
					break

				# Check if the rectangles overlap.
				var size_half: Vector2 = j.get_hitbox_extents() / 2
				if spawn_position.x + avoidable_distance.x >\
						j.position.x - size_half.x and\
						spawn_position.x - avoidable_distance.x <\
						j.position.x + size_half.x and\
						spawn_position.y + avoidable_distance.y >\
						j.position.y - size_half.y and\
						spawn_position.y - avoidable_distance.y <\
						j.position.y + size_half.y:
					is_valid = false

					break

			if is_valid:
				break

		i.position = spawn_position


func _on_flower_area_entered() -> void:
	_flowers_watered += 1
	if _flowers_watered < ($Flowers as Node2D).get_child_count():
		return

	($Sort/WateringCan as Area2D).disappear()

	# Avoid hose from continuing moving after the game ends.
	($Sort/WateringCan as Area2D).set_physics_process(false)

	($Victory as AudioStreamPlayer).play()
	($AnimationPlayer as AnimationPlayer).play("win")

	ended.emit(true)


func _on_dog_area_entered() -> void:
	($Sort/WateringCan as Area2D).disappear()

	# Avoid hose from continuing moving after the game ends.
	($Sort/WateringCan as Area2D).set_physics_process(false)

	($AnimationPlayer as AnimationPlayer).play("lose")

	ended.emit(false)
