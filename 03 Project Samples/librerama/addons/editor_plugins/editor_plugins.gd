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
extends EditorPlugin


const ExportHandler =\
		preload("res://addons/editor_plugins/export_handler/export_handler.gd")
const TranslationParser =\
		preload("res://addons/editor_plugins/translation_parser.gd")

var _export_handler: EditorExportPlugin
var _translation_parser: EditorTranslationParserPlugin


func _enter_tree() -> void:
	_export_handler = ExportHandler.new()
	add_export_plugin(_export_handler)

	DirAccess.make_dir_recursive_absolute(ExportHandler.ARTIFACTS_PATH)

	_translation_parser = TranslationParser.new()
	add_translation_parser_plugin(_translation_parser)


func _exit_tree() -> void:
	remove_export_plugin(_export_handler)
	_export_handler = null

	remove_translation_parser_plugin(_translation_parser)
	_translation_parser = null
