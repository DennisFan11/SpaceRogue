extends Node
class_name ShipBuilder

## 負責切換建造工具與模式的 Context

var current_ship: Ship = null
var is_build_mode_active: bool = false

var build_menu: BuildMenu = null  ## 由 ShipTestLoop 外部賦值
var _player_manager: PlayerManager ## DI 自動注入

var _current_tool: BuildTool = null
var _place_tool: PlaceTool = null
var _remove_tool: RemoveTool = null

func _ready() -> void:
	_place_tool = PlaceTool.new(self)
	_remove_tool = RemoveTool.new(self)
	add_child(_place_tool)
	add_child(_remove_tool)

func _unhandled_input(event: InputEvent) -> void:
	# 1. 全局輸入：切換建造模式
	if current_ship and event.is_action_pressed("build_menu"): # B 鍵
		if not _player_manager.is_piloting:
			return
			
		if is_build_mode_active:
			exit_build_mode()
		else:
			enter_build_mode(current_ship)
		return

	if not is_build_mode_active or not current_ship: return
	
	# 2. 轉發輸入給當前工具
	# 如果正在放置塊，優先給 PlaceTool
	if _place_tool.selected_block_id != "":
		_place_tool.handle_input(event)
	else:
		# 否則給 RemoveTool (處理右鍵拖曳)
		_remove_tool.handle_input(event)


func _process(delta: float) -> void:
	if is_build_mode_active:
		if not _player_manager.is_piloting:
			exit_build_mode()
			return
			
		if _place_tool.selected_block_id != "":
			_place_tool.update(delta)
		else:
			_remove_tool.update(delta)

func enter_build_mode(target_ship: Ship) -> void:
	current_ship = target_ship
	is_build_mode_active = true
	if build_menu:
		if current_ship.core_block is CoreBlock:
			build_menu.current_core = current_ship.core_block as CoreBlock
		build_menu.toggle_ui(true)
	
	# 預設啟動放置工具（處於待命狀態）
	_switch_tool(_place_tool)

func exit_build_mode() -> void:
	is_build_mode_active = false
	if _current_tool:
		_current_tool.on_deactivated()
		_current_tool = null
	
	if build_menu:
		build_menu.toggle_ui(false)

func _switch_tool(new_tool: BuildTool) -> void:
	if _current_tool == new_tool: return
	if _current_tool:
		_current_tool.on_deactivated()
	_current_tool = new_tool
	if _current_tool:
		_current_tool.on_activated()

## 供外部 (如 BuildMenu) 呼叫
func select_block(block_id: String) -> void:
	_switch_tool(_place_tool)
	_place_tool.select_block(block_id)

func deselect_block() -> void:
	_place_tool.deselect_block()
	_switch_tool(_remove_tool)
