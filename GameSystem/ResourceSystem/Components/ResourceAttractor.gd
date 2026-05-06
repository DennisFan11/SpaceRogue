extends Node2D
class_name ResourceAttractor

## 資源吸引採集組件：自動吸引範圍內的資源並將其採集入庫

@export var attraction_range: float = 300.0 ## 吸引範圍
@export var collection_radius: float = 20.0 ## 進入此半徑即被採集
@export var base_attraction_force: float = 400.0 ## 基礎吸引力

@onready var inventory: Inventory = _find_inventory()

func _physics_process(delta: float) -> void:
	if not inventory: return
	
	_handle_attraction(delta)

## 搜尋範圍內資源並施加吸引力
func _handle_attraction(_delta: float) -> void:
	var center_pos = global_position
	
	for res in get_tree().get_nodes_in_group("resource_items"):
		if not res is BaseResourceItem: continue
		if res.current_state == BaseResourceItem.State.COLLECTED: continue
		
		var dist = res.global_position.distance_to(center_pos)
		
		# 1. 檢查是否進入吸引範圍
		if dist <= attraction_range:
			# 只要進入範圍就轉為吸引狀態 (優先級最高)
			if res.current_state != BaseResourceItem.State.ATTRACTED:
				res.set_state(BaseResourceItem.State.ATTRACTED, self)
			
			# 2. 施加吸引力 (距離越近力越強)
			var dir = (center_pos - res.global_position).normalized()
			# 力 = 基礎力 * (1.0 + (吸引範圍 - 當前距離) / 吸引範圍) -> 越近越大
			var force_mult = 1.0 + (attraction_range - dist) / 100.0
			res.apply_central_force(dir * base_attraction_force * force_mult)
			
			# 3. 檢查是否達成採集條件
			if dist <= collection_radius:
				_collect_resource(res)

## 採集入庫
func _collect_resource(res: BaseResourceItem) -> void:
	res.set_state(BaseResourceItem.State.COLLECTED)
	
	# 增加倉庫資源
	if res.type != ResourceDB.Type.NONE:
		inventory.add_resource(res.type, res.amount)
	
	# 物理效果與銷毀
	res.queue_free()

func _find_inventory() -> Inventory:
	# 嘗試從父節點尋找 Inventory
	var p = get_parent()
	if p and p.has_node("Inventory"):
		return p.get_node("Inventory") as Inventory
	return null
