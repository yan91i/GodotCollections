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


const START_QUANTITY = 6

const SCORE_BASE = 100

const TWEEN_SPEED_TRANSITION = 0.25
const TWEEN_SPEED_INTERPOLATION = 2

const ICON_PARTICLES_COLUMN_MAX = 16
const ICON_PARTICLES_NANOGAME_MAX = ICON_PARTICLES_COLUMN_MAX * 2
const ICON_PARTICLES_AMOUNT_MAX = 12
@warning_ignore("integer_division")
const ICON_PARTICLES_AMOUNT_INCREASE =\
		ICON_PARTICLES_NANOGAME_MAX / ICON_PARTICLES_AMOUNT_MAX

const ISSUE_TRACKER_LINK = GameManager.REPOSITORY_LINK + "/issues"

var _time_left := 0.0

var _score := 0

var _is_player_starting := false
var _was_player_error := false

var _is_user_new := false

var _button_focus_last: Control

@onready var _nanogame_player := $NanogamePlayer as NanogamePlayer
@onready var _nanogame_hud := $NanogameHUD as Control


# Add nanogames at the first playthrough here instead of in `_ready()` so it's
# done before the nanogame selection screen checks for them.
func _init() -> void:
	if not ArcadeManager.get_owned_official_nanogames().is_empty():
		return

	_is_user_new = true

	var nanogames: Array[Nanogame] = ArcadeManager.get_official_nanogames()
	nanogames.shuffle()

	for i: int in START_QUANTITY:
		ArcadeManager.own_official_nanogame(nanogames[i], false)
	ArcadeManager.sort_owned_official_nanogames()

	ArcadeManager.save_data()


func _ready() -> void:
	set_process(false)

	_notification(NOTIFICATION_THEME_CHANGED)

	_set_tickets_label(ArcadeManager.tickets)

	_update_icon_particles()

	# TODO: Uncomment once the feature is implemented.
#	if ArcadeManager.get_owned_official_nanogames().size() <\
#			ArcadeManager.THEMES_UNLOCK_NANOGAME_QUANTITY:
	if true:
		var customize := %Customize as Button
		customize.text = tr(&"Coming Soon")
		customize.disabled = true
		customize.theme_type_variation = &"ButtonLocked"

	if ArcadeManager.community_mode:
		var community_mode := $CommunityMode as CheckButton
		# Avoid shoving a popup in the player's face at the start.
		community_mode.set_block_signals(true)
		community_mode.button_pressed = true
		community_mode.set_block_signals(false)
	elif ArcadeManager.has_highlighted_owned_nanogames():
		(%Quickplay as Button).theme_type_variation =\
				&"ButtonPositiveHighlight"
		(%Collection as Button).theme_type_variation =\
				&"ButtonPositiveHighlight"

	if not (ArcadeManager.get_owned_official_nanogames()
			if not ArcadeManager.community_mode else
			ArcadeManager.get_community_nanogames()).is_empty():
		(%Quickplay as Button).disabled = false

	($SubmenuContext/Submenus/NanogameCollection as Control).\
			set_start_quantity(START_QUANTITY)

	($Tickets/Quantity as Label).text = str(ArcadeManager.tickets)

	if ArcadeManager.is_statistics_highlighted():
		var statistics_button := %Statistics as Button
		statistics_button.theme_type_variation = &"ButtonHighlight"

		statistics_button.pressed.connect(
			statistics_button.set_theme_type_variation.bind(""),
			CONNECT_ONE_SHOT)

	GameManager.faded_out.connect(_on_game_manager_faded_out)

	GameManager.control_type_changed.connect(
			_on_game_manager_control_type_changed)
	_on_game_manager_control_type_changed()

	GameManager.dim_changed.connect(($MenuNoise as AudioStreamPlayer).play)

	if _is_user_new:
		($TutorialOffer as Modal).closed.connect(
				(%Quickplay as Button).grab_focus, CONNECT_ONE_SHOT)
	else:
		GameManager.faded_out.connect((%Quickplay as Button).grab_focus)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and\
			_nanogame_player.is_playing() and ProjectSettings.get_setting(
					"game_settings/pause_focus_lost"):
				get_tree().paused = true


func _input(event: InputEvent) -> void:
	if _is_player_starting or not (get_viewport() as Window).has_focus():
		return

	if _nanogame_player.is_playing():
		if event.is_action_pressed(&"pause"):
			get_tree().paused = not get_tree().paused
	elif event.is_action_pressed(&"menu_back"):
		_hide_submenu()


func _process(_delta: float) -> void:
	var time_adjusted: float = snapped(_nanogame_player.get_time(), 0.1)
	if _time_left != time_adjusted:
		_time_left = time_adjusted

		_nanogame_hud.set_time(time_adjusted)

	if _nanogame_player.joycursor_enabled:
		_nanogame_hud.set_joycursor_position(
			_nanogame_player.get_joycursor_position(),
			_nanogame_player.get_joycursor_position_snapped())


func _show_submenu(index: int, title: String, is_showing_start:=false) -> void:
	if _is_user_new:
		return # Let the tutorial modal appear first.

	_button_focus_last = get_viewport().gui_get_focus_owner()

	($IconParticles as Control).hide()
	($MainMenu as VBoxContainer).hide()
	($Tickets as HBoxContainer).hide()
	($Tutorial as Button).hide()
	($CommunityMode as CheckButton).hide()

	($SubmenuContext/TopBar/Back as Button).grab_focus()
	($SubmenuContext/TopBar/Title as Label).text = title
	(%Start as Button).self_modulate.a = float(is_showing_start)
	# Make it ignore the mouse so the tooltip doesn't appear on hover.
	(%Start as Button).mouse_filter =\
			MOUSE_FILTER_STOP if is_showing_start else MOUSE_FILTER_IGNORE

	($SubmenuContext/Submenus as TabContainer).current_tab = index

	($SubmenuContext as VBoxContainer).show()

	($MenuNoise as AudioStreamPlayer).play()


func _hide_submenu(is_hiding_main_menu := false) -> void:
	if _is_player_starting:
		return

	if not is_hiding_main_menu and ($SubmenuContext as VBoxContainer).visible:
		if _button_focus_last != null:
			_button_focus_last.grab_focus()

		($MenuNoise as AudioStreamPlayer).play()

	($SubmenuContext as VBoxContainer).hide()
	(%Start as Button).disabled = true

	($IconParticles as Control).visible = not is_hiding_main_menu
	($MainMenu as VBoxContainer).visible = not is_hiding_main_menu
	($Tickets as HBoxContainer).visible = not is_hiding_main_menu
	($Tutorial as Button).visible = not is_hiding_main_menu
	($CommunityMode as CheckButton).visible = not is_hiding_main_menu


func _start_playing(nanogames: Array[Nanogame]) -> void:
	_is_player_starting = true

	_nanogame_player.add_nanogames(nanogames)
	_nanogame_player.start()

	_nanogame_hud.animate_player_start(_nanogame_player.get_current_nanogame())

	await _nanogame_hud.gates_changed
	_finish_player_start()


func _finish_player_start() -> void:
	_is_player_starting = false

	_hide_submenu(true)

	# Check if still playing at every stage, in case the player is stopped
	# between animation changes.
	if not _nanogame_player.is_playing():
		return

	($Background as TextureRect).hide()
	($Music as AudioStreamPlayer).stop()

	await _nanogame_hud.animation_finished
	if not _nanogame_player.is_playing():
		return

	_nanogame_hud.animate_nanogame_start(
			_nanogame_player.get_current_nanogame())

	await _nanogame_hud.gates_changed
	if _nanogame_player.is_playing():
		_nanogame_hud.set_time(_nanogame_player.get_time())

		_nanogame_player.resume_yield()


func _update_icon_particles() -> void:
	var particles_left := $IconParticles/Left as GPUParticles2D
	particles_left.hide() # Prevent the particles from flickering.
	particles_left.restart()
	var particles_right := $IconParticles/Anchor/Right as GPUParticles2D
	particles_right.hide() # Same as above.
	particles_right.restart()

	var nanogames: Array[Nanogame] = ArcadeManager.\
			get_owned_official_nanogames() if not ArcadeManager.community_mode\
			else ArcadeManager.get_community_nanogames()

	if nanogames.is_empty():
		particles_left.emitting = false
		particles_right.emitting = false

		return

	var nanogames_size_max: int =\
			mini(nanogames.size(), ICON_PARTICLES_NANOGAME_MAX)
	if nanogames_size_max > 1 and\
			(nanogames_size_max % 2 != 0 or nanogames_size_max % 3 != 0):
		nanogames_size_max -= 1

	var rows: int
	var columns: int
	if nanogames_size_max <= ICON_PARTICLES_COLUMN_MAX:
		rows = 1
		columns = nanogames_size_max
	else:
		rows = 2 if nanogames_size_max % 2 == 0 else 3
		@warning_ignore("integer_division")
		columns = nanogames_size_max / rows

	var sheet_image: Image = Image.create(int(Nanogame.ICON_SIZE.x * columns),
			int(Nanogame.ICON_SIZE.y * rows), false, Image.FORMAT_RGBA8)

	var offset := Vector2()
	var sheet_width_limit :=\
			int(Nanogame.ICON_SIZE.x * columns - Nanogame.ICON_SIZE.x)
	for i: int in nanogames_size_max:
		var icon: Image = (nanogames[i].get_icon()
				if nanogames[i].get_icon() != null else
				preload("res://places/_assets/unknown.svg")).get_image()
		sheet_image.blit_rect(
				icon, Rect2(Vector2.ZERO, Nanogame.ICON_SIZE), offset)

		if offset.x < sheet_width_limit:
			offset.x += Nanogame.ICON_SIZE.x
		else:
			offset.x = 0
			offset.y += Nanogame.ICON_SIZE.y

	var sheet_texture: ImageTexture =\
			ImageTexture.create_from_image(sheet_image)

	particles_left.texture = sheet_texture
	@warning_ignore("integer_division")
	particles_left.amount =\
			maxi(1, nanogames_size_max / ICON_PARTICLES_AMOUNT_INCREASE)
	particles_left.emitting = true
	particles_right.texture = sheet_texture
	particles_right.amount = particles_left.amount
	particles_right.emitting = true

	# Workaround a Godot bug that prevent those values from being set. Rarely
	# happens on PC, but frequently on mobile.
	await get_tree().process_frame
	(particles_left.material as CanvasItemMaterial).particles_anim_h_frames =\
			columns
	(particles_left.material as CanvasItemMaterial).particles_anim_v_frames =\
			rows

	particles_left.show()
	particles_right.show()


func _set_tickets_label(quantity: int) -> void:
	($Tickets/Quantity as Label).text = str(quantity)


func _on_nanogame_player_stopped() -> void:
	_nanogame_player.clear_nanogames()

	if not _was_player_error:
		await _nanogame_hud.gates_changed
	($Background as TextureRect).show()
	($IconParticles as Control).show()
	($MainMenu as VBoxContainer).show()
	($Tickets as HBoxContainer).show()
	($Tutorial as Button).show()
	($CommunityMode as CheckButton).show()

	if _button_focus_last != null:
		_button_focus_last.grab_focus()

	($Music as AudioStreamPlayer).play()

	if _was_player_error:
		_was_player_error = false

		_nanogame_hud.force_clear()

	if _nanogame_hud.practice_mode:
		await _nanogame_hud.animation_finished

		_nanogame_player.energy_lock = false
		_nanogame_hud.practice_mode = false

		return

	if not ArcadeManager.community_mode:
		@warning_ignore("integer_division")
		ArcadeManager.tickets += _score / SCORE_BASE

		if ArcadeManager.has_highlighted_owned_nanogames():
			($SubmenuContext/Submenus/NanogameCollection as Control).\
					clear_selected_highlight()
		if not ArcadeManager.has_highlighted_owned_nanogames():
			(%Quickplay as Button).theme_type_variation = &"ButtonPositive"
			(%Collection as Button).theme_type_variation = &"ButtonPositive"

	if _score > 0:
		ArcadeManager.claim_best_score(_score)
	ArcadeManager.break_win_streak()

	ArcadeManager.save_data()

	($SubmenuContext/Submenus/Statistics as Control).update_played_nanogames()

	var statistics_button := %Statistics as Button
	if ArcadeManager.is_statistics_highlighted() and\
			not statistics_button.pressed.is_connected(
					statistics_button.set_theme_type_variation):
		statistics_button.theme_type_variation = &"ButtonHighlight"

		statistics_button.pressed.connect(
				statistics_button.set_theme_type_variation.bind(""),
				CONNECT_ONE_SHOT)

	_score = 0

	if ArcadeManager.community_mode:
		return

	var tickets_old := int(($Tickets/Quantity as Label).text)
	if ArcadeManager.tickets == tickets_old:
		return

	await _nanogame_hud.animation_finished

	var gain := $Tickets/Quantity/Gain as Label
	gain.text = "+ " + str(ArcadeManager.tickets - tickets_old)

	var tween: Tween = create_tween().set_parallel()
	tween.tween_property($Tickets/Icon as TextureRect, ^"self_modulate",
			Color.LIME_GREEN, TWEEN_SPEED_TRANSITION)

	tween.tween_method(_set_tickets_label, tickets_old, ArcadeManager.tickets,
			TWEEN_SPEED_INTERPOLATION)
	tween.tween_property(gain, ^"self_modulate:a", 1, TWEEN_SPEED_TRANSITION)

	tween.chain().tween_property($Tickets/Icon as TextureRect, ^"self_modulate",
			Color.WHITE, TWEEN_SPEED_TRANSITION)
	tween.tween_property(gain, ^"self_modulate:a", 0, TWEEN_SPEED_TRANSITION)


func _on_nanogame_player_timer_stopped() -> void:
	set_process(false)

	if _nanogame_player.joycursor_enabled:
		# Avoid corner cases where the joycursor may no be in the correct spot
		# (e.g. when snapping into something that will end the nanogame).
		_nanogame_hud.set_joycursor_position(
				_nanogame_player.get_joycursor_position())


func _on_nanogame_player_nanogame_won() -> void:
	if not _nanogame_hud.practice_mode:
		_score += SCORE_BASE * _nanogame_player.difficulty *\
				_nanogame_player.speed

		ArcadeManager.add_nanogame_win()

	_nanogame_hud.animate_nanogame_won(_nanogame_player.get_next_nanogame(),
			_nanogame_player.speed == NanogamePlayer.SPEED_MAX and\
			_nanogame_player.difficulty != NanogamePlayer.DIFFICULTY_MAX)


func _on_nanogame_player_nanogame_lost() -> void:
	if not _nanogame_hud.practice_mode:
		ArcadeManager.add_nanogame_loss()

	_nanogame_hud.animate_nanogame_lost(_nanogame_player.get_next_nanogame()
			if _nanogame_player.energy - NanogamePlayer.ENERGY_LOSS > 0 else
			null)


func _on_nanogame_player_nanogame_freed() -> void:
	_nanogame_hud.set_difficulty(_nanogame_player.difficulty)
	_nanogame_hud.set_speed(_nanogame_player.speed)

	if not _nanogame_hud.practice_mode:
		_nanogame_hud.set_energy(_nanogame_player.energy)
		_nanogame_hud.set_score(_score)


func _on_nanogame_player_next_nanogame_yielded() -> void:
	_nanogame_hud.set_joycursor_position(
			_nanogame_player.get_joycursor_position())

	# Avoid clashing with the player starting animation.
	if _is_player_starting:
		return

	await _nanogame_hud.gates_changed
	# Check if still playing, in case the player is stopped before the gates
	# actually change.
	if _nanogame_player.is_playing():
		_nanogame_hud.set_time(_nanogame_player.get_time())

		_nanogame_player.resume_yield()


func _on_nanogame_player_free_nanogame_yielded() -> void:
	await _nanogame_hud.gates_changed
	# Check if still playing, in case the player is stopped before the gates
	# actually change.
	if _nanogame_player.is_playing():
		_nanogame_player.resume_yield()


func _on_nanogame_player_error_occured(nanogame: Nanogame) -> void:
	_was_player_error = true

	var _nanogame_error_text := $NanogameError/RichTextLabel as RichTextLabel
	_nanogame_error_text.text = tr(&"An error occured while attempting to " +
			&'load the nanogame "%s", likely caused by it not being ' +
			&"properly configured.") % nanogame.get_nanogame_name(true)

	if not ArcadeManager.community_mode:
		_nanogame_error_text.text += tr(&"\n\nPlease open a bug report in " +
				&"the [url=%s]issue tracker[/url].") % ISSUE_TRACKER_LINK
	else:
		_nanogame_error_text.text += tr(&"\n\n[b]Do not open a bug report " +
				&"in the issue tracker[/b], this is a community nanogame, " +
				&"so the bug should be reported to its creator(s). " +
				&'Check the nanogame\'s "About" information.')

	# Delay popup to ensure the close button grabs the focus.
	await get_tree().process_frame
	($NanogameError as Modal).popup_centered()


func _on_quickplay_pressed() -> void:
	_button_focus_last = %Quickplay as Button

	var nanogames_available: Array[Nanogame] = ArcadeManager.\
			get_owned_official_nanogames() if not ArcadeManager.community_mode\
			else ArcadeManager.get_community_nanogames()
	var nanogames_highlighted: Array[Nanogame] = []
	var nanogames: Array[Nanogame] = []

	if not ArcadeManager.community_mode and\
			ArcadeManager.has_highlighted_owned_nanogames():
		# Prioritize unplayed nanogames.
		for i: Nanogame in nanogames_available:
			if not i.has_meta(&"highlight"):
				break

			nanogames_highlighted.append(i)

		if not nanogames_highlighted.is_empty():
			nanogames_highlighted.shuffle()

			for i: Nanogame in nanogames_highlighted:
				nanogames.append(i)
				i.remove_meta(&"highlight")

				nanogames_available.erase(i)

			ArcadeManager.sort_owned_official_nanogames()
			($SubmenuContext/Submenus/NanogameCollection as Control).\
					update_filtered_nanogames()

	if nanogames_highlighted.size() < START_QUANTITY:
		nanogames_available.shuffle()
		for i: int in min(nanogames_available.size(),
				START_QUANTITY - nanogames_highlighted.size()):
			nanogames.append(nanogames_available.pop_back())

	_start_playing(nanogames)


func _on_back_lobby_pressed() -> void:
	if _is_user_new:
		return # Let the tutorial modal appear first.

	GameManager.switch_main_scene("res://places/lobby/lobby.tscn")


func _on_start_pressed() -> void:
	_start_playing(($SubmenuContext/Submenus as TabContainer).
			get_current_tab_control().get_nanogames_selected())


func _on_nanogame_collection_practice_mode_started(
		nanogame: Nanogame, difficulty: int) -> void:
	_is_player_starting = true

	_nanogame_player.difficulty = difficulty
	_nanogame_player.energy_lock = true
	_nanogame_player.add_nanogames([nanogame])
	_nanogame_player.start()

	_nanogame_hud.practice_mode = true
	_nanogame_hud.animate_player_start(nanogame)
	_nanogame_hud.set_difficulty(difficulty)

	await _nanogame_hud.gates_changed
	_nanogame_hud.update_status_labels()

	_finish_player_start()


func _on_community_mode_toggled(is_enabled: bool) -> void:
	if is_enabled and ProjectSettings.get_setting(
			"game_settings/show_community_warning"):
		($CommunityWarning as Modal).popup_centered()

	ArcadeManager.community_mode = is_enabled
	ArcadeManager.save_data()

	(%Quickplay as Button).disabled = (ArcadeManager.
			get_owned_official_nanogames() if not ArcadeManager.community_mode
			else ArcadeManager.get_community_nanogames()).is_empty()

	var button_variation:= &"ButtonPositiveHighlight"\
			if not ArcadeManager.community_mode and ArcadeManager.\
			has_highlighted_owned_nanogames() else &"ButtonPositive"
	(%Collection as Button).theme_type_variation = button_variation

	### Icon Particles Switch Fade ###

	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(
			$IconParticles as Control, ^"modulate:a", 0, TWEEN_SPEED_TRANSITION)
	tween.chain().tween_callback(_update_icon_particles)
	tween.tween_callback(
			($IconParticles as Control).set_modulate.bind(Color.WHITE))


func _on_nanogame_error_meta_clicked(meta: String) -> void:
	OS.shell_open(meta)


func _on_game_manager_faded_out() -> void:
	if _is_user_new:
		_is_user_new = false

		($TutorialOffer as Modal).popup_centered()


func _on_game_manager_control_type_changed() -> void:
	GameManager.update_theme_focus_style(theme)

	# Enable the joycursor only if the control type is joypad-only (without a
	# touchscreen available).
	_nanogame_player.joycursor_enabled =\
			GameManager.get_control_type() == GameManager.ControlTypes.JOYPAD
