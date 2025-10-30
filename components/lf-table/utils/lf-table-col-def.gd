class_name  LFTableColDef;
extends Resource;


@export var name: String;


func _init(name: String) -> void:
	self.name = name if name else self.name;
