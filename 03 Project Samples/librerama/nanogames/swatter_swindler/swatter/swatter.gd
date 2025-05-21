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


signal swat_ended

const TARGET_OFFSET = 3
const BEAM_MARGIN = Vector2(30, 30)
const TILT_MAX = PI / 2


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func set_swatter_scale(swatter_scale: float) -> void:
	var beam := $Beam as NinePatchRect

	var size: Vector2 = beam.custom_minimum_size * swatter_scale
	var size_with_margin := size + Vector2(
			beam.patch_margin_left + beam.patch_margin_right,
			beam.patch_margin_top + beam.patch_margin_bottom)

	beam.position = -size_with_margin / 2
	beam.size = size_with_margin
	beam.pivot_offset = size_with_margin / 2

	(($CollisionShape2D as CollisionShape2D).shape as RectangleShape2D).size =\
			size

	($Swat as AudioStreamPlayer2D).pitch_scale =\
			beam.custom_minimum_size.y / size.y


func swat(target_position: Vector2) -> void:
	@warning_ignore("narrowing_conversion")
	var offset := Vector2i(($Beam as NinePatchRect).size.x / TARGET_OFFSET,
			($Beam as NinePatchRect).size.y / TARGET_OFFSET)
	position = target_position + Vector2(randi_range(-offset.x, offset.x),
			randi_range(-offset.y, offset.y))

	rotation = randf_range(-TILT_MAX, TILT_MAX)

	($AnimationPlayer as AnimationPlayer).play("swat")


func _on_area_entered(_area: Area2D) -> void:
	($AnimationPlayer as AnimationPlayer).stop(true)


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	swat_ended.emit()
