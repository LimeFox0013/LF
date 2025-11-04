class_name LFFile;


enum PATH_TARGET { MISSING, FILE, DIR }


static func create(path: String, content = ''):
	var globalPath = ProjectSettings.globalize_path(path);
	LFFile.ensureDir(globalPath);
	var f := FileAccess.open(globalPath, FileAccess.WRITE);
	
	if f == null:
		push_error("Failed to create file %s (open err=%s)" % [
			globalPath,
			FileAccess.get_open_error(),
		]);
		return false;
	f.store_string(content);
	f.close();


static func  ensureDir(path: String) -> void:
	return DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(path).get_base_dir(),
	);


static func save(path: String, content = '', ensureFile := true):
	var globalPath = ProjectSettings.globalize_path(path);
	if !FileAccess.file_exists(globalPath):
		if ensureFile:
			LFFile.create(globalPath, content);


static func saveJson(path: String, json: Dictionary) -> void:
	LFFile.save(path, JSON.stringify(json));


static func loadFile(path: String, ensureFile := true) -> String:
	var globalPath = ProjectSettings.globalize_path(path);
	if not FileAccess.file_exists(globalPath):
		if ensureFile:
			LFFile.create(globalPath);
	return FileAccess.get_file_as_string(globalPath);


static func loadJson(path: String, ensureFile := true) -> Dictionary:
	return JSON.parse_string(LFFile.loadFile(path, ensureFile));


static func pathLeadsTo(path: String) -> int:
	var p := path if path.ends_with("://") else path.rstrip("/\\")
	if FileAccess.file_exists(path):
		return PATH_TARGET.FILE
	var d := DirAccess.open(p)
	if d != null:
		return PATH_TARGET.DIR
	
	return PATH_TARGET.MISSING


static func pathExists(path: String):
	var globalPath = ProjectSettings.globalize_path(path);
	return LFFile.pathLeadsTo(globalPath) != PATH_TARGET.MISSING;
