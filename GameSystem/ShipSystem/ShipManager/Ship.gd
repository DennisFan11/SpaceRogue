extends Node2D
class_name Ship

const CELL_SIZE: int = 64

@onready var physics_body: RigidBody2D = $PhysicsBody
@onready var blocks_container: Node2D = $PhysicsBody/BlocksContainer
@onready var ship_input: ShipInput = $PhysicsBody/ShipInput
@onready var thruster_controller: ThrusterController = $PhysicsBody/ThrusterController

var core_block: BlockBase = null
var grid_map: Dictionary = {} # Vector2i -> BlockBase

func _ready() -> void:
	physics_body.collision_layer = BitmaskManager.LAYER_SHIP
	# 飛船不與玩家 (LAYER_PLAYER) 發生物理碰撞
	physics_body.collision_mask = BitmaskManager.LAYER_SHIP | BitmaskManager.LAYER_WALL | BitmaskManager.LAYER_PROJECTILE
	
	blocks_container.child_entered_tree.connect(_on_block_added)
	blocks_container.child_exiting_tree.connect(_on_block_removed)

func _on_block_added(node: Node) -> void:
	if node is BlockBase:
		# 延遲註冊，確保其 poly_shape 等資料已初始化
		call_deferred("register_block", node)

func _on_block_removed(node: Node) -> void:
	if node is BlockBase:
		unregister_block(node)

## 全域座標轉網格座標
func global_to_grid(global_pos: Vector2) -> Vector2i:
	var local_pos = blocks_container.to_local(global_pos)
	return local_to_grid(local_pos)

## 局部座標轉網格座標
func local_to_grid(local_pos: Vector2) -> Vector2i:
	var x = round(local_pos.x / CELL_SIZE)
	var y = round(local_pos.y / CELL_SIZE)
	return Vector2i(x, y)

## 網格座標轉局部座標
func grid_to_local(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * CELL_SIZE, grid_pos.y * CELL_SIZE)

## 將方塊註冊至網格快取
func register_block(block: BlockBase) -> void:
	for cell in block.get_global_occupied_cells():
		grid_map[cell] = block

## 從網格快取移除方塊
func unregister_block(block: BlockBase) -> void:
	for cell in block.get_global_occupied_cells():
		if grid_map.get(cell) == block:
			grid_map.erase(cell)

## 取得特定全域座標的方塊
func get_block_at_global_pos(global_pos: Vector2) -> BlockBase:
	var grid_pos = global_to_grid(global_pos)
	return get_block_at_grid(grid_pos)

## 取得特定網格位置的方塊 (O(1) 超高速查找)
func get_block_at_grid(grid_pos: Vector2i) -> BlockBase:
	return grid_map.get(grid_pos)

## 取得某方塊相鄰的所有方塊 (支援多連塊)
func get_neighbors(block: BlockBase) -> Array[BlockBase]:
	var neighbors: Array[BlockBase] = []
	var offsets = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	for cell in block.get_global_occupied_cells():
		for offset in offsets:
			var neighbor_pos = cell + offset
			var neighbor = get_block_at_grid(neighbor_pos)
			if neighbor and neighbor != block and not neighbors.has(neighbor):
				neighbors.append(neighbor)
	return neighbors

## 觸發結構完整性檢查 (BFS)
func trigger_structural_check() -> void:
	if not core_block or not is_instance_valid(core_block):
		return # 核心已被摧毀
		
	# BFS 尋找所有連接著 Core 的方塊
	var connected_blocks = []
	var queue = [core_block]
	var visited = {core_block: true}
	
	while queue.size() > 0:
		var current = queue.pop_front()
		connected_blocks.append(current)
		
		# 利用多連塊支援的相鄰尋找
		var neighbors = get_neighbors(current)
		for neighbor in neighbors:
			if neighbor.state_machine.is_built() and not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	
	# 將沒連上的方塊剝離
	for child in blocks_container.get_children():
		if child is BlockBase and child.state_machine.is_built():
			if not visited.has(child):
				# 剝離：強制銷毀
				child.state_machine.transition_to(BlockStateMachine.State.DESTROYED)
