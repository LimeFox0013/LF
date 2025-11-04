class_name LFDictionary;

# ToDo: ensure := false
func setByPath(dictionary: Dictionary, propsPath: String, value):
	var pathArr := propsPath.split('.');
	var target = dictionary;
	var propToSet: String;
	for i in pathArr.size():
		var pathStep = pathArr[i];
		if i == pathArr.size():
			return target.set(pathStep, value);
		target = target.get(pathStep);
	
	return false;
