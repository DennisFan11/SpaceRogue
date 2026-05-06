extends Resource
class_name TileState

## 儲存單個瓷磚的動態狀態

@export var type: TileBlockDB.TileType = TileBlockDB.TileType.AIR
@export var health: float = -1.0
@export var custom_data: Dictionary = {}

func _init(p_type: TileBlockDB.TileType = TileBlockDB.TileType.AIR, p_health: float = -1.0) -> void:
	type = p_type
	health = p_health

## 序列化為 Dictionary 以利存檔
func to_dict() -> Dictionary:
	return {
		"type": type,
		"health": health,
		"custom_data": custom_data
	}

## 從 Dictionary 恢復
static func from_dict(dict: Dictionary) -> TileState:
	var state = TileState.new(dict.get("type", 0), dict.get("health", 100.0))
	state.custom_data = dict.get("custom_data", {})
	return state
