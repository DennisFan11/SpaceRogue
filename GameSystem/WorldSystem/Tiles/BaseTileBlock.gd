extends StaticBody2D
class_name BaseTileBlock

## 所有世界瓷磚的基底類別

@export var preview_color: Color = Color.WHITE

@onready var sprite: Sprite2D = $Sprite2D
@onready var damageable: Damageable = $Damageable
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# 統一設定碰撞層 (Layer 8: Wall)
	collision_layer = BitmaskManager.LAYER_WALL
	collision_mask = 0
	
	if damageable:
		if not damageable.destroyed.is_connected(_on_destroyed):
			damageable.destroyed.connect(_on_destroyed)

## 當被摧毀時的預設行為
func _on_destroyed() -> void:
	queue_free()

## 支援外部呼叫以相容舊邏輯
func damage(amount: float, source_team_id: int = Team.NEUTRAL) -> void:
	if damageable:
		damageable.take_damage(amount, source_team_id)
