extends RefCounted
class_name ResourceDB

## 資源數據庫：管理所有資源的定義與場景映射
## 資料來源為各資源場景 (.tscn) 的導出變數

enum Type {
	NONE,
	COPPER,
	METAL,
	ENERGY
}

static var _scenes: Dictionary = {} # Type -> PackedScene
static var _cache: Dictionary = {} # Type -> BaseResourceItem (模板實例)

static func _static_init() -> void: 
	_register_all()

static func _register_all() -> void:
	# 嚴格對齊專案目錄結構：每個資源應有其專屬資料夾與 ResourceItem 命名
	_register(Type.COPPER, preload("res://GameSystem/ResourceSystem/Scenes/Copper/CopperResourceItem.tscn"))
	_register(Type.METAL, preload("res://GameSystem/ResourceSystem/Scenes/Metal/MetalResourceItem.tscn"))
	_register(Type.ENERGY, preload("res://GameSystem/ResourceSystem/Scenes/Energy/EnergyResourceItem.tscn"))

static func _register(type: Type, scene: PackedScene) -> void:
	# 禁止防護：直接寫入，若為空則在後續崩潰是預期的
	_scenes[type] = scene

## 確保模板實例存在
static func _ensure_cached(type: Type) -> void:
	if _cache.has(type): return
	
	var scene = _scenes[type]
	var inst = scene.instantiate() as BaseResourceItem
	
	# 直接注入類型並保存
	inst.type = type
	_cache[type] = inst

static func get_display_name(type: Type) -> String:
	_ensure_cached(type)
	return _cache[type].display_name

static func get_icon(type: Type) -> Texture2D:
	_ensure_cached(type)
	return _cache[type].ui_icon

static func get_world_scene(type: Type) -> PackedScene:
	return _scenes[type]
