extends Node2D
class_name BlockLight

@onready var block: BlockBase = get_parent() as BlockBase

const LIGHT_AGENT_SCENE = preload("res://GameSystem/LightSystem/LightAgent.tscn")

func _ready() -> void:
	await get_tree().process_frame
	block.state_machine.state_changed.connect(_on_state_changed)
	_update_lights()

func _on_state_changed(_old_state: BlockStateMachine.State, new_state: BlockStateMachine.State) -> void:
	set_enabled(new_state == BlockStateMachine.State.BUILT)

func _update_lights() -> void:
	var cells = block.poly_shape.occupied_cells
	if cells.size() == 0:
		return
		
	# 清除所有舊的
	for child in get_children():
		child.queue_free()
		
	# 為每個 cell 生成新的 LightAgent
	for cell in cells:
		var agent = LIGHT_AGENT_SCENE.instantiate() as LightAgent
		# 設定位置 (根據 cell 座標)
		agent.position = Vector2(cell.x * PolyominoShape.BLOCK_SIZE, cell.y * PolyominoShape.BLOCK_SIZE)
		add_child(agent)
		
	set_enabled(block.state_machine.current_state == BlockStateMachine.State.BUILT)

func set_enabled(enabled: bool) -> void:
	for child in get_children():
		if child is LightAgent:
			child.set_enabled(enabled)
