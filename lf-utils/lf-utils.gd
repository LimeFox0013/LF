class_name LFUtils;


static func saveFile(file: String, data: String):
	var dir := DirAccess.open("user://");
	dir.make_dir_recursive("user://data");
	var f := FileAccess.open("user://data/" + file, FileAccess.WRITE);
	f.store_string(data);
	f.close();


# Save (JSON)
static func saveJson(file: String, json: Dictionary) -> void:
	LFUtils.saveFile(file, JSON.stringify(json));


static func loadFile(file: String) -> String:
	var path := "user://data/" + file;
	if not FileAccess.file_exists(path):
		return '';
	return FileAccess.get_file_as_string(path);


# Load (JSON)
static func loadJson(file: String) -> Dictionary:
	return JSON.parse_string(loadFile(file));
