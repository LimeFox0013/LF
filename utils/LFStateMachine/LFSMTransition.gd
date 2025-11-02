class_name LFSMTransition;
extends Resource;


var name: int;
var from: Array[int];
var to: int;


func _init(name: int, from: Array[int], to: int) -> void:
	self.name = name;
	self.from = from;
	self.to = to;
