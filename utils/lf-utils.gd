class_name LFUtils;
extends Resource;


static func createTimer(ms: float, callback := func(): pass) -> SceneTreeTimer:
	var timer: SceneTreeTimer = treeRoot.root.get_tree().create_timer(ms / 1000.0);
	timer.timeout.connect(callback, CONNECT_ONE_SHOT);
	return timer;


static func timeout(ms: float, callback := func(): pass):
	return await createTimer(ms, callback).timeout;


static var mainLoop: MainLoop:
	get(): return Engine.get_main_loop();

static var treeRoot: SceneTree:
	get(): return mainLoop.root.get_tree();


static func mergeArr(targetArray: Array, ...arrays):
	var target = targetArray.duplicate(true);
	for array in arrays:
		target.append_array(array);
	return target;


static func mergeObj(targetObject: Resource, ...dictionaries):
	var target = targetObject.duplicate(true);
	for dictionary in dictionaries:
		for prop in dictionary.keys():
			target.set(prop, dictionary.get(prop));
	return target;


static func areEqualRes(props: Array[String], target: Resource, ...resources) -> bool:
	if resources.is_empty():
		return true;
	# Cache target values
	var targetProps := {}
	var targetPropsArr := selectPropsArr(target);
	for prop in props:
		targetProps[prop] = target.get(prop) if targetPropsArr.has(prop) else null;

	# Compare with each other resource
	for resource in resources:
		if resource == null || !(resource is Resource):
			return false;
		var resourcePropsArr := selectPropsArr(resource);
		for prop in props:
			var a = targetProps[prop];
			var b = resource.get(prop) if resourcePropsArr.has(prop) else null;
			if !deepEqual(a, b):
				return false;
	return true;


static func selectPropsArr(resource: Resource) -> Array[String]:
	var props: Array[String] = [];
	props.assign(
		resource.get_property_list().map(
			func (propDict): return propDict.name,
		),
	);
	return props;


static func deepEqual(a, b) -> bool:
	if typeof(a) != typeof(b):
		return false;

	match typeof(a):
		TYPE_ARRAY:
			var aa: Array = a
			var bb: Array = b
			if aa.size() != bb.size():
				return false;
			for i in aa.size():
				if !deepEqual(aa[i], bb[i]):
					return false;
			return true;

		TYPE_DICTIONARY:
			var da: Dictionary = a
			var db: Dictionary = b
			if da.size() != db.size():
				return false
			for k in da.keys():
				if !db.has(k) || !deepEqual(da[k], db[k]):
					return false;
			return true;

		_:
			return a == b;


static func moveNode(node: Node, newParent: Node):
	var nodesCurrentParent = node.get_parent();
	if nodesCurrentParent != newParent:
		if nodesCurrentParent:
			nodesCurrentParent.remove_child(node);
		newParent.add_child.call_deferred(node);
		await newParent.get_tree().process_frame;
		node.owner = newParent;
		
