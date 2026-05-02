extends Node2D
class_name Builder

@export var scan_interval: float = 0.5
@export var max_build_range: float = 500.0
var _time_since_last_scan: float = 0.0

@onready var inventory: Inventory = get_parent().get_node("Inventory")
@onready var core_block: BlockBase = get_parent() as BlockBase
var ship: Ship = null

func _ready() -> void:
	var node = self
	while node and not node is Ship:
		node = node.get_parent()
	if node is Ship:
		ship = node

func _process(delta: float) -> void:
	if not ship or not inventory: return
	
	_time_since_last_scan += delta
	if _time_since_last_scan >= scan_interval:
		_time_since_last_scan = 0.0
		scan_blueprints()
		process_deconstruction()

## 掃描相連的藍圖並嘗試建造
func scan_blueprints() -> void:
	for child in ship.blocks_container.get_children():
		if child is BlockBase and child.state_machine.is_blueprint():
			if _has_built_neighbor(child) and _is_within_range(child):
				try_build(child)

## 檢查是否在建造範圍內
func _is_within_range(block: BlockBase) -> bool:
	var distance = (block.global_position - global_position).length()
	return distance <= max_build_range

## 嘗試扣除資源並建造
func try_build(block: BlockBase) -> bool:
	if inventory.consume_cost(block.cost):
		block.state_machine.transition_to(BlockStateMachine.State.BUILDING)
		# 預設瞬間建造完成
		block.state_machine.transition_to(BlockStateMachine.State.BUILT)
		return true
	return false

## 掃描待拆除標記並處理合法退款
func process_deconstruction() -> void:
	# TODO: 處理 DECONSTRUCT 標記與合法順序檢查
	pass

## 檢查該方塊四周是否有已經建成的實體方塊
func _has_built_neighbor(block: BlockBase) -> bool:
	var dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for d in dirs:
		var neighbor = ship.get_block_at_grid(block.grid_position + d)
		if neighbor and neighbor.state_machine.is_built():
			return true
	return false
