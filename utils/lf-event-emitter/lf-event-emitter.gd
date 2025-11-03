class_name LFEventEmitter;


var handlers := {};


func emit(event: String, payload := {}):
	var callbacks: Array[Callable] = [];
	callbacks.assign(
		_getCallbacks(event).map(
			func(callback): return callback.bind(payload),
		),
	);
	
	return await LFAwait.all(callbacks);


func on(event: String, cb: Callable):
	_ensureCallbacks(event).append(cb);


func once(event: String, cb: Callable):
	_ensureCallbacks(event).append(
		func(payload := {}):
			off(event, cb);
			cb.call(payload);
	);


func off(event: String, cb: Callable):
	if cb:
		_getCallbacks(event).erase(cb);
	else:
		handlers.set(event, []);


func _getCallbacks(event: String) -> Array[Callable]:
	var ensuredHandlers: Array[Callable] = [];
	if handlers.has(event):
		ensuredHandlers.assign(handlers.get(event));
	return ensuredHandlers;


func _ensureCallbacks(event: String) -> Array[Callable]:
	if !handlers.get(event):
		var eventCallbacks: Array[Callable] = [];
		handlers.set(event, eventCallbacks);
	return _getCallbacks(event);
