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


@warning_ignore("unused_signal")
signal eat

const SPEED = 1.75
const ANIMATION_LENGTH = 0.2
const SIZE_MAX = 1000
const ROTATION_MIN = PI * 0.75
const ROTATION_MAX = PI * 1.25

var last_fly := false

var _direction_speed := 0.0

var _fly_caught: CharacterBody2D

var _tween: Tween

@onready var _tongue := $Tongue as NinePatchRect


func _unhandled_input(_event: InputEvent) -> void:
	# Use `Input` instead of the received event so multiple actions can be
	# detected at once. Not directly placed in `_physics_process()` as to not
	# capture inputs when it shouldn't.
	_direction_speed = int(Input.get_axis("nanogame_left", "nanogame_right"))

	if Input.is_action_just_pressed("nanogame_action") and _tween == null:
		_launch_tongue()

		# Double speed to facilitate targetting good flies behind bad ones.
		_direction_speed *= 2

	_direction_speed *= SPEED


func _physics_process(delta: float) -> void:
	if _direction_speed == 0:
		return

	_tongue.rotation += _direction_speed * delta
	_tongue.rotation =\
			clampf(_tongue.rotation, ROTATION_MIN, ROTATION_MAX)


func _launch_tongue() -> void:
	_tween = create_tween()
	_tween.tween_property(_tongue, "size:y", SIZE_MAX, ANIMATION_LENGTH)
	_tween.tween_callback(_retreat_tongue)

	($Tongue/Anchor/FlyHitbox/Slurp as AudioStreamPlayer2D).play()

	($FrogAnimation as AnimationPlayer).play("gulp")
	($IndicatorAnimation as AnimationPlayer).play("fade_out")


func _retreat_tongue() -> void:
	var animation_length_adjusted: float = (_tongue.size.y -
			_tongue.custom_minimum_size.y) / SIZE_MAX * ANIMATION_LENGTH

	if _tween != null:
		_tween.kill()

	_tween = create_tween()
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)

	_tween.tween_property(_tongue, "size:y", _tongue.custom_minimum_size.y,
			animation_length_adjusted)

	var is_fly_bad := false
	if _fly_caught != null:
		($Tongue/Anchor/FlyHitbox/FlyFollow as RemoteTransform2D).\
				remote_path = _fly_caught.get_path()

		_tween.set_parallel()
		_tween.tween_interval(animation_length_adjusted)
		_tween.set_parallel(false)

		_tween.tween_callback(_fly_caught.queue_free)

		if _fly_caught.has_meta("poison"):
			is_fly_bad = true

			_tween.tween_callback(set.bind("_direction_speed", 0))

			_tween.tween_callback(set_physics_process.bind(false))
			_tween.tween_callback(set_process_unhandled_input.bind(false))

			_tween.tween_callback(
					($FrogAnimation as AnimationPlayer).play.bind("sicken"))
		else:
			if last_fly:
				set_physics_process(false)

				_tween.tween_callback(($FrogAnimation as AnimationPlayer).
						queue.bind("lick_lips"))

			# Defer it, so the tweens are set first.
			emit_signal.call_deferred("eat")

	if (not last_fly or _fly_caught == null) and not is_fly_bad:
		_tween.tween_callback(
				($IndicatorAnimation as AnimationPlayer).play.bind("fade_in"))

	_tween.tween_callback(
			($Tongue/Anchor/FlyHitbox/CollisionShape2D as CollisionShape2D).
			set_disabled.bind(false))

	_tween.tween_callback(set.bind("_tween", null))


func _on_fly_hitbox_body_entered(body: CharacterBody2D) -> void:
	if _fly_caught != null:
		return

	_fly_caught = body
	_fly_caught.stop()

	# Defer it, to avoid error about flushing queries in physical objects.
	($Tongue/Anchor/FlyHitbox/CollisionShape2D as CollisionShape2D).\
			set_deferred("disabled", true)

	_retreat_tongue()

	# Defer it, so it syncs with the disabling of the "FlyHitbox".
	set_deferred("_fly_caught", null)


func _on_frog_animation_animation_finished(anim_name: String) -> void:
	if anim_name != "sicken":
		return

	set_physics_process(true)
	set_process_unhandled_input(true)

	($IndicatorAnimation as AnimationPlayer).play("fade_in")
