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


func returnEntity(entity):
	await onReturn(entity);
	var key = _entities[entity];
	_pools[key].append(entity);


func create(key, container := container):
	if !_createFns.has(key):
		push_error(
			'Factory dont has instructions for enttity key "{key}"'.format(
				{ 'key': key },
			),
		);
		return;
	
	if _pools[key].is_empty():
		var newEntity = await _createFns[key].call();
		await onNewCreated(newEntity);
		await LFUtils.moveNode(newEntity, container);
		
		#if newEntity is Loot:
			#var entityNumber = _entities.values().reduce(
				#func(count, entityKey):
					#return count + 1 if entityKey == key else count,
				#0,
			#) + 1;
			#var label = Label.new();
			#var labelSettings = LabelSettings.new();
			#labelSettings.font_size = 60.0;
			#labelSettings.font_color = Color.CHARTREUSE;
			#label.label_settings = labelSettings;
			#label.text = str(entityNumber);
			#newEntity.add_child(label)
		
		_entities[newEntity] = key;
		_pools[key].append(newEntity);
		
	var entity = _pools[key].pop_back();
	await onCreate(entity);
	return entity;
