extends Node2D
class_name CircleTileModifier

## 圓形瓷磚修改器：在遊戲開始時，將自身半徑內的瓷磚修改為指定類型

@export var block_type: TileBlockDB.TileType = TileBlockDB.TileType.COPPER
@export var R: float = 3.0 ## 半徑 (單位：Block)

var _tilemap_manager: TilemapManager

func _game_start() -> void:
	_apply_modification()

func _apply_modification() -> void:
	# 手動觸發一次注入確保獲取管理器
	if _tilemap_manager == null:
		DI.injection(self)
	
	if not _tilemap_manager:
		return
	
	var center_pos = global_position
	# 將全局座標轉為網格座標
	var center_grid = _tilemap_manager.local_to_grid(_tilemap_manager.to_local(center_pos))
	
	# 以網格為單位進行遍歷
	var r_int = ceil(R)
	for y in range(-r_int, r_int + 1):
		for x in range(-r_int, r_int + 1):
			var current_grid = center_grid + Vector2i(x, y)
			
			# 計算網格距離
			var dist_sq = x*x + y*y
			if dist_sq <= R * R:
				# 修改方塊類型
				_tilemap_manager.set_tile(current_grid, block_type)
	
	_tilemap_manager.notify_data_changed()
