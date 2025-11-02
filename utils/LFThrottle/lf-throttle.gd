class_name LFThrottle;


static func fn(
	callback: Callable,
	t := 1000.0 / 60,
	trailing := false,
	leading := true,
):
	var state := {
		'executedAt': -1.0,
		'latestArgs': [],
	};
	return func(...args):
		state.latestArgs = args;
		if state.executedAt == -1.0 || Time.get_ticks_msec() - state.executedAt >= t:
			if leading:
				state.executedAt = Time.get_ticks_msec();
				callback.callv(args);
			if trailing:
				state.executedAt = Time.get_ticks_msec() + t;
				await LFUtils.timeout(t, func(): callback.callv(state.latestArgs));
