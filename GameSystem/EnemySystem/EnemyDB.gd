extends RefCounted
class_name EnemyDB

## 預載並管理所有敵人場景 (靜態類別)

static var _enemy_scenes: Dictionary = {}

static func _static_init() -> void:
	_preload_enemies()

static func _preload_enemies() -> void:
	_register("bug", preload("res://GameSystem/EnemySystem/Bug/BugEnemy.tscn"))
	_register("centipede", preload("res://GameSystem/EnemySystem/Centipede/CentipedeSegment.tscn"))

static func _register(id: String, scene: PackedScene) -> void:
	_enemy_scenes[id] = scene

static func get_enemy_scene(id: String) -> PackedScene:
	return _enemy_scenes.get(id)

static func instantiate_enemy(id: String) -> Node:
	var scene = get_enemy_scene(id)
	if scene:
		return scene.instantiate()
	push_warning("EnemyDB: 找不到 ID 為 %s 的敵人場景！" % id)
	return null
