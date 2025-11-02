class_name LFControl;
extends Control;

# Identifies whenever the controll will be awailable in global registry by
# given id. So You can get it then by LFControl.g({defined id})
@export var registryId: String;


func _init() -> void:
	if registryId:
		_controls_registry.set(registryId, self);


static var _controls_registry := {};

static func g(registryId: String) -> Control:
	var control = _controls_registry.get(registryId);
	return control if control else null as Control;


# Returns the Control's center position.
static func getCenterPos(controlNode: Control):
	return controlNode.size * 0.5;


# Returns the Control's center in viewport (screen) coordinates.
static func getCenterPosOnViewport(controlNode: Control) -> Vector2:
	return controlNode.get_global_rect().position + getCenterPos(controlNode);
