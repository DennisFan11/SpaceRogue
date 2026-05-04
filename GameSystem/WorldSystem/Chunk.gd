extends Node2D
class_name WorldChunk

## 單個 Chunk 節點，負責管理特定區域內的瓷磚實體

var chunk_size: int = 16
var chunk_pos: Vector2i  ## Chunk 座標 (不是網格座標)
var manager: TilemapManager

func _ready() -> void:
	if not manager:
		manager = get_parent().get_parent() as TilemapManager
	
	_spawn_tiles()

func _spawn_tiles() -> void:
	var start_x = chunk_pos.x * chunk_size
	var start_y = chunk_pos.y * chunk_size
	
	for offset_y in range(chunk_size):
		for offset_x in range(chunk_size):
			var gx = start_x + offset_x
			var gy = start_y + offset_y
			
			var state = manager.get_tile_state(gx, gy)
			if state == null or state.type == TileBlockDB.TileType.AIR:
				continue
			
			_create_tile_instance(gx, gy, state)

func _create_tile_instance(gx: int, gy: int, state: TileState) -> void:
	var tile = TileBlockDB.instantiate_tile(state.type)
	if tile:
		add_child(tile)
		tile.position = manager.grid_to_local(gx, gy) - global_position
		
		# 如果瓷磚有 Damageable 組件，初始化血量並連接信號
		if tile.has_node("Damageable"):
			var dmg = tile.get_node("Damageable") as Damageable
			# 我們需要確保在 Damageable._ready() 之後設定血量，或者直接手動設定
			# 這裡我們等待一幀或直接在 add_child 後設定（因為 add_child 會觸發 _ready）
			dmg.current_hp = state.health
			dmg.destroyed.connect(_on_tile_destroyed.bind(gx, gy))
			dmg.health_changed.connect(_on_tile_health_changed.bind(gx, gy))

func _on_tile_destroyed(gx: int, gy: int) -> void:
	# 更新 Manager 數據
	manager.set_tile_state(gx, gy, null)

func _on_tile_health_changed(current_hp: float, _max_hp: float, gx: int, gy: int) -> void:
	var state = manager.get_tile_state(gx, gy)
	if state:
		state.health = current_hp
		manager.set_tile_state(gx, gy, state)
