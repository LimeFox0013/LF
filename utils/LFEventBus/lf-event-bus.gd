class_name LFEventBus;


static var _ee: LFEventEmitter;
static var ee: LFEventEmitter:
	get():
		if !LFEventBus._ee:
			LFEventBus._ee = LFEventEmitter.new();
		return LFEventBus._ee;
	


static func emit(event: String, payload := {}):
	LFEventBus.ee.emit.call(event, payload);


static func on(event, cb: Callable):
	LFEventBus.ee.on.call(event, cb);


static func once(event, cb: Callable):
	LFEventBus.ee.once.call(event, cb);


static func off(event: String, cb: Callable):
	LFEventBus.ee.off.call(event, cb);
