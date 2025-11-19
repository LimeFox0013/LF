class_name LFControlOut;
extends LFControl;


@export var label: Label;


static func setProp(propKey: String, text: String):
	var control = _controls_registry.get(propKey);
	
	if control is LFControlOut:
		print(propKey, ' ', text, ' ', control)
		control.label.text = text;
