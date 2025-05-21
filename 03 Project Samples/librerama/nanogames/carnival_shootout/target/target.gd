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


signal hit(type: Types)

enum Types {
	NONE,
	GOOD,
	BAD,
	UGLY,
}

const REGION_GOOD = 0
const REGION_BAD = 128
const REGION_UGLY = 256
const REGION_BACK = 384

var _type: int = Types.NONE


func renew_target(type: Types) -> void:
	if type >= Types.size():
		push_error('Invalid target type of index "' + str(type) + '".')

		return

	if type == Types.NONE and\
			($Renew as AnimationPlayer).assigned_animation != "raise":
		return

	if _type == Types.NONE:
		($Renew as AnimationPlayer).play("raise")
	else:
		($Renew as AnimationPlayer).play("lower")

		if type != Types.NONE:
			($Renew as AnimationPlayer).queue("raise")

	_type = type


func _change_to_target_texture(is_back:=false) -> void:
	if is_back:
		(%Target as Sprite2D).region_rect.position.x = REGION_BACK

		return

	match _type:
		Types.GOOD:
			(%Target as Sprite2D).region_rect.position.x = REGION_GOOD
		Types.BAD:
			(%Target as Sprite2D).region_rect.position.x = REGION_BAD
		Types.UGLY:
			(%Target as Sprite2D).region_rect.position.x = REGION_UGLY


func _on_hitbox_input_event(_viewport: Node, event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.is_pressed() or\
			event.button_mask != MOUSE_BUTTON_MASK_LEFT:
		return

	($Base/Hitbox/CollisionShape2D as CollisionShape2D).disabled = true

	($Effects as AudioStreamPlayer2D).play()

	($Hit as AnimationPlayer).play("hit_right"
			if event.position.x - get_canvas_transform().origin.x >
					global_position.x else "hit_left")

	hit.emit(_type)
