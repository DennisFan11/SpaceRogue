extends StaticBody2D
class_name BaseTileBlock

## 所有世界瓷磚的基底類別

@export var preview_color: Color = Color.WHITE

@onready var sprite: Sprite2D = $Sprite2D
@onready var damageable: Damageable = $Damageable
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _vfx_manager: Node # DI 注入

func _ready() -> void:
	# 統一設定碰撞層 (Layer 8: Wall)
	collision_layer = BitmaskManager.LAYER_WALL
	collision_mask = 0
	
	if damageable:
		if not damageable.destroyed.is_connected(_on_destroyed):
			damageable.destroyed.connect(_on_destroyed)
		if not damageable.hit.is_connected(_on_hit):
			damageable.hit.connect(_on_hit)

func _on_destroyed() -> void:
	queue_free()

func _on_hit(_amount: float, source_position: Vector2) -> void:
	if not _vfx_manager:
		return
		
	if source_position != Vector2.ZERO:
		var dir = (source_position - global_position).normalized()
		_vfx_manager.play_damage_particles(source_position, preview_color, dir)
	else:
		_vfx_manager.play_damage_particles(global_position, preview_color)

## 支援外部呼叫以相容舊邏輯
func damage(amount: float, source_team_id: int = Team.NEUTRAL, source_position: Vector2 = Vector2.ZERO) -> void:
	if damageable:
		damageable.take_damage(amount, source_team_id, source_position)
