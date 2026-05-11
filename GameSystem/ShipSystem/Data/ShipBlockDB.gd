extends RefCounted
class_name ShipBlockDB

## 預載並管理所有 Block 場景 (靜態類別)

## 每個方塊的 PackedScene
static var _block_scenes: Dictionary = {}
## 每個方塊額外的顯示資訊 (顯示名稱)
static var _block_display_names: Dictionary = {}

static func _static_init() -> void:
	_preload_blocks()

## 預載所有內建方塊
static func _preload_blocks() -> void:
	_register("core",
		preload("res://GameSystem/ShipSystem/Blocks/CoreBlock/CoreBlock.tscn"),
		"飛船核心 (2x2)")
	_register("wall",
		preload("res://GameSystem/ShipSystem/Blocks/WallBlock/WallBlock.tscn"),
		"空白牆體 (1x1)")
	_register("thruster_fixed",
		preload("res://GameSystem/ShipSystem/Blocks/ThrusterFixed/ThrusterFixed.tscn"),
		"固定推進器 (2x1)")
	_register("thruster_rcs",
		preload("res://GameSystem/ShipSystem/Blocks/ThrusterRCS/ThrusterRCS.tscn"),
		"RCS 推進器 (1x1)")
	_register("thruster_angled",
		preload("res://GameSystem/ShipSystem/Blocks/ThrusterAngled/ThrusterAngled.tscn"),
		"15° 斜噴推進器 (1x1)")
	_register("mechanical_drill",
		preload("res://GameSystem/ShipSystem/Blocks/DrillBlock/DrillBlock.tscn"),
		"機械鑽頭 (1x1)")
	_register("laser_drill",
		preload("res://GameSystem/ShipSystem/Blocks/LaserDrill/LaserDrill.tscn"),
		"雷射鑽頭 (1x1)")
	_register("twin_cannon",
		preload("res://GameSystem/ShipSystem/Blocks/TwinCannon/TwinCannon.tscn"),
		"雙管砲艙 (1x1)")
	_register("radar",
		preload("res://GameSystem/ShipSystem/Blocks/RadarBlock/RadarBlock.tscn"),
		"雷達方塊 (1x1)")
	_register("pursuit_radar",
		preload("res://GameSystem/ShipSystem/Blocks/PursuitRadarBlock/PursuitRadarBlock.tscn"),
		"追擊雷達方塊 (1x1)")
	_register("directional_radar",
		preload("res://GameSystem/ShipSystem/Blocks/DirectionalRadarBlock/DirectionalRadarBlock.tscn"),
		"指向性雷達方塊 (1x1)")

static func _register(id: String, scene: PackedScene, display_name: String) -> void:
	_block_scenes[id] = scene
	_block_display_names[id] = display_name

## 取得所有可建造的 ID 列表 (不含 core，玩家無法再造一個 core)
static func get_buildable_ids() -> Array[String]:
	return ["wall", "thruster_fixed", "thruster_rcs", "thruster_angled", "mechanical_drill", "laser_drill", "twin_cannon", "radar", "pursuit_radar", "directional_radar"]

## 取得顯示名稱
static func get_display_name(id: String) -> String:
	return _block_display_names.get(id, id)

## 獲取模組的 PackedScene
static func get_block_scene(id: String) -> PackedScene:
	return _block_scenes.get(id)

## 實例化一個模組 (回傳 Node，外部應自行轉型為 BlockBase)
static func instantiate_block(id: String) -> Node:
	if _block_scenes.has(id):
		var scene = _block_scenes[id] as PackedScene
		if scene:
			return scene.instantiate()
	push_warning("ShipBlockDB: 找不到 ID 為 %s 的方塊場景！" % id)
	return null
