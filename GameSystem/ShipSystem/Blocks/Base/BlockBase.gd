extends Node2D
class_name BlockBase

@export var cost: BlockCost
@export var rotation_degrees_snap: int = 0

var grid_position: Vector2i = Vector2i.ZERO

@onready var state_machine: BlockStateMachine = $BlockStateMachine
@onready var damageable: Damageable = $Damageable
@onready var poly_shape: PolyominoShape = $PolyominoShape
@onready var visual: Node2D = $Visual

# 動態生成的剛體碰撞，只在 BUILT 狀態時有值
var _active_collisions: Array[CollisionShape2D] = []

func _ready() -> void:
	if damageable:
		damageable.destroyed.connect(_on_damageable_destroyed)
	rotation_degrees = rotation_degrees_snap

func _on_damageable_destroyed() -> void:
	state_machine.transition_to(BlockStateMachine.State.DESTROYED)

## 取得所有被佔用的絕對網格坐標
func get_global_occupied_cells() -> Array[Vector2i]:
	if not poly_shape:
		return [grid_position]
	return poly_shape.get_global_occupied_cells(grid_position, rotation_degrees_snap)

## 當狀態機切換為 BUILT 時呼叫
func on_built() -> void:
	if poly_shape:
		var new_shapes = poly_shape.get_collision_shapes()
		var parent_container = get_parent()
		if parent_container:
			var physics_body = parent_container.get_parent()
			if physics_body is RigidBody2D:
				for col in new_shapes:
					# 將每個碰撞體的座標加上方塊本身的相對座標與旋轉
					var t = Transform2D().rotated(deg_to_rad(rotation_degrees_snap))
					col.position = position + (t * col.position)
					physics_body.add_child(col)
					_active_collisions.append(col)

## 當狀態機切換為 DESTROYED 時呼叫
func on_destroyed() -> void:
	for col in _active_collisions:
		if is_instance_valid(col):
			col.queue_free()
	_active_collisions.clear()
	
	# TODO: 播放爆炸特效、從結構中移除等
	queue_free()
