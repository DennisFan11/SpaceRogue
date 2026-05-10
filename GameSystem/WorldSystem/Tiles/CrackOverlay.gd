extends ColorRect

## 控制方塊破壞特效的覆蓋層
## 透過連接 Damageable 的信號來更新 Shader 的進度

@onready var damageable: Damageable = $"../Damageable"

func _ready() -> void:
	if damageable:
		damageable.health_changed.connect(_on_health_changed)
		damageable.hit.connect(_on_hit)
		# 初始化
		_on_health_changed(damageable.current_hp, damageable.max_hp)

func _on_hit(_amount: float, source_position: Vector2) -> void:
	if source_position != Vector2.ZERO:
		var local_pos = get_parent().to_local(source_position)
		var uv = (local_pos / 32.0) * 0.5 + Vector2(0.5, 0.5)
		uv.x = clamp(uv.x, 0.0, 1.0)
		uv.y = clamp(uv.y, 0.0, 1.0)
		if material:
			material.set_shader_parameter("hit_center", uv)

func _on_health_changed(current_hp: float, max_hp: float) -> void:
	var progress = clamp(1.0 - (current_hp / max_hp), 0.0, 1.0)
	if material:
		material.set_shader_parameter("progress", progress)
