@tool
extends EditorTranslationParserPlugin


const _KEYS_NANOGAME = ["name", "kickoff", "description", "tags"]


func _parse_file(path: String) -> Array[PackedStringArray]:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_as_text())
	file.close()

	var msgids: Array[PackedStringArray] = []
	match path.get_file():
		"nanogame.json":
			for i: String in _KEYS_NANOGAME:
				if i == "tags":
					for j: String in json.data[i].split(",", false):
						msgids.append(PackedStringArray([j]))
				else:
					msgids.append(PackedStringArray([json.data[i]]))
		"dialog.json":
			for i: Array in json.data.values():
				for j: Array in i:
					for k: Variant in j:
						if k is String:
							msgids.append(PackedStringArray([k]))
						else:
							msgids.append(PackedStringArray([k["text"]]))
		"messages.json":
			for i: Array in json.data:
				for j: String in i:
					msgids.append_array(PackedStringArray([j]))
		"translation_extract.json":
			for i: String in json.data:
				msgids.append(PackedStringArray([i]))

	return msgids


func _get_recognized_extensions() -> PackedStringArray:
	return ["json"]
