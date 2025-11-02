# MIT License
# LFThread.gd — per-thread utility that does NOT interact with the scene tree.
# - Extend RefCounted (no Node, no timers, no auto-exit hooks).
# - Cooperative cancellation via shouldStop().
# - Manual .poll() to opportunistically join finished threads.
# - Signals are emitted from this object; you can connect/await them as needed.

class_name LFThread;
extends RefCounted;

signal started(id: String, key: String);
signal finished(id: String, key: String, result);
signal cancelled(id: String, key: String);

# ---- Public config (you can read/modify if needed)
# optional label
var key: String = '';
var id: String = LFUuid.gen('lf-thread');

# ---- State (read-only by convention; use getters)
var _thread: Thread;
var _stopFlag: bool = false;
var _task: Callable;
var _startedAt: int = 0;
var _endedAt: int = 0;
var _result: Variant = null;
var _running: bool = false;


func _init(_key: String = '') -> void:
	key = _key;

# ------------------------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------------------------

## start
## Starts the thread with the provided callable.
## If the callable accepts 1 argument, it receives a `shouldStop` callable to poll.
## Returns true on success; false if already running or start failed.
func start(task: Callable) -> bool:
	if _running:
		return false;
	_task = task;
	_thread = Thread.new();
	_stopFlag = false;
	_result = null;
	_startedAt = Time.get_unix_time_from_system();
	_endedAt = 0;

	var err := _thread.start(Callable(self, '_threadWrapper'));
	if err != OK:
		_thread = null;
		return false;

	_running = true;
	started.emit(id, key);
	return true;

## requestStop / cancel
## Signals the worker to stop ASAP (cooperative).
func requestStop() -> void:
	_stopFlag = true;

func cancel() -> void:
	requestStop();

## isDone
## Returns true if the thread has completed and finalization ran.
func isDone() -> bool:
	return not _running;

## joinNow
## Blocks until the thread ends and performs cleanup.
## Returns true if a join happened; false if nothing was running.
func joinNow() -> bool:
	if not _running:
		return false;
	var result = _thread.wait_to_finish() if _thread.is_alive() else _thread.wait_to_finish();
	_finalize(result);
	return true;

## poll
## Non-blocking maintenance you call from your own loop.
## If the thread finished, this joins and emits the appropriate signal.
func poll() -> void:
	if not _running or _thread == null:
		return;
	if not _thread.is_alive():
		var result = _thread.wait_to_finish();
		_finalize(result);

## shouldStop
## The worker can call this periodically to check for cancellation.
func shouldStop() -> bool:
	return _stopFlag;

## getResult
## Access the result after completion (null until finished).
func getResult() -> Variant:
	return _result;

## getInfo
## Lightweight status snapshot for debugging/telemetry.
func getInfo() -> Dictionary:
	return {
		'id': id,
		'key': key,
		'running': _running,
		'startedAt': _startedAt,
		'endedAt': _endedAt,
		'durationSec': (_endedAt - _startedAt) if _endedAt > 0 else (Time.get_unix_time_from_system() - _startedAt) if _running else 0,
		'stopRequested': _stopFlag
	};

# ------------------------------------------------------------------------------
# Internals
# ------------------------------------------------------------------------------

func _threadWrapper() -> Variant:
	# No try/catch in GDScript; just execute and return.
	var result = null;
	result = _task.call(Callable(self, 'shouldStop')) if _task.get_argument_count() >= 1 else _task.call();
	return result;

func _finalize(result: Variant) -> void:
	_running = false;
	_result = result;
	_endedAt = Time.get_unix_time_from_system();

	# Emit finished vs cancelled based on whether a stop was requested when it ended.
	(cancelled if _stopFlag else finished).emit(id, key, _result);
