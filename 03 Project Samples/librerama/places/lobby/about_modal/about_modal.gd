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

@tool
extends TabModal


const LIBRERAMA_LINK = "https://librerama.codeberg.page/"
const PERSONAL_WEBSITE_LINK = "https://yeldham.codeberg.page/"
const DONATE_LINK = "https://liberapay.com/Yeldham/donate"

var _thirdparty_elements: Array[Array] = [
	[
		"Godot Engine",
		"Juan Linietsky, Ariel Manzur, and Godot contributors",
		Nanogame.get_license_link(Nanogame.Licenses.MIT),
		Nanogame.get_license_name(Nanogame.Licenses.MIT),
		"https://github.com/godotengine/godot",
	],
	[
		"Freetype",
		"FreeType Project",
		"https://git.savannah.gnu.org/cgit/freetype/freetype2.git/tree/" +\
				"docs/FTL.TXT",
		"FLT",
		"https://git.savannah.gnu.org/cgit/freetype/freetype2.git/",
	],
	[
		"Noto Fonts",
		"Google",
		Nanogame.get_license_link(Nanogame.Licenses.OFL),
		Nanogame.get_license_name(Nanogame.Licenses.OFL),
		"https://github.com/googlefonts/noto-fonts",
	],
	[
		"Cash Register Fake",
		"CapsLok",
		Nanogame.get_license_link(Nanogame.Licenses.CC0),
		Nanogame.get_license_name(Nanogame.Licenses.CC0),
		"https://freesound.org/people/CapsLok/sounds/184438/",
	],
	[
		"dorm door opening",
		"pagancow",
		Nanogame.get_license_link(Nanogame.Licenses.CC0),
		Nanogame.get_license_name(Nanogame.Licenses.CC0),
		"https://freesound.org/people/pagancow/sounds/15419/",
	],
	[
		"scratch01",
		"LMMS Team",
		Nanogame.get_license_link(Nanogame.Licenses.GPL_2_LATER),
		Nanogame.get_license_name(Nanogame.Licenses.GPL_2_LATER),
		"https://github.com/LMMS/lmms/tree/v1.2.2/data/samples/effects/scratch01.ogg",
	],
]

@onready var _about := $About as RichTextLabel
@onready var _donate := $Donate as RichTextLabel
@onready var _contributors := $Contributors as RichTextLabel
@onready var _thirdparty := $Thirdparty as RichTextLabel


func _ready() -> void:
	super()

	if not Engine.is_editor_hint():
		_update_texts()


func _notification(what: int) -> void:
	# Check if an tab is ready first, as this can trigger before it.
	if not Engine.is_editor_hint() and\
			what == NOTIFICATION_TRANSLATION_CHANGED and _about != null:
		# Defer it, so the result doesn't get wiped out.
		_update_texts.call_deferred()


func _update_texts() -> void:
	### About ###

	_about.clear()

	_about.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)

	_about.push_bold()
	_about.push_meta(LIBRERAMA_LINK)
	_about.add_text("Librerama")
	_about.pop()
	_about.pop()
	_about.add_text(
			" v" + ProjectSettings.get_setting("application/config/version"))
	_about.newline()

	_about.add_text("Copyright © 2023 ")
	_about.push_bold()
	_about.push_meta(PERSONAL_WEBSITE_LINK)
	_about.add_text("Michael Alexsander")
	_about.pop()
	_about.pop()
	_about.newline()

	_about.newline()

	_about.push_italics()
	_about.add_text(tr(
			"A free/libre fast-paced arcade collection of mini-games."))
	_about.pop()
	_about.newline()

	_about.pop()
	_about.newline()

	_about.append_text(tr("This program is [url=%s]free software[/url]: you " +
			"can redistribute it and/or modify it under the terms of the " +
			"[url=%s]GNU General Public License[/url] as published by the " +
			"Free Software Foundation, either version 3 of the License, or " +
			"(at your option) any later version.") % [
					"https://www.gnu.org/philosophy/free-sw.html",
					Nanogame.get_license_link(Nanogame.Licenses.GPL_3_LATER)])
	_about.newline()

	_about.newline()

	_about.append_text(tr("The source code and assets can be found in its " +
			"[url=%s]repository[/url].") % GameManager.REPOSITORY_LINK)


	### Donate ###

	_donate.clear()

	_donate.append_text(tr("Librerama is not just free as in " +
			"[i]freedom[/i], but also free as in [i]free of charge[/i], so " +
			"donations are very much welcomed!"))
	_donate.newline()

	_donate.newline()

	_donate.append_text(tr(
			"You can donate to me via [url=%s]Liberapay[/url]. The money " +
			"will be used to help me put more work not just into this game, " +
			"but also my general work in free/libre gaming.") % DONATE_LINK)


	### Contributors ###

	_contributors.clear()

	_contributors.add_text(tr("The wonderful people listed below offered " +
			"sizable contributions to the game. Make sure to check them out."))
	_contributors.newline()

	_contributors.newline()

	_contributors.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	_contributors.push_bold()
	_contributors.add_text(tr("Music"))
	_contributors.pop()
	_contributors.pop()
	_contributors.newline()

	var bullet_point_colon := tr("• %s: ")

	_contributors.push_bold()
	_contributors.add_text(
			bullet_point_colon % tr("Arcade Menu Theme and Jingles"))
	_contributors.pop()

	_contributors.push_meta("https://www.francescorrado.com")
	_contributors.add_text("Francesco Corrado")
	_contributors.pop()
	_contributors.newline()

	_contributors.newline()

	_contributors.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	_contributors.push_bold()
	_contributors.add_text(tr("Translation"))
	_contributors.pop()
	_contributors.pop()
	_contributors.newline()

	_contributors.push_bold()
	_contributors.add_text(bullet_point_colon % tr("Dutch"))
	_contributors.pop()
	_contributors.add_text("Vistaus")
	_contributors.newline()

	_contributors.push_bold()
	_contributors.add_text(bullet_point_colon % tr("Esperanto"))
	_contributors.pop()
	_contributors.add_text("jorgesumle")
	_contributors.newline()

	_contributors.push_bold()
	_contributors.add_text(bullet_point_colon % tr("German"))
	_contributors.pop()
	_contributors.add_text("fnetX, HaSa, Wuzzy")
	_contributors.newline()

	_contributors.push_bold()
	_contributors.add_text(bullet_point_colon % tr("Portuguese, Brazil"))
	_contributors.pop()
	_contributors.add_text("Cavernosa")

	_contributors.push_bold()
	_contributors.add_text(bullet_point_colon % tr("Spanish"))
	_contributors.pop()
	_contributors.add_text("jorgesumle")
	_contributors.newline()

	_contributors.push_bold()
	_contributors.add_text(bullet_point_colon % tr("Turkish"))
	_contributors.pop()
	_contributors.add_text("furkanunsalan")


	### Third-party ###

	_thirdparty.clear()

	var bullet_point := tr("• %s")

	for i: Array[String] in _thirdparty_elements:
		_thirdparty.push_bold()
		_thirdparty.add_text(bullet_point % i[0])
		_thirdparty.pop()

		# Add the version number on the "Godot Engine" element.
		if i[0] == _thirdparty_elements[0][0]:
			_thirdparty.add_text(" v" + Engine.get_version_info()["string"])

		_thirdparty.newline()

		_thirdparty.push_indent(2)

		_thirdparty.add_text(tr("By %s") % i[1])
		_thirdparty.newline()
		_thirdparty.push_meta(i[2])
		_thirdparty.add_text(i[3])
		_thirdparty.pop()
		_thirdparty.newline()
		_thirdparty.push_meta(i[4])
		_thirdparty.add_text(tr("Source"))
		_thirdparty.pop()
		_thirdparty.newline()

		_thirdparty.pop()
		_thirdparty.newline()

	_thirdparty.add_text(tr("For the licenses of the third-party " +\
			"components used by the nanogames themselves, check their " +\
			'respective "About" information.'))


func _on_rich_text_label_meta_clicked(meta: String) -> void:
	OS.shell_open(meta)
