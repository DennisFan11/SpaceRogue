extends RefCounted
class_name BulletDB

## 預載並管理所有子彈場景 (靜態類別)

static var _bullet_scenes: Dictionary = {}

static func _static_init() -> void:
	_preload_bullets()

static func _preload_bullets() -> void:
	_register("default", preload("res://GameSystem/BulletSystem/Bullet.tscn"))

static func _register(id: String, scene: PackedScene) -> void:
	_bullet_scenes[id] = scene

static func get_bullet_scene(id: String) -> PackedScene:
	return _bullet_scenes.get(id)
