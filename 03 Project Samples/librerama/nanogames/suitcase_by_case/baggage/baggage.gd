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


signal picked(baggage: Area2D)

const _COLORS = [
	Color(0.78, 0.21, 0.21),
	Color(0, 0.66, 0.49),
	Color(0.22, 0.54, 0.71),
]

const _MASKS = [
	preload("_assets/masks/mask_1.png"),
	preload("_assets/masks/mask_2.png"),
	preload("_assets/masks/mask_3.png"),
]

const _PATTERNS = [
	preload("_assets/patterns/pattern_1.png"),
	preload("_assets/patterns/pattern_2.png"),
	preload("_assets/patterns/pattern_3.png"),
]

const LOOKS_TYPE_SIZE = 4
const LOOKS_INDEX_MAX = 3


func _input_event(
		_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and\
			event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		picked.emit(self)


func generate(looks_correct:Array[int]=[], imitate:=0) -> void:
	var imitate_order: Array[bool] = [false, false, false, false]

	if not looks_correct.is_empty():
		if looks_correct.size() != LOOKS_TYPE_SIZE:
			push_error('`looks_correct` array must be of size "%d".' %
					LOOKS_TYPE_SIZE)

			return

		if imitate < 0 or imitate > LOOKS_TYPE_SIZE:
			push_error('Invalid `imitate` value of "%d".' % imitate)

			return

		for i: int in looks_correct:
			if i < 0 or i >= LOOKS_INDEX_MAX:
				push_error("Invalid indexes inside the `looks_correct` array.")

				return

		if imitate > 0:
			for i: int in imitate:
				imitate_order[i] = true

			imitate_order.shuffle()
	else:
		looks_correct = [-1, -1, -1, -1]

	($Base as Sprite2D).frame = _decide_index(looks_correct[0])\
			if not imitate_order[0] else looks_correct[0]
	($Mask as Sprite2D).texture = _MASKS[($Base as Sprite2D).frame]

	(%Pattern as TextureRect).texture = _PATTERNS[_decide_index(
			looks_correct[1]) if not imitate_order[1] else looks_correct[1]]

	var color: Color = _COLORS[_decide_index(looks_correct[2])\
			if not imitate_order[2] else looks_correct[2]]
	(%Pattern as TextureRect).self_modulate = color

	($Mask/ColorblindHelper as ColorRect).visible =\
			color == _COLORS[1] or color == _COLORS[2]
	($Mask/ColorblindHelper/StripSecond as ColorRect).visible =\
			color == _COLORS[2]

	($Mask/Decoration as Sprite2D).frame = _decide_index(looks_correct[3])\
			if not imitate_order[3] else looks_correct[3]


func get_looks() -> Array[int]:
	return [($Base as Sprite2D).frame, _PATTERNS.find(
			(%Pattern as TextureRect).texture), _COLORS.find(
					(%Pattern as TextureRect).self_modulate),
					($Mask/Decoration as Sprite2D).frame]


func _decide_index(avoid: int) -> int:
	var value: int
	while true:
		value = randi() % LOOKS_INDEX_MAX
		if value != avoid:
			break

	return value
