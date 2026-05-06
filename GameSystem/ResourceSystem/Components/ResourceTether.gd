extends Node2D
class_name ResourceTether

## 玩家資源連線組件：自動連接範圍內的資源實體並在距離過遠時拉動它們

@export var tether_range: float = 200.0 ## 偵測與建立連線的範圍
@export var max_distance: float = 150.0 ## 開始產生拉力的距離
@export var pull_force: float = 200.0  ## 拉動資源的力

var connected_resources: Array[BaseResourceItem] = []

func _physics_process(_delta: float) -> void:
	_update_connections()
	_apply_pull_forces()

## 更新連線狀態
func _update_connections() -> void:
	# 1. 移除已失效或正在被核心吸引的資源
	var to_remove = []
	for res in connected_resources:
		if not is_instance_valid(res) or res.current_state != BaseResourceItem.State.TETHERED:
			to_remove.append(res)
		elif res.global_position.distance_to(global_position) > tether_range * 1.5:
			# 距離過遠自動斷開
			res.set_state(BaseResourceItem.State.IDLE)
			to_remove.append(res)
			
	for res in to_remove:
		connected_resources.erase(res)

	# 2. 搜尋新資源 (使用 Physics Server 或直接遍歷群組)
	# 為了效能與簡潔，這裡暫時使用 get_tree().get_nodes_in_group
	# 但實作時建議在 Player.tscn 加入一個專門的 Area2D
	for res in get_tree().get_nodes_in_group("resource_items"):
		if res is BaseResourceItem and res.current_state == BaseResourceItem.State.IDLE:
			if res.global_position.distance_to(global_position) <= tether_range:
				res.set_state(BaseResourceItem.State.TETHERED, get_parent())
				connected_resources.append(res)

## 對過遠的資源施加拉力
func _apply_pull_forces() -> void:
	var player_pos = global_position
	for res in connected_resources:
		if not is_instance_valid(res): continue
		
		var dist = res.global_position.distance_to(player_pos)
		if dist > max_distance:
			var dir = (player_pos - res.global_position).normalized()
			# 彈性力：距離越遠力越大
			var spring_force = (dist - max_distance) * 10.0
			var final_force = dir * (pull_force + spring_force)
			res.apply_central_force(final_force)
			# 額外增加阻尼以防止過度震盪
			res.linear_damp = 3.0
		else:
			# 在範圍內恢復正常阻尼，讓資源能維持物理慣性
			res.linear_damp = 1.0
