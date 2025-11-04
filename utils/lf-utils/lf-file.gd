class_name LFFile;


enum PATH_TARGET { MISSING, FILE, DIR }


static func create(path: String, content = ''):
	var absolutePath = toAbsolute(path);
	LFFile.ensureDir(absolutePath);
	var f := FileAccess.open(absolutePath, FileAccess.WRITE);
	
	if f == null:
		push_error("Failed to create file %s (open err=%s)" % [
			absolutePath,
			FileAccess.get_open_error(),
		]);
		return false;
	f.store_string(content);
	f.close();


static func ensureDir(path: String) -> String:
	DirAccess.make_dir_recursive_absolute(
		toAbsolute(path).get_base_dir(),
	);
	return path;


static func save(path: String, content = '', ensureFile := true):
	var absolutePath = toAbsolute(path);
	if !FileAccess.file_exists(absolutePath):
		if ensureFile:
			LFFile.create(absolutePath, content);
	var f := FileAccess.open(absolutePath, FileAccess.WRITE);
	f.store_string(content);
	f.close();
	


static func saveJson(path: String, json: Dictionary) -> void:
	LFFile.save(path, JSON.stringify(json));


static func loadFile(path: String, ensureFile := true) -> String:
	var absolutePath = toAbsolute(path);
	if not FileAccess.file_exists(absolutePath):
		if ensureFile:
			LFFile.create(absolutePath);
	return FileAccess.get_file_as_string(absolutePath);


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


static func pathExists(path: String) -> bool:
	var absolutePath = toAbsolute(path);
	return LFFile.pathLeadsTo(absolutePath) != PATH_TARGET.MISSING;


static func toAbsolute(inputPath: String) -> String:
	var path := inputPath.strip_edges();
	if path == '':
		return ProjectSettings.globalize_path('res://').simplify_path();

	# Normalize slashes early so checks are consistent.
	path = _normalizeSlashes(path);

	# If already a Windows or POSIX absolute path, just simplify.
	if _isWindowsAbsolute(path) or path.begins_with('/'):
		return path.simplify_path();

	# Recognized Godot schemes.
	if path.begins_with('res://') or path.begins_with('user://'):
		return ProjectSettings.globalize_path(path).simplify_path();

	# Handle dot-relative: './...' or '../...'
	if path.begins_with('./') or path.begins_with('../'):
		var resRel := ('res://' + path).simplify_path();
		return ProjectSettings.globalize_path(resRel).simplify_path();

	# Otherwise treat as project-relative to res://
	var assumedRes := ('res://' + (path if not path.begins_with('/') else path.substr(1))).simplify_path();
	return ProjectSettings.globalize_path(assumedRes).simplify_path();


static func _normalizeSlashes(p: String) -> String:
	return p.replace('\\', '/');


# Detects Windows absolute like 'C:/...' or 'z:/...'.
# Uses unicode_at(0) to check for an ASCII letter.
static func _isWindowsAbsolute(p: String) -> bool:
	if p.length() < 3:
		return false;
	if p[1] != ':' or p[2] != '/':
		return false;
	var c := p.unicode_at(0);
	var is_letter := (c >= 65 and c <= 90) or (c >= 97 and c <= 122); # A-Z or a-z
	return is_letter;
