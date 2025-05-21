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

extends Control


# Emitted by a signal from the "Settings" button.
@warning_ignore("unused_signal")
signal settings_requested

signal stop_requested

# Emitted from the gates animations.
@warning_ignore("unused_signal")
signal gates_changed

signal animation_finished

const TOUCH_CONTROLS_MARGIN = 112
const TOUCH_NAVIGATION_RADIUS = 140
const TOUCH_NAVIGATION_RADIUS_PRESSED = 200

const STATUS_TWEEN_SPEED_BASE = 0.25
const STATUS_TWEEN_SPEED_MAX = 1

var practice_mode := false: set = set_practice_mode

var _difficulty := 0
var _speed := 0
var _energy := 0
var _score := 0

var _has_joycursor_moved := false

var _messages := {}

var _tweens: Array[Tween] = []

var _nanogame: Nanogame

# Stored, as the methods that set their values can be called several times.
@onready var _time := $Timer/HBoxContainer/Time as Label
@onready var _joycursor := $Joycursor as Sprite2D
@onready var _snap_line := $Joycursor/CanvasGroup/SnapLine as Line2D
@onready var _joycursor_snapped :=\
		$Joycursor/CanvasGroup/JoycursorSnapped as Sprite2D


func _ready() -> void:
	var file := FileAccess.open(
			"res://places/arcade_machine/nanogame_hud/messages.json",
			FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_as_text())
	file.close()

	_messages = json.data

	GameManager.control_type_changed.connect(_update_input_elements)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED:
			($PauseScreen as ColorRect).show()
			($PauseScreen/VBoxContainer/Menu/Continue as Button).grab_focus()

			if _nanogame == null:
				return

			### Pause Screen Nanogame Information ###

			($PauseScreen/VBoxContainer/NanogameInfo/Icon as TextureRect).\
					texture = _nanogame.get_icon()\
					if _nanogame.get_icon() != null else\
					preload("res://places/_assets/unknown.svg")

			($PauseScreen/VBoxContainer/NanogameInfo/Name as Label).text =\
					_nanogame.get_nanogame_name()\
					if not _nanogame.get_nanogame_name().is_empty() else\
					tr("[No Name]")
			($PauseScreen/VBoxContainer/NanogameInfo/Name as Label).\
					self_modulate = Color.WHITE\
							if not _nanogame.get_nanogame_name().is_empty()\
							else Color.SILVER

			($PauseScreen/VBoxContainer/NanogameInfo/Kickoff as Label).text =\
					_nanogame.get_kickoff()\
					if not _nanogame.get_kickoff().is_empty() else\
					tr("[No Kickoff]")
			($PauseScreen/VBoxContainer/NanogameInfo/Kickoff as Label).\
					self_modulate = Color.WHITE\
							if not _nanogame.get_nanogame_name().is_empty()\
							else Color.SILVER

			var input_icon: CompressedTexture2D
			match _nanogame.get_input():
				Nanogame.Inputs.NAVIGATION:
					input_icon = preload("res://places/_assets/" +\
							"input_types_small/navigation.svg")
				Nanogame.Inputs.ACTION:
					input_icon = preload("res://places/_assets/" +\
							"input_types_small/action.svg")
				Nanogame.Inputs.NAVIGATION_ACTION:
					input_icon = preload("res://places/_assets/" +\
							"input_types_small/navigation_action.svg")
				Nanogame.Inputs.DRAG_DROP:
					input_icon = preload("res://places/_assets/" +\
							"input_types_small/drag_drop.svg")

			($PauseScreen/VBoxContainer/NanogameInfo/Input as TextureRect).\
					texture = input_icon
			($PauseScreen/VBoxContainer/NanogameInfo/Input as TextureRect).\
					tooltip_text = tr("Input: %s") %\
					tr(Nanogame.get_input_name(_nanogame.get_input()))

			($PauseScreen/VBoxContainer/NanogameDescription as RichTextLabel).\
					text = _nanogame.get_description()\
					if not _nanogame.get_description().is_empty() else\
					tr("[No Description]")
			($PauseScreen/VBoxContainer/NanogameDescription as RichTextLabel).\
					self_modulate = Color("white"
							if not _nanogame.get_description().is_empty() else
							"silver")
		NOTIFICATION_UNPAUSED:
			# Check if the touch buttons settings where modified ot not.
			_update_input_elements()

			($PauseScreen as ColorRect).hide()
		NOTIFICATION_TRANSLATION_CHANGED:
			if _nanogame == null:
				return

			($PauseScreen/VBoxContainer/NanogameInfo/Input as TextureRect).\
					tooltip_text = tr("Input: %s") %\
					tr(Nanogame.get_input_name(_nanogame.get_input()))


func animate_player_start(starting_nanogame: Nanogame) -> void:
	_nanogame = starting_nanogame

	set_speed(NanogamePlayer.SPEED_MIN)
	set_difficulty(NanogamePlayer.DIFFICULTY_MIN)
	set_energy(NanogamePlayer.ENERGY_MAX)
	set_score(0)

	_set_speed_label(_speed)
	_set_difficulty_label(_difficulty)
	_set_energy_label(_energy)
	_set_score_label(0)

	(%DifficultyIcon as TextureRect).self_modulate = Color.WHITE
	(%SpeedIcon as TextureRect).self_modulate = Color.WHITE
	(%EnergyIcon as TextureRect).self_modulate = Color.GOLD

	(%Icon as TextureRect).texture = preload("_assets/starting.svg")

	(%State as Label).text = tr("Starting")
	(%Message as Label).text =\
			_messages["start"][randi() % _messages["start"].size()]

	($Pause as Button).visible =\
			GameManager.get_control_type() != GameManager.ControlTypes.JOYPAD

	(%DifficultyIconPause as TextureRect).self_modulate = Color.WHITE
	($PauseScreen/VBoxContainer/Status/SpeedIcon as TextureRect).\
			self_modulate = Color.WHITE
	(%EnergyIconPause as TextureRect).self_modulate = Color.GOLD

	($HUDAnimations as AnimationPlayer).play("close_gates")
	($HUDAnimations as AnimationPlayer).queue("player_start")


func animate_nanogame_start(nanogame: Nanogame) -> void:
	# Remove the color modulation if the previous nanogame was nameless.
	if _nanogame != null and _nanogame.get_nanogame_name().is_empty():
		(%Message as Label).self_modulate = Color.WHITE

	_nanogame = nanogame

	($HUDAnimations as AnimationPlayer).queue("nanogame_start")
	($HUDAnimations as AnimationPlayer).queue("open_gates")


func animate_nanogame_won(next_nanogame: Nanogame, is_harder:=false) -> void:
	(%Icon as TextureRect).texture = preload("_assets/victory.svg")

	(%State as Label).text = tr("Victory!")
	if not is_harder:
		(%Message as Label).text =\
				_messages["win"][randi() % _messages["win"].size()]

		match _difficulty:
			1:
				($Music as AudioStreamPlayer).stream =\
						preload("_assets/nanogame_won_1.ogg")
			2:
				($Music as AudioStreamPlayer).stream =\
						preload("_assets/nanogame_won_2.ogg")
			3:
				($Music as AudioStreamPlayer).stream =\
						preload("_assets/nanogame_won_3.ogg")
	else:
		(%Message as Label).text =\
				_messages["winHarder"][randi() % _messages["winHarder"].size()]

		match _difficulty:
			1:
				($Music as AudioStreamPlayer).stream =\
						preload("_assets/difficulty_increased_1.ogg")
			2:
				($Music as AudioStreamPlayer).stream =\
						preload("_assets/difficulty_increased_2.ogg")

	($HUDAnimations as AnimationPlayer).play("close_gates")
	($HUDAnimations as AnimationPlayer).queue("nanogame_result")

	animate_nanogame_start(next_nanogame)


func animate_nanogame_lost(next_nanogame: Nanogame) -> void:
	(%Icon as TextureRect).texture = preload("_assets/failure.svg")

	(%State as Label).text = tr("Failure!")
	(%Message as Label).text =\
			_messages["lose"][randi() % _messages["lose"].size()]

	match _difficulty:
		1:
			($Music as AudioStreamPlayer).stream =\
					preload("_assets/nanogame_lost_1.ogg")
		2:
			($Music as AudioStreamPlayer).stream =\
					preload("_assets/nanogame_lost_2.ogg")
		3:
			($Music as AudioStreamPlayer).stream =\
					preload("_assets/nanogame_lost_3.ogg")

	($HUDAnimations as AnimationPlayer).play("close_gates")
	($HUDAnimations as AnimationPlayer).queue("nanogame_result")

	if next_nanogame != null:
		animate_nanogame_start(next_nanogame)
	else:
		($HUDAnimations as AnimationPlayer).queue("player_stop")
		($HUDAnimations as AnimationPlayer).queue("open_gates")


func hide_kickoff() -> void:
	if OS.has_feature("mobile"):
		# Check if any `TouchScreenButton`s were being held before the kickoff
		# finished and trigger their actions manually.
		for i: Node in ($TouchNavigation as TextureRect).get_children() +\
				[$TouchAction/Action as TouchScreenButton]:
			if i.is_pressed():
				var input := InputEventAction.new()
				input.action = i.action
				input.pressed = true
				Input.parse_input_event(input)

	($HUDAnimations as AnimationPlayer).play("hide_kickoff")


func update_status_labels() -> void:
	for i: Tween in _tweens:
		i.kill()
	_tweens.clear()

	### Difficulty ###

	var difficulty_old := int(($GateTop/Status/Difficulty as Label).text)
	if _difficulty != difficulty_old:
		var tween: Tween = create_tween()
		_tweens.append(tween)

		var difficulty_icon := %DifficultyIcon as TextureRect
		tween.tween_property(difficulty_icon, "self_modulate",
				Color.DODGER_BLUE, STATUS_TWEEN_SPEED_BASE)

		tween.tween_method(_set_difficulty_label, difficulty_old, _difficulty,
				minf(STATUS_TWEEN_SPEED_MAX, STATUS_TWEEN_SPEED_BASE *
						absi(difficulty_old - _difficulty)))

		tween.tween_property(difficulty_icon, "self_modulate",
				Color.WHITE if _difficulty < NanogamePlayer.DIFFICULTY_MAX
				else Color.GOLD, STATUS_TWEEN_SPEED_BASE)

		(%DifficultyIconPause as TextureRect).self_modulate = Color.WHITE\
				if _difficulty < NanogamePlayer.DIFFICULTY_MAX else Color.GOLD


	### Speed ###

	var speed_old := int(($GateTop/Status/Speed as Label).text)
	if _speed != speed_old:
		var tween: Tween = create_tween()
		_tweens.append(tween)

		tween.tween_property(%SpeedIcon as TextureRect, "self_modulate",
				Color.DODGER_BLUE, STATUS_TWEEN_SPEED_BASE)

		tween.tween_method(_set_speed_label, speed_old, _speed,
				minf(STATUS_TWEEN_SPEED_MAX, STATUS_TWEEN_SPEED_BASE *
						absi(speed_old - _speed)))

		tween.tween_property(%SpeedIcon as TextureRect, "self_modulate",
				Color.WHITE if _speed < NanogamePlayer.SPEED_MAX\
						else Color.GOLD, STATUS_TWEEN_SPEED_BASE)

		($PauseScreen/VBoxContainer/Status/SpeedIcon as TextureRect).\
				self_modulate = Color.WHITE\
						if _speed < NanogamePlayer.SPEED_MAX else Color.GOLD

		# Visually notify that the difficulty can increase if speed is at max
		# but the difficulty isn't, or remove it if it just increased.
		if  _difficulty < NanogamePlayer.DIFFICULTY_MAX and\
				(_speed == NanogamePlayer.SPEED_MAX or
						speed_old == NanogamePlayer.SPEED_MAX):
			var is_speed_max: bool = _speed == NanogamePlayer.SPEED_MAX
			tween.tween_property(%DifficultyIcon as TextureRect,
					"self_modulate", Color.PURPLE if is_speed_max
							else Color.WHITE, STATUS_TWEEN_SPEED_BASE)

			(%DifficultyIconPause as TextureRect).self_modulate =\
					Color.PURPLE if is_speed_max else Color.WHITE


	if not practice_mode:
		### Energy ###

		var energy_old := int((%Energy as Label).text)
		if _energy != energy_old:
			var tween: Tween = create_tween()
			_tweens.append(tween)

			tween.tween_property(%EnergyIcon as TextureRect, "self_modulate",
					Color.LIME_GREEN if _energy > energy_old else Color.CRIMSON,
					STATUS_TWEEN_SPEED_BASE)

			tween.tween_method(_set_energy_label, energy_old, _energy,
					minf(STATUS_TWEEN_SPEED_MAX, STATUS_TWEEN_SPEED_BASE *
							absi(energy_old - _energy)))

			var color: Color
			if _energy <= NanogamePlayer.ENERGY_LOSS:
				color = Color.FIREBRICK
			elif _energy == NanogamePlayer.ENERGY_MAX:
				color = Color.GOLD
			else:
				color = Color.WHITE
			tween.tween_property(%EnergyIcon as TextureRect, "self_modulate",
					color, STATUS_TWEEN_SPEED_BASE)

			(%EnergyIconPause as TextureRect).self_modulate = color


		### Score ###

		var score_old := int((%ScoreValue as Label).text)
		var score_gain: int = _score - score_old
		if score_gain > 0:
			var score_gain_node := $GateBottom/VBoxContainer/ScoreGain as Label
			score_gain_node.text = "+ " + str(score_gain)

			var tween: Tween = create_tween()
			_tweens.append(tween)

			tween.tween_property(score_gain_node, "self_modulate:a", 1,
					STATUS_TWEEN_SPEED_BASE)

			tween.tween_method(_set_score_label, score_old, _score,
					STATUS_TWEEN_SPEED_MAX)

			tween.tween_property(score_gain_node, "self_modulate:a", 0,
					STATUS_TWEEN_SPEED_BASE)


func force_clear() -> void:
	# Remove the color modulation if the previous nanogame was nameless.
	if _nanogame != null and _nanogame.get_nanogame_name().is_empty():
		(%Message as Label).self_modulate = Color.WHITE

	_nanogame = null

	($KickoffScreen as ColorRect).modulate.a = 0

	($Timer as PanelContainer).hide()

	($TouchNavigation as Control).hide()
	($TouchAction as Control).hide()

	($Pause as Button).self_modulate.a = 0
	($Pause as Button).hide()


func set_practice_mode(is_enabled: bool) -> void:
	practice_mode = is_enabled

	($GateTop/Status/Space2 as Control).visible = not is_enabled
	(%EnergyIcon as TextureRect).visible = not is_enabled
	(%Energy as Label).visible = not is_enabled
	($GateBottom/VBoxContainer/ScoreLabel as Label).visible = not is_enabled
	(%ScoreValue as Label).visible = not is_enabled

	($PauseScreen/VBoxContainer/Status/Space2 as Control).visible =\
			not is_enabled
	(%EnergyIconPause as TextureRect).visible = not is_enabled
	($PauseScreen/VBoxContainer/Status/Energy as Label).visible =\
			not is_enabled
	($PauseScreen/VBoxContainer/Score as VBoxContainer).visible =\
			not is_enabled


func set_time(time: float) -> void:
	_time.text = "%1.1f" % time


func set_difficulty(value: int) -> void:
	_difficulty = value
	($PauseScreen/VBoxContainer/Status/Difficulty as Label).text = str(value)


func set_speed(value: int) -> void:
	_speed = value
	($PauseScreen/VBoxContainer/Status/Speed as Label).text = str(value)


func set_energy(value: int) -> void:
	_energy = value
	($PauseScreen/VBoxContainer/Status/Energy as Label).text = str(value)


func set_score(value: int) -> void:
	_score = value
	($PauseScreen/VBoxContainer/Score/Value as Label).text = "%06d" % value


func set_joycursor_position(new_position: Vector2,\
		snapped_position:=Vector2.INF) -> void:
	if not _has_joycursor_moved:
		_has_joycursor_moved = true

		($JoycursorBlink as AnimationPlayer).play("stop")

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


func _update_input_elements() -> void:
	var control_type: int = GameManager.get_control_type()

	($Pause as Button).visible =\
			control_type != GameManager.ControlTypes.JOYPAD

	if _nanogame == null:
		return

	var touch_navigation := $TouchNavigation as TextureRect
	touch_navigation.hide()
	var touch_action := $TouchAction as Control
	touch_action.hide()

	var nanogame_input: int = _nanogame.get_input()

	_joycursor.visible = nanogame_input == Nanogame.Inputs.DRAG_DROP and\
			control_type == GameManager.ControlTypes.JOYPAD
	if _joycursor.visible:
		_has_joycursor_moved = false

		($JoycursorBlink as AnimationPlayer).play("blink")
	else:
		($JoycursorBlink as AnimationPlayer).stop()

	if nanogame_input == Nanogame.Inputs.DRAG_DROP or\
			control_type != GameManager.ControlTypes.TOUCH:
		return

	if ProjectSettings.get_setting("game_settings/switch_touch_controls"):
		touch_navigation.anchor_left = ANCHOR_END
		touch_navigation.position.x = get_viewport_rect().size.x -\
				TOUCH_CONTROLS_MARGIN - touch_navigation.texture.get_width()

		touch_action.anchor_right = ANCHOR_BEGIN
		touch_action.position.x = TOUCH_CONTROLS_MARGIN
	else:
		touch_navigation.anchor_right = ANCHOR_BEGIN
		touch_navigation.position.x = TOUCH_CONTROLS_MARGIN

		touch_action.anchor_left = ANCHOR_END
		touch_action.position.x = get_viewport_rect().size.x -\
				TOUCH_CONTROLS_MARGIN - ($TouchAction/Action as
						TouchScreenButton).texture_normal.get_width()

	match nanogame_input:
		Nanogame.Inputs.NAVIGATION:
			touch_navigation.show()
		Nanogame.Inputs.ACTION:
			touch_action.show()
		Nanogame.Inputs.NAVIGATION_ACTION:
			touch_navigation.show()
			touch_action.show()

	if nanogame_input == Nanogame.Inputs.NAVIGATION or\
			nanogame_input == Nanogame.Inputs.NAVIGATION_ACTION:
		match _nanogame.get_input_modifier():
			Nanogame.InputModifiers.NONE:
				touch_navigation.texture =\
						preload("_assets/input_elements/navigation_full.svg")
			Nanogame.InputModifiers.HORIZONTAL:
				touch_navigation.texture = preload(
						"_assets/input_elements/navigation_horizontal.svg")
			Nanogame.InputModifiers.VERTICAL:
				touch_navigation.texture = preload(
						"_assets/input_elements/navigation_vertical.svg")


func _prepare_nanogame_start() -> void:
	_update_input_elements()

	### Main Information ###

	var nanogame_icon: CompressedTexture2D = _nanogame.get_icon()
	(%Icon as TextureRect).texture = nanogame_icon if nanogame_icon != null\
			else preload("res://places/_assets/unknown.svg")

	(%State as Label).text = tr("Up Next:")

	(%Message as Label).text = _nanogame.get_nanogame_name()\
			if not _nanogame.get_nanogame_name().is_empty() else\
			tr("[No Name]")
	if _nanogame.get_nanogame_name().is_empty():
		(%Message as Label).self_modulate = Color.SILVER


	### Kickoff ###

	var input_icon: CompressedTexture2D
	match _nanogame.get_input():
		Nanogame.Inputs.NAVIGATION:
			input_icon = preload("_assets/input_types_big/navigation.svg")
		Nanogame.Inputs.ACTION:
			input_icon = preload("_assets/input_types_big/action.svg")
		Nanogame.Inputs.NAVIGATION_ACTION:
			input_icon =\
					preload("_assets/input_types_big/navigation_action.svg")
		Nanogame.Inputs.DRAG_DROP:
			input_icon = preload("_assets/input_types_big/drag_drop.svg")
	($KickoffScreen/VBoxContainer/Input as TextureRect).texture = input_icon

	($KickoffScreen/VBoxContainer/Kickoff as Label).text =\
			_nanogame.get_kickoff() if not _nanogame.get_kickoff().is_empty()\
			else tr("[No Kickoff]")
	($KickoffScreen/VBoxContainer/Kickoff as Label).self_modulate =\
			Color.WHITE if not _nanogame.get_kickoff().is_empty()\
			else Color.SILVER


	### Timer Icon ###

	var timer_icon: CompressedTexture2D
	match _nanogame.get_timer():
		Nanogame.Timers.OBJECTIVE:
			timer_icon = preload("res://places/_assets/timer_objective.svg")
		Nanogame.Timers.SURVIVAL:
			timer_icon = preload("res://places/_assets/timer_survival.svg")

	($Timer/HBoxContainer/Type as TextureRect).texture = timer_icon
	($Timer/HBoxContainer/Type as TextureRect).tooltip_text =\
			tr("Timer:") + " " + Nanogame.get_timer_name(_nanogame.get_timer())


	### Music ###

	match _difficulty:
		1:
			($Music as AudioStreamPlayer).stream =\
					preload("_assets/nanogame_start_1.ogg")
		2:
			($Music as AudioStreamPlayer).stream =\
					preload("_assets/nanogame_start_2.ogg")
		3:
			($Music as AudioStreamPlayer).stream =\
					preload("_assets/nanogame_start_3.ogg")
	($Music as AudioStreamPlayer).play()


func _prepare_player_stop() -> void:
	# Remove the color modulation if the previous nanogame was nameless.
	if _nanogame != null and _nanogame.get_nanogame_name().is_empty():
		(%Message as Label).self_modulate = Color.WHITE

	_nanogame = null

	(%Icon as TextureRect).texture = preload("_assets/stopping.svg")

	(%State as Label).text = tr("Game Over")
	(%Message as Label).text =\
			_messages["stop"][randi() % _messages["stop"].size()]

	match _difficulty:
		1:
			($Music as AudioStreamPlayer).stream =\
					preload("_assets/player_stop_1.ogg")
		2:
			($Music as AudioStreamPlayer).stream =\
					preload("_assets/player_stop_2.ogg")
		3:
			($Music as AudioStreamPlayer).stream =\
					preload("_assets/player_stop_3.ogg")
	($Music as AudioStreamPlayer).play()


func _set_speed_label(value: int) -> void:
	($GateTop/Status/Speed as Label).text = str(value)


func _set_difficulty_label(value: int) -> void:
	($GateTop/Status/Difficulty as Label).text = str(value)


func _set_energy_label(value: int) -> void:
	(%Energy as Label).text = str(value)


func _set_score_label(value: int) -> void:
	(%ScoreValue as Label).text = "%06d" % value


func _on_expand_touch_pressed() -> void:
	($TouchNavigation/Up as TouchScreenButton).show()
	($TouchNavigation/Left as TouchScreenButton).show()
	($TouchNavigation/Right as TouchScreenButton).show()
	($TouchNavigation/Down as TouchScreenButton).show()

	(($TouchNavigation/ExpandTouch as TouchScreenButton).
			shape as CircleShape2D).radius = TOUCH_NAVIGATION_RADIUS_PRESSED


func _on_expand_touch_released() -> void:
	($TouchNavigation/Up as TouchScreenButton).hide()
	($TouchNavigation/Left as TouchScreenButton).hide()
	($TouchNavigation/Right as TouchScreenButton).hide()
	($TouchNavigation/Down as TouchScreenButton).hide()

	(($TouchNavigation/ExpandTouch as TouchScreenButton).
			shape as CircleShape2D).radius = TOUCH_NAVIGATION_RADIUS


func _on_pause_changed(is_paused: bool) -> void:
	get_tree().paused = is_paused


func _on_stop_pressed() -> void:
	get_tree().paused = false

	($KickoffScreen as ColorRect).modulate.a = 0

	($Pause as Button).hide()

	($HUDAnimations as AnimationPlayer).play("player_stop")
	($HUDAnimations as AnimationPlayer).queue("open_gates")

	stop_requested.emit()


func _on_hud_animations_animation_finished() -> void:
	animation_finished.emit()
