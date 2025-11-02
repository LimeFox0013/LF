class_name LFAwait;

@export var onFnAwaited: Callable;

var successfullyAwaited := 0;
var fns: Array;
var awaitedResults := [];
var completed := false;

signal awaited(results: Array[Variant]);


func _init(fns := fns) -> void:
	reset(fns);


func reset(fns := fns):
	self.fns = fns;
	completed = false;
	successfullyAwaited = 0;
	awaitedResults.clear();
	awaitedResults.resize(fns.size());
	
	return self;


func execAwaiterFn(fn):
	var fnIndx = fns.find(fn);
	var execFn = func ():
		var fnResult = await fn.call();
		
		if awaitedResults.has(fnIndx):
				push_error(
					'Function with index: "fnIndx" already was awaited.'
						.format({ "fnIndx": fnIndx }),
				);
		awaitedResults[fnIndx] = fnResult;
		successfullyAwaited += 1;
		if onFnAwaited:
			onFnAwaited.call(fnResult, fn);
			
		if !completed && successfullyAwaited == fns.size():
			awaited.emit(awaitedResults);
		
		return fnResult;
	return await execFn.call();


func exec():
	for fnIndx in fns.size():
		execAwaiterFn(fns[fnIndx]);
	
	await awaited;
	
	return awaitedResults;


static func all(fns: Array):
	return await LFAwait.new(fns).exec();


static func any(fns: Array):
	var awaiter = LFAwait.new(fns);
	awaiter.onFnAwaited = func (result, _fn):
		awaiter.completed = true;
		awaiter.awaited.emit(result);
	return await awaiter.exec();


static var nextTick:
	get(): return LFUtils.treeRoot.process_frame;
