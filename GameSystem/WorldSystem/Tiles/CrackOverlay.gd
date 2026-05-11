extends ColorRect

## 控制方塊破壞特效的覆蓋層
## 只有在受到傷害時才會建立 Material，避免大量無傷方塊佔用資源

const SHADER = preload("res://GameSystem/WorldSystem/Tiles/Shaders/Destruction.gdshader")

@onready var damageable: Damageable = $"../Damageable"

func _ready() -> void:
	# 預設不放 material
	material = null
	
	if damageable:
		damageable.health_changed.connect(_on_health_changed)
		damageable.hit.connect(_on_hit)
		# 初始化
		_on_health_changed(damageable.current_hp, damageable.max_hp)

func _on_hit(_amount: float, source_position: Vector2) -> void:
	if source_position != Vector2.ZERO:
		var local_pos = get_parent().to_local(source_position)
		var uv = local_pos / float(TilemapManager.BLOCK_SIZE) + Vector2(0.5, 0.5)
		uv.x = clamp(uv.x, 0.0, 1.0)
		uv.y = clamp(uv.y, 0.0, 1.0)
		
		# 確保有 material 後再設定參數
		_ensure_material()
		material.set_shader_parameter("hit_center", uv)

func _on_health_changed(current_hp: float, max_hp: float) -> void:
	var progress = clamp(1.0 - (current_hp / max_hp), 0.0, 1.0)
	if progress > 0.0:
		_ensure_material()
		material.set_shader_parameter("progress", progress)
	else:
		material = null

func _ensure_material() -> void:
	if not material:
		var mat = ShaderMaterial.new()
		mat.shader = SHADER
		mat.set_shader_parameter("scale", 4.0)
		mat.set_shader_parameter("crack_color", Color(0, 0, 0, 1))
		material = mat
