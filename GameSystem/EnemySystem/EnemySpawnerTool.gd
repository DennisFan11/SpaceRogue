extends Node2D
class_name EnemySpawnerTool

## 臨時生成敵人的工具節點 (在 _ready 時自動在其位置生成)

@export var enemy_id: String = "bug"

var _enemy_manager: EnemyManager # DI 注入

func _game_start() -> void:
	_spawn()

func _spawn() -> void:
	if _enemy_manager:
		var enemy = _enemy_manager.spawn_enemy(enemy_id, global_position)
		if enemy:
			print("[EnemySpawnerTool] 自動生成敵人 at: ", global_position)
	
	# 生成後自我刪除
	queue_free()
