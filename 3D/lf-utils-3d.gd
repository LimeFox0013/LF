class_name LFUtils3D;


static func worldToCanvasPosition(worldPosition: Vector3, camera: Camera3D) -> Vector2:
	if camera == null:
		return Vector2.ZERO;
	return camera.unproject_position(worldPosition);
