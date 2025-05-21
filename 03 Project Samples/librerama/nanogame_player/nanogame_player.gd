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

class_name NanogamePlayer
extends SubViewportContainer


signal stopped

signal kickoff_started
signal kickoff_ended

signal timer_stopped

signal nanogame_won
signal nanogame_lost
signal nanogame_freed

signal next_nanogame_yielded
signal free_nanogame_yielded

signal error_occured(nanogame: Nanogame)

const DIFFICULTY_MAX = 3
const DIFFICULTY_MIN = 1

const SPEED_MAX = 10
const SPEED_MIN = 1
const SPEED_LOSS = 2
const SPEED_INCREMENT = 0.075

const ENERGY_MAX = 16
const ENERGY_MIN = 0
const ENERGY_LOSS = 4

const VIEW_SIZE = Vector2(960, 720)

const JOYSTICK_DEADZONE = 0.1
const JOYCURSOR_SPEED = 750
const JOYCURSOR_SNAP_RANGE = 150
const JOYCURSOR_SNAP_DEPTH = 6.0

var difficulty: int = DIFFICULTY_MIN: set = set_difficulty
var speed: int = SPEED_MIN: set = set_speed
var energy: int = ENERGY_MAX: set = set_energy

var difficulty_lock := false
var speed_lock := false
var energy_lock := false

var timer_lock := false: set = set_timer_lock

var joycursor_enabled := false: set = set_joycursor_enabled

var debug_code := 0

var _is_playing := false
var _is_receiving_inputs := false

var _joystick_direction := Vector2()
var _joycursor_position := Vector2()
var _joycursor_position_snapped := Vector2()

var _nanogames: Array[Nanogame] = []

var _nanogame_scene_instantiator := Thread.new()

var _yielder := GameManager.Yielder.new()

var _physics_point_query := PhysicsPointQueryParameters2D.new()
var _physics_shape_query := PhysicsShapeQueryParameters2D.new()

var _nanogame_current: Nanogame
var _nanogame_scene: Node
var _nanogame_timer: int
var _nanogame_translation: Translation

var _physics_space: PhysicsDirectSpaceState2D

@export var reset_status_on_stop := true

@export var yield_nanogame_swapping := false: set = set_yield_nanogame_swapping

@onready var _nanogame_viewport := $NanogameViewport as SubViewport

# Stored, as `get_time()` can be called multiple times in a row of frames by
# the interfaces.
@onready var _goal_timer := $Goal as Timer


func _ready() -> void:
	set_physics_process(false)

	_nanogame_viewport.msaa_2d = get_tree().root.msaa_2d
	_nanogame_viewport.msaa_3d = get_tree().root.msaa_3d


func _notification(what: int) -> void:
	if not _is_playing:
		return

	match what:
		NOTIFICATION_PAUSED:
			_joystick_direction = Vector2.ZERO

			Engine.time_scale = 1
			AudioServer.playback_speed_scale = 1
		NOTIFICATION_UNPAUSED:
			set_speed(speed)
		NOTIFICATION_TRANSLATION_CHANGED:
			if _nanogame_translation != null:
				TranslationServer.remove_translation(_nanogame_translation)

			_nanogame_translation = _nanogame_current.get_current_translation()
			if _nanogame_translation != null:
				TranslationServer.add_translation(_nanogame_translation)
		NOTIFICATION_WM_CLOSE_REQUEST:
			if _nanogame_scene_instantiator.is_started():
				_nanogame_scene_instantiator.wait_to_finish()

			# Avoid crashing in case the nanogame has something that triggers
			# the signal when offscreen (e.g. `VisibilityNotifier2D/3D`).
			if is_instance_valid(_nanogame_scene) and\
					_nanogame_scene.ended.is_connected(_end_nanogame):
				_nanogame_scene.ended.disconnect(_end_nanogame)


func _physics_process(delta: float) -> void:
	if _physics_space == null:
		_physics_space = PhysicsServer2D.space_get_direct_state(
				_nanogame_viewport.find_world_2d().space)

		_physics_point_query.collide_with_areas = true
		_physics_shape_query.collide_with_areas = true
		var shape := CircleShape2D.new()
		shape.radius = JOYCURSOR_SNAP_RANGE
		_physics_shape_query.shape = shape

	_joycursor_position += _joystick_direction * delta
	# Keep the joycursor inside the screen.
	_joycursor_position = _joycursor_position.clamp(
			Vector2.ZERO, Vector2(size.x, VIEW_SIZE.y))

	var is_inside_body := false

	_physics_point_query.position = _joycursor_position -\
			_nanogame_viewport.canvas_transform.origin
	var result: Array[Dictionary] =\
			_physics_space.intersect_point(_physics_point_query)
	for i: Dictionary in result:
		if result[0]["collider"].input_pickable:
			is_inside_body = true

			break

	if not is_inside_body:
		_physics_shape_query.transform.origin = _physics_point_query.position
		var collisions: Array[Vector2] =\
				_physics_space.collide_shape(_physics_shape_query)
		var collision := Vector2.INF
		var distance_closest := 0
		var joycursor_no_canvas: Vector2 = _joycursor_position -\
				_nanogame_viewport.canvas_transform.origin
		var excluded: Array[RID] = []
		var has_previous_collision := false
		for i: int in collisions.size():
			# Ignore collisions in the query shape.
			if i % 2 == 0:
				continue

			# Push the position further, to guarantee it's inside the body.
			var collision_current: Vector2 = collisions[i] +\
					joycursor_no_canvas.direction_to(
							collisions[i]) * JOYCURSOR_SNAP_DEPTH
			_physics_point_query.position = collision_current
			_physics_point_query.exclude = excluded
			result = _physics_space.intersect_point(_physics_point_query, 1)
			if not result.is_empty():
				if result[0]["collider"].input_pickable:
					var distance := int(joycursor_no_canvas.
							distance_squared_to(collision_current))
					if distance_closest == 0 or distance <= distance_closest:
						collision =  collision_current +\
								_nanogame_viewport.canvas_transform.origin
						collisions[i] = collision
						distance_closest = distance

						if collision == _joycursor_position_snapped:
							has_previous_collision = true
				else:
					excluded.append(result[0]["collider"].get_rid())

		# Avoid constantly snapping between multiple targets with the same
		# distance.
		if has_previous_collision and distance_closest ==\
				int(_joycursor_position.distance_squared_to(
						_joycursor_position_snapped)):
			collision = _joycursor_position_snapped

		_physics_point_query.exclude = []

		_joycursor_position_snapped = collision if collision.is_finite()\
				else _joycursor_position
	else:
		_joycursor_position_snapped = _joycursor_position

	var event: InputEventMouse
	if Input.is_action_pressed("nanogame_action"):
		event = InputEventMouseButton.new()
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
	else:
		event = InputEventMouseMotion.new()

	event.position = _joycursor_position
	event.global_position = _joycursor_position
	_nanogame_viewport.push_input(event)


func _propagate_input_event(event: InputEvent) -> bool:
	if not _is_receiving_inputs:
		return false

	match _nanogame_current.get_input():
		Nanogame.Inputs.NAVIGATION:
			match _nanogame_current.get_input_modifier():
				Nanogame.InputModifiers.NONE:
					if not event.is_action("nanogame_left") and\
							not event.is_action("nanogame_right") and\
							not event.is_action("nanogame_up") and\
							not event.is_action("nanogame_down"):
						return false
				Nanogame.InputModifiers.HORIZONTAL:
					if not event.is_action("nanogame_left") and\
							not event.is_action("nanogame_right"):
						return false
				Nanogame.InputModifiers.VERTICAL:
					if not event.is_action("nanogame_up") and\
							not event.is_action("nanogame_down"):
						return false

			if event is InputEventJoypadMotion and\
					absf(event.axis_value) < JOYSTICK_DEADZONE:
				event.axis_value = 0
		Nanogame.Inputs.ACTION:
			if not event.is_action("nanogame_action"):
				return false
		Nanogame.Inputs.NAVIGATION_ACTION:
			match _nanogame_current.get_input_modifier():
				Nanogame.InputModifiers.NONE:
					if not event.is_action("nanogame_left") and\
							not event.is_action("nanogame_right") and\
							not event.is_action("nanogame_up") and\
							not event.is_action("nanogame_down") and\
							not event.is_action("nanogame_action"):
						return false
				Nanogame.InputModifiers.HORIZONTAL:
					if not event.is_action("nanogame_left") and\
							not event.is_action("nanogame_right") and\
							not event.is_action("nanogame_action"):
						return false
				Nanogame.InputModifiers.VERTICAL:
					if not event.is_action("nanogame_up") and\
							not event.is_action("nanogame_down") and\
							not event.is_action("nanogame_action"):
						return false

			if event is InputEventJoypadMotion and\
					absf(event.axis_value) < JOYSTICK_DEADZONE:
				event.axis_value = 0
		Nanogame.Inputs.DRAG_DROP:
			if not joycursor_enabled:
				if event is not InputEventMouse:
					return false
			else:
				# Transform the joypad event into a mouse event.
				if event is InputEventJoypadButton:
					if not event.is_action("nanogame_action"):
						return false

					# Lie to the engine that the mouse is still inside the
					# window in case it isn't.
					_nanogame_viewport.notification(
							NOTIFICATION_VP_MOUSE_ENTER)

					if Input.is_action_just_pressed("nanogame_action"):
						_joycursor_position = _joycursor_position_snapped

					var event_mouse := InputEventMouseButton.new()
					event_mouse.button_mask = MOUSE_BUTTON_MASK_LEFT
					event_mouse.pressed = event.pressed
					event_mouse.position = _joycursor_position;
					event_mouse.global_position = event_mouse.position
					_nanogame_viewport.push_input(event_mouse)
				elif event is InputEventJoypadMotion:
					match event.axis:
						JOY_AXIS_LEFT_X:
							_joystick_direction.x =\
									event.axis_value * JOYCURSOR_SPEED\
									if absf(event.axis_value) >=\
									JOYSTICK_DEADZONE else 0.0
						JOY_AXIS_LEFT_Y:
							_joystick_direction.y =\
									event.axis_value * JOYCURSOR_SPEED\
									if absf(event.axis_value) >=\
									JOYSTICK_DEADZONE else 0.0

				return false

	return true


func start() -> void:
	if _is_playing:
		return

	if _nanogames.is_empty():
		push_error("Nanogame player can't be started if it doesn't have any " +
				"nanogames to play.")

		return

	if energy == ENERGY_MIN:
		push_error("Nanogame player can't be started if the energy level is " +
				"at minimum.")

		return

	_is_playing = true

	_nanogames.shuffle()

	if speed > SPEED_MIN:
		set_speed(speed)

	_next_nanogame()


func stop() -> void:
	if not _is_playing:
		return

	_is_playing = false

	if _nanogame_scene_instantiator.is_started():
		_nanogame_scene_instantiator.wait_to_finish()

	if _nanogame_current != null:
		_is_receiving_inputs = false
		_joystick_direction = Vector2.ZERO

		set_physics_process(false)

		# Avoid crashing in case the nanogame has something that triggers the
		# signal when offscreen (e.g. `VisibilityNotifier2D/3D`).
		if is_instance_valid(_nanogame_scene) and\
				_nanogame_scene.ended.is_connected(_end_nanogame):
			_nanogame_scene.ended.disconnect(_end_nanogame)

		_goal_timer.stop()

		($Kickoff as Timer).stop()
		($Victory as Timer).stop()
		($Failure as Timer).stop()

		if _yielder.is_active():
			_yielder.resume()

		_free_nanogame()

	if reset_status_on_stop:
		difficulty = DIFFICULTY_MIN
		speed = SPEED_MIN
		energy = ENERGY_MAX

	Engine.time_scale = 1
	AudioServer.playback_speed_scale = 1

	stopped.emit()


func add_nanogames(nanogames: Array[Nanogame]) -> void:
	if _is_playing:
		push_error("Unable to add nanogames while nanogame player is " +
				"playing. It must be stopped first.")

		return

	if nanogames.is_empty():
		return

	var nanogames_valid: Array[Nanogame] = []
	for i: Nanogame in nanogames:
		if not i.has_data():
			push_error('Unable to add nanogame "' + i.get_nanogame_name() +
					"\" to nanogame player. It doesn't contain valid data.")

			continue

		if _nanogames.has(i) or nanogames_valid.has(i):
			push_warning('Nanogame "' + i.get_nanogame_name() +
					'" is already present in the nanogame player or in the ' +
					"given list. Skipped.")

			continue

		nanogames_valid.append(i)

	_nanogames.append_array(nanogames_valid)


func clear_nanogames() -> void:
	if _is_playing:
		push_error(
				"Unable to clear nanogames while nanogame player is playing.")

		return

	_nanogames.clear()


func resume_yield() -> void:
	if yield_nanogame_swapping and _yielder.is_active():
		_yielder.resume()


func set_timer_lock(is_locked: bool) -> void:
	timer_lock = is_locked

	_goal_timer.paused = is_locked

	if _is_playing and _goal_timer.is_stopped():
		_goal_timer.start()


func set_difficulty(value: int) -> void:
	if value < DIFFICULTY_MIN or value > DIFFICULTY_MAX:
		push_error("Nanogame player's `difficulty` value must be above or " +
				'equal to "%d", or below or equal to "%d".' %
				[DIFFICULTY_MIN, DIFFICULTY_MAX])

		return

	difficulty = value


func set_speed(value: int) -> void:
	if value < SPEED_MIN or value > SPEED_MAX:
		push_error("Nanogame player's `speed` value must be above or equal " +
				'to "%d", or below or equal to "%d".' % [SPEED_MIN, SPEED_MAX])

		return

	speed = value

	if not _is_playing:
		return

	var speed_adjusted: float = (value - 1) * SPEED_INCREMENT
	Engine.time_scale = 1 + speed_adjusted
	AudioServer.playback_speed_scale = Engine.time_scale


func set_energy(value: int) -> void:
	if value < ENERGY_MIN or value > ENERGY_MAX:
		push_error("Nanogame player's `energy` value must be above or equal " +
				'to "%d", or below or equal to "%d".' %
				[ENERGY_MIN, ENERGY_MAX])

		return

	energy = value


func set_joycursor_enabled(is_enabled: bool) -> void:
	if joycursor_enabled == is_enabled:
		return

	joycursor_enabled = is_enabled
	if joycursor_enabled:
		# Place the joycursor in the center of the screen.
		_joycursor_position = size / 2

	set_physics_process(joycursor_enabled and _is_receiving_inputs)


func set_yield_nanogame_swapping(is_enabled: bool) -> void:
	resume_yield()

	yield_nanogame_swapping = is_enabled


func is_playing() -> bool:
	return _is_playing


func get_time() -> float:
	return _goal_timer.time_left if not _goal_timer.is_stopped()\
			else _goal_timer.wait_time


func get_nanogames() -> Array:
	return _nanogames.duplicate()


func get_current_nanogame() -> Nanogame:
	if not _is_playing:
		return null

	return _nanogame_current


func get_next_nanogame() -> Nanogame:
	if not _is_playing:
		return null

	return _nanogames.front()


func get_joycursor_position() -> Vector2:
	return _joycursor_position


func get_joycursor_position_snapped() -> Vector2:
	return _joycursor_position_snapped


func _instantiate_nanogame_scene(nanogame: Nanogame) -> Node:
	return nanogame.instantiate_scene()


func _next_nanogame() -> void:
	_nanogame_current = _nanogames.front()
	_nanogames.append(_nanogames.pop_front())

	_nanogame_timer = _nanogame_current.get_timer()

	_nanogame_translation = _nanogame_current.get_current_translation()
	if _nanogame_translation != null:
		TranslationServer.add_translation(_nanogame_translation)

	# Place the joycursor in the center of the screen.
	_joycursor_position = size / 2
	_joycursor_position_snapped = _joycursor_position

	if yield_nanogame_swapping:
		_nanogame_scene_instantiator.start(
				_instantiate_nanogame_scene.bind(_nanogame_current))

		_yielder.activate()

		next_nanogame_yielded.emit()

		if _yielder != null and _yielder.is_active():
			await _yielder.resumed
		if not _is_playing:
			return

		_nanogame_scene = _nanogame_scene_instantiator.wait_to_finish()\
				if _nanogame_scene_instantiator.is_started() else\
				_instantiate_nanogame_scene(_nanogame_current)

		if _nanogame_scene == null:
			error_occured.emit(_nanogame_current)
			stop()

			return
	else:
		_nanogame_scene = _instantiate_nanogame_scene(_nanogame_current)
		if _nanogame_scene == null:
			error_occured.emit(_nanogame_current)
			stop()

			return

	if not _nanogame_scene.has_method("nanogame_prepare"):
		push_error('The nanogame "' + _nanogame_current.get_nanogame_name() +
				'" at path "' + _nanogame_current.get_nanogame_path() +
				'" lacks the `nanogame_prepare()` method. ' +
				"The nanogame player has been stopped.")

		error_occured.emit(_nanogame_current)
		stop()

		return

	if not _nanogame_scene.has_signal("ended"):
		push_error('The nanogame "' + _nanogame_current.get_nanogame_name() +
				'" at path "' + _nanogame_current.get_nanogame_path() +
				'" lacks the `ended` signal. The nanogame player has been' +
				"stopped.")

		error_occured.emit(_nanogame_current)
		stop()

		return

	_nanogame_viewport.physics_object_picking =\
			_nanogame_current.get_input() == Nanogame.Inputs.DRAG_DROP

	_nanogame_viewport.add_child(_nanogame_scene)
	_nanogame_scene.nanogame_prepare(difficulty, debug_code)

	($Kickoff as Timer).start()
	kickoff_started.emit()


func _free_nanogame() -> void:
	_nanogame_current = null

	if _nanogame_scene != null and is_instance_valid(_nanogame_scene) and\
			_nanogame_scene.is_inside_tree():
		_nanogame_viewport.remove_child(_nanogame_scene)

		_nanogame_scene.queue_free()

	if _nanogame_translation != null:
		TranslationServer.remove_translation(_nanogame_translation)
		_nanogame_translation = null

	nanogame_freed.emit()


func _end_nanogame(has_won: bool) -> void:
	if has_won and not _goal_timer.is_stopped() and\
			_nanogame_timer == Nanogame.Timers.SURVIVAL:
		return

	# Return if there's no connection, as there are some cases where this
	# method can be called multiple times in the same frame.
	if not _nanogame_scene.ended.is_connected(_end_nanogame):
		return

	_is_receiving_inputs = false
	_joystick_direction = Vector2.ZERO

	set_physics_process(false)

	_nanogame_scene.ended.disconnect(_end_nanogame)

	match _nanogame_timer:
		Nanogame.Timers.OBJECTIVE:
			if has_won:
				($Victory as Timer).start()
			elif not ($Goal as Timer).is_stopped() or ($Goal as Timer).paused:
				($Failure as Timer).start()
			else:
				_lose_nanogame()
		Nanogame.Timers.SURVIVAL:
			if has_won:
				_win_nanogame()
			else:
				($Failure as Timer).start()

	# Emit it earlier, so the timer in the interfaces can stop at the last
	# value, instead of going directly to 0.
	timer_stopped.emit()

	_goal_timer.stop()


func _win_nanogame() -> void:
	nanogame_won.emit()

	if yield_nanogame_swapping:
		_yielder.activate()

		free_nanogame_yielded.emit()

		if _yielder.is_active():
			await _yielder.resumed
		if not _is_playing:
			return

		# Give time to the `Yielder` to disconnect.
		await get_tree().process_frame

	if energy < ENERGY_MAX and not energy_lock:
		energy += 1

	if speed < SPEED_MAX:
		if not speed_lock:
			speed += 1

			Engine.time_scale += SPEED_INCREMENT
			AudioServer.playback_speed_scale = Engine.time_scale
	elif difficulty < DIFFICULTY_MAX and not (difficulty_lock or speed_lock):
		difficulty += 1

		speed = SPEED_MIN

		Engine.time_scale = 1
		AudioServer.playback_speed_scale = 1

	_free_nanogame()
	_next_nanogame()


func _lose_nanogame() -> void:
	nanogame_lost.emit()

	if yield_nanogame_swapping:
		_yielder.activate()

		free_nanogame_yielded.emit()

		if _yielder != null and _yielder.is_active():
			await _yielder.resumed
		if not _is_playing:
			return

		# Give time to the `Yielder` to disconnect.
		await get_tree().process_frame

	if not energy_lock:
		energy = maxi(energy - ENERGY_LOSS, ENERGY_MIN)

	if not speed_lock:
		speed = maxi(speed - SPEED_LOSS, SPEED_MIN)

		var speed_adjusted: float = (speed - 1) * SPEED_INCREMENT
		Engine.time_scale = 1 + speed_adjusted
		AudioServer.playback_speed_scale = Engine.time_scale

	_free_nanogame()

	if energy == ENERGY_MIN:
		stop()
	else:
		_next_nanogame()


func _on_kickoff_timeout() -> void:
	_is_receiving_inputs = true

	set_physics_process(joycursor_enabled)

	_nanogame_scene.ended.connect(_end_nanogame)

	if _nanogame_scene.has_method("nanogame_start"):
		_nanogame_scene.nanogame_start()

	if not timer_lock:
		_goal_timer.start()

	kickoff_ended.emit()


func _on_goal_timeout() -> void:
	_end_nanogame(_nanogame_timer == Nanogame.Timers.SURVIVAL)
