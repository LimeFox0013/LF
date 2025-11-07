class_name LFProcess;
extends RefCounted;


# Public settings
var autoRestart: bool = true
var maxRestartAttempts: int = -1	# -1 = infinite
var restartBackoffMs: int = 1500	# grows linearly by attempt count

# Internal state
var procInfo: Dictionary = {}
var pid: int = -1

var _uid := LFUuid.gen('lf-process');
var _logger := LFLogger.new(['[LFProcess]', '(%s):' % [_uid]]);

var _stdio: FileAccess = null
var _stderr: FileAccess = null
var _readerThread: Thread = null
var _stderrThread: Thread = null
var _monitorThread: Thread = null
var _stopRequested: bool = false
var _restartCount: int = 0
var _commandPath: String
var _commandArgs: PackedStringArray = []
var _env: Dictionary = {}

signal output(pid: int, line: String)
signal errorOutput(pid: int, line: String)
signal started(pid: int)
signal exited(pid: int, exitCode: int)
signal restarted(pid: int, attempt: int)


func _init(uid: String = ''):
	if uid:
		setUid(uid);


func setUid(uid: String):
	_uid = uid;
	_logger.setPrefix(['[LFProcess]', '(%s): ' % [_uid]]);


func start(path: String, args: PackedStringArray = [], env: Dictionary = {}) -> bool:
	# Save config for restarts
	_commandPath = path
	_commandArgs = args
	_env = env
	_stopRequested = false
	_restartCount = 0
	return _spawn()

func stop(killTree: bool = false) -> void:
	_autoJoinAndClean()
	_stopRequested = true
	if pid > 0:
		OS.kill(pid)	# will also work for non-child processes with given PID
		# (cross-platform per OS docs)
		pid = -1

func writeLine(text: String) -> void:
	if _stdio and _stdio.is_open():
		_stdio.write_line(text)
		_stdio.flush()


func isRunning() -> bool:
	return pid > 0 and OS.is_process_running(pid)


func getPid() -> int:
	return pid


func restartNow() -> bool:
	_logger.log('restarting process...')
	_autoJoinAndClean()
	_stopRequested = false
	return _spawn()

# Convenience: cross-platform shell command
# e.g. runShell("npm run start:dev", projectDir)
func runShell(cmdLine: String) -> bool:
	var path: String
	var args: PackedStringArray
	if OS.has_feature("windows"):
		path = "cmd.exe"
		args = ["/C", cmdLine]
	else:
		path = "/bin/sh"
		args = ["-lc", cmdLine]
	return start(path, args)

# ---- internals ----
func _spawn() -> bool:
	if _env and _env.size() > 0:
		for k in _env.keys():
			OS.set_environment(str(k), str(_env[k]))

	# Non-blocking exec with pipes; returns { "stdio": FileAccess, "stderr": FileAccess, "pid": int }
	procInfo = OS.execute_with_pipe(_commandPath, _commandArgs)
	if typeof(procInfo) != TYPE_DICTIONARY or not procInfo.has("pid"):
		_logger.error("Failed to start process: %s %s" % [_commandPath, str(_commandArgs)])
		return false

	pid = int(procInfo["pid"])
	_stdio = procInfo.get("stdio", null)
	_stderr = procInfo.get("stderr", null)

	# Spawn threads for I/O + lifecycle monitor
	_readerThread = Thread.new()
	_readerThread.start(_stdoutPump)

	_stderrThread = Thread.new()
	_stderrThread.start(_stderrPump)

	_monitorThread = Thread.new()
	_monitorThread.start(_monitor)

	_logger.log('successfully started process PID = ', pid);
	emit_signal("started", pid);
	return true


func _stdoutPump() -> void:
	while not _stopRequested and _stdio and _stdio.is_open():
		var line := _stdio.get_line()	# blocks until a line arrives; keep it off main thread
		if line == null:
			break
		emit_signal("output", pid, line)


func _stderrPump() -> void:
	while not _stopRequested and _stderr and _stderr.is_open():
		var line := _stderr.get_line()
		if line == null:
			break
		emit_signal("errorOutput", pid, line)


func _monitor() -> void:
	# Poll the process; when it exits, decide on restart
	while not _stopRequested and pid > 0 and OS.is_process_running(pid):
		OS.delay_msec(1000)	# gentle polling

	# Exited (or stop requested)
	var code := 0
	if pid > 0:
		code = OS.get_process_exit_code(pid)
	emit_signal("exited", pid, code)

	if not _stopRequested and autoRestart and (maxRestartAttempts < 0 or _restartCount < maxRestartAttempts):
		_restartCount += 1
		var waitMs := restartBackoffMs * _restartCount
		var deadline := Time.get_ticks_msec() + waitMs
		while Time.get_ticks_msec() < deadline and not _stopRequested:
			OS.delay_msec(100)
		if not _stopRequested:
			_spawn()
			emit_signal('restarted', pid, _restartCount)
			_logger.log('restarted with PID =', pid, 'restart count =', _restartCount)


func _autoJoinAndClean() -> void:
	for t in [_readerThread, _stderrThread, _monitorThread]:
		if t and t.is_started():
			t.wait_to_finish()
	# Close pipes
	if _stdio:
		_stdio.flush()
		_stdio = null
	if _stderr:
		_stderr = null
	procInfo = {}
