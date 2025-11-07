class_name LFDictionary;


static func getByPath(dictionary: Dictionary, propsPath: String, stepDelta := 0):
	var pathArr := propsPath.split('.');
	var target = dictionary;
	for i in pathArr.size():
		var pathStep = pathArr[i];
		if (i + stepDelta) == pathArr.size():
			return target;
		target = target.get(pathStep);
	
	return null;


static func setByPath(dictionary: Dictionary, propsPath: String, value):
	var pathArr := propsPath.split('.');
	var targetProp := propsPath[pathArr.size() - 1];
	var target = getByPath(dictionary, propsPath, 1);
	target.set(targetProp, value);
	
	return dictionary;


static func eraseByPath(dictionary: Dictionary, propsPath: String):
	var pathArr := propsPath.split('.');
	var targetProp := propsPath[pathArr.size() - 1];
	var target = getByPath(dictionary, propsPath, 1);
	target.erase(targetProp);
	
	return dictionary;
	
