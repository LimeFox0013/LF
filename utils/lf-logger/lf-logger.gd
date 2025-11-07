class_name LFLogger;
extends RefCounted;

var _loggerPrefix := [];

func _init(prefix := []) -> void:
	if !prefix.is_empty():
		setPrefix(prefix);


func setPrefix(prefix := []):
	_loggerPrefix = prefix;


# ToDo: write actual log.
func write():
	pass;


func log(...messages):
	if !LFLogger.enablePrintLogs:
		return;
	LFLogger.printMessage.callv(_loggerPrefix + messages);


func warning(...messages):
	if !LFLogger.enablePrintWarnings:
		return;
	LFLogger.pushWarning.callv(_loggerPrefix + messages);


func error(...messages):
	if !LFLogger.enablePrintErrors:
		return;
	LFLogger.pushError.callv(_loggerPrefix + messages);


static var enablePrintLogs := true;
static var enablePrintWarnings := true;
static var enablePrintErrors := true;
static var enableWritingLogFiles := false;

static func _completeMessage(prefix := [], ...messages):
	var completeLog := prefix.duplicate(true);
	for message in messages:
		completeLog.append(message);
		completeLog.append(' ');
	
	return completeLog;


static func printMessage(...messages):
	print.callv(_completeMessage.callv([[]] + messages));


static func pushWarning(...messages):
	push_warning.callv(_completeMessage.callv([[]] + messages));


static func pushError(...messages):
	push_error.callv(_completeMessage.callv([[]] + messages));
