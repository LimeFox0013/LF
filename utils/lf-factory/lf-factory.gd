class_name LFFactory;


var container: Node;
var _pools: Dictionary[Variant, Array] = {};
var _entities: Dictionary[Variant, Variant] = {};
var _createFns: Dictionary[Variant, Callable] = {};


func setupFactory(
	instructions : Array[LFFactoryInstruction],
	container := container,
):
	setContainer(container);
	for instruction in instructions:
		_createFns[instruction.key] = instruction.create;
		_pools[instruction.key] = [];


func setContainer(newCotainer: Node):
	if container && container != newCotainer:
		push_error('Switching containers can lead to unexpected behaviour');
	container = newCotainer;


func onNewCreated(entity):
	pass;


func onCreate(entity):
	pass;


func onReturn(entity):
	pass;


func reset():
	#for entity in _entities:
		#if entity && !pool.has(entity):
			#returnEntity(entity);
	
	for pool in _pools.values():
		pool.clear();
	#_entities.clear();
	for entity in _entities:
		if entity.queue_free:
			entity.queue_free();
	await LFAwait.nextTick;
	_entities.clear();
	container = Node.new();
	#_createFns = {} as Dictionary[Variant, Callable];

## calls current onReturn callback to each created entity
func returnAllEntities():
	for entity in _entities:
		returnEntity(entity);


func returnEntity(entity):
	await onReturn(entity);
	var key = _entities[entity];
	_pools[key].append(entity);


func createEntityInPool(key, container := container):
	var newEntity = await _createFns[key].call();
	_entities[newEntity] = key;
	await onNewCreated(newEntity);
	await LFUtils.moveNode(newEntity, container);
	_pools[key].append(newEntity);
	return newEntity;

func create(key, container := container):
	if !_createFns.has(key):
		push_error(
			'Factory dont has instructions for enttity key "{key}"'.format(
				{ 'key': key },
			),
		);
		return;
	
	if _pools[key].is_empty():
		await createEntityInPool(key, container)
		
	var entity = _pools[key].pop_back();
	await onCreate(entity);
	return entity;
