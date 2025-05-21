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

class_name Nanogame
extends Resource


enum Inputs {
	NAVIGATION,
	ACTION,
	NAVIGATION_ACTION,
	DRAG_DROP,
}

enum InputModifiers {
	NONE,
	HORIZONTAL,
	VERTICAL,
}

enum Timers {
	OBJECTIVE,
	SURVIVAL,
}

enum Licenses {
	UNKNOWN,

	MIT,
	BSD_2,
	BSD_3,
	APACHE_2,
	MPL_2,
	MPL_2_NO_DERIVATIVES,
	GPL_2_ONLY,
	GPL_2_LATER,
	GPL_3_ONLY,
	GPL_3_LATER,
	LGPL_2_1_ONLY,
	LGPL_2_1_LATER,
	LGPL_3_ONLY,
	LGPL_3_LATER,
	AGPL_3_ONLY,
	AGPL_3_LATER,

	CC0,
	CC_BY_3,
	CC_BY_SA_3,
	CC_BY_4,
	CC_BY_SA_4,

	OFL,

	PUBLIC_DOMAIN,

	NON_FREE,
}

const ICON_SIZE = Vector2(128, 128)

var _has_data := false

var _is_instantiating_scene := false

var _is_official := false

var _directory_path := ""
var _icon_path := ""

var _name := ""
var _kickoff := ""
var _description := ""
var _author := ""
var _input: int = Inputs.NAVIGATION
var _input_modifier: int = InputModifiers.NONE
var _timer: int = Timers.OBJECTIVE
var _tags := ""
var _license_code: int = Licenses.UNKNOWN
var _license_assets: int = Licenses.UNKNOWN
var _source := ""
var _third_party: Array[Dictionary] = []
var _translations := {}


func _to_string() -> String:
	return "[Nanogame: %d]" % (_name if not _name.is_empty() else "(Empty)")


func load_data(path: String, is_nanogame_official:=false) -> int:
	if _is_instantiating_scene:
		push_error("Forbidden from replacing data while it's scene is being " +
				"instantiated.")

		return FAILED

	var file: FileAccess =\
			FileAccess.open(path.path_join("nanogame.json"), FileAccess.READ)
	var error_code: int = FileAccess.get_open_error()
	if error_code != OK:
		push_error('Unable to load nanogame data at path "' + path +
				'". Error code: ' + str(error_code))

		return error_code

	var info_text: String = file.get_as_text()
	file.close()

	### File Validation ###

	var json := JSON.new()
	error_code = json.parse(info_text)
	if error_code != OK:
		push_error('Unable to load nanogame data at path "' + path +
				"\". Nanogame file doesn't contain valid JSON.")

		return error_code

	json.parse(info_text)
	if json.data is not Dictionary:
		push_error('Unable to load nanogame data at path "' + path +
				"\". JSON contents aren't in a dictionary format.")

		return ERR_INVALID_DATA

	# Use `ResourceLoader` to check, as original path isn't kept on export.
	if not ResourceLoader.exists(path.path_join("main.tscn")):
		push_error('Unable to load nanogame data at path "' + path +
				'". Main scene file is missing.')

		return ERR_FILE_NOT_FOUND


	var validate_key: Callable = func(source: Dictionary, key: String,
			type: int, internal_source:={}) -> bool:
		return source.has(key) and typeof(source[key]) == type and\
				(internal_source.is_empty() or\
						internal_source.has(source[key]))

	### Information Extraction ###

	if not validate_key.call(json.data, "name", TYPE_STRING) or\
			not validate_key.call(json.data, "kickoff", TYPE_STRING) or\
			not validate_key.call(json.data, "description", TYPE_STRING) or\
			not validate_key.call(json.data, "author", TYPE_STRING) or\
			not validate_key.call(json.data, "input", TYPE_STRING, Inputs) or\
			not validate_key.call(json.data, "inputModifier", TYPE_STRING,
					InputModifiers) or\
			not validate_key.call(json.data, "timer", TYPE_STRING, Timers) or\
			not validate_key.call(json.data, "tags", TYPE_STRING) or\
			not validate_key.call(
					json.data, "licenseCode", TYPE_STRING, Licenses) or\
			not validate_key.call(
					json.data, "licenseAssets", TYPE_STRING, Licenses) or\
			not validate_key.call(json.data, "source", TYPE_STRING):
		push_error('Unable to load nanogame data at path "' + path +
				"\". Nanogame file doesn't have all properties necessary, " +
				"or their values are incorrect.")

		return ERR_INVALID_PARAMETER

	_name = json.data["name"]
	_kickoff = json.data["kickoff"]
	_description = json.data["description"]
	_author = json.data["author"]
	_input = Inputs.get(json.data["input"])
	_input_modifier = InputModifiers.get(json.data["inputModifier"])
	_timer = Timers.get(json.data["timer"])
	_tags = json.data["tags"]
	_license_code = Licenses.get(json.data["licenseCode"])
	_license_assets = Licenses.get(json.data["licenseAssets"])
	_source = json.data["source"]

	if FileAccess.file_exists(path.path_join("icon.png.import")):
		_icon_path = path.path_join("icon.png")
	elif FileAccess.file_exists(path.path_join("icon.svg.import")):
		_icon_path = path.path_join("icon.svg")
	elif _has_data:
		_icon_path = ""

	_directory_path = path

	_is_official = is_nanogame_official

	if _has_data:
		_third_party.clear()
		_translations.clear()
	else:
		_has_data = true

	### Thirdparty Assets ###

	if json.data.has("thirdParty") and json.data["thirdParty"] is Array:
		for i: Variant in json.data["thirdParty"]:
			if i is not Dictionary:
				continue

			if not validate_key.call(i, "name", TYPE_STRING) or\
					not validate_key.call(i, "author", TYPE_STRING) or\
					not validate_key.call(
							i, "license", TYPE_STRING, Licenses) or\
					not validate_key.call(i, "source", TYPE_STRING):
				push_error("Invalid third-party information in nanogame " +
						"file at path \"%s\". It either doesn't have all " +
						"properties necessary, or their values are " +
						"incorrect." % path)

				continue

			_third_party.append({
				"name": i["name"],
				"author": i["author"],
				"license": Licenses.get(i["license"]),
				"source": i["source"],
			})

	### Translations ###

	if not is_nanogame_official and\
			DirAccess.dir_exists_absolute(path.path_join("translations")):
		var dir := DirAccess.open(path.path_join("translations"))
		for i: String in dir.get_files():
			if i.get_extension() == "po" or i.get_extension() == "csv":
				var translation: Variant =\
						load(path.path_join("translations".path_join(i)))
				if translation is Translation and not TranslationServer.\
						get_locale_name(translation.get_locale()).is_empty():
					_translations[translation.locale] = translation
				else:
					push_error('Unable to load translation file "%s" ' +
							'of nanogame at path "%s".' % [i, path])


	return OK


# Returns the nanogame's main scene node, if the loading was successful.
# Intended to be called from a separate thread.
func instantiate_scene() -> Node:
	_is_instantiating_scene = true

	if not _has_data:
		push_error("Can't load nanogame scene without any data loaded.")

		_is_instantiating_scene = false

		return null

	var nanogame_scene: Variant = load(_directory_path.path_join("main.tscn"))
	if nanogame_scene == null:
		push_error('Unable to load nanogame scene at path "' +
				_directory_path + '". Unable to load main scene file.')

		_is_instantiating_scene = false

		return null

	if nanogame_scene is not PackedScene:
		push_error('Unable to instance nanogame scene at path "' +
				_directory_path +
				"\". Main scene file doesn't contain a valid scene.")

		_is_instantiating_scene = false

		return null

	var scene: Node = nanogame_scene.instantiate()

	_is_instantiating_scene = false

	return scene


func has_data() -> bool:
	return _has_data


func is_official() -> bool:
	return _is_official


func get_nanogame_path() -> String:
	return _directory_path


func get_icon() -> CompressedTexture2D:
	if _icon_path.is_empty():
		return null

	var icon: CompressedTexture2D = load(_icon_path)

	if icon == null:
		push_error('Unable to load icon file for nanogame at path "' +
				_directory_path + '".')

		return null

	if icon.get_size() != ICON_SIZE:
		push_error('Unable to load icon file for nanogame at path "%s". '+
			'Image size resolution must be "%dx%d".' %
			[_directory_path, ICON_SIZE.x, ICON_SIZE.y])

		return null

	return icon


func get_nanogame_name(is_translated:=false) -> String:
	if not is_official() and is_translated and\
			get_current_translation() != null:
		var position: String =\
				get_current_translation().get_message(_name)
		if not position.is_empty():
			return position

	return _name if not is_translated else tr(_name)


func get_kickoff(is_translated:=false) -> String:
	if not is_official() and is_translated and\
			get_current_translation() != null:
		var position: String =\
				get_current_translation().get_message(_kickoff)
		if not position.is_empty():
			return position

	return _kickoff if not is_translated else tr(_kickoff)


func get_description(is_translated:=false) -> String:
	if not is_official() and is_translated and\
			get_current_translation() != null:
		var position: String =\
				get_current_translation().get_message(_description)
		if not position.is_empty():
			return position

	return _description if not is_translated else tr(_description)


func get_author() -> String:
	return _author


func get_input() -> int:
	return _input


func get_input_modifier() -> int:
	return _input_modifier


func get_timer() -> int:
	return _timer


func get_tags(is_translated:=false) -> String:
	if not is_translated:
		return _tags

	var tags: PackedStringArray = _tags.split(",")
	var tags_translated := []

	var is_translation_internal: bool =\
			is_official() or get_current_translation() == null
	var current_translation: Translation
	if not is_translation_internal:
		current_translation = get_current_translation()

	for i: String in tags:
		var tag: String = tr(i) if is_translation_internal\
				else str(current_translation.get_message(i))
		# Check for repeats, as different tags can have the same translation
		# depending on the language.
		if not tags_translated.has(tag):
			tags_translated.append(tag)

	tags_translated.sort()

	var position: String =\
			str(tags_translated).replace(", ", tr("%s, %s").replace("%s", ""))

	position = position.erase(0)
	position = position.erase(position.length() - 1)

	return position


func get_license_code() -> int:
	return _license_code


func get_license_assets() -> int:
	return _license_assets


func get_source() -> String:
	return _source


func get_thirdparty() -> Array[Dictionary]:
	return _third_party.duplicate(true)


func get_translations() -> Dictionary:
	return _translations.duplicate()


func get_current_translation() -> Translation:
	if _is_official:
		return null

	var locale: String = TranslationServer.get_locale()
	if not _translations.keys().has(locale):
		var locale_bits: PackedStringArray = locale.split("_")
		if not locale_bits.is_empty() and\
				_translations.keys().has(locale_bits[0]):
			return _translations[locale_bits[0]]

		return null

	return _translations[locale]


static func get_input_name(input: int) -> String:
	match input:
		Inputs.NAVIGATION:
			return "Navigation"
		Inputs.ACTION:
			return "Action"
		Inputs.NAVIGATION_ACTION:
			return "Navigation and Action"
		Inputs.DRAG_DROP:
			return "Drag and Drop"
		_:
			return ""


static func get_timer_name(timer: int) -> String:
	match timer:
		Timers.OBJECTIVE:
			return "Objective"
		Timers.SURVIVAL:
			return "Survival"
		_:
			return ""


static func get_license_name(license: int) -> String:
	match license:
		Licenses.UNKNOWN:
			return "Unknown"

		Licenses.MIT:
			return "MIT"
		Licenses.BSD_2:
			return "BSD 2-Clause"
		Licenses.BSD_3:
			return "BSD 3-Clause"
		Licenses.APACHE_2:
			return "Apache 2.0"
		Licenses.MPL_2:
			return "MPL-2.0"
		Licenses.MPL_2_NO_DERIVATIVES:
			return "MPL-2.0 (No Derivatives)"
		Licenses.GPL_2_ONLY:
			return "GPLv2 Only"
		Licenses.GPL_2_LATER:
			return "GPLv2 or Later"
		Licenses.GPL_3_ONLY:
			return "GPLv3 Only"
		Licenses.GPL_3_LATER:
			return "GPLv3 or Later"
		Licenses.LGPL_2_1_ONLY:
			return "LGPLv2.1 Only"
		Licenses.LGPL_2_1_LATER:
			return "LGPLv2.1 or Later"
		Licenses.LGPL_3_ONLY:
			return "LGPLv3 Only"
		Licenses.LGPL_3_LATER:
			return "LGPLv3 or Later"
		Licenses.AGPL_3_ONLY:
			return "AGPLv3 Only"
		Licenses.AGPL_3_LATER:
			return "AGPLv3 or Later"

		Licenses.CC0:
			return "CC0"
		Licenses.CC_BY_3:
			return "CC BY 3.0"
		Licenses.CC_BY_SA_3:
			return "CC BY-SA 3.0"
		Licenses.CC_BY_4:
			return "CC BY 4.0"
		Licenses.CC_BY_SA_4:
			return "CC BY-SA 4.0"

		Licenses.OFL:
			return "OFL"

		Licenses.PUBLIC_DOMAIN:
			return "Public Domain"

		Licenses.NON_FREE:
			return "Non-Free"

		_:
			return ""


static func get_license_link(license: int) -> String:
	match license:
		Licenses.MIT:
			return "https://opensource.org/licenses/MIT"
		Licenses.BSD_2:
			return "https://opensource.org/licenses/BSD-2-Clause"
		Licenses.BSD_3:
			return "https://opensource.org/licenses/BSD-3-Clause"
		Licenses.APACHE_2:
			return "https://www.apache.org/licenses/LICENSE-2.0.html"
		Licenses.MPL_2,\
		Licenses.MPL_2_NO_DERIVATIVES:
			return "https://www.mozilla.org/en-US/MPL/2.0/"
		Licenses.GPL_2_ONLY,\
		Licenses.GPL_2_LATER:
			return "https://www.gnu.org/licenses/old-licenses/gpl-2.0.html"
		Licenses.GPL_3_ONLY,\
		Licenses.GPL_3_LATER:
			return "https://www.gnu.org/licenses/gpl-3.0.html"
		Licenses.LGPL_2_1_ONLY,\
		Licenses.LGPL_2_1_LATER:
			return "https://www.gnu.org/licenses/lgpl-2.1.html"
		Licenses.LGPL_3_ONLY,\
		Licenses.LGPL_3_LATER:
			return "https://www.gnu.org/licenses/lgpl-3.0.html"
		Licenses.AGPL_3_ONLY,\
		Licenses.AGPL_3_LATER:
			return "https://www.gnu.org/licenses/agpl-3.0.html"

		Licenses.CC0:
			return "https://creativecommons.org/publicdomain/zero/1.0/"
		Licenses.CC_BY_3:
			return "https://creativecommons.org/licenses/by/3.0/"
		Licenses.CC_BY_SA_3:
			return "https://creativecommons.org/licenses/by-sa/3.0/"
		Licenses.CC_BY_4:
			return "https://creativecommons.org/licenses/by/4.0/"
		Licenses.CC_BY_SA_4:
			return "https://creativecommons.org/licenses/by-sa/4.0/"

		Licenses.OFL:
			return "https://scripts.sil.org/OFL_web"

		_:
			return ""
