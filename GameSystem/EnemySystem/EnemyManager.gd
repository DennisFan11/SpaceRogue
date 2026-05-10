extends Node2D
class_name EnemyManager

## 管理敵人的生成與生命週期

func _ready() -> void:
	DI.register("_enemy_manager", self)

## 生成敵人
func spawn_enemy(id: String, pos: Vector2) -> Node:
	var enemy = EnemyDB.instantiate_enemy(id)
	if enemy:
		enemy.global_position = pos
		add_child(enemy)
		return enemy
	return null
