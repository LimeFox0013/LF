class_name LFDebounce;

static func fn(callback: Callable, ms := 1000.0 / 60):
	var state := {
		'timer': null,
		'callback': null,
	};
	
	return func(...args):
		if state.timer:
			state.timer.timeout.disconnect(state.callback);
		state.callback = callback.bindv(args);
		state.timer = LFUtils.createTimer(ms, state.callback);
	
