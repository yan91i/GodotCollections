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

const RUNE_DISTANCE = 280

const ANIMATION_LENGTH = 0.2

const COLOR_CORRECT = Color(0.22, 0.54, 0.71)
const COLOR_WRONG = Color(0.55, 0.18, 0.18)
const COLOR_VICTORY = Color(0, 0.66, 0.49)

var _gems_untouched: Array[Node] = []

var _is_gem_touched := false

var _debug_code := 0

@onready var _trail := $Trail as Line2D
@onready var _trail_end := $TrailEnd as GPUParticles2D
@onready var _trajectory := $Trajectory as Line2D

func _ready() -> void:
	_trail.self_modulate = COLOR_CORRECT
	_trail_end.self_modulate = COLOR_CORRECT


func _unhandled_input(event: InputEvent) -> void:
	if not _is_gem_touched or not event is InputEventMouse:
		return

	if event.button_mask != MOUSE_BUTTON_MASK_LEFT:
		_is_gem_touched = false

		if _trail.get_point_count() > 2:
			_trail.remove_point(_trail.get_point_count() - 1)
		else:
			_trail.clear_points()

		_trail_end.emitting = false

		return
	elif not _trail_end.emitting:
		# Enable it on movement, so it doesn't emit while still on the top left
		# of the screen.
		_trail_end.emitting = true

	# Place the position value into a variable and use that instead, to avoid
	# blocking further events.
	var mouse_position: Vector2 = event.position
	mouse_position.x -= get_canvas_transform().origin.x
	_trail.set_point_position(_trail.get_point_count() - 1, mouse_position)
	_trail_end.position = mouse_position


func nanogame_prepare(difficulty: int, debug_code: int) -> void:
	_debug_code = debug_code

	_gems_untouched = ($Gems as Node2D).get_children()
	match difficulty:
		1:
			_gems_untouched.resize(4)
		2, 3:
			_gems_untouched[4].create_instance(true)

			if difficulty == 3:
				_gems_untouched[5].create_instance(true)

			_gems_untouched = ($Gems as Node2D).get_children()

			# Connect signals in-script, as `InstancePlaceholder`s don't store
			# connections for later.
			_gems_untouched[4].touched.connect(_on_gem_touched)

			if difficulty == 3:
				_gems_untouched[5].touched.connect(_on_gem_touched)
			else:
				_gems_untouched.resize(5)

	var rotation_slice: float = TAU / _gems_untouched.size()
	for i: int in _gems_untouched.size():
		_gems_untouched[i].position =\
				Vector2.UP.rotated(rotation_slice * i) * RUNE_DISTANCE
		_gems_untouched[i].rotation = randf_range(0, TAU)

	_gems_untouched.shuffle()


func nanogame_start() -> void:
	var trajectory_noise := $TrajectoryNoise as AudioStreamPlayer2D
	for i: Node in _gems_untouched:
		_trajectory.add_point(
				_trajectory.points[_trajectory.get_point_count() - 1]
				if not _trajectory.points.is_empty() else i.global_position)

		if _trajectory.get_point_count() > 1:
			trajectory_noise.play()

			var tween: Tween = create_tween().set_parallel()
			tween.tween_method(_update_trajectory,
					_trajectory.points[_trajectory.get_point_count() - 1],
					i.global_position, ANIMATION_LENGTH)
			tween.tween_property(trajectory_noise, "position",
					i.global_position, ANIMATION_LENGTH)

			await tween.finished

	for i: Node in _gems_untouched:
		i.input_pickable = true

	trajectory_noise.stop()

	if _debug_code != 1:
		create_tween().tween_property(
				_trajectory, "self_modulate:a", 0, ANIMATION_LENGTH)


func _update_trajectory(point_position: Vector2) -> void:
	_trajectory.set_point_position(_trajectory.get_point_count() - 1
			if _trajectory.get_point_count() > 1 else 0, point_position)


func _light_gems(index: int, color: Color) -> void:
	var tween: Tween = create_tween().set_parallel()
	if index == -1:
		tween.tween_property(_trail, "self_modulate", color, ANIMATION_LENGTH)
		tween.tween_property(
				_trail_end, "self_modulate", color, ANIMATION_LENGTH)

		for i: Node in ($Gems as Node2D).get_children():
			if i is InstancePlaceholder:
				break

			tween.tween_property(i, "gem_color", color, ANIMATION_LENGTH)
	else:
		tween.tween_property(($Gems as Node2D).get_child(index) as Area2D,
				"gem_color", color, ANIMATION_LENGTH)


func _lose(gem_index: int) -> void:
	_trail_end.emitting = false

	_light_gems(gem_index, COLOR_WRONG)

	(($Gems as Node2D).get_child(gem_index) as Area2D).play_sound(1.5)

	get_viewport().set_input_as_handled()

	ended.emit(false)

	if _debug_code != 1:
		create_tween().tween_property(
			_trajectory, "self_modulate:a", 1, ANIMATION_LENGTH)


func _on_gem_touched(index: int) -> void:
	var gem := ($Gems as Node2D).get_child(index) as Area2D
	if not _is_gem_touched:
		if gem != _gems_untouched.front():
			_lose(index)

			return

		_is_gem_touched = true

		if _trail.points.is_empty():
			_trail.add_point(gem.global_position)
	else:
		_trail.set_point_position(
				_trail.points.size() - 1, gem.global_position)

		if _gems_untouched.size() > 2:
			_gems_untouched.front().input_pickable = false
			_gems_untouched.pop_front()

			if gem != _gems_untouched.front():
				_lose(index)

				return
		else:
			_trail_end.emitting = false

			($Victory as AudioStreamPlayer).play()

			_light_gems(-1, COLOR_VICTORY)

			get_viewport().set_input_as_handled()

			ended.emit(true)

			return

	_light_gems(index, COLOR_CORRECT)

	_trail.add_point(gem.global_position)

	gem.play_sound()
