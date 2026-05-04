extends RefCounted
class_name ResourceDB

## 資源數據庫：管理所有 ResourceType 資源

static var _resources: Dictionary = {} # id (String) -> ResourceType

static func _static_init() -> void:
	_preload_resources()

static func _preload_resources() -> void:
	# 這裡未來可以改為自動掃描目錄，目前先手動註冊或預載
	# 例如: _register(load("res://Data/Resources/Metal.tres"))
	pass

static func _register(res: ResourceType) -> void:
	if res and res.id != "":
		_resources[res.id] = res

static func get_resource(id: String) -> ResourceType:
	return _resources.get(id)

static func get_all_resources() -> Array[ResourceType]:
	var list: Array[ResourceType] = []
	for res in _resources.values():
		list.append(res)
	return list
