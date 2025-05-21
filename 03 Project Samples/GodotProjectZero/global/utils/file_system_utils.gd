class_name FileSystemUtils

const USER_PATH: String = "user://"
const RESOURCES_PATH: String = "res://resources/"
const IMAGE_RESOURCES_PATH: String = "res://assets/image/"


static func read_text_from(path: String) -> String:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var content: String = file.get_as_text()
	file.close()
	return content


static func get_files_at(path: String) -> PackedStringArray:
	var files: PackedStringArray = DirAccess.get_files_at(path)
	if Game.PARAMS["debug_logs"]:
		print("CALL get_files: " + path)
		print(files)
	return files


static func get_user_files() -> Array[String]:
	return get_files(FileSystemUtils.USER_PATH)


static func get_files(path: String) -> Array[String]:
	var files: Array[String] = []
	for file: String in get_files_at(path):
		files.append(file)
	return files


static func get_image_resources(
	resource_path: String,
	recursive: bool,
	root: String = FileSystemUtils.IMAGE_RESOURCES_PATH,
	extension: String = ".png"
) -> Dictionary:
	return get_resources(resource_path, recursive, root, extension)


static func get_resources(
	resource_path: String,
	recursive: bool,
	root: String = FileSystemUtils.RESOURCES_PATH,
	extension: String = ".tres"
) -> Dictionary:
	var path: String = root
	if StringUtils.is_not_empty(resource_path):
		path += resource_path + "/"
	var resources: Dictionary = {}
	for file: String in get_files_at(path):
		file = fix_web_build_file_extension(file)
		if file.ends_with(extension):
			var resource: Resource = load(path + file) as Resource
			if resource != null:
				var id: String = file.split(".")[0]
				resources[id] = resource
	if recursive:
		for dir: String in DirAccess.get_directories_at(path):
			var resources_dir: Dictionary = get_resources(
				resource_path + "/" + dir, recursive, root, extension
			)
			resources.merge(resources_dir)
	return resources


static func fix_web_build_file_extension(file: String, force_one_extension: bool = true) -> String:
	if file.ends_with(".remap"):
		file = file.trim_suffix(".remap")
	if file.ends_with(".import"):
		file = file.trim_suffix(".import")
	if force_one_extension:
		var file_split: PackedStringArray = file.split(".")
		if file_split.size() > 2:
			if Game.PARAMS["debug_logs"]:
				print("!! FORCE ONE EXTENSION: " + file)
			file = file_split[0] + "." + file_split[1]
	return file
