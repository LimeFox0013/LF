class_name LFTableDef;
extends Control;

var cellDefs: Dictionary = {}; # Dictionary mapping cellName -> LFTableCellDef

func _ready():
	_collectCellDefs();

func _collectCellDefs():
	cellDefs.clear();
	for child in get_children():
		if child is LFTableCellDef:
			var cellDef: LFTableCellDef = child;
			if cellDef.cellName.is_empty():
				push_warning("LFTableDef: Found LFTableCellDef with empty cellName, skipping");
				continue;
			if cellDefs.has(cellDef.cellName):
				push_warning("LFTableDef: Duplicate cellName '%s' found, overwriting previous definition" % cellDef.cellName);
			cellDefs[cellDef.cellName] = cellDef;

func getCellDef(cellName: String) -> LFTableCellDef:
	return cellDefs.get(cellName, null);

func hasCellDef(cellName: String) -> bool:
	return cellDefs.has(cellName);

func getCellNames() -> Array:
	return cellDefs.keys();
