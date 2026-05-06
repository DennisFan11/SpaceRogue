extends Node2D
class_name PlayerManager

## 管理玩家太空人與飛船駕駛模式的切換

var current_player_instance: Player = null
var current_piloted_core: CoreBlock = null
var is_piloting: bool = false
var saved_equipment: BaseEquipment = null

var player_scene: PackedScene = preload("res://GameSystem/PlayerSystem/Player.tscn")
var player_ui_scene: PackedScene = preload("res://GameSystem/PlayerSystem/PlayerUI.tscn")

var main_camera: Camera2D = null ## 由 ShipTestLoop 設定
var zoom_target: Vector2 = Vector2.ONE
const ZOOM_SENSITIVITY = 0.1
const MIN_ZOOM = 0.1
const MAX_ZOOM = 5.0

func _ready() -> void:
	DI.register("_player_manager", self)
	
	# 初始化 PlayerUI
	var ui = player_ui_scene.instantiate()
	add_child(ui)

func _process(delta: float) -> void:
	# 攝影機縮放插值留在 _process 以獲得最高流暢度
	if main_camera:
		main_camera.zoom = main_camera.zoom.lerp(zoom_target, 10.0 * delta)

func _physics_process(delta: float) -> void:
	# 攝影機位置與旋轉跟隨物理物件，必須在 _physics_process 中處理以避免抖動
	if main_camera:
		var target_pos = main_camera.global_position
		var target_rot = 0.0
		var lerp_speed = 5.0
		
		if is_piloting and current_piloted_core:
			var offset = Vector2(32, 32).rotated(current_piloted_core.global_rotation)
			target_pos = current_piloted_core.global_position + offset
			target_rot = current_piloted_core.global_rotation
			lerp_speed = 10.0
		elif current_player_instance:
			target_pos = current_player_instance.global_position
			
		main_camera.global_position = main_camera.global_position.lerp(target_pos, lerp_speed * delta)
		main_camera.rotation = lerp_angle(main_camera.rotation, target_rot, 10.0 * delta)

func _unhandled_input(event: InputEvent) -> void:
	# 攝影機縮放
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_target *= (1.0 + ZOOM_SENSITIVITY)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_target *= (1.0 - ZOOM_SENSITIVITY)
		
		zoom_target.x = clamp(zoom_target.x, MIN_ZOOM, MAX_ZOOM)
		zoom_target.y = clamp(zoom_target.y, MIN_ZOOM, MAX_ZOOM)

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
		# 如果玩家持有裝備，保存它
		if current_player_instance.current_equipment:
			saved_equipment = current_player_instance.current_equipment
			saved_equipment.get_parent().remove_child(saved_equipment)
			add_child(saved_equipment)
			saved_equipment.hide()
			
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
		add_child(current_player_instance)
		
		# 恢復裝備
		if saved_equipment:
			remove_child(saved_equipment)
			current_player_instance.pick_up_equipment(saved_equipment)
			saved_equipment.show()
			saved_equipment = null
		
	current_piloted_core = null
	print("Player exited core.")
