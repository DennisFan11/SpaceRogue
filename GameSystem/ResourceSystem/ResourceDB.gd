extends RefCounted
class_name ResourceDB

## 資源數據庫：管理所有 ResourceType 資源

enum Type {
	NONE,
	COPPER,
	METAL,
	ENERGY
}

static var _resources: Dictionary = {} # Type (int) -> ResourceType

static func _static_init() -> void:
	_preload_resources()

static func _preload_resources() -> void:
	_register(Type.COPPER, load("res://Data/Resources/Copper.tres"))
	_register(Type.METAL, load("res://Data/Resources/Metal.tres"))
	_register(Type.ENERGY, load("res://Data/Resources/Energy.tres"))

static func _register(type: Type, res: ResourceType) -> void:
	if res:
		_resources[type] = res

static func get_resource(type: Type) -> ResourceType:
	return _resources.get(type)

static func get_all_resources() -> Array[ResourceType]:
	var list: Array[ResourceType] = []
	for res in _resources.values():
		list.append(res)
	return list
