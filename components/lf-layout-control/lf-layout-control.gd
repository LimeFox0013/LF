## LFLayoutControl is Control node that dont overlaps any other controls that
## placed behind it on z-index (click through).
class_name LFLayoutControl;
extends LFControl;

func _enter_tree() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE;
	focus_mode = Control.FOCUS_NONE;
