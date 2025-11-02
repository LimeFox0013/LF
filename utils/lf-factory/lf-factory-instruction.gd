class_name LFFactoryInstruction;
extends Resource;

var key: Variant;
var create: Callable;

func _init(key, create) -> void:
	self.key = key;
	self.create = create;
