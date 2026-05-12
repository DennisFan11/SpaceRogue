extends Sprite2D
class_name LightNode

func _ready() -> void:
	# 預設半徑 500
	set_radius(500.0)

func set_radius(r: float) -> void:
	# 假設紋理大小是 256x256，中心到邊緣半徑是 128
	var scale_factor = r / 128.0
	scale = Vector2(scale_factor, scale_factor)
