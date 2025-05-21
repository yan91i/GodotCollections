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

const COLOR_NEUTRAL = Color(0.1, 0.1, 0.1)
const COLOR_CORRECT = Color(0, 1, 0.5)
const COLOR_WRONG = Color(1, 0.16, 0.16)

var correct_count := 0

var _difficulty := 0


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("nanogame_action") or _difficulty < 1:
		return

	set_process_unhandled_input(false)

	var animation_player := $AnimationPlayer as AnimationPlayer
	var target := $Meter/Indicators/Target as ColorRect
	if ($Meter/Indicators/Pointer as Sprite2D).position.x >=\
			target.position.x and ($Meter/Indicators/Pointer as Sprite2D).\
			position.x <= target.position.x + target.size.x:
		((($Lights as HBoxContainer).get_child(correct_count) as TextureRect).\
				get_child(0) as ColorRect).color = COLOR_CORRECT

		correct_count += 1
		if correct_count == _difficulty:
			animation_player.play("light_dance")

			ended.emit(true)

			return

		($Effects as AudioStreamPlayer).stream = preload("_assets/correct.wav")
		($Effects as AudioStreamPlayer).play()

		animation_player.pause()

		($CorrectPause as Timer).start()
		await ($CorrectPause as Timer).timeout

		animation_player.play()
	else:
		var light_current := ((($Lights as HBoxContainer).get_child(
				correct_count) as TextureRect).get_child(0) as ColorRect)
		light_current.color = COLOR_WRONG

		var pointer_time: float = animation_player.current_animation_position
		animation_player.play("machine_shake")
		await animation_player.animation_finished

		light_current.color = COLOR_NEUTRAL

		animation_player.play("pointer_move")
		animation_player.seek(pointer_time)

	($PointerCooldown as Timer).start()
	await ($PointerCooldown as Timer).timeout

	set_process_unhandled_input(true)


func nanogame_prepare(difficulty: int, _debug_code: int) -> void:
	_difficulty = difficulty

	var target := $Meter/Indicators/Target as ColorRect
	# Shrink the target size according to difficulty level.
	target.size.x /= 1.0 + 0.5 * (difficulty - 1)

	target.position.x = randf_range(0, ($Meter/Indicators as\
			TextureRect).size.x - target.size.x)

	if difficulty > 1:
		($Lights/Border2 as TextureRect).show()

		if difficulty == 3:
			($Lights/Border3 as TextureRect).show()
