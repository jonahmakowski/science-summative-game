extends Node

const QUESTION_PATH = "res://Resources/Questions/"

var questions: Array[Question]


func _ready() -> void:
	load_questions()


func load_questions() -> void:
	_load_recursive(QUESTION_PATH, questions)


func _load_recursive(path: String, resources: Array) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Could not open directory: " + path)
		return

	dir.list_dir_begin()

	var file_name := dir.get_next()
	while file_name != "":
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue

		var full_path := path.path_join(file_name)

		if dir.current_is_dir():
			_load_recursive(full_path, resources)
		else:
			var resource := load(full_path)
			if resource:
				resources.append(resource)

		file_name = dir.get_next()

	dir.list_dir_end()
