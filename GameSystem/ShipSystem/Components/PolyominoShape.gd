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
	# 如果在編輯器中，或者方塊沒有實體視覺組件時，才繪製紫色替代框
	# 或者 DebugSetting.show_polyomino_shape 為 true 時強制顯示
	if not Engine.is_editor_hint() and not DebugSetting.show_polyomino_shape:
		var block = get_parent()
		if block is BlockBase and block.visual and block.visual.get_child_count() > 0:
			return

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
