extends Node
class_name ShipManager

## 管理場上所有飛船實體 (由 DI 注入)
var active_ships: Dictionary = {}

func _ready() -> void:
	DI.register("_ship_manager", self)


## 生成一艘新飛船
func spawn_ship(id: String, global_pos: Vector2) -> Ship:
	var ship_scene = load("res://GameSystem/ShipSystem/ShipManager/Ship.tscn")
	if ship_scene:
		var ship = ship_scene.instantiate() as Ship
		ship.global_position = global_pos
		active_ships[id] = ship
		add_child(ship)
		inject_starting_resources(ship)
		return ship
	return null

## 注入初始資源給新生成的飛船
func inject_starting_resources(ship: Ship) -> void:
	if not ship.blocks_container: return
	for child in ship.blocks_container.get_children():
		if child is CoreBlock: # 尋找 CoreBlock
			if child.inventory:
				child.inventory.add_resource(ResourceDB.Type.METAL, 100)
				child.inventory.add_resource(ResourceDB.Type.ENERGY, 50)
				print("Injected starting resources to CoreBlock.")
			break

## 取得指定飛船
func get_ship(id: String) -> Ship:
	return active_ships.get(id)

## 銷毀飛船
func destroy_ship(id: String) -> void:
	var ship = get_ship(id)
	if is_instance_valid(ship):
		ship.queue_free()
	active_ships.erase(id)
