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

extends EditorExportPlugin


const EXPORT_PATH = "_export/"
const ARTIFACTS_PATH = EXPORT_PATH + "_artifacts/"
const FILES_PATH = "res://addons/editor_plugins/export_handler/files/"

var _os := ""
var _arch := ""
var _path := ""


func _get_name() -> String:
	return "page.codeberg.yeldham.ExportHelper"


func _export_begin(features: PackedStringArray, _is_debug: bool, path: String,
		_flags: int) -> void:
	if features.has("android"):
		_os = "android"
	elif features.has("linux"):
		_os = "linux"
	elif features.has("macos"):
		_os = "macos"
	elif features.has("web"):
		_os = "web"
	elif features.has("windows"):
		_os = "windows"

	if _os == "linux" or _os == "windows":
		_arch = "64" if features.has("x86_64") else "32"
	else:
		_arch = ""

	_path = path

	DirAccess.make_dir_recursive_absolute(path.get_base_dir())


func _export_end() -> void:
	var directory_path: String = _path.get_base_dir() + "/"
	match _os:
		"android":
			if directory_path == EXPORT_PATH:
				DirAccess.remove_absolute(_path + ".idsig")
		"linux", "windows":
			if directory_path == ARTIFACTS_PATH:
				_archive_and_clean()
		"macos":
			if directory_path != EXPORT_PATH:
				return

			var zip := ZIPPacker.new()
			zip.open(_path, ZIPPacker.APPEND_ADDINZIP)

			zip.start_file("README")
			zip.write_file(FileAccess.get_file_as_bytes(
					FILES_PATH.path_join("macos_readme")))
			zip.close_file()

			zip.close()
		"web":
			if directory_path != ARTIFACTS_PATH:
				return

			var dir: DirAccess = DirAccess.open(directory_path)
			dir.rename("librerama.html", "index.html")

			var file: FileAccess = FileAccess.open(FILES_PATH.path_join(
					"js_license_template"), FileAccess.READ)
			var license: String = file.get_as_text()
			file.close()

			file = FileAccess.open(directory_path.path_join("librerama.js"),
					FileAccess.READ_WRITE)
			file.store_string(license + file.get_as_text())
			file.close()

			_archive_and_clean()


func _archive_and_clean() -> void:
	var dir: DirAccess = DirAccess.open(ARTIFACTS_PATH)
	if DirAccess.get_open_error() != OK:
		push_error("Unable to access files inside the artifacts directory.")

		return

	var zip_name: String = "librerama_" + _os
	if not _arch.is_empty():
		zip_name += "_x" + _arch
	zip_name += ".zip"

	var zip := ZIPPacker.new()
	zip.open(EXPORT_PATH.path_join(zip_name), ZIPPacker.APPEND_CREATE)

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if dir.current_is_dir():
			push_error('Unexpect directory "' + file_name +
					'" found while exporting. Archiving canceled.')

			break

		zip.start_file(file_name)
		zip.write_file(FileAccess.get_file_as_bytes(
				ARTIFACTS_PATH.path_join(file_name)))
		zip.close_file()

		dir.remove(file_name)

		file_name = dir.get_next()

	dir.list_dir_end()
	zip.close()
