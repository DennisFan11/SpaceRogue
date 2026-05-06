extends RefCounted
class_name EquipmentDB

## 裝備數據庫：管理所有可用的裝備場景

static var _equipment_scenes: Dictionary = {} # id (String) -> PackedScene

static func _static_init() -> void:
	_preload_equipment()

static func _preload_equipment() -> void:
	# 手動註冊基本裝備
	register_equipment("drill", "res://GameSystem/EquipmentSystem/Drill/DrillEquipment.tscn")

static func register_equipment(id: String, path: String) -> void:
	var scene = load(path)
	if scene:
		_equipment_scenes[id] = scene
	else:
		push_error("EquipmentDB: 無法載入路徑為 %s 的裝備場景" % path)

static func get_equipment_scene(id: String) -> PackedScene:
	if _equipment_scenes.has(id):
		return _equipment_scenes[id]
	push_warning("EquipmentDB: 找不到裝備 ID %s" % id)
	return null
