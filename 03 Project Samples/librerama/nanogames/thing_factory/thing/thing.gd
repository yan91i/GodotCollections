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


signal destroyed(index: int)

var thing_index := 0: set = set_thing_index


func _input_event(
		_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if not event is InputEventMouseButton or not event.is_pressed() or\
			event.button_mask != MOUSE_BUTTON_MASK_LEFT:
		return

	($Sprite2D as Sprite2D).hide()
	($Explosion as GPUParticles2D).emitting = true
	($CollisionShape2D as CollisionShape2D).disabled = true
	($Destroy as AudioStreamPlayer2D).play()

	destroyed.emit(thing_index)


func set_thing_index(index: int) -> void:
	if index < 0 or index >= ($Sprite2D as Sprite2D).hframes:
		push_error('Invalid thing of index "' + str(thing_index) + '".')

		return

	thing_index = index
	($Sprite2D as Sprite2D).frame = index

	var explosion_color := Color()
	match index:
		0:
			explosion_color = Color.DODGER_BLUE
		1:
			explosion_color = Color.RED
		2:
			explosion_color = Color.LIME_GREEN
	($Explosion as GPUParticles2D).self_modulate = explosion_color


func is_destroyed() -> bool:
	return ($CollisionShape2D as CollisionShape2D).disabled


func get_thing_index_size() -> int:
	return ($Sprite2D as Sprite2D).hframes
