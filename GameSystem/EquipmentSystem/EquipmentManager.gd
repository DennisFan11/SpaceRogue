extends Node2D
class_name EquipmentManager

## 裝備管理器：負責裝備的生成與全局控制

func _ready() -> void:
	DI.register("_equipment_manager", self)

## 在世界中生成裝備實體
func spawn_equipment(id: String, global_pos: Vector2) -> BaseEquipment:
	var scene = EquipmentDB.get_equipment_scene(id)
	if not scene:
		return null
		
	var instance = scene.instantiate() as BaseEquipment
	if instance:
		add_child(instance)
		instance.global_position = global_pos
		return instance
	
	return null
