## LFControl2D works as viewport anchor for a 2D nodes.
class_name LFControl2D;
extends LFLayoutControl;

@export var target: Node2D;
@export var syncInitialPosition := false;


func _ready() -> void:
	if syncInitialPosition:
		target.global_position = LFControl.getCenterPosOnViewport(self);
