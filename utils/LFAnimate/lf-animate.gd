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
