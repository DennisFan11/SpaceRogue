@tool
extends Node2D
class_name TilemapGenerator

## 地圖生成器基類 (Node 模式)

enum BlendMode {
	OVERRIDE, # 覆蓋
	ADD,      # 填補 (僅在空位填入)
	SUB,      # 挖掘 (清除既有瓷磚)
	AND       # 交集 (僅在已有瓷磚處替換)
}

## 當任意屬性改變時發出，通知 TilemapManager 重新生成預覽
signal preview_dirty

@export_group("Range")
@export var from_y: int = 0:
	set(v): from_y = v; preview_dirty.emit()
@export var end_y: int = 100:
	set(v): end_y = v; preview_dirty.emit()

@export_group("Config")
@export var tile_type: TileBlockDB.TileType = TileBlockDB.TileType.DIRT:
	set(v):
		tile_type = v
		_update_preview_texture()
		preview_dirty.emit()

@export var blend_mode: BlendMode = BlendMode.OVERRIDE:
	set(v): blend_mode = v; preview_dirty.emit()

@export_group("Editor Preview")
@export var preview_texture: Texture2D

func _ready() -> void:
	_update_preview_texture()

## 核心採樣函式，由子類別實作
func samp(x: float, y: float) -> float:
	return 0.0

## 判斷特定座標是否受此圖層影響 (預設為大於 0.5 則受影響)
func get_influence(x: float, y: float) -> bool:
	return samp(x, y) > 0.5

## 更新編輯器預覽貼圖
func _update_preview_texture() -> void:
	if Engine.is_editor_hint():
		var tex = TileBlockDB.get_tile_texture(tile_type)
		if tex:
			preview_texture = tex

## 在編輯器中繪製簡易預覽 (可選)
func _draw() -> void:
	if Engine.is_editor_hint() and is_visible_in_tree():
		# 可以在此繪製代表範圍或類型的視覺輔助
		pass
