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


signal jumped
signal landed(area: Area2D)

const JUMP_DISTANCE_MIN = 150
const JUMP_DISTANCE_MAX = 400

const JUMP_ANIMATION_LENGTH = 0.6

const TARGET_ARC_START_MIN = -1.5
const TARGET_ARC_START_MAX = -2.47
const TARGET_ARC_END_MIN = -0.3
const TARGET_ARC_END_MAX = -0.12

const TARGET_ANIMATION_LENGTH_HALF = 0.7
const TARGET_COLOR = Color(0.23, 0.23, 0.23)

var position_limit := 0

var is_never_splashing := false

var goal_area: Area2D

var _target_arc_start_current := 0.0
var _target_arc_end_current := 0.0

var _tween_hop: Tween
var _tween_target: Tween

@onready var _target := $Target as CollisionShape2D


func _ready() -> void:
	set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("nanogame_action"):
		return

	### Jump ###

	set_process(false)
	set_process_unhandled_input(false)

	queue_redraw()

	_target.disabled = true
	_target.hide()

	var distance: float = minf(_target.position.x, position_limit - position.x)
	var animation_length: float =\
			JUMP_ANIMATION_LENGTH / JUMP_DISTANCE_MAX * distance

	_tween_hop = create_tween()
	_tween_hop.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)

	_tween_hop.tween_property(
			self, "position:x", position.x + distance, animation_length)

	var land_area: Area2D
	if not get_overlapping_areas().is_empty():
		land_area = get_overlapping_areas().front()

	_tween_hop.tween_callback(_land.bind(land_area))

	var tween: Tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)

	tween.set_trans(Tween.TRANS_CIRC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y - distance / 2,
			animation_length / 2)

	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y",position.y, animation_length / 2)

	($Noises as AudioStreamPlayer2D).play()

	($AnimationPlayer as AnimationPlayer).speed_scale =\
			JUMP_ANIMATION_LENGTH / animation_length
	($AnimationPlayer as AnimationPlayer).play("jump")

	jumped.emit()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if is_processing():
		draw_arc(_target.position / 2, _target.position.x / 2,
				_target_arc_start_current, _target_arc_end_current, 16,
				TARGET_COLOR, 2, true)


func activate_target() -> void:
	if not is_processing() and\
			(_tween_hop == null or not _tween_hop.is_running()):
		set_process(true)

		_target.show()
		_move_target()


func _move_target() -> void:
	_target.position.x = JUMP_DISTANCE_MIN
	_target_arc_start_current = TARGET_ARC_START_MIN
	_target_arc_end_current = TARGET_ARC_END_MIN

	if _tween_target != null:
		_tween_target.kill()

	_tween_target = create_tween()
	_tween_target.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween_target.set_parallel()
	_tween_target.set_loops(-1)

	_tween_target.tween_property(_target, "position:x", JUMP_DISTANCE_MAX,
			TARGET_ANIMATION_LENGTH_HALF)

	_tween_target.tween_property(self, "_target_arc_start_current",
			TARGET_ARC_START_MAX, TARGET_ANIMATION_LENGTH_HALF)
	_tween_target.tween_property(self, "_target_arc_end_current",
			TARGET_ARC_END_MAX, TARGET_ANIMATION_LENGTH_HALF)

	_tween_target.chain()

	_tween_target.tween_property(_target, "position:x", JUMP_DISTANCE_MIN,
			TARGET_ANIMATION_LENGTH_HALF)

	_tween_target.tween_property(self, "_target_arc_start_current",
			TARGET_ARC_START_MIN, TARGET_ANIMATION_LENGTH_HALF)
	_tween_target.tween_property(self, "_target_arc_end_current",
			TARGET_ARC_END_MIN, TARGET_ANIMATION_LENGTH_HALF)


func _land(area:Area2D=null) -> void:
	($AnimationPlayer as AnimationPlayer).speed_scale = 1

	if area != null or is_never_splashing:
		if goal_area != null and area == goal_area:
			($AnimationPlayer as AnimationPlayer).play("land_blush")
		else:
			# Avoid showing the target's past position in the first frame.
			_target.position.x = JUMP_DISTANCE_MIN

			set_process(true)
			set_process_unhandled_input(true)

			_target.disabled = false
			_target.show()

			_move_target()

			($AnimationPlayer as AnimationPlayer).play("land")
	else:
		($AnimationPlayer as AnimationPlayer).play("splash")

	landed.emit(area)
