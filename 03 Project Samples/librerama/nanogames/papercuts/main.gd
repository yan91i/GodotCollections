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

const SHAPE_SECTION_SIZE = 2

const POLYGON_OFFSET = 48

const INDICATOR_RADIUS = 64

const CUT_DISTANCE = 32
var _cut_position_start := Vector2()
var _cut_position_current := Vector2()
var _is_cutting := false

var _area_inner_points := PackedVector2Array()

var _mouse_position_correct := Vector2()

@onready var _cut_marks := $CutMarks as Line2D
@onready var _scissors_noise := $ScissorsNoise as AudioStreamPlayer2D


func _unhandled_input(event: InputEvent) -> void:
	if not _is_cutting or event is not InputEventMouse:
		return

	# Workaround for Godot bug that makes 'get_*_mouse_position()' have
	# incorrect values when the window's stretch mode is set to 2D.
	_mouse_position_correct = event.position
	_mouse_position_correct.x -= get_canvas_transform().origin.x


func nanogame_prepare(difficulty: int, _debug_code: int) -> void:
	# Pick one of the shapes in the section according with the difficulty,
	# either randomly, or with a index matching any debug code above "1".
	var shape_index: int = randi() % SHAPE_SECTION_SIZE if _debug_code == 0\
			else clampi(_debug_code, 1, SHAPE_SECTION_SIZE) - 1
	var shape := ($AreaValid as Area2D).get_child(
			(difficulty - 1) * SHAPE_SECTION_SIZE + shape_index)\
			as CollisionPolygon2D
	shape.disabled = false

	if OS.is_debug_build():
		shape.show() # Allow seeing the shape with "Visible Collision Shapes".

	var start_index: int = randi() % shape.polygon.size()

	_cut_position_start = shape.polygon[start_index]
	_cut_position_current = _cut_position_start
	($StartIndicator as Sprite2D).position = _cut_position_start

	($ScissorsIndicator as Sprite2D).position = _cut_position_start
	($ScissorsIndicator as Sprite2D).rotation =\
			_cut_position_start.angle_to_point(shape.polygon[start_index + 1
			if start_index < shape.polygon.size() - 1 else 0])
	_cut_marks.add_point(_cut_position_start)

	_area_inner_points =\
			Geometry2D.offset_polygon(shape.polygon, -POLYGON_OFFSET).front()
	# Avoid using `front()` to get the first element, as it causes a crash on
	# release builds due to a Godot bug.
	_area_inner_points.append(_area_inner_points[0])
	($AreaValidVisual/ValidOutlineIn as Line2D).points = _area_inner_points

	var area_outer_points: Array =\
			Geometry2D.offset_polygon(shape.polygon, POLYGON_OFFSET).front()
	area_outer_points.append(area_outer_points[0]) # Same as above.

	($AreaValidVisual/ValidOutlineOut as Line2D).points = area_outer_points

	_area_inner_points.reverse()
	# Workaround a Godot bug that makes the `array_1 += array_2` operation be
	# ignored in this instance.
	for i: Vector2 in _area_inner_points:
		area_outer_points.append(i)

	($AreaValidVisual as Polygon2D).polygon = area_outer_points

	shape.polygon = area_outer_points


func _miscut() -> void:
	if not _is_cutting:
		return

	_is_cutting = false

	_cut_marks.add_point(_mouse_position_correct)

	var scissors_indicator := $ScissorsIndicator as Sprite2D
	scissors_indicator.texture = preload("_assets/mistake.svg")
	scissors_indicator.position = _mouse_position_correct
	scissors_indicator.rotation = 0
	scissors_indicator.self_modulate.a = 1
	scissors_indicator.show()

	($EndNoise as AudioStreamPlayer).stream = preload("_assets/fail.wav")
	($EndNoise as AudioStreamPlayer).play()

	get_viewport().set_input_as_handled()

	ended.emit(false)


func _get_polygon_size(polygon: PackedVector2Array) -> float:
	var count: int = polygon.size() - 1
	var size := 0.0
	for i: int in count:
		size += (polygon[count].x + polygon[i].x) *\
				(polygon[count].y - polygon[i].y)
		count = i

	return size


func _on_area_valid_input_event(
		_viewport: Viewport, event: InputEvent) -> void:
	if not event is InputEventMouse:
		return

	event.position.x -= get_canvas_transform().origin.x
	if not _is_cutting and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		if event.position.distance_to(_cut_position_current) >\
				INDICATOR_RADIUS:
			return

		_is_cutting = true

		($StartIndicator as Sprite2D).show()

		($ScissorsIndicator as Sprite2D).hide()
		($AnimationPlayer as AnimationPlayer).stop()
	elif event.button_mask != MOUSE_BUTTON_MASK_LEFT:
		if _is_cutting:
			_is_cutting = false

			var scissor_indicator := $ScissorsIndicator as Sprite2D
			scissor_indicator.position = _cut_position_current
			scissor_indicator.rotation =\
					_cut_marks.points[-1].angle_to_point(event.position)
			scissor_indicator.show()

			($AnimationPlayer as AnimationPlayer).play("indicator_blink")

		return

	# Once the cursor is in the cutting start area, check if the cutting
	# outline covers the invalid area shape.
	if event.position.distance_to(_cut_position_start) <= INDICATOR_RADIUS and\
			Geometry2D.clip_polygons(
					_area_inner_points, _cut_marks.points).is_empty():
		_is_cutting = false

		var polygon_main: PackedVector2Array = _cut_marks.points
		if not Geometry2D.is_polygon_clockwise(polygon_main):
			polygon_main.reverse()

		# Find self-intersections, removing them from the main polygon, but
		# keeping the biggest one to check if it's bigger than the main one.
		var polygon_index := 0
		var polygon_biggest := PackedVector2Array()
		var area_biggest := 0.0
		while polygon_index < polygon_main.size() - 1:
			for j: int in range(polygon_index + 2, polygon_main.size() - 1):
				var intersection: Variant = Geometry2D.\
						segment_intersects_segment(polygon_main[polygon_index],
								polygon_main[polygon_index + 1],
								polygon_main[j], polygon_main[j + 1])
				if intersection != null:
					var polygon: PackedVector2Array =\
							polygon_main.slice(polygon_index, j)
					polygon[0] = intersection
					var area: float = _get_polygon_size(polygon)
					if area > area_biggest:
						area_biggest = area

						polygon_biggest = polygon

					var polygon_fixed := PackedVector2Array()
					if polygon_index - 1 > 0:
						polygon_fixed = polygon_main.slice(0, polygon_index)

					polygon_fixed.append(intersection)

					if j + 1 < polygon_main.size() - 1:
						polygon_fixed += polygon_main.slice(
								j + 1, polygon_main.size() - 1)

					polygon_main = polygon_fixed

					break

			polygon_index += 1

		if _get_polygon_size(polygon_main) > area_biggest:
			polygon_biggest = polygon_main

		($Foreground/Center/Cutout as Polygon2D).polygon = polygon_biggest

		# Give a slightly larger version of the inner outline as a fallback, in
		# case the points from the cutout still result in an invalid polygon.
		($Foreground/Center/Fallback as Polygon2D).polygon =\
				Geometry2D.offset_polygon(
						($AreaValidVisual/ValidOutlineIn as Line2D).points,
						POLYGON_OFFSET / 2.0).front()

		_cut_marks.add_point(_cut_marks.points[0])

		($AnimationPlayer as AnimationPlayer).play("cutout_popout")

		get_viewport().set_input_as_handled()

		ended.emit(true)

		return

	if event.position.distance_to(_cut_position_current) > CUT_DISTANCE:
		# Check if the new line cut doesn't intersect with the inner points of
		# the polygon, as it's possible to create one without triggering the
		# `mouse_exit` signal of the area if done fast.
		var points: Array = _area_inner_points
		points.append(_area_inner_points[0])
		for i: int in points.size() - 1:
			if Geometry2D.segment_intersects_segment(_cut_position_current,
					event.position, points[i], points[i + 1]) != null:
				_miscut()

				return

		_cut_position_current = event.position

		_cut_marks.add_point(event.position)

		_scissors_noise.position = event.position
		if not _scissors_noise.playing:
			_scissors_noise.play()
