extends RigidBody2D
class_name BaseResourceItem

## 資源掉落物的基礎類別

@export var resource_type: ResourceType
@export var amount: int = 1

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# 設置碰撞層與遮罩
	collision_layer = BitmaskManager.LAYER_RESOURCE
	# 資源可以與船隻、牆體碰撞，但不與玩家直接物理碰撞 (玩家通過區域檢測拾取)
	collision_mask = BitmaskManager.LAYER_SHIP | BitmaskManager.LAYER_WALL
	
	if resource_type:
		_apply_visual()

func _apply_visual() -> void:
	if sprite and resource_type.icon:
		sprite.texture = resource_type.icon

## 初始化數據
func init(type: ResourceType, amt: int) -> void:
	resource_type = type
	amount = amt
	if is_inside_tree():
		_apply_visual()
