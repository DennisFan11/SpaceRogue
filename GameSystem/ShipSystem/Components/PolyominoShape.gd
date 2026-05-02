@tool
extends Node2D
class_name PolyominoShape

const BLOCK_SIZE: float = 64.0

## 多連塊佔據的相對網格座標 (預設佔據原點)
@export var occupied_cells: Array[Vector2i] = [Vector2i.ZERO]:
	set(value):
		occupied_cells = value
		queue_redraw()

func _draw() -> void:
	# 由於目前沒有實體視覺組件，先用紫色帶邊框的方形替代顯示
	for cell in occupied_cells:
		var top_left = Vector2(cell.x * BLOCK_SIZE - BLOCK_SIZE/2, cell.y * BLOCK_SIZE - BLOCK_SIZE/2)
		var rect = Rect2(top_left, Vector2(BLOCK_SIZE, BLOCK_SIZE))
		
		draw_rect(rect, Color(0.6, 0.2, 0.8, 0.6), true) # 半透明紫色底
		draw_rect(rect, Color(0.8, 0.4, 1.0, 1.0), false, 2.0) # 紫色亮邊框

## 為剛體生成精準的方形碰撞體陣列
func get_collision_shapes() -> Array[CollisionShape2D]:
	var shapes: Array[CollisionShape2D] = []
	for cell in occupied_cells:
		var col = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(BLOCK_SIZE, BLOCK_SIZE)
		col.shape = rect
		col.position = Vector2(cell.x * BLOCK_SIZE, cell.y * BLOCK_SIZE)
		shapes.append(col)
	return shapes

## 取得考慮了旋轉後的真實佔用網格陣列
func get_global_occupied_cells(base_grid_pos: Vector2i, rotation_deg: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var rad = deg_to_rad(rotation_deg)
	var cos_r = int(round(cos(rad)))
	var sin_r = int(round(sin(rad)))
	
	for cell in occupied_cells:
		var rx = cell.x * cos_r - cell.y * sin_r
		var ry = cell.x * sin_r + cell.y * cos_r
		result.append(base_grid_pos + Vector2i(rx, ry))
		
	return result
