extends BaseTileBlock

## 銅礦方塊：被摧毀時會掉落銅資源

var _resource_manager: ResourceManager

func _ready() -> void:
	super._ready()

func _on_destroyed() -> void:
	var pos = global_position
	# 延遲一幀生成，確保方塊已經完全從物理世界移除
	call_deferred("_spawn_drop", pos)
	super._on_destroyed()

func _spawn_drop(pos: Vector2) -> void:
	_resource_manager.spawn_resource(ResourceDB.Type.COPPER, pos, randi_range(1, 3))
