class_name LFAnimate;
extends Resource;

static func control(
	obj: Control,
	prop: String,
	value: Variant,
	t := 4.20,
	tweenEase := Tween.EaseType.EASE_IN,
) -> Tween:
	var tween := obj.get_tree().create_tween();
	tween.tween_property.call(obj, prop, value, t);
	tween.set_ease(tweenEase);
	return tween;


static func comicsPopAppear(
	node,
	popupTime := 0.35,
):
	if !(node is Control) && !(node is Node2D):
		return false;
	
	var originalScale = node.scale;
	var originalPosition = node.position;
	# start tiny and invisible
	node.scale = Vector2.ZERO;
	node.modulate = Color(1, 1, 1, 0);
	node.rotation = 0.0;
	
	var tween : Tween = node.create_tween();
	tween.set_parallel(true);
	
	# pop scale (overshoot)
	tween.tween_property(node, "scale", originalScale * 1.2, popupTime * 0.6)\
		.from(Vector2.ZERO)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT);

	# fade in
	tween.tween_property(node, "modulate", Color(1, 1, 1, 1), popupTime * 0.3)\
		.from(Color(1, 1, 1, 0));

	# little random rotation
	var target_rot := deg_to_rad(randf_range(-20.0, 20.0))
	tween.tween_property(node, "rotation", target_rot, popupTime * 0.5)\
		.from(0.0);
	
	tween.tween_property(node, 'position', node.position + Vector2(0, -60.0), popupTime * 0.5)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT);

	tween.set_parallel(false);
	
	# settle back to normal scale
	tween.tween_property(node, "scale", originalScale, popupTime * 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN_OUT);
	
	await tween.finished;
	#node.scale = originalScale;
	#node.position = originalPosiation;


static func comicsPopDissapear(
	node,
	fallTime := 0.55,
	fallDistance := 300.0,
):
	if !(node is Control) && !(node is Node2D):
		return false;
		
	var originalPosition: Vector2 = node.position;

	var tween: Tween = node.create_tween();
	tween.set_parallel(true);

	# fall down (gravity feel)
	tween.tween_property(node, "position",
		originalPosition + Vector2(0, fallDistance), fallTime)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN);

	# fade out while falling
	tween.tween_property(node, "modulate", Color(1, 1, 1, 0), fallTime * 0.9);
	await tween.finished;
	node.position = originalPosition;
