extends Node2D
class_name WorldChunk

## 單個 Chunk 節點，負責管理特定區域內的瓷磚實體

var chunk_size: int = 16
var chunk_pos: Vector2i  ## Chunk 座標 (不是網格座標)
var manager: TilemapManager

var _spawn_queue: Array[Vector3i] = [] # x, y, type
var _spawn_timer := CooldownTimer.new()
var _spawn_batch_size: int = 4 # 每幀生成的數量
var _spawn_interval: float = 0.01 # 生成間隔

func _ready() -> void:
	if not manager:
		manager = get_parent().get_parent() as TilemapManager
	
	_prepare_spawn_queue()

func _process(_delta: float) -> void:
	if _spawn_queue.is_empty():
		set_process(false) # 隊列空了就停止 process
		return
		
	if _spawn_timer.is_ready():
		_process_spawn_queue()
		_spawn_timer.trigger(_spawn_interval)

func _prepare_spawn_queue() -> void:
	var start_x = chunk_pos.x * chunk_size
	var start_y = chunk_pos.y * chunk_size
	
	for offset_y in range(chunk_size):
		for offset_x in range(chunk_size):
			var gx = start_x + offset_x
			var gy = start_y + offset_y
			
			var state = manager.get_tile_state(gx, gy)
			if state == null or state.type == TileBlockDB.TileType.AIR:
				continue
			
			_spawn_queue.append(Vector3i(gx, gy, state.type))

func _process_spawn_queue() -> void:
	for i in range(_spawn_batch_size):
		if _spawn_queue.is_empty(): break
		
		var task = _spawn_queue.pop_front()
		var gx = task.x
		var gy = task.y
		var state = manager.get_tile_state(gx, gy)
		
		if state:
			_create_tile_instance(gx, gy, state)

func _create_tile_instance(gx: int, gy: int, state: TileState) -> void:
	var tile = TileBlockDB.instantiate_tile(state.type)
	if tile:
		add_child(tile)
		tile.position = manager.grid_to_local(gx, gy) - global_position
		
		if tile.has_node("Damageable"):
			var dmg = tile.get_node("Damageable") as Damageable
			if state.health >= 0:
				dmg.current_hp = state.health
			dmg.destroyed.connect(_on_tile_destroyed.bind(gx, gy))
			dmg.health_changed.connect(_on_tile_health_changed.bind(gx, gy))

func _on_tile_destroyed(gx: int, gy: int) -> void:
	manager.set_tile_state(gx, gy, null)

func _on_tile_health_changed(current_hp: float, _max_hp: float, gx: int, gy: int) -> void:
	var state = manager.get_tile_state(gx, gy)
	if state:
		state.health = current_hp
		manager.set_tile_state(gx, gy, state)
