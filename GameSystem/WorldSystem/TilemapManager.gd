@tool
extends Node2D
class_name TilemapManager

## 地圖管理器：數據中心與生成器協調器
## 負責管理全局地圖數據，並提供給 WorldLoader 進行動態加載

const BLOCK_SIZE = 64

@export_group("Dimensions")
@export var map_width: int = 100:
	set(v): map_width = v; _on_dimensions_changed()
@export var map_height: int = 100:
	set(v): map_height = v; _on_dimensions_changed()

@export_group("Actions")
@export_tool_button("Generate Base Grid")
var generate_button = generate_map

## 原始生成的地圖網格 (TileType 陣列)
var _id_grid: Array = []

## 儲存已被修改或具有特殊狀態的瓷磚 (Vector2i -> TileState)
var _tile_data_map: Dictionary = {}

# --- 生命週期 ---

func _ready() -> void:
	# 對現有子節點連接信號
	for child in get_children():
		_connect_generator(child)
	
	child_entered_tree.connect(_on_child_entered)
	child_exiting_tree.connect(_on_child_exiting)
	
	if not Engine.is_editor_hint():
		DI.register("_tilemap_manager", self)
		generate_map()

func _on_child_entered(node: Node) -> void:
	_connect_generator(node)

func _on_child_exiting(node: Node) -> void:
	if node is TilemapGenerator and node.preview_dirty.is_connected(_on_generator_changed):
		node.preview_dirty.disconnect(_on_generator_changed)

func _connect_generator(node: Node) -> void:
	if node is TilemapGenerator:
		if not node.preview_dirty.is_connected(_on_generator_changed):
			node.preview_dirty.connect(_on_generator_changed)

func _on_generator_changed() -> void:
	if Engine.is_editor_hint():
		generate_map()

func _on_dimensions_changed() -> void:
	if Engine.is_editor_hint():
		generate_map()

# --- 數據管理 ---

## 執行基礎生成流程 (生成原始 _id_grid)
func generate_map() -> void:
	_initialize_grid()
	for gen in _get_generators():
		_apply_generator_layer(gen)
	
	if Engine.is_editor_hint():
		queue_redraw()
	else:
		# 通知 Loader 刷新或重新加載
		var loader = get_node_or_null("WorldLoader")
		if loader and loader.has_method("refresh_world"):
			loader.refresh_world()

func _initialize_grid() -> void:
	_id_grid.clear()
	for y in range(map_height):
		var row = []
		row.resize(map_width)
		row.fill(TileBlockDB.TileType.AIR)
		_id_grid.append(row)

func _apply_generator_layer(gen: TilemapGenerator) -> void:
	var start_y = clampi(gen.from_y, 0, map_height - 1)
	var end_y = clampi(gen.end_y, 0, map_height - 1)
	
	for y in range(start_y, end_y + 1):
		for x in range(map_width):
			if gen.get_influence(x, y):
				_blend_tile_at(x, y, gen.tile_type, gen.blend_mode)

func _blend_tile_at(x: int, y: int, new_type: TileBlockDB.TileType, mode: TilemapGenerator.BlendMode) -> void:
	var current = _id_grid[y][x]
	var air = TileBlockDB.TileType.AIR
	
	match mode:
		TilemapGenerator.BlendMode.OVERRIDE:
			_id_grid[y][x] = new_type
		TilemapGenerator.BlendMode.ADD:
			if current == air: _id_grid[y][x] = new_type
		TilemapGenerator.BlendMode.SUB:
			_id_grid[y][x] = air
		TilemapGenerator.BlendMode.AND:
			if current != air: _id_grid[y][x] = new_type

## 獲取指定位置的瓷磚狀態
func get_tile_state(x: int, y: int) -> TileState:
	var pos = Vector2i(x, y)
	# 優先回傳修改過的動態資料 (包含超出原始邊界的資料)
	if _tile_data_map.has(pos):
		return _tile_data_map[pos]
	
	if x < 0 or x >= map_width or y < 0 or y >= map_height:
		return null
	
	# 否則回傳基於原始網格的初始狀態
	var type = _id_grid[y][x]
	if type == TileBlockDB.TileType.AIR:
		return null
		
	return TileState.new(type)

## 更新指定位置的瓷磚狀態 (當發生損壞、移除時呼叫)
func set_tile_state(x: int, y: int, state: TileState) -> void:
	var pos = Vector2i(x, y)
	if state == null or state.type == TileBlockDB.TileType.AIR:
		# 如果變為空氣，記錄一個空氣狀態或從地圖移除（視為被挖掉）
		_tile_data_map[pos] = TileState.new(TileBlockDB.TileType.AIR)
	else:
		_tile_data_map[pos] = state

## 便利方法：設定瓷磚類型
func set_tile(grid_pos: Vector2i, type: TileBlockDB.TileType) -> void:
	set_tile_state(grid_pos.x, grid_pos.y, TileState.new(type))

# --- 存檔與序列化 ---

## 序列化所有被修改過的瓷磚數據
func serialize_world_data() -> Dictionary:
	var data = {}
	for pos in _tile_data_map:
		data[var_to_str(pos)] = _tile_data_map[pos].to_dict()
	return {
		"width": map_width,
		"height": map_height,
		"modified_tiles": data
	}

## 從數據恢復
func deserialize_world_data(data: Dictionary) -> void:
	map_width = data.get("width", map_width)
	map_height = data.get("height", map_height)
	_tile_data_map.clear()
	
	var tiles_data = data.get("modified_tiles", {})
	for pos_str in tiles_data:
		var pos = str_to_var(pos_str)
		_tile_data_map[pos] = TileState.from_dict(tiles_data[pos_str])
	
	generate_map()

## 通知地圖數據已變更，需要重新載入場景中的 Chunk
func notify_data_changed() -> void:
	var loader = get_node_or_null("WorldLoader")
	if loader and loader.has_method("refresh_world"):
		loader.refresh_world()

# --- 座標轉換 ---

func grid_to_local(x: int, y: int) -> Vector2:
	return Vector2(x - float(map_width) / 2.0, -y) * BLOCK_SIZE

func local_to_grid(local_pos: Vector2) -> Vector2i:
	var grid_pos = local_pos / BLOCK_SIZE
	var x = int(grid_pos.x + float(map_width) / 2.0)
	var y = int(-grid_pos.y)
	return Vector2i(x, y)

# --- 編輯器預覽 ---

func _draw() -> void:
	if not Engine.is_editor_hint() or _id_grid.is_empty(): return
	
	# 獲取編輯器視圖的可見範圍
	var transform = get_viewport_transform() * get_canvas_transform()
	var inv_transform = transform.affine_inverse()
	var view_rect = inv_transform * get_viewport_rect()
	
	# 將可見範圍轉換為網格座標範圍
	var min_pos = view_rect.position
	var max_pos = view_rect.end
	
	var grid_min = local_to_grid(min_pos)
	var grid_max = local_to_grid(max_pos)
	
	# 確保範圍在有效邊界內
	var start_x = clamp(grid_min.x - 1, 0, map_width - 1)
	var end_x = clamp(grid_max.x + 1, 0, map_width - 1)
	var start_y = clamp(grid_max.y - 1, 0, map_height - 1) # 注意 Y 軸向上
	var end_y = clamp(grid_min.y + 1, 0, map_height - 1)
	
	# 僅繪製可見範圍內的瓷磚
	for y in range(start_y, end_y + 1):
		for x in range(start_x, end_x + 1):
			var state = get_tile_state(x, y)
			if state == null or state.type == TileBlockDB.TileType.AIR: continue
			
			var color = TileBlockDB.get_tile_color(state.type)
			var pos = grid_to_local(x, y)
			var rect = Rect2(pos - Vector2(BLOCK_SIZE, BLOCK_SIZE) / 2.0, Vector2(BLOCK_SIZE, BLOCK_SIZE))
			
			draw_rect(rect, color, true)
	
	var border_origin = grid_to_local(0, 0) - Vector2(BLOCK_SIZE, BLOCK_SIZE) / 2.0
	border_origin.y -= (map_height - 1) * BLOCK_SIZE
	var border_size = Vector2(map_width, map_height) * BLOCK_SIZE
	draw_rect(Rect2(border_origin, border_size), Color.YELLOW, false, 2.0)

func _get_generators() -> Array[TilemapGenerator]:
	var result: Array[TilemapGenerator] = []
	for child in get_children():
		if child is TilemapGenerator and not child.get_script() == null:
			result.append(child)
	return result
