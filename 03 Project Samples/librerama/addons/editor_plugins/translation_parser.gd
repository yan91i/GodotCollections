@tool
extends EditorTranslationParserPlugin


const _KEYS_NANOGAME = ["name", "kickoff", "description", "tags"]


func _parse_file(path: String,
		msgids: Array[String], msgids_context_plural: Array[Array]) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_as_text())
	file.close()

	match path.get_file():
		"nanogame.json":
			for i: String in _KEYS_NANOGAME:
				if i == "tags":
					for j: String in json.data[i].split(",", false):
						msgids.append(j)
				else:
					msgids.append(json.data[i])
		"dialog.json":
			for i: Array in json.data.values():
				for j: Array in i:
					for k: Variant in j:
						if k is String:
							msgids.append(k)
						else:
							msgids.append(k["text"])
		"messages.json":
			for i: Array in json.data:
				msgids.append_array(i)
		"translation_extract.json":
			for i: String in json.data:
				msgids.append(i)


func _get_recognized_extensions() -> PackedStringArray:
	return ["json"]
