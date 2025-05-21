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

extends TextureRect


signal end_reached(thing: Area2D)

const THING_MOVE_DURATION = 2.5

var _tweens: Array[Tween] = []


func place_thing(thing: Area2D) -> void:
	if thing.is_inside_tree():
		push_error("Unable to place thing. It's already inside the tree.")

		return

	add_child(thing)
	thing.position = ($SpawnStart as Marker2D).position

	var tween: Tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(thing, "position:x",
			($SpawnEnd as Marker2D).position.x, THING_MOVE_DURATION)

	tween.finished.connect(_on_tween_finished.bind(thing))

	_tweens.append(tween)


func stop_things() -> void:
	for i: Tween in _tweens:
		i.kill()


func _on_tween_finished(thing: Area2D) -> void:
	if not thing.is_destroyed():
		end_reached.emit(thing)

	_tweens.pop_front()
	thing.queue_free()
