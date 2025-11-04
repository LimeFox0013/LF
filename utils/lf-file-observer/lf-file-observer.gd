class_name LFFileObserver
extends Resource;

var _path: String;
var _transformOut: Callable = func(data): return data;
var _transformIn: Callable = func(data): return data;

var _data;

var data:
	get():
		if !_data:
			_data = _transformOut.call(LFFile.loadFile(_path));
		return _data;
	set(newData):
		LFFile.save(_path, _transformIn.call(newData));
		_data = newData;
		update.emit();
		

signal update;

func _init(
	filePath: String = '',
	transformOut := _transformOut,
	transformIn := _transformIn,
) -> void:
	_transformOut = transformOut;
	_transformIn = transformIn;
	_path = filePath;
