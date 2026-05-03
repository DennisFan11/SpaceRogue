extends GameLoop
class_name ShipTestLoop

func _ready() -> void:
	# super._ready() 呼叫 DI.injection(self, true) 以及通用初始化
	await super._ready()


	# 生成測試飛船
	var ship = ship_manager.spawn_ship("test_ship", Vector2.ZERO)
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

	ship_manager.inject_starting_resources(ship)
	ship_builder.current_ship = ship

	var player_scene = load("res://GameSystem/PlayerSystem/Player.tscn")
	if player_scene:
		var player = player_scene.instantiate()
		player.global_position = Vector2(200, 200)
		add_child(player)
		# 把 Camera 交給 PlayerManager 管理 (已在 GameLoop 處理，這裡僅設定實體)
		player_manager.current_player_instance = player
