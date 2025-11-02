class_name LFSMOnLeaveState;
extends LFSMHook;


var states: Array[int];
var callback: Callable;


func _init(states: Array[int], callback: Callable) -> void:
	self.states = states;
	self.callback = callback;
