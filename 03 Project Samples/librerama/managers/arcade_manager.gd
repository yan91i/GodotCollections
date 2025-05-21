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

extends Node


signal community_mode_changed
signal best_scores_changed

signal tickets_removed

const SAVE_PATH = "user://save.ini"

const OFFICIAL_NANOGAMES_PATH = "res://nanogames/"
const COMMUNITY_NANOGAMES_PATH_RES = "res://community_nanogames/"
const COMMUNITY_NANOGAMES_PATH_USER = "user://community_nanogames/"

const BEST_SCORES_SIZE_MAX = 6

const PRIZES_UNLOCK_NANOGAME_QUANTITY = 18
const THEMES_UNLOCK_NANOGAME_QUANTITY = PRIZES_UNLOCK_NANOGAME_QUANTITY * 2

var tickets := 0: set = set_tickets

var community_mode := false: set = set_community_mode

var _nanogames_official: Array[Nanogame] = []
var _nanogames_community: Array[Nanogame] = []

var _nanogames_official_owned: Array[Nanogame] = []

var _best_scores: Array[int] = []
var _best_scores_highlighted: Array[bool] = []

var _nanogames_won_count := 0
var _nanogames_lost_count := 0

var _win_streak_current := 0
var _win_streak_best := 0
var _win_streak_best_highlighted := false


func _init() -> void:
	for i: int in BEST_SCORES_SIZE_MAX:
		_best_scores_highlighted.append(false)

	### Load Official Nanogames ###

	var dir: DirAccess = DirAccess.open(OFFICIAL_NANOGAMES_PATH)
	for i: String in dir.get_directories():
		var nanogame := Nanogame.new()
		# Don't check if an official nanogame is valid, as it wastes time, and
		# if happens to not be, it's better to just crash the game to make
		# itself obvious.
		nanogame.load_data(OFFICIAL_NANOGAMES_PATH.path_join(i), true)
		_nanogames_official.append(nanogame)


	### Load Community Nanogames ###

	if not DirAccess.dir_exists_absolute(COMMUNITY_NANOGAMES_PATH_USER):
		@warning_ignore("confusable_local_declaration")
		var error_code: int =\
				DirAccess.make_dir_absolute(COMMUNITY_NANOGAMES_PATH_USER)
		if error_code != OK:
			push_error("Unable to create directory for community nanogames. " +
					"Error code: " + str(error_code))

			return

	dir = DirAccess.open(COMMUNITY_NANOGAMES_PATH_USER)
	if DirAccess.get_open_error() == OK:
		for i: String in dir.get_files():
			if not ProjectSettings.load_resource_pack(
					COMMUNITY_NANOGAMES_PATH_USER.path_join(i), false):
				push_error('Unable to load resource package "%s".' % i)
			else:
				print("Resource pack (nanogame) loaded: " + i)

		if DirAccess.dir_exists_absolute(COMMUNITY_NANOGAMES_PATH_RES):
			dir = DirAccess.open(COMMUNITY_NANOGAMES_PATH_RES)
			for i: String in dir.get_directories():
				var nanogame := Nanogame.new()
				if nanogame.load_data(
						COMMUNITY_NANOGAMES_PATH_RES.path_join(i)) == OK:
					_nanogames_community.append(nanogame)

			_sort_community_nanogames()


	### Load Save ###

	var config := ConfigFile.new()
	var error_code: int = config.load(SAVE_PATH)
	if error_code != OK:
		if error_code != ERR_FILE_NOT_FOUND:
			push_error("Unable to load settings data. Error code: " +
					str(error_code))
		else:
			save_data()

		return

	if config.has_section_key("arcade", "tickets"):
		var value: Variant = config.get_value("arcade", "tickets")
		if value is int and value >= 0:
			tickets = value

	if config.has_section_key("arcade", "community_mode"):
		var value: Variant = config.get_value("arcade", "community_mode")
		if value is bool:
			community_mode = value

	if config.has_section_key("arcade", "nanogames_owned"):
		var value: Variant = config.get_value("arcade", "nanogames_owned")
		if value is PackedStringArray:
			var nanogame_new_quantity := 0
			if config.has_section_key("arcade", "nanogames_highlighted"):
				var value_new: Variant =\
						config.get_value("arcade", "nanogames_highlighted")
				if value_new is int and value_new > 0:
					nanogame_new_quantity = value_new

			for i: String in value:
				for j: Nanogame in _nanogames_official:
					if j.get_nanogame_name() == i:
						if _nanogames_official_owned.has(j):
							break

						_nanogames_official_owned.append(j)

						if nanogame_new_quantity > 0:
							j.set_meta("highlight", true)

						break

				if nanogame_new_quantity > 0:
					nanogame_new_quantity -= 1

			sort_owned_official_nanogames()

	if config.has_section_key("statistics", "best_scores"):
		var value: Variant = config.get_value("statistics", "best_scores")
		if value is Array[int]:
			if value.size() > BEST_SCORES_SIZE_MAX:
				value.resize(BEST_SCORES_SIZE_MAX)

			for i: int in value:
				if i < 1:
					value = null

					break

			if value != null:
				_best_scores = value

	if config.has_section_key("statistics", "best_scores_highlighted"):
		var value: Variant =\
				config.get_value("statistics", "best_scores_highlighted")
		if value is Array[bool]:
			if value.size() > _best_scores.size():
				value.resize(_best_scores.size())
			while value.size() < BEST_SCORES_SIZE_MAX:
				value.append(false)

			_best_scores_highlighted = value

	if config.has_section_key("statistics", "nanogames_won"):
		var value: Variant = config.get_value("statistics", "nanogames_won")
		if value is int and value >= 0:
			_nanogames_won_count = value

	if config.has_section_key("statistics", "nanogames_lost"):
		var value: Variant = config.get_value("statistics", "nanogames_lost")
		if value is int and value >= 0:
			_nanogames_lost_count = value

	if config.has_section_key("statistics", "win_streak_best"):
		var value: Variant = config.get_value("statistics", "win_streak_best")
		if value is int and value >= 0:
			_win_streak_best = value

	if config.has_section_key("statistics", "win_streak_best_highlighted"):
		var value: Variant =\
				config.get_value("statistics", "win_streak_best_highlighted")
		if value is bool:
			_win_streak_best_highlighted = value


	save_data()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		sort_owned_official_nanogames()
		_sort_community_nanogames()


func own_official_nanogame(nanogame: Nanogame, is_highlighted:=true) -> void:
	if not _nanogames_official.has(nanogame):
		push_error('Requested nanogame to be owned, "' +
				nanogame.get_nanogame_name() +
				'", was not found inside the official nanogame list.')

		return
	if _nanogames_official_owned.has(nanogame):
		push_warning('Requested nanogame to be owned, "' +
				nanogame.get_nanogame_name() + '", is already owned.')

		return

	if is_highlighted:
		nanogame.set_meta("highlight", true)

	# Place it at the start, together with other highlighted nanogames.
	var nanogame_name: String = tr(nanogame.get_nanogame_name()).to_lower()
	for i: int in _nanogames_official_owned.size():
		if not _nanogames_official_owned[i].has_meta("highlight") or\
				nanogame_name < tr(_nanogames_official_owned[i].
						get_nanogame_name()).to_lower():
			_nanogames_official_owned.insert(i, nanogame)

			return

	_nanogames_official_owned.append(nanogame)


# Sorts the list of official nanogames owned alphabetically, putting the
# highlighted ones at the beginning. Needs to be called manually, which allows
# batching nanogame operations.
func sort_owned_official_nanogames() -> void:
	var nanogames_sorted: Array[Nanogame] = []

	for i: Nanogame in _nanogames_official_owned:
		var nanogame_name: String = tr(i.get_nanogame_name()).to_lower()
		var is_highlighted: bool = i.has_meta("highlight")
		var is_inserted := false

		for j: int in nanogames_sorted.size():
			var is_index_before: bool = nanogame_name <\
					tr(nanogames_sorted[j].get_nanogame_name()).to_lower()
			var is_index_highlighted: bool =\
					nanogames_sorted[j].has_meta("highlight")

			if not is_highlighted and not is_index_highlighted and\
					is_index_before or is_highlighted and\
					is_index_highlighted and is_index_before or\
					is_highlighted and not is_index_highlighted:
				nanogames_sorted.insert(j, i)
				is_inserted = true

				break

		if not is_inserted:
			nanogames_sorted.append(i)

	_nanogames_official_owned = nanogames_sorted


func claim_best_score(score: int) -> void:
	if score < 1:
		push_error(
				'Score value must be above "0" to be added to the statistics.')

		return

	var best_scores_size: int = _best_scores.size()
	var is_better_score := false
	for i: int in best_scores_size:
		if score <= _best_scores[i]:
			continue

		_best_scores.insert(i, score)
		if best_scores_size + 1 > BEST_SCORES_SIZE_MAX:
			_best_scores.resize(BEST_SCORES_SIZE_MAX)

		is_better_score = true

		_best_scores_highlighted.insert(i, true)
		_best_scores_highlighted.resize(BEST_SCORES_SIZE_MAX)

		best_scores_changed.emit()

		return

	if not is_better_score and best_scores_size < BEST_SCORES_SIZE_MAX:
		_best_scores.append(score)

		# Highlight if it's the player's first acquired score.
		if best_scores_size == 0:
			_best_scores_highlighted[best_scores_size] = true

		best_scores_changed.emit()


func add_nanogame_win() -> void:
	_nanogames_won_count += 1

	_win_streak_current += 1
	if _win_streak_current > _win_streak_best:
		_win_streak_best = _win_streak_current

		_win_streak_best_highlighted = true


func add_nanogame_loss() -> void:
	_nanogames_lost_count += 1

	_win_streak_current = 0


func break_win_streak() -> void:
	_win_streak_current = 0


func clear_statistics_highlight() -> void:
	for i: int in _best_scores_highlighted.size():
		_best_scores_highlighted[i] = false

	_win_streak_best_highlighted = false


func save_data() -> void:
	var config := ConfigFile.new()
	config.set_value("arcade", "tickets", tickets)
	config.set_value("arcade", "community_mode", community_mode)

	var nanogame_names := PackedStringArray()
	var nanogame_highlight_quantity := 0
	for i: Nanogame in _nanogames_official_owned:
		nanogame_names.append(i.get_nanogame_name())
		if i.has_meta("highlight"):
			nanogame_highlight_quantity += 1
	config.set_value("arcade", "nanogames_owned", nanogame_names)
	config.set_value(
			"arcade", "nanogames_highlighted", nanogame_highlight_quantity)

	config.set_value("statistics", "best_scores", _best_scores)
	config.set_value(
			"statistics", "best_scores_highlighted", _best_scores_highlighted)
	config.set_value("statistics", "nanogames_won", _nanogames_won_count)
	config.set_value("statistics", "nanogames_lost", _nanogames_lost_count)
	config.set_value("statistics", "win_streak_best", _win_streak_best)
	config.set_value("statistics", "win_streak_best_highlighted",
			_win_streak_best_highlighted)

	var error_code: int = config.save(SAVE_PATH)
	if error_code != OK:
		push_error("Unable to save settings data. Error code: " +
				str(error_code))


func set_tickets(value: int) -> void:
	if value < 0:
		push_error('Unvalid ticket quantity value of "' + str(value) +
				'". It must be a positive number.')

		return

	var tickets_old: int = tickets
	tickets = value
	if tickets < tickets_old:
		tickets_removed.emit()


func set_community_mode(is_enabled: bool) -> void:
	if community_mode == is_enabled:
		return

	community_mode = is_enabled
	community_mode_changed.emit()


func get_official_nanogames() -> Array[Nanogame]:
	return _nanogames_official.duplicate()


func get_community_nanogames() -> Array[Nanogame]:
	return _nanogames_community.duplicate()


func get_owned_official_nanogames() -> Array[Nanogame]:
	return _nanogames_official_owned.duplicate()


func has_highlighted_owned_nanogames() -> bool:
	return not _nanogames_official_owned.is_empty() and\
			_nanogames_official_owned.front().has_meta("highlight")


func get_best_scores() -> Array[int]:
	return _best_scores.duplicate()


func get_highlighted_best_scores() -> Array[bool]:
	return _best_scores_highlighted.duplicate()


func get_nanogames_won_count() -> int:
	return _nanogames_won_count


func get_nanogames_lost_count() -> int:
	return _nanogames_lost_count


func get_best_win_streak() -> int:
	return _win_streak_best


func is_best_win_streak_highlighted() -> bool:
	return _win_streak_best_highlighted


func is_statistics_highlighted() -> bool:
	if _win_streak_best_highlighted:
		return true

	for i: bool in _best_scores_highlighted:
		if i:
			return true

	return false


func _sort_community_nanogames() -> void:
	var nanogames_sorted: Array[Nanogame] = []
	for i: Nanogame in _nanogames_community:
		var nanogame: Nanogame = i
		var nanogame_name: String = tr(nanogame.get_nanogame_name()).to_lower()
		var is_inserted := false
		for j: int in nanogames_sorted.size():
			if nanogame_name <\
					tr(nanogames_sorted[j].get_nanogame_name()).to_lower():
				nanogames_sorted.insert(j, nanogame)

				is_inserted = true

				break

		if not is_inserted:
			nanogames_sorted.append(nanogame)

	_nanogames_community = nanogames_sorted
