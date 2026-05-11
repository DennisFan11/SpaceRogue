extends Node2D
class_name WorldChunk

## 單個 Chunk 節點，負責管理特定區域內的瓷磚實體

var chunk_size: int = 8
var chunk_pos: Vector2i ## Chunk 座標 (不是網格座標)
var _tilemap_manager: TilemapManager # DI 注入
var _player_manager: PlayerManager # DI 注入

func _ready() -> void:
	_spawn_tiles()

func _spawn_tiles() -> void:
	var start_x = chunk_pos.x * chunk_size
	var start_y = chunk_pos.y * chunk_size
	
	var timer = CooldownTimer.new()
	timer.trigger(0.001)
	
	for offset_y in range(chunk_size):
		for offset_x in range(chunk_size):
			var gx = start_x + offset_x
			var gy = start_y + offset_y
			
			var state = _tilemap_manager.get_tile_state(gx, gy)
			if state == null or state.type == TileBlockDB.TileType.AIR:
				continue
			
			_create_tile_instance(gx, gy, state)
			
			if not _is_in_view() and not timer.is_ready():
				await get_tree().process_frame
				#if not is_inside_tree():
					#return
				#
		timer.trigger(0.001)

func _create_tile_instance(gx: int, gy: int, state: TileState) -> void:
	var tile = TileBlockDB.instantiate_tile(state.type)
	if tile:
		add_child(tile)
		tile.position = _tilemap_manager.grid_to_local(gx, gy) - global_position

func _is_in_view() -> bool:
	return false
	if not _player_manager:
		return false
		
	var target_pos = Vector2.ZERO
	if _player_manager.is_piloting and _player_manager.current_piloted_core:
		target_pos = _player_manager.current_piloted_core.global_position
	elif _player_manager.current_player_instance:
		target_pos = _player_manager.current_player_instance.global_position
	else:
		return false
		
	var dist = global_position.distance_to(target_pos)
	# 1500 像素大約涵蓋了螢幕可見範圍 (1920x1080) 的一半對角線加上一些緩衝
	return dist < 800.0
