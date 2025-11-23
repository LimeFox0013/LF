# LFBackgroundController.gd
class_name LFBackgroundController;
extends Node2D;

@export var cameraPath: NodePath;
@export var scrollLayers: Array[LFInfiniteScrollSprite] = [];

var camera: Camera2D;
var previousCameraPos: Vector2 = Vector2.ZERO;

func _ready() -> void:
	if cameraPath != NodePath():
		camera = get_node_or_null(cameraPath) as Camera2D;
	if camera != null:
		previousCameraPos = camera.global_position;


func _physics_process(delta: float) -> void:
	if camera == null:
		return;

	var currentPos: Vector2 = camera.global_position;
	var cameraDelta: Vector2 = currentPos - previousCameraPos;
	previousCameraPos = currentPos;

	updateInfiniteScrollLayers(cameraDelta);


func updateInfiniteScrollLayers(cameraDelta: Vector2) -> void:
	for layer in scrollLayers:
		if layer != null:
			layer.applyCameraDelta(cameraDelta);
