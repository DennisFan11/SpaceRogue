extends Node
class_name ShipBuilder

var current_ship: Ship = null
var selected_block_id: String = ""
var current_rotation: int = 0
var preview_block: BlockBase = null
var is_build_mode_active: bool = false

var build_menu: BuildMenu = null  ## 由 ShipTestLoop 外部赋値
var _player_manager: PlayerManager = null ## DI 自動注入

func _unhandled_input(event: InputEvent) -> void:
	if current_ship and event.is_action_pressed("build_menu"): # B 鍵
		# 只有在駕駛模式下才能開啟建造選單
		if _player_manager and not _player_manager.is_piloting:
			return
			
		if is_build_mode_active:
			exit_build_mode()
		else:
			enter_build_mode(current_ship)
		return

	if not is_build_mode_active or not current_ship: return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				start_drag_remove(current_ship.get_global_mouse_position())
			else:
				end_drag_remove(current_ship.get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			place_blueprint()
	elif event is InputEventKey:
		# 假設按 R 鍵可以旋轉
		if event.physical_keycode == KEY_R and event.pressed and not event.echo:
			rotate_block()

func _process(_delta: float) -> void:
	if is_build_mode_active:
		if _player_manager and not _player_manager.is_piloting:
			exit_build_mode()
			return
			
		if current_ship and preview_block:
			update_preview_position(current_ship.get_global_mouse_position())

func enter_build_mode(target_ship: Ship) -> void:
	current_ship = target_ship
	is_build_mode_active = true
	if build_menu:
		if current_ship.core_block is CoreBlock:
			build_menu.current_core = current_ship.core_block as CoreBlock
		build_menu.toggle_ui(true)

func exit_build_mode() -> void:
	is_build_mode_active = false
	if build_menu:
		build_menu.toggle_ui(false)
	if preview_block and is_instance_valid(preview_block):
		preview_block.queue_free()
		preview_block = null

func select_block(block_id: String) -> void:
	selected_block_id = block_id
	if preview_block and is_instance_valid(preview_block):
		preview_block.queue_free()
	
	preview_block = ShipBlockDB.instantiate_block(block_id) as BlockBase
	if preview_block:
		# 關閉碰撞等功能，純顯示虛影
		preview_block.modulate.a = 0.5
		# 將虛影加入場景樹
		add_child(preview_block)

func rotate_block() -> void:
	current_rotation = (current_rotation + 90) % 360
	if preview_block:
		preview_block.rotation_degrees_snap = current_rotation
		preview_block.rotation_degrees = current_rotation

func update_preview_position(mouse_global_pos: Vector2) -> void:
	if not current_ship or not preview_block: return
	
	var base_grid_pos = current_ship.global_to_grid(mouse_global_pos)
	var local_pos = current_ship.grid_to_local(base_grid_pos)
	
	preview_block.grid_position = base_grid_pos
	preview_block.global_position = current_ship.blocks_container.to_global(local_pos)
	# 預覽方塊在全局環境下，需要加上飛船當前的旋轉
	preview_block.global_rotation = current_ship.blocks_container.global_rotation + deg_to_rad(current_rotation)
	
	var is_overlapping = false
	var has_neighbor = false
	var has_built_neighbor = false
	
	for cell in preview_block.get_global_occupied_cells():
		if current_ship.get_block_at_grid(cell) != null:
			is_overlapping = true
			break
		
		# 檢查相鄰格子
		for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var neighbor = current_ship.get_block_at_grid(cell + offset)
			if neighbor:
				has_neighbor = true
				if neighbor.state_machine.is_built():
					has_built_neighbor = true
			
	if is_overlapping or not has_neighbor:
		preview_block.modulate = Color(1, 0, 0, 0.5) # 紅色：重疊或無連接，不允許放置
	else:
		var builder_node = current_ship.core_block.builder if current_ship.core_block and current_ship.core_block.builder else null
		var in_range = false
		if builder_node:
			in_range = builder_node._is_within_range(preview_block)
			
		if has_built_neighbor and in_range:
			preview_block.modulate = Color(0.5, 0.5, 0.5, 0.5) # 灰色：合法可立刻建造
		else:
			preview_block.modulate = Color(1, 1, 0, 0.5) # 黃色：未來合法，目前距離不夠或鄰居還沒建好

func place_blueprint() -> void:
	if not current_ship or not preview_block or selected_block_id == "": return
	
	var base_grid_pos = current_ship.global_to_grid(preview_block.global_position)
	preview_block.grid_position = base_grid_pos
	
	var is_overlapping = false
	var has_neighbor = false
	
	for cell in preview_block.get_global_occupied_cells():
		if current_ship.get_block_at_grid(cell) != null:
			is_overlapping = true
			break
		for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if current_ship.get_block_at_grid(cell + offset) != null:
				has_neighbor = true
			
	# 只允許沒有重疊且有連接現有方塊的情況放置
	if not is_overlapping and has_neighbor:
		var new_block = ShipBlockDB.instantiate_block(selected_block_id) as BlockBase
		if new_block:
			new_block.grid_position = base_grid_pos
			new_block.rotation_degrees_snap = current_rotation
			new_block.position = current_ship.grid_to_local(base_grid_pos)
			current_ship.blocks_container.add_child(new_block)
			new_block.state_machine.transition_to(BlockStateMachine.State.BLUEPRINT)

var drag_start_grid_pos: Vector2i

func start_drag_remove(start_pos: Vector2) -> void:
	drag_start_grid_pos = current_ship.global_to_grid(start_pos)

func end_drag_remove(end_pos: Vector2) -> void:
	var drag_end_grid_pos = current_ship.global_to_grid(end_pos)
	
	var min_x = min(drag_start_grid_pos.x, drag_end_grid_pos.x)
	var max_x = max(drag_start_grid_pos.x, drag_end_grid_pos.x)
	var min_y = min(drag_start_grid_pos.y, drag_end_grid_pos.y)
	var max_y = max(drag_start_grid_pos.y, drag_end_grid_pos.y)
	
	var blocks_to_remove: Array[BlockBase] = []
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var block = current_ship.get_block_at_grid(Vector2i(x, y))
			if block and not block is CoreBlock and not blocks_to_remove.has(block):
				blocks_to_remove.append(block)
				
	for block in blocks_to_remove:
		if current_ship.core_block and current_ship.core_block.inventory:
			# 退款 50%
			current_ship.core_block.inventory.refund_cost(block.cost, 0.5)
		block.state_machine.transition_to(BlockStateMachine.State.DESTROYED)
		
	if blocks_to_remove.size() > 0:
		current_ship.trigger_structural_check()
