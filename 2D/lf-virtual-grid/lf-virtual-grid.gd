class_name LFVirtualGrid;
extends Node2D;

@export var camera: Camera2D;
@export var gridDef: Dictionary = {};
@export var rowHeight: float = 100.0;

## Node used to track logical viewport position (e.g. camera rig or player).
## If set, the virtual "view rect" will be centered on this node instead of the camera.
@export var viewportTracker: Node2D;

## Optional custom draw area in world units.
## If (0, 0), the real viewport size is used.
## If set (e.g. 2x or 3x viewport size), row visibility will be based on this
## larger area so rows are drawn ahead of time.
@export var drawArea: Vector2 = Vector2.ZERO;

var basePosition: Vector2 = Vector2.ZERO;

var currentFirstRow: int = 0;  # Top visible row index.
var currentLastRow: int = -1;  # Bottom visible row index.

signal drawRows(rows: Array[int]);
signal eraseRows(rows: Array[int]);

## Called when the node enters the scene tree.
## Initializes the grid state by calling reset().
func _ready() -> void:
	reset();


## Called every physics frame.
## Updates which rows should be drawn/erased based on logical viewport movement.
func _physics_process(delta: float) -> void:
	updateGrid();


## Resets the grid:
## - Saves the current node position as basePosition.
## - Clears all currently visible rows (via clearAll()).
## - Recalculates visible rows using the effective view rect (viewport or drawArea).
## - Emits drawRows() for the newly visible rows.
func reset(newPosition: Vector2 = position) -> void:
	basePosition = newPosition;
	position = basePosition;

	# Clear any existing visible rows.
	clearAll();

	var view: Rect2 = getEffectiveViewRectWorld();

	currentFirstRow = floori(view.position.y / rowHeight);
	currentLastRow = floori((view.position.y + view.size.y) / rowHeight);

	var rowsToDraw: Array[int] = [];
	for r in range(currentFirstRow, currentLastRow + 1):
		rowsToDraw.append(r);

	if rowsToDraw.size() > 0:
		drawRows.emit(rowsToDraw);


## Clears all currently tracked visible rows.
## Emits eraseRows() for every row in the current [currentFirstRow..currentLastRow] range,
## then resets the range so no rows are considered visible.
func clearAll() -> void:
	var rowsToErase: Array[int] = getCurrentVisibleRows();

	if rowsToErase.size() > 0:
		eraseRows.emit(rowsToErase);

	# After clear, no visible rows tracked.
	currentFirstRow = 0;
	currentLastRow = -1;


## Returns an array of currently visible row indices based on currentFirstRow/currentLastRow.
func getCurrentVisibleRows() -> Array[int]:
	var rows: Array[int] = [];
	if currentLastRow >= currentFirstRow:
		for r in range(currentFirstRow, currentLastRow + 1):
			rows.append(r);
	return rows;


## Computes which row indices entered or left the effective view area.
## Emits drawRows(rowsToDraw) and eraseRows(rowsToErase) accordingly.
func updateGrid() -> void:
	var view: Rect2 = getEffectiveViewRectWorld();

	var newFirstRow: int = floori(view.position.y / rowHeight);
	var newLastRow: int = floori((view.position.y + view.size.y) / rowHeight);

	# No change in visible vertical row range.
	if newFirstRow == currentFirstRow and newLastRow == currentLastRow:
		return;

	var oldRows: Array[int] = [];
	var newRows: Array[int] = [];

	for r in range(currentFirstRow, currentLastRow + 1):
		oldRows.append(r);

	for r in range(newFirstRow, newLastRow + 1):
		newRows.append(r);

	var rowsToDraw: Array[int] = [];
	var rowsToErase: Array[int] = [];

	# new - old = rows to draw
	for r in newRows:
		if not oldRows.has(r):
			rowsToDraw.append(r);

	# old - new = rows to erase
	for r in oldRows:
		if not newRows.has(r):
			rowsToErase.append(r);

	if rowsToDraw.size() > 0:
		drawRows.emit(rowsToDraw);
	if rowsToErase.size() > 0:
		eraseRows.emit(rowsToErase);

	currentFirstRow = newFirstRow;
	currentLastRow = newLastRow;


## Returns the camera's real viewport rectangle expressed in world coordinates.
## This accounts for the camera's canvas transform (zoom, offset, etc.).
func getCameraViewportRectWorld(cam: Camera2D) -> Rect2:
	var viewport := cam.get_viewport();
	var vpRect: Rect2 = viewport.get_visible_rect();

	var screenTopLeft: Vector2 = vpRect.position;
	var screenBottomRight: Vector2 = vpRect.position + vpRect.size;

	var invCanvasXform: Transform2D = cam.get_canvas_transform().affine_inverse();
	var worldTopLeft: Vector2 = invCanvasXform * screenTopLeft;
	var worldBottomRight: Vector2 = invCanvasXform * screenBottomRight;

	return Rect2(worldTopLeft, worldBottomRight - worldTopLeft);


## Returns the effective view rect in world coordinates.
## - Size: viewport size or drawArea.
## - Center: viewportTracker.global_position if set, otherwise camera center.
##   This lets you drive visibility using another node (e.g. a camera rig without shake).
func getEffectiveViewRectWorld() -> Rect2:
	var baseView: Rect2 = getCameraViewportRectWorld(camera);

	var size: Vector2 = baseView.size;
	if drawArea != Vector2.ZERO:
		size = drawArea;

	var center: Vector2;

	if viewportTracker:
		center = viewportTracker.global_position;
	else:
		# Fallback: center on actual camera rect (may include shake)
		center = baseView.position + baseView.size * 0.5;

	var halfSize: Vector2 = size * 0.5;
	return Rect2(center - halfSize, size);


## Returns the world-space Rect2 for the given row index.
## The row spans the current effective view width (based on drawArea or viewport)
## and is aligned along the Y-axis starting at basePosition.y + row * rowHeight.
func getRowRectWorld(row: int) -> Rect2:
	var view: Rect2 = getEffectiveViewRectWorld();
	var rowTopY: float = basePosition.y + float(row) * rowHeight;
	var rowPos: Vector2 = Vector2(view.position.x, rowTopY);
	var rowSize: Vector2 = Vector2(view.size.x, rowHeight);

	return Rect2(rowPos, rowSize);


## Returns the screen-space (viewport coordinates) Rect2 for the given row index.
## Useful if you need pixel-perfect positioning in the viewport.
func getRowRectScreen(row: int) -> Rect2:
	var worldRect: Rect2 = getRowRectWorld(row);

	var camXform: Transform2D = camera.get_canvas_transform();
	var screenTopLeft: Vector2 = camXform * worldRect.position;
	var screenBottomRight: Vector2 = camXform * (worldRect.position + worldRect.size);

	return Rect2(screenTopLeft, screenBottomRight - screenTopLeft);
