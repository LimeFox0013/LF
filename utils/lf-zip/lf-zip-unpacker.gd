class_name ZipUnpacker;
extends RefCounted;

signal unzipProgress(done: int, total: int);
signal unzipFinished(result: Dictionary);

var _thread: Thread;
var _cancelFlag := false;

# --- helpers ---
static func _ensureDirLike(path: String) -> String:
	# Treat a path as a directory: strip trailing file name if it looks like one.
	# Examples:
	#  'user://out'        -> 'user://out/'
	#  'user://out.zip'    -> 'user://'
	#  'user://out/f.zip'  -> 'user://out/'
	#  'user://out/'       -> 'user://out/'
	var p := path.simplify_path();
	if p == '':
		return p;
	# If it ends with '/', it's already a dir.
	if p.ends_with('/'):
		return p;
	# If the last segment has a dot, assume it's a file name; drop it.
	var last := p.get_file();
	if last.find('.') != -1:
		p = p.get_base_dir();
	# Ensure trailing slash.
	return p if  p.ends_with('/') else (p + '/');

## Starts async unzip work. Emits `unzipFinished(result)`.
func start(zipPath: String, targetDir: String = '', progressEvery: int = 1) -> int:
	if _thread != null && _thread.is_alive():
		return ERR_BUSY;
	_cancelFlag = false;
	_thread = Thread.new();
	var err := _thread.start(Callable(self, '_job').bind(zipPath, targetDir, progressEvery));
	return err;

func cancel() -> void:
	_cancelFlag = true;

# --- Internal threaded job ---
func _job(zipPath: String, targetDir: String, progressEvery: int) -> void:
	var zr := ZIPReader.new();
	var openErr := zr.open(zipPath);
	if openErr != OK:
		call_deferred('_emitFinished', {
			'ok': false, 'written': 0, 'skipped': 0,
			'errors': PackedStringArray(['Failed to open zip (%s), error: %d' % [zipPath, openErr]])
		});
		return;

	# Force destination to be a directory.
	var baseDir := targetDir if targetDir != '' else zipPath.get_base_dir();
	baseDir = _ensureDirLike(baseDir).simplify_path();

	# Create the base dir up front.
	var mkRoot := DirAccess.make_dir_recursive_absolute(baseDir);
	if mkRoot != OK && mkRoot != ERR_ALREADY_EXISTS:
		zr.close();
		call_deferred('_emitFinished', {
			'ok': false, 'written': 0, 'skipped': 0,
			'errors': PackedStringArray(['Failed to create base dir: %s (err %d)' % [baseDir, mkRoot]])
		});
		return;

	var entries := zr.get_files();

	# Count only files for progress.
	var fileList: PackedStringArray = [];
	for e in entries:
		if !e.ends_with('/'):
			fileList.append(e);
	var total := fileList.size();

	var result := { 'ok': false, 'written': 0, 'skipped': 0, 'errors': PackedStringArray() };

	# Debug: show what we’re extracting to (remove if noisy).
	print_debug('[LFZip] entries=', entries.size(), ' -> baseDir=', baseDir);

	for entry in entries:
		if _cancelFlag:
			result.errors.append('Cancelled by user.');
			break;

		# Normalize output path and pin it under baseDir.
		var outPath := (baseDir.path_join(entry)).simplify_path();

		# Ensure it never escapes baseDir.
		if !outPath.begins_with(baseDir):
			result.errors.append('Blocked unsafe path: %s' % entry);
			result.skipped += 1;
			continue;

		if entry.ends_with('/'):
			var mkDirErr := DirAccess.make_dir_recursive_absolute(outPath);
			if mkDirErr != OK && mkDirErr != ERR_ALREADY_EXISTS:
				result.errors.append('Failed to create dir: %s (err %d)' % [outPath, mkDirErr]);
			continue;

		# Ensure parent dir exists.
		var outDir := outPath.get_base_dir();
		var mkErr := DirAccess.make_dir_recursive_absolute(outDir);
		if mkErr != OK && mkErr != ERR_ALREADY_EXISTS:
			result.errors.append('Failed to create dir for %s (err %d)' % [outPath, mkErr]);
			result.skipped += 1;
			continue;

		# Read file bytes and write out.
		var data := zr.read_file(entry);
		var fa := FileAccess.open(outPath, FileAccess.WRITE);
		if fa == null:
			result.errors.append('Failed to open for write: %s (err %d)' % [outPath, FileAccess.get_open_error()]);
			result.skipped += 1;
			continue;

		fa.store_buffer(data);
		fa.flush();
		fa.close();
		result.written += 1;

		if progressEvery > 0 && (result.written % progressEvery) == 0:
			call_deferred('_emitProgress', result.written, total);

	zr.close();

	result.ok = result.errors.is_empty() if !_cancelFlag else false;

	call_deferred('_emitProgress', result.written, total);
	call_deferred('_emitFinished', result);

func _emitProgress(done: int, total: int) -> void:
	emit_signal('unzipProgress', done, total);

func _emitFinished(result: Dictionary) -> void:
	if _thread != null && !_thread.is_alive():
		_thread = null;
	emit_signal('unzipFinished', result);
