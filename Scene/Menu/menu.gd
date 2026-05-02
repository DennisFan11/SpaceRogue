extends Node2D









func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	await _close_eye()









	

func _close_eye():
	var tween = get_tree().create_tween()
	tween.tween_method(set_blink, 0.0, 1.0, 7.0)
	await tween.finished

## p (0~1)
@export var blink_curve: Curve

func set_blink(p: float):
	p = blink_curve.sample_baked(p)
	_ssp(%Blink, "open_amount", 1.0-p)
	_ssp(%Blur, "blur", p)

func _ssp(n: Node, p: StringName, v: Variant):
	(n.material as ShaderMaterial).set_shader_parameter(p, v)




##
