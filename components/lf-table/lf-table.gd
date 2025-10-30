class_name LFTable;
extends MarginContainer;

const LF_TABLE_HEADER_SCENE = preload("./lf-table-header/lf-table-header.tscn");
const LF_TABLE_BODY_SCENE = preload("./lf-table-body/lf-table-body.tscn");
const LF_TABLE_FOOTER_SCENE = preload("./lf-table-footer/lf-table-footer.tscn");

@export var tableDef := LFTableDef.new();
@export var colDefs: Array[LFTableColDef] = [];
# Defines row id property name.
@export var rowId := 'id';
@export var rowsData: Array[Dictionary] = [];

var header: LFTableHeader;
var body: LFTableBody;
var footer: LFTableFooter;

func _ready():
	_buildTable();

func _buildTable():
	for child in get_children():
		if child is LFTableHeader:
			header = child;
		if child is LFTableBody:
			body = child;
		if child is LFTableFooter:
			footer = child;
	
	if !body:
		body = LF_TABLE_BODY_SCENE.instantiate();
		add_child(body);
	
	if tableDef.header && !header:
		header = LF_TABLE_HEADER_SCENE.instantiate();
		add_child(header);
		move_child(header, body.get_index());

	if tableDef.footer && !footer:
		footer = LF_TABLE_FOOTER_SCENE.instantiate();
		body.add_sibling(footer);

func setData(rows: Array):
	pass;
