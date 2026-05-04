extends RefCounted
class_name TileBlockDB

## 預載並管理所有地圖瓷磚 (Tile) 資源 (靜態類別)

enum TileType {
	AIR,
	DIRT,
	STONE
}

## 每個 Tile 的 PackedScene
static var _tile_scenes: Dictionary = {}
## 每個 Tile 的預覽顏色
static var _tile_colors: Dictionary = {}

static func _static_init() -> void:
	_preload_tiles()

## 預載所有內建瓷磚
static func _preload_tiles() -> void:
	_register(TileType.DIRT, load("res://GameSystem/WorldSystem/Tiles/Dirt.tscn"), Color(0.6, 0.45, 0.3))
	_register(TileType.STONE, load("res://GameSystem/WorldSystem/Tiles/Stone.tscn"), Color(0.55, 0.6, 0.65))
	_register(TileType.AIR, null, Color(0, 0, 0, 0))

static func _register(type: TileType, scene: PackedScene, color: Color) -> void:
	_tile_scenes[type] = scene
	_tile_colors[type] = color

## 獲取瓷磚場景
static func get_tile_scene(type: TileType) -> PackedScene:
	return _tile_scenes.get(type)

## 獲取瓷磚預覽顏色
static func get_tile_color(type: TileType) -> Color:
	if _tile_colors.is_empty():
		_preload_tiles()
	
	if not _tile_colors.has(type):
		return Color.MAGENTA # 如果還是找不到，才回傳紅紫色
		
	return _tile_colors[type]

## 取得所有可用類型
static func get_all_types() -> Array:
	return _tile_scenes.keys()

## 實例化瓷磚
static func instantiate_tile(type: TileType) -> Node:
	var scene = get_tile_scene(type)
	if scene:
		return scene.instantiate()
	return null
