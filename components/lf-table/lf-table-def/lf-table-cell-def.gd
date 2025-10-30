class_name LFTableCellDef;
extends Control;

@export var cellName: String = "";
@export var maxX: Variant = "auto"; # Can be int or "auto"
@export var maxY: Variant = "auto"; # Can be int or "auto"

func _ready():
	if cellName.is_empty():
		push_warning("LFTableCellDef: cellName is empty, this may cause issues");
