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

const PARTICLE_QUANTITY_DIVISOR = 100

var _inputs: Array[Node] = []


func _ready() -> void:
	set_process_unhandled_input(false)

	# Delay the play area update, otherwise the values will be incorrect.
	get_viewport().size_changed.connect(($ResizeDelay as Timer).start)
	_on_resize_delay_timeout()


func _unhandled_input(event: InputEvent) -> void:
	if _inputs.is_empty() or not event.is_action_type() or\
			(not event.is_action_pressed("nanogame_up") and
					not event.is_action_pressed("nanogame_down") and
					not event.is_action_pressed("nanogame_left") and
					not event.is_action_pressed("nanogame_right") and
					not event.is_action_pressed("nanogame_action")):
		return

	var input: TextureRect = _inputs.pop_front()
	if not input.try_input(event):
		($ParticlesTop as GPUParticles2D).emitting = false
		($ParticlesBottom as GPUParticles2D).emitting = false

		($Music as AudioStreamPlayer).stop()

		($AnimationPlayer as AnimationPlayer).play("fail")

		ended.emit(false)
	else:
		if _inputs.is_empty():
			($ParticlesTop as GPUParticles2D).lifetime *= 2
			($ParticlesTop as GPUParticles2D).speed_scale *= 2

			($ParticlesBottom as GPUParticles2D).lifetime *= 2
			($ParticlesBottom as GPUParticles2D).speed_scale *= 2

			ended.emit(true)

			await input.animation_pick_finished

			($Music as AudioStreamPlayer).stop()

			($AnimationPlayer as AnimationPlayer).play("win")

			return

		($AnimationPlayer as AnimationPlayer).play("match_input")


func nanogame_prepare(difficulty: int, _debug_code: int) -> void:
	_inputs = (($Inputs/Top as HBoxContainer).get_children() +
			($Inputs/Bottom as HBoxContainer).get_children()) as Array[Node]

	match difficulty:
		1:
			_inputs.remove_at(5)
			_inputs.remove_at(2)
		2, 3:
			_inputs[2].create_instance(true)

			if difficulty == 3:
				_inputs[5].create_instance(true)

			_inputs = (($Inputs/Top as HBoxContainer).get_children() +
					($Inputs/Bottom as HBoxContainer).get_children())\
					as Array[Node]

			if difficulty < 3:
				_inputs.remove_at(5)

	_inputs.shuffle()


func nanogame_start() -> void:
	var animation_player := $AnimationPlayer as AnimationPlayer
	for i: Node in _inputs:
		i.show_input()

		# Make sure that the animation is stopped, as there could still be some
		# frames left.
		animation_player.stop()

		animation_player.play("show_input")

		await i.animation_show_finished

	set_process_unhandled_input(true)

	animation_player.play("start")


func _on_resize_delay_timeout() -> void:
	var display_width_half := int(get_viewport_rect().size.x / 2)
	@warning_ignore("integer_division")
	($ParticlesTop as GPUParticles2D).amount =\
			display_width_half / PARTICLE_QUANTITY_DIVISOR
	(($ParticlesTop as GPUParticles2D).
			process_material as ParticleProcessMaterial).\
			emission_box_extents.x = display_width_half
	@warning_ignore("integer_division")
	($ParticlesBottom as GPUParticles2D).amount =\
			display_width_half / PARTICLE_QUANTITY_DIVISOR
