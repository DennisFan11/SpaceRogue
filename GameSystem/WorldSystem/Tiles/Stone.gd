extends StaticBody2D
class_name StoneTile

## 64x64 岩石瓷磚，使用標準 Damageable 組件

@onready var damageable: Damageable = $Damageable

func _ready() -> void:
	collision_layer = BitmaskManager.LAYER_WALL
	collision_mask = 0
	
	if not damageable.destroyed.is_connected(queue_free):
		damageable.destroyed.connect(queue_free)

func damage(amount: float, source_team_id: int = -1) -> void:
	damageable.take_damage(amount, source_team_id)
