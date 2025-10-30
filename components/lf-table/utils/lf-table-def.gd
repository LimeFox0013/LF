class_name LFTableDef;
extends Resource;


@export var header := true;
@export var footer := true;

func _init(
	header := true,
	footer := true,
) -> void:
	self.header = header;
	self.footer = footer;
