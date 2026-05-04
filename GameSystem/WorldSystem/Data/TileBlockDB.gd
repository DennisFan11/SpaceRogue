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
## 每個 Tile 的預覽貼圖 (用於編輯器顯示)
static var _tile_textures: Dictionary = {}

static func _static_init() -> void:
	_preload_tiles()

## 預載所有內建瓷磚
static func _preload_tiles() -> void:
	_register(TileType.DIRT, load("res://GameSystem/WorldSystem/Tiles/Dirt.tscn"), null)
	_register(TileType.STONE, load("res://GameSystem/WorldSystem/Tiles/Stone.tscn"), null)
	_register(TileType.AIR, null, null)

static func _register(type: TileType, scene: PackedScene, texture: Texture2D) -> void:
	_tile_scenes[type] = scene
	_tile_textures[type] = texture

## 獲取瓷磚場景
static func get_tile_scene(type: TileType) -> PackedScene:
	return _tile_scenes.get(type)

## 獲取瓷磚預覽貼圖
static func get_tile_texture(type: TileType) -> Texture2D:
	return _tile_textures.get(type)

## 取得所有可用類型
static func get_all_types() -> Array:
	return _tile_scenes.keys()

## 實例化瓷磚
static func instantiate_tile(type: TileType) -> Node:
	var scene = get_tile_scene(type)
	if scene:
		return scene.instantiate()
	return null
