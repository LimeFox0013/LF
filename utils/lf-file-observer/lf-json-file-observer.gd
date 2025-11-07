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


func setByPath(propsPath: String, value):
	data = LFDictionary.setByPath(data.duplicate(true), propsPath, value);


func eraseByPath(propsPath: String):
	data = LFDictionary.eraseByPath(data.duplicate(true), propsPath);
