extends RigidBody2D
class_name BaseResourceItem

## 資源掉落物的基礎類別，包含狀態機管理採集行為
## 資料直接定義在場景的導出變數中

enum State {
	IDLE,
	TETHERED,
	ATTRACTED,
	COLLECTED
}

@export_group("Resource Data")
@export var type: ResourceDB.Type = ResourceDB.Type.NONE
@export var display_name: String = "Unknown Resource"
@export var ui_icon: Texture2D

@export_group("Physics")
@export var amount: int = 1

var current_state: State = State.IDLE
var target_node: Node2D = null ## 當前互動的對象 (玩家或吸引器)

@onready var sprite: Sprite2D = $Sprite2D
@onready var tether_line: Line2D = $TetherLine
@onready var res_selecter: Sprite2D = %ResSelecter

func _ready() -> void:
	add_to_group("resource_items")
	# 設置物理層級：僅與資源、牆體(TileBlock)、玩家碰撞
	collision_layer = BitmaskManager.LAYER_RESOURCE
	collision_mask = BitmaskManager.LAYER_RESOURCE | BitmaskManager.LAYER_WALL | BitmaskManager.LAYER_PLAYER
	
	# 資源通常不受重力影響 (太空環境)
	gravity_scale = 0.0
	linear_damp = 1.0
	angular_damp = 1.0
	
	if tether_line:
		tether_line.visible = false
		tether_line.points = [Vector2.ZERO, Vector2.ZERO]
	
	if res_selecter:
		res_selecter.visible = false
	


func _physics_process(_delta: float) -> void:
	match current_state:
		State.TETHERED:
			_handle_tether_logic()
		State.ATTRACTED:
			_handle_attraction_logic()
		_:
			if tether_line: tether_line.visible = false

## 狀態切換
func set_state(new_state: State, target: Node2D = null) -> void:
	if current_state == State.COLLECTED: return # 已採集則不接受任何狀態
	
	# 吸引優先級高於連線
	if current_state == State.ATTRACTED and new_state == State.TETHERED:
		return
	
	current_state = new_state
	target_node = target
	
	# 更新連線視覺
	if tether_line:
		tether_line.visible = (current_state == State.TETHERED)
	
	if res_selecter:
		res_selecter.visible = (current_state == State.TETHERED)

func _handle_tether_logic() -> void:
	if not is_instance_valid(target_node): 
		set_state(State.IDLE)
		return
	
	if tether_line:
		tether_line.visible = true
		tether_line.set_point_position(0, global_position)
		tether_line.set_point_position(1, target_node.global_position)

func _handle_attraction_logic() -> void:
	if not is_instance_valid(target_node): 
		set_state(State.IDLE)
		return
	
	if tether_line: tether_line.visible = false

## 初始化數據
func init(new_type: ResourceDB.Type, amt: int) -> void:
	type = new_type
	amount = amt
