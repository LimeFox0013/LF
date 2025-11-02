class_name LFSMOnAfterTransition;
extends LFSMHook;


var transitions: Array[int];
var callback: Callable;


func _init(transitions: Array[int], callback: Callable) -> void:
	self.transitions = transitions;
	self.callback = callback;
