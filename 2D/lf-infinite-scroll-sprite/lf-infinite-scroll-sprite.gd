# LFInfiniteScrollSprite.gd
class_name LFInfiniteScrollSprite;
extends Sprite2D;

@export var trackCamera := true;
@export var camera: Camera2D;
# Defines how the texture position will apply cameras global_position
@export var positionFactor := 1.0;

var base_position := Vector2.ZERO;

func _ready() -> void:
	reset();


func _physics_process(delta: float) -> void:
	if trackCamera && camera:
		global_position = camera.global_position;
		region_rect.position = camera.global_position * positionFactor;


func reset():
	if camera:
		base_position = camera.global_position;
