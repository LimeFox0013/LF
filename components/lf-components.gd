class_name LFComponents;

## ToDo: do I need this way ?
static func initComponent(componentName: String):
	var prefixedName = 'lf-' + componentName;
	var scene = load('./' + prefixedName + '/' + prefixedName + '.tscn');
	return scene.instantiate();


static func createComponent(componentName: String, parentNode: Node):
	var component = initComponent(componentName);
	parentNode.add_child(component);
	await LFAwait.nextTick;
	return component;
	
