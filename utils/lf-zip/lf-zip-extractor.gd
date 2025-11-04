# LFZipExtractor.gd
# Extracts a ZIP on a background Thread.
# Signals:
#   started()
#   progress(percent: float, file: String, index: int, total: int)
#   finished(success: bool, canceled: bool)

class_name LFZipExtractor;
extends Node;

signal started;
signal progress(percent: float, file: String, index: int, total: int);
signal finished(success: bool, canceled: bool);

var pathToZip: String = '';
var pathToExtract: String = '';

var _thread: Thread;
var _cancelRequested: bool = false;
var _isRunning: bool = false;

func start() -> void:
	if _isRunning:
		return;
	_isRunning = true;
	_cancelRequested = false;

	print('[LFZipExtractor] start -> zip: ', pathToZip, ' -> dir: ', pathToExtract);
	call_deferred('_emitStarted');

	_thread = Thread.new();
	# Thread function RETURNS a Dictionary {success: bool, canceled: bool}
	_thread.start(Callable(self, '_threadExtract'));

func cancel() -> void:
	_cancelRequested = true;

func _emitStarted() -> void:
	started.emit();

# ---- Worker thread body (DO NOT touch scene tree here) ----
func _threadExtract() -> Dictionary:
	var result := { 'success': false, 'canceled': false };

	var zip := ZIPReader.new();
	var open_err := zip.open(pathToZip);
	if open_err != OK:
		print('[LFZipExtractor] ZIP open failed: ', open_err);
		# Schedule finalize on main thread, then return.
		call_deferred('_onThreadDone');
		return result;

	# Ensure extract directory exists.
	if DirAccess.open(pathToExtract) == null:
		DirAccess.make_dir_recursive_absolute(pathToExtract);

	var files := zip.get_files();
	var total := files.size();
	var index := 0;

	for file_path in files:
		if _cancelRequested:
			result.canceled = true;
			zip.close();
			call_deferred('_onThreadDone');
			return result;

		var is_dir := file_path.ends_with('/');

		if is_dir:
			var abs_dir := _join(pathToExtract, file_path);
			DirAccess.make_dir_recursive_absolute(abs_dir);
		else:
			var abs_file := _join(pathToExtract, file_path);
			var parent := abs_file.get_base_dir();
			DirAccess.make_dir_recursive_absolute(parent);

			var bytes := zip.read_file(file_path); # PackedByteArray
			var fa := FileAccess.open(abs_file, FileAccess.WRITE);
			if fa:
				fa.store_buffer(bytes);
				fa.flush();
				fa.close();

		index += 1;
		var percent := (float(index) * 100.0 / float(total)) if total > 0 else 100.0;
		# Bounce progress back to main thread:
		call_deferred('_emitProgress', percent, file_path, index, total);

	zip.close();
	result.success = true;

	# Tell main thread to collect & emit 'finished'.
	call_deferred('_onThreadDone');
	return result;
# ---- end worker ----

# Runs on main thread; joins the thread and emits 'finished'.
func _onThreadDone() -> void:
	if _thread:
		var ret = _thread.wait_to_finish(); # Dictionary from _threadExtract()
		_thread = null;

		_isRunning = false;
		var success = ret.has('success') and ret.success;
		var canceled = ret.has('canceled') and ret.canceled;

		print('[LFZipExtractor] finished. success=', success, ' canceled=', canceled);
		finished.emit(success, canceled);

func _emitProgress(percent: float, file: String, index: int, total: int) -> void:
	progress.emit(percent, file, index, total);

# Helpers
func _join(base: String, entry: String) -> String:
	return (base + entry if base.ends_with('/') else base + '/' + entry).simplify_path();
