class_name LFSMCfg;
extends Resource;


var initialState: int;
var transitions: Array[LFSMTransition];
var hooks: Array[LFSMHook];


func _init(
	initialState: int,
	transitions: Array[LFSMTransition],
	hooks := hooks,
) -> void:
	self.initialState = initialState;
	self.transitions = transitions;
	self.hooks = hooks;
