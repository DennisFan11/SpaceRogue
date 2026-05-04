class_name ResourceSet
extends RefCounted

## 用於進行資源算術操作的集合 (Set)

# Key: String (Resource ID), Value: int (Amount)
var resources: Dictionary = {}

func _init(initial_data: Dictionary = {}) -> void:
	resources = initial_data.duplicate()

## 取得特定資源數量
func get_amount(id: String) -> int:
	return resources.get(id, 0)

## 設定特定資源數量 (小於等於 0 時會自動清除)
func set_amount(id: String, amount: int) -> void:
	if amount <= 0:
		resources.erase(id)
	else:
		resources[id] = amount

## 加法：回傳一個新的 ResourceSet，包含兩者的資源總和
func add(other: ResourceSet) -> ResourceSet:
	var result = ResourceSet.new(resources)
	for id in other.resources.keys():
		result.set_amount(id, result.get_amount(id) + other.get_amount(id))
	return result

## 減法：回傳一個新的 ResourceSet，扣除對方的資源
func sub(other: ResourceSet) -> ResourceSet:
	var result = ResourceSet.new(resources)
	for id in other.resources.keys():
		var final_amount = result.get_amount(id) - other.get_amount(id)
		result.set_amount(id, final_amount)
	return result

## 乘法 (純量)：通常用於計算比例退款，回傳新的 ResourceSet
func mul(scalar: float) -> ResourceSet:
	var result = ResourceSet.new()
	for id in resources.keys():
		var final_amount = int(resources[id] * scalar)
		result.set_amount(id, final_amount)
	return result

## 判斷自身是否能夠負擔對方 (是否為對方的 Superset)
func has_enough(other: ResourceSet) -> bool:
	for id in other.resources.keys():
		if get_amount(id) < other.get_amount(id):
			return false
	return true

## 判斷是否為空
func is_empty() -> bool:
	return resources.is_empty()

## 將 Inspector 編輯用的 ResourceCost 轉換為可用於數學計算的 ResourceSet
static func from_resource_cost(cost: ResourceCost) -> ResourceSet:
	var set = ResourceSet.new()
	if cost:
		for c in cost.costs:
			if c.resource_type:
				set.set_amount(c.resource_type.id, set.get_amount(c.resource_type.id) + c.amount)
	return set

## 舊方法兼容
static func from_block_cost(cost: ResourceCost) -> ResourceSet:
	return from_resource_cost(cost)
