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

const HOUR_CONVERSION = TAU / 12
const MINUTE_LOOSE_CONVERSION = TAU / 6
const MINUTE_PRECISE_CONVERSION = TAU / 60

const DEBUG_POLYGON_COUNT = 60
const DEBUG_LINE_WIDTH = 25

# The `x` axis being the start and the `y` axis being the end.
var _hour_angle_goal := Vector2()
var _minute_angle_goal := Vector2()

var _difficulty := 0
var _debug_code := 0

var _minute: Area2D
@onready var _hour := $Hour as Area2D


func nanogame_prepare(difficulty: int, debug_code: int) -> void:
	_difficulty = difficulty

	var hour_time_goal: int = randi() % 12
	while true:
		var hour_time: int = randi() % 12
		# Check if the start value is not equal to the goal or the value next
		# to it.
		if hour_time != hour_time_goal and\
				hour_time != wrapi(hour_time_goal + 1, 0, 11):
			_hour.rotation = hour_time * HOUR_CONVERSION

			break

	if hour_time_goal == 0 or hour_time_goal > 9:
		($Goal/Hour as Sprite2D).frame = 1

	($Goal/Hour2 as Sprite2D).frame =\
			hour_time_goal % 10 if hour_time_goal > 0 else 2

	# Give the player a minute of margin of error.
	_hour_angle_goal.x =\
			hour_time_goal * HOUR_CONVERSION - MINUTE_PRECISE_CONVERSION
	_hour_angle_goal.y = (hour_time_goal + 1) * HOUR_CONVERSION

	if difficulty > 1:
		_minute = (($Minute as InstancePlaceholder).\
				create_instance(true) as Area2D)

		# Connect signals in-script, as `InstancePlaceholder`s don't store
		# connections for later.
		_minute.released.connect(_on_hand_released)
		_minute.grabbed.connect(_hour.set_pickable.bind(false))
		_hour.grabbed.connect(_minute.set_pickable.bind(false))

		var minute_time_max: int =  6 if difficulty == 2 else 60
		var minute_time_goal: int = randi() % minute_time_max
		while true:
			var minute_time: int = randi() % 6
			if minute_time == minute_time_goal:
				continue

			# Continue the loop if the start value is equal to the margins of
			# error.
			if minute_time == wrapi(minute_time_goal + 1, 0, minute_time_max):
				continue
			if difficulty == 3 and minute_time ==\
					wrapi(minute_time_goal - 1, 0, minute_time_max):
				continue

			_minute.rotation = minute_time * (MINUTE_LOOSE_CONVERSION
					if difficulty == 2 else MINUTE_PRECISE_CONVERSION)

			break

		($Goal/Minute as Sprite2D).show()

		match difficulty:
			2:
				($Goal/Minute as Sprite2D).frame = minute_time_goal % 10

				_minute_angle_goal.x = minute_time_goal *\
						MINUTE_LOOSE_CONVERSION - MINUTE_PRECISE_CONVERSION
				_minute_angle_goal.y =\
						(minute_time_goal + 1) * MINUTE_LOOSE_CONVERSION
			3:
				($Goal/Minute as Sprite2D).frame =\
						floori(minute_time_goal / 10.0)

				($Goal/Minute2 as Sprite2D).frame = minute_time_goal % 10
				($Goal/Minute2 as Sprite2D).show()

				_minute_angle_goal.x = minute_time_goal *\
						MINUTE_PRECISE_CONVERSION - MINUTE_PRECISE_CONVERSION
				_minute_angle_goal.y =\
						(minute_time_goal + 1) * MINUTE_PRECISE_CONVERSION

	_debug_code = debug_code
	if debug_code == 1:
		($Clock as Sprite2D).draw.connect(_on_clock_draw, CONNECT_ONE_SHOT)


func _on_hand_released() -> void:
	var hour_rotation: float = wrapf(_hour.global_rotation, 0, TAU)
	var is_hour_correct: bool = hour_rotation > _hour_angle_goal.x and\
			hour_rotation < _hour_angle_goal.y

	if not is_hour_correct:
		# Adjust the logic if the start margin of error is a negative value.
		if hour_rotation >= wrapf(_hour_angle_goal.x, 0, TAU):
			if _hour_angle_goal.x < 0:
				hour_rotation -= TAU
			if hour_rotation <= _hour_angle_goal.y:
				is_hour_correct = true

		if not is_hour_correct:
			_hour.input_pickable = true
			if _difficulty > 1:
				_minute.input_pickable = true

			return

	if _difficulty > 1:
		var minute_rotation := wrapf(_minute.global_rotation, 0, TAU)
		var is_minute_correct: bool = minute_rotation >\
				_minute_angle_goal.x and minute_rotation < _minute_angle_goal.y

		if not is_minute_correct:
			# Same as above.
			if minute_rotation >= wrapf(_minute_angle_goal.x, 0, TAU):
				if _minute_angle_goal.x < 0:
					minute_rotation -= TAU
				if minute_rotation <= _minute_angle_goal.y:
					is_minute_correct = true

			if not is_minute_correct:
				_hour.input_pickable = true
				_minute.input_pickable = true

				return

		_minute.input_pickable = false
		_minute.energize()

	($Victory as AudioStreamPlayer).play()

	_hour.input_pickable = false
	_hour.energize()

	ended.emit(true)


func _on_clock_draw() -> void:
	if _debug_code != 1:
		return

	var clock := $Clock as Sprite2D
	clock.draw_arc(Vector2.ZERO, 326, _hour_angle_goal.x - PI / 2,
			_hour_angle_goal.y - PI / 2, DEBUG_POLYGON_COUNT,
			Color(Color.CHARTREUSE, 0.5), DEBUG_LINE_WIDTH)

	if _difficulty > 1:
		clock.draw_arc(Vector2.ZERO, 350, _minute_angle_goal.x - PI / 2,
				_minute_angle_goal.y - PI / 2, DEBUG_POLYGON_COUNT,
				Color(Color.GREEN, 0.5), DEBUG_LINE_WIDTH)
