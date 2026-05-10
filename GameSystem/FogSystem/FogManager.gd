@tool
extends Polygon2D
class_name FogManager

@export var visible_range: float = 300.0:
	set(value):
		visible_range = value
		_update_shader()

func _ready() -> void:
	if Engine.is_editor_hint():
		hide()
		return
	visible = true
		
	DI.register("_fog_manager", self)
	_update_shader()

func _update_shader() -> void:
	var mat = material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("visible_range", visible_range)

## 為 Gdscript 提供獲取接口
func get_visible_range() -> float:
	return visible_range
