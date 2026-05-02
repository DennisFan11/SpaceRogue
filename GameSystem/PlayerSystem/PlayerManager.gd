extends Node
class_name PlayerManager

## 管理玩家太空人與飛船駕駛模式的切換

var current_player_instance: Player = null
var current_piloted_core: CoreBlock = null
var is_piloting: bool = false

var player_scene: PackedScene = preload("res://GameSystem/PlayerSystem/Player.tscn")

var _ship_manager: ShipManager = null ## DI 自動注入
var main_camera: Camera2D = null ## 由 ShipTestLoop 設定

func _ready() -> void:
	DI.register("_player_manager", self)

func _process(delta: float) -> void:
	# 1. 調解攝影機跟隨
	if main_camera:
		var target_pos = main_camera.global_position
		var target_rot = 0.0
		if is_piloting and current_piloted_core:
			target_pos = current_piloted_core.global_position
			target_rot = current_piloted_core.global_rotation
		elif current_player_instance:
			target_pos = current_player_instance.global_position
			
		main_camera.global_position = main_camera.global_position.lerp(target_pos, 5.0 * delta)
		main_camera.rotation = target_rot

func _unhandled_input(event: InputEvent) -> void:
	# 假設 "interact" 對應鍵盤 F 鍵
	if event.is_action_pressed("interact"): 
		if is_piloting:
			exit_core()

func enter_core(core: Node) -> void:
	if not core: return
	
	is_piloting = true
	current_piloted_core = core
	
	# 將玩家實體刪除 (進入飛船)
	if is_instance_valid(current_player_instance):
		current_player_instance.queue_free()
		current_player_instance = null
	
	# 轉移控制權給飛船 (啟動 ShipInput)
	var ship = core.get_parent().get_parent() 
	if ship and ship.has_node("ShipInput"):
		# ship.get_node("ShipInput").set_active(true)
		pass
	
	print("Player entered core.")

func exit_core() -> void:
	if not is_piloting or not current_piloted_core: return
	
	is_piloting = false
	
	# 關閉飛船控制權
	var ship = current_piloted_core.get_parent().get_parent()
	if ship and ship.has_node("ShipInput"):
		# ship.get_node("ShipInput").set_active(false)
		pass
	
	# 重新生成玩家實體
	if player_scene:
		current_player_instance = player_scene.instantiate() as Player
		current_player_instance.global_position = ship.global_position + Vector2(100, 0)
		get_tree().current_scene.add_child(current_player_instance)
		
	current_piloted_core = null
	print("Player exited core.")
