extends Node
class_name ResourceManager

## 資源管理器：負責場景中資源節點的生成與管理

func _ready() -> void:
	DI.register("_resource_manager", self)

## 在世界中生成資源掉落物
func spawn_resource(type: ResourceDB.Type, global_pos: Vector2, amount: int = 1) -> BaseResourceItem:
	var res_type = ResourceDB.get_resource(type)
	if not res_type:
		push_warning("ResourceManager: 找不到資源類型 %d" % type)
		return null
	
	var scene = res_type.world_scene
	if not scene:
		# 如果沒有指定特定場景，使用基礎場景
		scene = load("res://GameSystem/ResourceSystem/Scenes/BaseResourceItem.tscn")
	
	var instance = scene.instantiate() as BaseResourceItem
	if instance:
		get_tree().current_scene.add_child(instance)
		instance.global_position = global_pos
		instance.init(res_type, amount)
		return instance
	
	return null

## 批量生成資源（例如從方塊掉落）
func spawn_resources(cost: ResourceCost, global_pos: Vector2, ratio: float = 1.0) -> void:
	var set = ResourceSet.from_resource_cost(cost)
	var final_set = set.mul(ratio)
	
	for id in final_set.resources.keys():
		var amount = final_set.get_amount(id)
		if amount > 0:
			spawn_resource(id, global_pos + Vector2(randf_range(-20, 20), randf_range(-20, 20)), amount)
