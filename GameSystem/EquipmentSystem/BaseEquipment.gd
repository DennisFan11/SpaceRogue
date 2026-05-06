extends RigidBody2D
class_name BaseEquipment

## 裝備基底類別

enum State { DROPPED, HELD }

@export var equipment_id: String = ""
@export var rotate_speed: float = 10.0

var current_state: State = State.DROPPED
var carrier: Node2D = null
var interactable: Interactable = null

func _ready() -> void:
	# 預設碰撞層級
	collision_layer = BitmaskManager.LAYER_EQUIPMENT
	collision_mask = BitmaskManager.LAYER_WALL | BitmaskManager.LAYER_SHIP
	
	# 如果是 RigidBody，我們需要能夠在 HELD 狀態下手動控制位移與旋轉
	lock_rotation = false
	linear_damp = 5.0
	angular_damp = 5.0
	
	_setup_interactable()

func _setup_interactable() -> void:
	interactable = Interactable.new()
	interactable.action_name = "pick_up"
	interactable.prompt_text = "[E] Pick up " + (equipment_id if equipment_id != "" else "Equipment")
	add_child(interactable)
	interactable.interacted.connect(_on_interacted)

func _on_interacted(interactor: Node) -> void:
	if interactor is Player and current_state == State.DROPPED:
		if interactor.current_equipment == null:
			interactor.pick_up_equipment(self)

func _physics_process(delta: float) -> void:
	if current_state == State.HELD and carrier:
		# 當被持用時，位置會被父節點 (EquipmentAnchor) 決定
		# 我們主要處理轉向鼠標
		_handle_rotation(delta)

func _handle_rotation(delta: float) -> void:
	var target_dir = (get_global_mouse_position() - global_position).normalized()
	var target_angle = target_dir.angle()
	global_rotation = lerp_angle(global_rotation, target_angle, rotate_speed * delta)

## 被撿起
func pick_up(new_carrier: Node2D) -> void:
	carrier = new_carrier
	current_state = State.HELD
	
	# 停用物理模擬
	freeze = true
	
	# 停用自身碰撞以避免影響玩家移動
	# 這裡可以透過變更 collision_layer/mask 來實現
	collision_layer = 0
	collision_mask = 0
	
	# 重置本地旋轉/位置
	position = Vector2.ZERO
	rotation = 0
	
	# 隱藏互動提示
	if interactable:
		interactable.hide_prompt()
		interactable.process_mode = PROCESS_MODE_DISABLED

## 被丟下
func drop(impulse: Vector2 = Vector2.ZERO) -> void:
	carrier = null
	current_state = State.DROPPED
	
	# 恢復物理模擬
	freeze = false
	
	# 恢復碰撞層級
	collision_layer = BitmaskManager.LAYER_EQUIPMENT
	collision_mask = BitmaskManager.LAYER_WALL | BitmaskManager.LAYER_SHIP
	
	# 恢復互動提示
	if interactable:
		interactable.process_mode = PROCESS_MODE_INHERIT
	
	# 施加衝量
	apply_central_impulse(impulse)

## 主功能啟動 (子類實作)
func use_start() -> void:
	pass

## 主功能停止 (子類實作)
func use_stop() -> void:
	pass

## 主功能持續觸發 (子類實作)
func use_process(_delta: float) -> void:
	pass
