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

const BAGGAGE_CORRECT_MIN = 4
const BAGGAGE_CORRECT_LENGTH = 8

const BAGGAGE_MOVE_DURATION = 2

const BAGGAGE_SHADER_WAVES_BASE = Vector2(2, 2)

const Baggage = preload("baggage/baggage.tscn")

var _baggage_count := 0
var _baggage_correct_target := 0

var _difficulty := 0
var _debug_code := 0

@onready var _baggage_correct :=\
		$ToughtBubble/BaggageShader/SubViewport/BaggageCorrect as Area2D


func nanogame_prepare(difficulty: int, debug_code: int) -> void:
	_difficulty = difficulty
	_debug_code = debug_code

	(($ToughtBubble/BaggageShader as SubViewportContainer).\
			material as ShaderMaterial).set_shader_parameter(
					"waves", BAGGAGE_SHADER_WAVES_BASE * difficulty)

	_baggage_correct_target =\
			randi() % BAGGAGE_CORRECT_LENGTH + BAGGAGE_CORRECT_MIN
	_baggage_correct.generate()

	_spawn_baggage()
	($BaggageSpawn as Timer).start()


func nanogame_start() -> void:
	if _debug_code != 1:
		($ThoughtVanish as Timer).start()


func _spawn_baggage() -> void:
	_baggage_count += 1

	var baggage := Baggage.instantiate() as Area2D
	baggage.generate(
			_baggage_correct.get_looks(), _baggage_correct.LOOKS_TYPE_SIZE
			if _baggage_count == _baggage_correct_target else _difficulty)

	($Conveyor/Baggages as Control).add_child(baggage)
	baggage.global_position = ($SpawnStart as Marker2D).position

	baggage.picked.connect(_on_baggage_picked)

	var tween: Tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(baggage, "position:x",
			($SpawnEnd as Marker2D).position.x, BAGGAGE_MOVE_DURATION)
	tween.tween_callback(baggage.queue_free)

	baggage.set_meta("tween", tween)


func _on_baggage_picked(baggage: Area2D) -> void:
	baggage.get_meta("tween").kill()

	var baggage_position_old: Vector2 = baggage.global_position
	($Conveyor/Baggages as Control).remove_child(baggage)
	add_child(baggage)
	baggage.global_position = baggage_position_old

	var tween: Tween = create_tween().set_parallel()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	var thought_bubble := $ToughtBubble as GPUParticles2D

	tween.tween_property(
			thought_bubble, "position:x", thought_bubble.position.x - 200, 0.2)
	tween.tween_property(baggage, "position", Vector2(($Camera2D as Camera2D).\
			position.x + 200, thought_bubble.position.y), 0.2)

	if not ($ThoughtVanish as Timer).is_stopped():
		($ThoughtVanish as Timer).stop()
		($AnimationPlayer as AnimationPlayer).stop()
	($AnimationPlayer as AnimationPlayer).play_backwards("thought_transition")

	if baggage.get_looks().hash() == _baggage_correct.get_looks().hash():
		tween.tween_property(
				thought_bubble, "self_modulate", Color.SPRING_GREEN, 0.5)

		($Results as AudioStreamPlayer).stream = preload("_assets/correct.wav")

		ended.emit(true)
	else:
		tween.tween_property(
				thought_bubble, "self_modulate", Color.CRIMSON, 0.5)

		($Results as AudioStreamPlayer).stream = preload("_assets/wrong.wav")

		ended.emit(false)

	($Results as AudioStreamPlayer).play()
