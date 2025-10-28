class_name LFJsonFileObserver;
extends LFFileObserver;

func _init(filePath: String = '') -> void:
	_transformIn = func (data): return JSON.stringify(data);
	_transformOut = func (data): return JSON.parse_string(data);
	super._init(
		filePath,
		_transformOut,
		_transformIn,
	);
