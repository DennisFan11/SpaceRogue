extends Node2D
class_name BlockOccluder

## 方塊遮光組件：負責根據 PolyominoShape 動態生成 LightOccluder2D
## 並根據方塊狀態控制其開關

@onready var block: BlockBase = get_parent() as BlockBase

func _ready() -> void:
	await get_tree().process_frame
	block.state_machine.state_changed.connect(_on_state_changed)
	_update_occluders()

func _on_state_changed(_old_state: BlockStateMachine.State, new_state: BlockStateMachine.State) -> void:
	set_enabled(new_state == BlockStateMachine.State.BUILT)

func _update_occluders() -> void:
	var cells = block.poly_shape.occupied_cells
	if cells.size() == 0:
		return
		
	# 清除所有舊的
	for child in get_children():
		child.queue_free()
		
	# 為每個 cell 生成新的 occluders
	for cell in cells:
		var occ = LightOccluder2D.new()
		var poly = OccluderPolygon2D.new()
		var s = PolyominoShape.BLOCK_SIZE / 2.0
		poly.polygon = PackedVector2Array([
			Vector2(-s, -s),
			Vector2(s, -s),
			Vector2(s, s),
			Vector2(-s, s)
		])
		occ.occluder = poly
		occ.position = Vector2(cell.x * PolyominoShape.BLOCK_SIZE, cell.y * PolyominoShape.BLOCK_SIZE)
		add_child(occ)
		
	set_enabled(block.state_machine.current_state == BlockStateMachine.State.BUILT)

func set_enabled(enabled: bool) -> void:
	visible = enabled
