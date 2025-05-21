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


signal practice_mode_started(nanogame: Nanogame, difficulty: int)

var _nanogame: Nanogame


func _ready() -> void:
	super()

	set_tab_title(1, tr("Practice Mode"))

	if Engine.is_editor_hint():
		return

	var practice_popup :=\
			($PracticeMode/Practice as MenuButton).get_popup() as PopupMenu
	practice_popup.theme_type_variation = "PopupMenuPositive"
	practice_popup.visibility_changed.connect(
			_on_practice_menu_visibility_changed)
	practice_popup.id_pressed.connect(_on_practice_menu_id_pressed)


func _notification(what: int) -> void:
	if Engine.is_editor_hint():
		return

	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if not visible:
				_nanogame = null

				current_tab = 0
		NOTIFICATION_TRANSLATION_CHANGED:
			if _nanogame != null:
				popup_nanogame(_nanogame)


func popup_nanogame(nanogame: Nanogame) -> void:
	if not nanogame.has_data():
		push_error("Can't show information about a nanogame without data.")

		return

	_nanogame = nanogame

	### About ##

	var about := $About as RichTextLabel
	about.scroll_to_line(0)
	about.clear()

	about.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)

	about.push_color(Color.WHITE
			if not nanogame.get_nanogame_name().is_empty() else Color.SILVER)
	about.push_bold()
	about.add_text(nanogame.get_nanogame_name(true) if not nanogame.\
			get_nanogame_name().is_empty() else tr("[No Name]"))
	about.pop()
	about.pop()
	about.newline()

	about.push_color(Color.WHITE if not nanogame.get_kickoff().is_empty()
			else Color.SILVER)
	about.push_italics()
	about.add_text(tr('"%s"') % nanogame.get_kickoff(true)
			if not nanogame.get_kickoff().is_empty() else tr("[No Kickoff]"))
	about.pop()
	about.pop()
	about.newline()

	about.push_color(Color.WHITE if not nanogame.get_author().is_empty()
			else Color.SILVER)
	about.add_text(tr("By %s") % nanogame.get_author()
			if not nanogame.get_author().is_empty() else tr("[No Author]"))
	about.pop()
	about.newline()

	if not nanogame.get_source().is_empty():
		about.push_meta(nanogame.get_source())
		about.add_text(tr("Source"))
		about.pop()
	else:
		about.push_color(Color.SILVER)
		about.add_text(tr("[No Source]"))
		about.pop()

	about.pop()
	about.newline()

	about.newline()

	about.push_color(Color.WHITE if not nanogame.get_description().is_empty()
			else Color.SILVER)
	about.add_text(nanogame.get_description(true) if not nanogame.\
			get_description().is_empty() else tr("[No Description]"))
	about.pop()
	about.newline()

	about.newline()

	about.append_text(tr("[b]Input:[/b] %s") %
			tr(Nanogame.get_input_name(nanogame.get_input())))
	about.newline()

	about.append_text(tr("[b]Timer:[/b] %s") %
			tr(Nanogame.get_timer_name(nanogame.get_timer())))
	about.newline()

	about.append_text(tr("[b]Tags:[/b] %s") %
			(nanogame.get_tags(ArcadeManager.community_mode or
							TranslationServer.get_locale() != "en_US")
					if not nanogame.get_tags().is_empty() else
					"[color=silver]%s[/color]" % tr("[None]")))
	about.newline()

	about.append_text(tr("[b]Code License:[/b] %s") % ("[url=%s]%s[/url]" %
			[Nanogame.get_license_link(nanogame.get_license_code()),
					Nanogame.get_license_name(nanogame.get_license_code())]
			if not Nanogame.get_license_link(
					nanogame.get_license_code()).is_empty() else
			Nanogame.get_license_name(nanogame.get_license_code())))
	about.newline()

	about.append_text(tr("[b]Assets License:[/b] %s") % ("[url=%s]%s[/url]" %
			[Nanogame.get_license_link(nanogame.get_license_assets()),
					Nanogame.get_license_name(nanogame.get_license_assets())]
			if not Nanogame.get_license_link(
					nanogame.get_license_assets()).is_empty() else
			Nanogame.get_license_name(nanogame.get_license_assets())))


	### Third-party ###

	var thirdparty := $Thirdparty as RichTextLabel
	thirdparty.scroll_to_line(0)
	thirdparty.clear()

	var index_max: int
	var index_current: = 0
	if not nanogame.get_thirdparty().is_empty():
		# TODO: Implement checking of right-to-left languages.
		# Use a non-breaking space, so long names are still kept besides the
		# bullet point.
		var bullet_point := "•" + char(0032) + "%s"
		index_max = nanogame.get_thirdparty().size() - 1
		for i: Dictionary in nanogame.get_thirdparty():
			thirdparty.push_bold()
			thirdparty.add_text(bullet_point %
					i["name"] if not i["name"].is_empty() else tr("[No Name]"))
			thirdparty.pop()
			thirdparty.newline()

			thirdparty.push_indent(2)

			thirdparty.add_text(tr("By %s") % i["author"]
					if not i["author"].is_empty() else tr("[No Author]"))
			thirdparty.newline()

			if not Nanogame.get_license_link(i["license"]).is_empty():
				thirdparty.push_meta(Nanogame.get_license_link(i["license"]))
				thirdparty.add_text(Nanogame.get_license_name(i["license"]))
				thirdparty.pop()
			else:
				thirdparty.add_text(Nanogame.get_license_name(i["license"]))
			thirdparty.newline()

			if not i["source"].is_empty():
				thirdparty.push_meta(i["source"])
				thirdparty.add_text(tr("Source"))
				thirdparty.pop()
			else:
				thirdparty.add_text(tr("[No Source]"))

			thirdparty.pop()

			if index_current < index_max:
				thirdparty.newline()
				thirdparty.newline()

				index_current += 1
	else:
		thirdparty.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
		thirdparty.add_text(tr("No third-party resources used."))
		thirdparty.pop()

	popup_centered()


func _on_practice_menu_visibility_changed() -> void:
	var practice_menu := (%Practice as MenuButton).get_popup() as PopupMenu
	if practice_menu.visible:
		# Adjust the position so it's spawn above the button, to avoid it
		# hugging the bottom of the screen.
		@warning_ignore("narrowing_conversion")
		practice_menu.position.y = (%Practice as MenuButton).\
				get_screen_transform().origin.y - practice_menu.size.y


func _on_practice_menu_id_pressed(id: int) -> void:
	practice_mode_started.emit(_nanogame, id)

	hide() # Hide later, to avoid nulling the last reference of the nanogame.


func _on_rich_text_label_meta_clicked(meta: String) -> void:
	OS.shell_open(meta)
