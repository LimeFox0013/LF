class_name LFSM;
extends Resource;

var _state: int;
var _cfg = LFSMCfg;
var _passing := false;

var _transitionDefs: Dictionary[int, LFSMTransition] = {};
var _hooks := {
	LFSMTransitionGuard: {},
	LFSMOnLeaveState: {},
	LFSMOnEnterState: {},
	LFSMOnAfterTransition: {},
};

signal leaveState(state: int);
signal enterState(state: int);
signal passedTransition(transition: int);

func _init(cfg: LFSMCfg) -> void:
	_cfg = cfg;
	_state = cfg.initialState;
	
	for transitionDef in cfg.transitions:
		_transitionDefs[transitionDef.name] = transitionDef;
	
	for hook in cfg.hooks:
		if hook is LFSMTransitionGuard:
			for transitionName in hook.transitions:
				if !_hooks[LFSMTransitionGuard].has(transitionName):
					_hooks[LFSMTransitionGuard][transitionName] = [];
				_hooks[LFSMTransitionGuard][transitionName].append(hook);
			
		if hook is LFSMOnLeaveState:
			for stateName in hook.states:
				if !_hooks[LFSMOnLeaveState].has(stateName):
					_hooks[LFSMOnLeaveState][stateName] = [];
				_hooks[LFSMOnLeaveState][stateName].append(hook);
			
		if hook is LFSMOnEnterState:
			for stateName in hook.states:
				if !_hooks[LFSMOnEnterState].has(stateName):
					_hooks[LFSMOnEnterState][stateName] = [];
				_hooks[LFSMOnEnterState][stateName].append(hook);
			
		if hook is LFSMOnAfterTransition:
			for transitionName in hook.transitions:
				if !_hooks[LFSMOnAfterTransition].has(transitionName):
					_hooks[LFSMOnAfterTransition][transitionName] = [];
				_hooks[LFSMOnAfterTransition][transitionName].append(hook);



func getTransitionDef(transition: int):
	return _transitionDefs[transition];


func canDo(transition: int):
	if _passing:
		return false;
	
	var transitionDef = getTransitionDef(transition);
	if transitionDef && _state in transitionDef.from:
		return true
	
	return false;


func do(transition: int):
	var transitionDef = getTransitionDef(transition);
	
	if canDo(transition):
		_passing = true;
		
		if _hooks[LFSMTransitionGuard].has(transition):
			var transitionGuards = _hooks[LFSMTransitionGuard][transition];
			for guardHook in transitionGuards:
				if await guardHook.callback.call() == false:
					return false;
		
		var previousState = _state;
		_state = NAN;
		
		if _hooks[LFSMOnLeaveState].has(previousState):
			var onLeaveStateHooks = _hooks[LFSMOnLeaveState][previousState];
			for hook in onLeaveStateHooks:
				await hook.callback.call();
		leaveState.emit(previousState);
		
		_state = transitionDef.to;
		if _hooks[LFSMOnEnterState].has(_state):
			var onEnterStateHooks = _hooks[LFSMOnEnterState][_state];
			for hook in onEnterStateHooks:
				await hook.callback.call();
		enterState.emit(_state);
		
		if _hooks[LFSMOnAfterTransition].has(transition):
			var onAfterTransitionHooks = _hooks[LFSMOnAfterTransition][transition];
			for hook in onAfterTransitionHooks:
				await hook.callback.call();
		
		_passing = false;
		passedTransition.emit(transition);
		
		return true;
	
	return false;
