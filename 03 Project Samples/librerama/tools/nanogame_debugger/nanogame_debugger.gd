#=============================================================================#
# Librerama                                                                   #
# Copyright (c) 2020-present Michael Alexsander.                              #
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
#=============================================================================#

extends Control


const DEBUG_SESSION_PATH = "user://debug_session.ini"

const BARS_ALPHA_ON_PLAY = 0.6

var _timer := 0
var _time_left := 0.0

var _is_saving_blocked := false

var _nanogame_path := ""
var _nanogame_uses_joycursor := false

var _is_auto_hiding := false

@onready var _nanogame_player := $NanogamePlayer as NanogamePlayer

@onready var _time := $TopBar/HBoxContainer/Time as Label

@onready var _joycursor := $Joycursor as Sprite2D
@onready var _snap_line := $Joycursor/SnapLine as Line2D
@onready var _joycursor_snapped := $Joycursor/JoycursorSnapped as Sprite2D


func _ready() -> void:
	set_process(false)

	_nanogame_player.energy_lock = true

	# Re-use existing icons.
	(%OpenNanogameButton as Button).icon =\
			get_theme_icon("folder", "FileDialog")
	(%ReloadNanogame as Button).icon = get_theme_icon("reload", "FileDialog")
	(%ToggleAutoHide as Button).icon =\
			get_theme_icon("toggle_hidden", "FileDialog")

	_is_saving_blocked = true

	var difficulty := %Difficulty as SpinBox
	difficulty.min_value = NanogamePlayer.DIFFICULTY_MIN
	difficulty.max_value = NanogamePlayer.DIFFICULTY_MAX
	var speed := %Speed as SpinBox
	speed.min_value = NanogamePlayer.SPEED_MIN
	speed.max_value = NanogamePlayer.SPEED_MAX

	_load_session()

	_is_saving_blocked = false

	_save_session()

	# Make the `SpinBox`es lose focus when the mouse exits then, so they don't
	# interrupt input while playing.
	for i: SpinBox in [difficulty, speed,
			$BottomBar/HBoxContainer/Code as SpinBox] as Array[SpinBox]:
		i.mouse_exited.connect(i.get_line_edit().release_focus)
		i.get_line_edit().mouse_exited.connect(i.get_line_edit().release_focus)

	GameManager.control_type_changed.connect(
			_on_game_manager_control_type_changed)
	_on_game_manager_control_type_changed()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and _nanogame_player.is_playing():
		(%Pause as Button).button_pressed = not get_tree().paused


func _process(_delta: float) -> void:
	var time_adjusted: float = snapped(_nanogame_player.get_time(), 0.1)
	if _time_left != time_adjusted:
		_time_left = time_adjusted

		_time.text = "%1.1f" % time_adjusted

	if _nanogame_player.joycursor_enabled:
		_set_joycursor_position(_nanogame_player.get_joycursor_position(),
				_nanogame_player.get_joycursor_position_snapped())


func _load_nanogame(path: String) -> int:
	var nanogame := Nanogame.new()
	var error_code: int = nanogame.load_data(path.get_base_dir())
	if error_code != OK:
		($NanogameError as AcceptDialog).popup_centered()

		return error_code

	_timer = nanogame.get_timer()

	_nanogame_path = nanogame.get_nanogame_path() + "/"

	_nanogame_player.clear_nanogames()
	_nanogame_player.add_nanogames([nanogame])

	_nanogame_uses_joycursor =\
			nanogame.get_input() == Nanogame.Inputs.DRAG_DROP

	(%Start as Button).disabled = false

	($BottomBar/HBoxContainer/CurrentNanogame as Label).text =\
			nanogame.get_nanogame_name()\
			if not nanogame.get_nanogame_name().is_empty() else\
			"[Nameless Nanogame]"

	(%ReloadNanogame as Button).disabled = false

	_save_session()

	return OK


func _update_references() -> void:
	var is_showing_references: bool =\
			(%ToggleReferences as Button).button_pressed
	($TimerReference as ColorRect).visible = is_showing_references
	($PauseReference as ColorRect).visible = is_showing_references

	($TouchNavigationReference as Panel).hide()
	($TouchActionReference as Panel).hide()

	if not is_showing_references:
		return

	match _nanogame_player.get_nanogames().front().get_input():
		Nanogame.Inputs.NAVIGATION:
			($TouchNavigationReference as Panel).show()
			($TouchActionReference as Panel).hide()
		Nanogame.Inputs.ACTION:
			($TouchNavigationReference as Panel).hide()
			($TouchActionReference as Panel).show()
		Nanogame.Inputs.NAVIGATION_ACTION:
			($TouchNavigationReference as Panel).show()
			($TouchActionReference as Panel).show()


func _load_session() -> void:
	var config := ConfigFile.new()
	var error_code: int = config.load(DEBUG_SESSION_PATH)
	if error_code != OK:
		if error_code != ERR_FILE_NOT_FOUND:
			push_error("Unable to load debug session. Error code: " +
					str(error_code))

		return

	# Timer Lock.
	if config.has_section_key("status", "lock_timer"):
		var value: Variant = config.get_value("status", "lock_timer", null)
		if value != null and value is bool:
			($TopBar/HBoxContainer/LockTimer as Button).button_pressed = value

	# Difficulty.
	if config.has_section_key("status", "difficulty"):
		var value: Variant = config.get_value("status", "difficulty", null)
		if value != null and value is int and\
				value >= NanogamePlayer.DIFFICULTY_MIN and\
				value <= NanogamePlayer.DIFFICULTY_MAX:
			(%Difficulty as SpinBox).value = value

	# Difficulty Lock.
	if config.has_section_key("status", "lock_difficulty"):
		var value: Variant =\
				config.get_value("status", "lock_difficulty", null)
		if value != null and value is bool:
			($TopBar/HBoxContainer/LockDifficulty as Button).button_pressed =\
					value

	# Speed.
	if config.has_section_key("status", "speed"):
		var value: Variant = config.get_value("status", "speed", null)
		if value != null and value is int and\
				value >= NanogamePlayer.SPEED_MIN and\
				value <= NanogamePlayer.SPEED_MAX:
			(%Speed as SpinBox).value = value

	# Speed Lock.
	if config.has_section_key("status", "lock_speed"):
		var value: Variant = config.get_value("status", "lock_speed", null)
		if value != null and value is bool:
			($TopBar/HBoxContainer/LockSpeed as Button).button_pressed = value

	# Nanogame Path.
	if config.has_section_key("nanogame", "nanogame_path"):
		var value: Variant =\
				config.get_value("nanogame", "nanogame_path", null)
		if value != null and value is String and not value.is_empty() and\
				_load_nanogame(value.path_join("nanogame.json")) == OK:
			($OpenNanogame as FileDialog).current_path = value

	# Debug Code.
	if config.has_section_key("nanogame", "code"):
		var value: Variant = config.get_value("nanogame", "code", null)
		if value != null and value is int and value >= 0:
			($BottomBar/HBoxContainer/Code as SpinBox).value = value
			_nanogame_player.debug_code = value

	# References.
	if config.has_section_key("hud", "references"):
		var value: Variant = config.get_value("hud", "references", null)
		if value != null and value is bool:
			(%ToggleReferences as Button).button_pressed = value

	# Auto Hide.
	if config.has_section_key("hud", "auto_hide"):
		var value: Variant = config.get_value("hud", "auto_hide", null)
		if value != null and value is bool:
			(%ToggleAutoHide as Button).button_pressed = value


func _save_session() -> void:
	if _is_saving_blocked:
		return

	var config := ConfigFile.new()
	config.set_value("status", "lock_timer", _nanogame_player.timer_lock)
	config.set_value("status", "difficulty", _nanogame_player.difficulty)
	config.set_value("status", "lock_difficulty",
			_nanogame_player.difficulty_lock)
	config.set_value("status", "speed", _nanogame_player.speed)
	config.set_value("status", "lock_speed", _nanogame_player.speed_lock)

	config.set_value("nanogame", "nanogame_path", _nanogame_path)
	config.set_value("nanogame", "code", _nanogame_player.debug_code)
	config.set_value(
			"hud", "references", (%ToggleReferences as Button).pressed)
	config.set_value("hud", "auto_hide", (%ToggleAutoHide as Button).pressed)

	var error_code: int = config.save(DEBUG_SESSION_PATH)
	if error_code != OK:
		push_error("Unable to save debug session. Error code: " +
				str(error_code))


func _set_joycursor_position(new_position: Vector2,\
		snapped_position:=Vector2.INF) -> void:
	_joycursor.position = new_position

	if not snapped_position.is_finite() or new_position == snapped_position:
		# Set the end of the line to be as close as possible to the beginning,
		# but not in the exact place, as that would make the line not be drawn.
		_snap_line.points[1] = Vector2(0.001, 0)
		_joycursor_snapped.hide()
	else:
		_snap_line.points[1] = snapped_position - _snap_line.global_position
		_joycursor_snapped.show()
		_joycursor_snapped.global_position = snapped_position


func _on_nanogame_player_stopped() -> void:
	set_process(false)

	($TimerReference as ColorRect).hide()
	($PauseReference as ColorRect).hide()
	($TouchNavigationReference as Panel).hide()
	($TouchActionReference as Panel).hide()

	_joycursor.hide()

	($KickoffDim as ColorRect).hide()

	($TopBar as PanelContainer).modulate.a = 1
	($BottomBar as PanelContainer).modulate.a = 1

	(%Timer as TextureRect).self_modulate = Color.WHITE
	_time.text = "0.0"

	(%Start as Button).icon = preload("_assets/start.svg")

	var pause := %Pause as Button
	if pause.button_pressed:
		pause.button_pressed = false
	pause.disabled = true

	(%OpenNanogameButton as Button).disabled = false
	(%ReloadNanogame as Button).disabled = false


func _on_nanogame_player_kickoff_started() -> void:
	($KickoffDim as ColorRect).show()

	_time.text = "%1.1f" % _nanogame_player.get_time()

	if not _nanogame_player.difficulty_lock:
		(%Difficulty as SpinBox).value = _nanogame_player.difficulty
	if not _nanogame_player.speed_lock:
		(%Speed as SpinBox).value = _nanogame_player.speed

	if _nanogame_player.joycursor_enabled:
		_set_joycursor_position(_nanogame_player.get_joycursor_position())


func _on_nanogame_player_timer_stopped() -> void:
	set_process(false)

	if _nanogame_player.joycursor_enabled:
		# Avoid corner cases where the joycursor may no be in the correct spot
		# (e.g. when snapping into something that will end the nanogame).
		_set_joycursor_position(_nanogame_player.get_joycursor_position())



func _on_bar_mouse_entered() -> void:
	if not _nanogame_player.is_playing():
		return

	($TopBar as PanelContainer).modulate.a = 1
	($BottomBar as PanelContainer).modulate.a = 1


func _on_bar_mouse_exited() -> void:
	if not _nanogame_player.is_playing():
		return

	if _is_auto_hiding:
		($TopBar as PanelContainer).modulate.a = 0
		($BottomBar as PanelContainer).modulate.a = 0
	else:
		($TopBar as PanelContainer).modulate.a = BARS_ALPHA_ON_PLAY
		($BottomBar as PanelContainer).modulate.a = BARS_ALPHA_ON_PLAY


func _on_lock_timer_toggled(button_pressed: bool) -> void:
	_nanogame_player.timer_lock = button_pressed

	_save_session()


func _on_difficulty_value_changed(value: float) -> void:
	_nanogame_player.difficulty = int(value)

	_save_session()


func _on_lock_difficulty_toggled(button_pressed: bool) -> void:
	_nanogame_player.difficulty_lock = button_pressed

	_save_session()


func _on_speed_value_changed(value: float) -> void:
	_nanogame_player.speed = int(value)

	_save_session()


func _on_lock_speed_toggled(button_pressed: bool) -> void:
	_nanogame_player.speed_lock = button_pressed

	_save_session()


func _on_start_pressed() -> void:
	if _nanogame_player.is_playing():
		_nanogame_player.stop()

		return

	_nanogame_player.start()

	# Stop if the nanogame player is not in a playable state, as it likely
	# errored out.
	if not _nanogame_player.is_playing():
		return

	_joycursor.visible = _nanogame_uses_joycursor and\
			GameManager.get_control_type() == GameManager.ControlTypes.JOYPAD

	($TopBar as PanelContainer).modulate.a = BARS_ALPHA_ON_PLAY
	($BottomBar as PanelContainer).modulate.a = BARS_ALPHA_ON_PLAY

	match _timer:
		Nanogame.Timers.OBJECTIVE:
			(%Timer as TextureRect).self_modulate = Color.ORANGE
		Nanogame.Timers.SURVIVAL:
			(%Timer as TextureRect).self_modulate = Color.GREEN

	(%Start as Button).icon = preload("_assets/stop.svg")

	if (%ToggleReferences as Button).button_pressed:
		_update_references()

	(%Pause as Button).disabled = false

	(%OpenNanogameButton as Button).disabled = true
	(%ReloadNanogame as Button).disabled = true


func _on_pause_toggled(button_pressed: bool) -> void:
	get_tree().paused = button_pressed


func _on_reload_nanogame_pressed() -> void:
	_load_nanogame(_nanogame_path.path_join("nanogame.json"))


func _on_code_value_changed(value: float) -> void:
	_nanogame_player.debug_code = int(value)

	_save_session()


func _on_toggle_references_toggled(_button_pressed: bool) -> void:
	if _nanogame_player.is_playing():
		_update_references()

	_save_session()


func _on_toggle_auto_hide_toggled(button_pressed: bool) -> void:
	_is_auto_hiding = button_pressed

	_save_session()


func _on_game_manager_control_type_changed() -> void:
	# Enable the joycursor only if the control type is joypad-only (without a
	# touchscreen available).
	_nanogame_player.joycursor_enabled =\
			GameManager.get_control_type() == GameManager.ControlTypes.JOYPAD

	_joycursor.visible =\
			_nanogame_uses_joycursor and _nanogame_player.joycursor_enabled
