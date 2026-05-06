extends BuildTool
class_name RemoveTool

var is_dragging: bool = false
var drag_start_grid_pos: Vector2i
var selection_visual: Polygon2D = null

func on_activated() -> void:
	_ensure_selection_visual()

func on_deactivated() -> void:
	is_dragging = false
	if selection_visual:
		selection_visual.hide()

func _ensure_selection_visual() -> void:
	if selection_visual and is_instance_valid(selection_visual): return
	selection_visual = Polygon2D.new()
	# 建立一個矩形點集
	selection_visual.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)
	])
	selection_visual.color = Color(1, 0, 0, 0.3)
	selection_visual.hide()
	builder.add_child(selection_visual)

func handle_input(event: InputEvent) -> void:
	var ship = builder.current_ship
	if not ship: return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				start_drag(ship.get_global_mouse_position())
			else:
				if is_dragging:
					end_drag(ship.get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_try_cancel_pending_removal(ship.get_global_mouse_position())

func update(_delta: float) -> void:
	if is_dragging:
		update_selection_visual()

func _try_cancel_pending_removal(global_pos: Vector2) -> void:
	var ship = builder.current_ship
	if not ship: return
	
	var block = ship.get_block_at_global_pos(global_pos)
	if block and block.state_machine.current_state == BlockStateMachine.State.PENDING_REMOVAL:
		block.state_machine.transition_to(BlockStateMachine.State.BUILT)

func start_drag(start_pos: Vector2) -> void:
	var ship = builder.current_ship
	if not ship: return
	
	_ensure_selection_visual()
	drag_start_grid_pos = ship.global_to_grid(start_pos)
	is_dragging = true
	
	if selection_visual:
		if selection_visual.get_parent() != ship.blocks_container:
			if selection_visual.get_parent():
				selection_visual.get_parent().remove_child(selection_visual)
			ship.blocks_container.add_child(selection_visual)
		selection_visual.show()

func update_selection_visual() -> void:
	var ship = builder.current_ship
	if not ship or not selection_visual: return
	
	var drag_end_grid_pos = ship.global_to_grid(ship.get_global_mouse_position())
	
	var min_x = min(drag_start_grid_pos.x, drag_end_grid_pos.x)
	var max_x = max(drag_start_grid_pos.x, drag_end_grid_pos.x)
	var min_y = min(drag_start_grid_pos.y, drag_end_grid_pos.y)
	var max_y = max(drag_start_grid_pos.y, drag_end_grid_pos.y)
	
	var top_left_local = ship.grid_to_local(Vector2i(min_x, min_y))
	var bottom_right_local = ship.grid_to_local(Vector2i(max_x, max_y))
	
	var half_cell = float(Ship.CELL_SIZE) / 2.0
	var tl = top_left_local - Vector2(half_cell, half_cell)
	var br = bottom_right_local + Vector2(half_cell, half_cell)
	
	# 更新 Polygon2D 的點以符合當前拉取的矩形
	selection_visual.polygon = PackedVector2Array([
		Vector2(tl.x, tl.y), Vector2(br.x, tl.y),
		Vector2(br.x, br.y), Vector2(tl.x, br.y)
	])

func end_drag(end_pos: Vector2) -> void:
	var ship = builder.current_ship
	if not is_dragging or not ship: return
	
	is_dragging = false
	if selection_visual:
		selection_visual.hide()
	
	var drag_end_grid_pos = ship.global_to_grid(end_pos)
	var min_x = min(drag_start_grid_pos.x, drag_end_grid_pos.x)
	var max_x = max(drag_start_grid_pos.x, drag_end_grid_pos.x)
	var min_y = min(drag_start_grid_pos.y, drag_end_grid_pos.y)
	var max_y = max(drag_start_grid_pos.y, drag_end_grid_pos.y)
	
	var blocks_to_process: Array[BlockBase] = []
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var block = ship.get_block_at_grid(Vector2i(x, y))
			if block and not block is CoreBlock and not blocks_to_process.has(block):
				blocks_to_process.append(block)
				
	for block in blocks_to_process:
		# 檢查是否安全移除
		if ship.is_removal_safe(block):
			# 安全：直接拆除並退款
			if is_instance_valid(ship.core_block) and ship.core_block.inventory:
				if block.cost:
					ship.core_block.inventory.refund_cost(block.cost, 0.5)
			block.state_machine.transition_to(BlockStateMachine.State.DESTROYED)
		else:
			# 不安全：標記為待拆除
			block.state_machine.transition_to(BlockStateMachine.State.PENDING_REMOVAL)
		
	if blocks_to_process.size() > 0:
		ship.call_deferred("trigger_structural_check")
