class_name LFSMTransitionGuard;
extends LFSMHook;


var transitions: Array[int];
var callback := func () -> bool: return true;


func _init(transitions: Array[int], callback := callback) -> void:
	self.transitions = transitions;
	self.callback = callback;
