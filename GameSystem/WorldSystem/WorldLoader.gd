extends Node2D
class_name WorldLoader

## 世界加載器：負責追蹤目標並管理 Chunk 的加載與卸載

@export var chunk_size: int = 16
@export var view_distance: int = 4  ## 加載半徑 (單位：Chunk)
@export var update_interval: float = 0.1 ## 檢查間隔 (秒)

var manager: TilemapManager
var chunk_scene: PackedScene = preload("res://GameSystem/WorldSystem/Chunk.tscn")
var active_chunks: Dictionary = {} ## Vector2i -> Chunk 節點

## DI 自動注入
var _player_manager: PlayerManager = null

var _update_timer: float = 0.0

func _ready() -> void:
	manager = get_parent() as TilemapManager
	if not manager:
		push_error("[WorldLoader] Must be a child of TilemapManager")

func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer >= update_interval:
		_update_timer = 0.0
		_update_chunks()

## 核心邏輯：計算並加載玩家周圍的 Chunk
func _update_chunks() -> void:
	var target_pos = _get_target_position()
	var current_grid_pos = manager.local_to_grid(manager.to_local(target_pos))
	var current_chunk_pos = Vector2i(
		floor(float(current_grid_pos.x) / chunk_size),
		floor(float(current_grid_pos.y) / chunk_size)
	)
	
	var needed_chunks = []
	for y in range(-view_distance, view_distance + 1):
		for x in range(-view_distance, view_distance + 1):
			needed_chunks.append(current_chunk_pos + Vector2i(x, y))
	
	# 加載新 Chunk
	for cpos in needed_chunks:
		if not active_chunks.has(cpos):
			_load_chunk(cpos)
	
	# 卸載過遠的 Chunk (加 1 作為緩衝，避免邊緣抖動)
	var keys_to_remove = []
	for cpos in active_chunks:
		if cpos.distance_to(current_chunk_pos) > view_distance + 1:
			keys_to_remove.append(cpos)
	
	for cpos in keys_to_remove:
		_unload_chunk(cpos)

func _load_chunk(cpos: Vector2i) -> void:
	# 檢查座標是否超出地圖範圍
	var start_x = cpos.x * chunk_size
	var start_y = cpos.y * chunk_size
	if start_x >= manager.map_width or start_y >= manager.map_height or \
	   start_x + chunk_size <= 0 or start_y + chunk_size <= 0:
		return

	var chunk = chunk_scene.instantiate() as WorldChunk
	chunk.chunk_pos = cpos
	chunk.chunk_size = chunk_size
	chunk.manager = manager
	
	# 設定 Chunk 位置 (世界座標)
	chunk.position = manager.grid_to_local(start_x, start_y)
	chunk.position += Vector2(manager.BLOCK_SIZE, -manager.BLOCK_SIZE) / 2.0
	
	manager.get_node("ActiveChunks").add_child(chunk)
	active_chunks[cpos] = chunk

func _unload_chunk(cpos: Vector2i) -> void:
	var chunk = active_chunks[cpos]
	chunk.queue_free()
	active_chunks.erase(cpos)

## 重新加載所有內容 (當生成器變更時)
func refresh_world() -> void:
	for cpos in active_chunks:
		_unload_chunk(cpos)
	active_chunks.clear()
	_update_chunks()

## 從 PlayerManager 獲取追蹤目標的位置
func _get_target_position() -> Vector2:
	if _player_manager:
		if _player_manager.is_piloting and _player_manager.current_piloted_core:
			return _player_manager.current_piloted_core.global_position
		elif _player_manager.current_player_instance:
			return _player_manager.current_player_instance.global_position
	
	# 如果沒有玩家，回傳地圖中心或當前座標
	return global_position
