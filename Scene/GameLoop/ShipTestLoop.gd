extends GameLoop
class_name ShipTestLoop

@onready var _ship_manager: ShipManager = $ShipManager
@onready var build_menu: BuildMenu = $CanvasLayer/BuildMenu
@onready var ship_builder: ShipBuilder = $ShipBuilder

@onready var camera: Camera2D = $Camera2D
@onready var player_manager: PlayerManager = $PlayerManager

func _ready() -> void:
	# super._ready() 呼叫 DI.injection(self, true)
	# 此前所有子節點 _ready() 已執行並向 DI 登錄完畢
	await super._ready()

	# ShipBuilder 的 build_menu 不走 DI，直接賦值
	ship_builder.build_menu = build_menu
	build_menu.on_block_selected.connect(ship_builder.select_block)

	# 生成測試飛船
	var ship = _ship_manager.spawn_ship("test_ship", Vector2.ZERO)
	if not ship:
		return

	var core = ShipBlockDB.instantiate_block("core") as CoreBlock
	if not core:
		return

	core.grid_position = Vector2i(0, 0)
	ship.blocks_container.add_child(core)
	core.state_machine.transition_to(BlockStateMachine.State.BUILT)
	ship.core_block = core
	core.damageable.destroyed.connect(on_core_destroyed)

	_ship_manager.inject_starting_resources(ship)
	ship_builder.current_ship = ship

	var player_scene = load("res://GameSystem/PlayerSystem/Player.tscn")
	if player_scene:
		var player = player_scene.instantiate()
		player.global_position = Vector2(200, 200)
		add_child(player)
		# 把 Camera 交給 PlayerManager 管理
		player_manager.main_camera = camera
		player_manager.current_player_instance = player
