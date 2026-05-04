extends Node
class_name Inventory

var resources_set: ResourceSet = ResourceSet.new()

## 新增特定 ID 的資源
func add_resource(type_id: String, amount: int) -> void:
	if amount <= 0: return
	resources_set.set_amount(type_id, resources_set.get_amount(type_id) + amount)

## 取得資源數量
func get_amount(type_id: String) -> int:
	return resources_set.get_amount(type_id)

## 新增資源 (透過 ResourceCost)
func add_cost(cost: ResourceCost) -> void:
	var cost_set = ResourceSet.from_resource_cost(cost)
	resources_set = resources_set.add(cost_set)

## 檢查是否能負擔指定的 ResourceCost
func can_afford(cost: ResourceCost) -> bool:
	var cost_set = ResourceSet.from_resource_cost(cost)
	return resources_set.has_enough(cost_set)

## 扣除資源。若資源不足則回傳 false 並放棄扣除
func consume_cost(cost: ResourceCost) -> bool:
	var cost_set = ResourceSet.from_resource_cost(cost)
	if resources_set.has_enough(cost_set):
		resources_set = resources_set.sub(cost_set)
		return true
	return false

## 依據比例退還資源（用於拆除退款）
func refund_cost(cost: ResourceCost, ratio: float = 1.0) -> void:
	var cost_set = ResourceSet.from_resource_cost(cost)
	var refund_set = cost_set.mul(ratio)
	resources_set = resources_set.add(refund_set)
