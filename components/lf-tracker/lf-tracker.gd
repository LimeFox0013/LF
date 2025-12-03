class_name LFTracker;
extends LFControl;

@export var camera: Camera3D;
@export var target: Node3D;
@export var padding: float = 32.0;
@export var hideIfOnScreen: bool = false;

var viewportSize: Vector2;
var isOnScreen := true;
var wasOnScreen := true;

signal outScreen;
signal onScreen;


func _ready() -> void:
	viewportSize = get_viewport_rect().size;


func _process(delta: float) -> void:
	if camera == null or target == null:
		return;

	viewportSize = get_viewport_rect().size;

	# 1. Get target in camera/view space
	var targetGlobalPos: Vector3 = target.global_transform.origin;
	var camTransform: Transform3D = camera.global_transform;
	var toTarget: Vector3 = camTransform.basis.inverse() * (targetGlobalPos - camTransform.origin);

	# If behind camera, we can either flip direction or treat as off-screen behind.
	var isBehind: bool = toTarget.z > 0.0;

	# 2. Project to screen coordinates
	# This gives coordinates in pixels (0..viewportSize.x, 0..viewportSize.y)
	var screenPos: Vector2 = camera.unproject_position(targetGlobalPos);

	# 3. Determine if target is within viewport (with padding)
	var paddedRect := Rect2(
		Vector2(padding, padding),
		viewportSize - Vector2(padding * 2.0, padding * 2.0),
	);

	wasOnScreen = isOnScreen;
	isOnScreen = paddedRect.has_point(screenPos) and not isBehind;
	
	if wasOnScreen && !isOnScreen:
		outScreen.emit();
	
	if !wasOnScreen && isOnScreen:
		onScreen.emit();

	if hideIfOnScreen and isOnScreen:
		visible = false;
		return;
	else:
		visible = true;

	# 4. Clamp to padded screen area (so it stays inside viewport with padding)
	var clampedPos: Vector2 = screenPos.clamp(
		paddedRect.position,
		paddedRect.position + paddedRect.size,
	);

	# 5. If behind camera, push the indicator to the closest edge opposite direction
	if isBehind:
		# Invert direction relative to screen center
		var center: Vector2 = viewportSize * 0.5;
		var dir: Vector2 = (clampedPos - center).normalized();
		clampedPos = center - dir * (paddedRect.size * 0.5).length();

		# Clamp again to keep in rect
		clampedPos = clampedPos.clamp(
			paddedRect.position,
			paddedRect.position + paddedRect.size,
		);

	# 6. Position the tracker
	# Control.position is relative to top-left of viewport
	position = clampedPos;

	# 7. Rotate arrow toward the target (relative to screen center)
	var screenCenter: Vector2 = viewportSize * 0.5;
	var dirToTarget: Vector2 = (screenPos - screenCenter).normalized();
	rotation = dirToTarget.angle();
