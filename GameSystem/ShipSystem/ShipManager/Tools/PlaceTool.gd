extends BuildTool
class_name PlaceTool

var selected_block_id: String = ""
var current_rotation: int = 0
var preview_block: BlockBase = null
var arrow_visual: Polygon2D = null

func on_activated() -> void:
	_create_arrow_visual()

func on_deactivated() -> void:
	_clear_preview()
	if arrow_visual:
		arrow_visual.queue_free()
		arrow_visual = null

func _create_arrow_visual() -> void:
	if arrow_visual: return
	arrow_visual = Polygon2D.new()
	# 繪製一個指向下的箭頭 (表示噴射/噴口方向)
	arrow_visual.polygon = PackedVector2Array([
		Vector2(0, 25), Vector2(-15, 10), Vector2(-7, 10), Vector2(-7, -20),
		Vector2(7, -20), Vector2(7, 10), Vector2(15, 10)
	])
	arrow_visual.color = Color(0, 1, 1, 0.8) # 青色
	arrow_visual.z_index = 100
	arrow_visual.hide()
	builder.add_child(arrow_visual)

func select_block(block_id: String) -> void:
	selected_block_id = block_id
	_clear_preview()
	
	preview_block = ShipBlockDB.instantiate_block(block_id) as BlockBase
	if preview_block:
		preview_block.modulate.a = 0.5
		builder.add_child(preview_block)
		if arrow_visual:
			arrow_visual.show()

func deselect_block() -> void:
	selected_block_id = ""
	_clear_preview()
	if arrow_visual:
		arrow_visual.hide()

func _clear_preview() -> void:
	if preview_block and is_instance_valid(preview_block):
		preview_block.queue_free()
	preview_block = null

func rotate_block() -> void:
	current_rotation = (current_rotation + 90) % 360
	if preview_block:
		preview_block.rotation_degrees_snap = current_rotation
		preview_block.rotation_degrees = current_rotation

func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			place_blueprint()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			deselect_block()
	elif event is InputEventKey:
		if event.physical_keycode == KEY_R and event.pressed and not event.echo:
			rotate_block()

func update(_delta: float) -> void:
	if builder.current_ship and preview_block:
		update_preview_position(builder.current_ship.get_global_mouse_position())

func update_preview_position(mouse_global_pos: Vector2) -> void:
	var ship = builder.current_ship
	if not ship or not preview_block: return
	
	var base_grid_pos = ship.global_to_grid(mouse_global_pos)
	var local_pos = ship.grid_to_local(base_grid_pos)
	
	preview_block.grid_position = base_grid_pos
	preview_block.global_position = ship.blocks_container.to_global(local_pos)
	preview_block.global_rotation = ship.blocks_container.global_rotation + deg_to_rad(current_rotation)
	
	# 更新箭頭位置與旋轉
	if arrow_visual:
		arrow_visual.global_position = preview_block.global_position
		arrow_visual.global_rotation = preview_block.global_rotation
	
	var is_overlapping = false
	var has_neighbor = false
	var has_built_neighbor = false
	
	for cell in preview_block.get_global_occupied_cells():
		if ship.get_block_at_grid(cell) != null:
			is_overlapping = true
			break
		
		for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var neighbor = ship.get_block_at_grid(cell + offset)
			if neighbor:
				has_neighbor = true
				if neighbor.state_machine.is_built():
					has_built_neighbor = true
			
	if is_overlapping or not has_neighbor:
		preview_block.modulate = Color(1, 0, 0, 0.5)
	else:
		var builder_node = ship.core_block.builder if ship.core_block and ship.core_block.builder else null
		var in_range = true # 預設 true，如果沒有 builder 限制
		if builder_node:
			in_range = builder_node._is_within_range(preview_block)
			
		if has_built_neighbor and in_range:
			preview_block.modulate = Color(0.5, 0.5, 0.5, 0.5)
		else:
			preview_block.modulate = Color(1, 1, 0, 0.5)

func place_blueprint() -> void:
	var ship = builder.current_ship
	if not ship or not preview_block or selected_block_id == "": return
	
	var base_grid_pos = ship.global_to_grid(preview_block.global_position)
	
	var is_overlapping = false
	var has_neighbor = false
	
	for cell in preview_block.get_global_occupied_cells():
		if ship.get_block_at_grid(cell) != null:
			is_overlapping = true
			break
		for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if ship.get_block_at_grid(cell + offset) != null:
				has_neighbor = true
			
	if not is_overlapping and has_neighbor:
		var new_block = ShipBlockDB.instantiate_block(selected_block_id) as BlockBase
		if new_block:
			new_block.grid_position = base_grid_pos
			new_block.rotation_degrees_snap = current_rotation
			new_block.position = ship.grid_to_local(base_grid_pos)
			ship.blocks_container.add_child(new_block)
			new_block.state_machine.transition_to(BlockStateMachine.State.BLUEPRINT)
