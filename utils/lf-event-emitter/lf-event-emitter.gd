class_name LFEventEmitter;


var handlers := {};


func emit(event: String, ...args):
	print('emit of ', event, ' ', _getCallbacks(event), handlers)
	var callbacks: Array[Callable] = [];
	callbacks.assign(
		_getCallbacks(event).map(
			func(callback: Callable): return callback.bindv(args),
		),
	);
	
	return await LFAwait.all(callbacks);


func on(event: String, cb: Callable):
	print('On ', event, cb)
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
		print(123, handlers.get(event))
		ensuredHandlers.assign(handlers.get(event));
	return ensuredHandlers;


func _ensureCallbacks(event: String) -> Array[Callable]:
	if !handlers.get(event):
		var eventCallbacks: Array[Callable] = [];
		handlers.set(event, eventCallbacks);
		# ToDo: why this fix ???
		return eventCallbacks;
	return _getCallbacks(event);
