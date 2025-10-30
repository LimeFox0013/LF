class_name LFTableRow;
extends HBoxContainer;

var rowData: Dictionary = {};
var tableDef: LFTableDef = null;

func setRowData(data: Dictionary, def: LFTableDef):
	rowData = data;
	tableDef = def;
	_buildCells();

func _buildCells():
	# Clear existing cells
	for child in get_children():
		child.queue_free();
	
	if tableDef == null:
		push_warning("LFTableRow: tableDef is null, cannot build cells");
		return;
	
	# Create cells based on table definition
	var cellNames = tableDef.getCellNames();
	for cellName in cellNames:
		var cellDef: LFTableCellDef = tableDef.getCellDef(cellName);
		var cell = LFTableCell.new();
		
		# Set cell size constraints
		if cellDef.maxX != "auto" and cellDef.maxX is int:
			cell.custom_minimum_size.x = cellDef.maxX;
		if cellDef.maxY != "auto" and cellDef.maxY is int:
			cell.custom_minimum_size.y = cellDef.maxY;
		
		# Set cell content
		var cellValue = rowData.get(cellName, "");
		cell.setCellContent(cellValue);
		
		add_child(cell);
