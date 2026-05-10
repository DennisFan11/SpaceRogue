extends Node2D
class_name BlockBase

@export var cost: ResourceCost
@export var rotation_degrees_snap: int = 0
@export var mass: float = 1.0

var grid_position: Vector2i = Vector2i.ZERO

@onready var state_machine: BlockStateMachine = $BlockStateMachine
@onready var damageable: Damageable = $Damageable
@onready var poly_shape: PolyominoShape = $PolyominoShape
@onready var visual: Node2D = $Visual

var _vfx_manager: Node # DI 注入

# 動態生成的剛體碰撞，只在 BUILT 狀態時有值
var _active_collisions: Array[CollisionShape2D] = []

func _ready() -> void:
	if damageable:
		damageable.destroyed.connect(_on_damageable_destroyed)
	rotation_degrees = rotation_degrees_snap
	_update_occluders()


func _on_damageable_destroyed() -> void:
	state_machine.transition_to(BlockStateMachine.State.DESTROYED)

## 取得所有被佔用的絕對網格坐標
func get_global_occupied_cells() -> Array[Vector2i]:
	if not poly_shape:
		return [grid_position]
	return poly_shape.get_global_occupied_cells(grid_position, rotation_degrees_snap)

## 更新遮光多邊形以符合多連塊形狀
func _update_occluders() -> void:
	if not poly_shape:
		return
		
	var base_occ = $LightOccluder2D as LightOccluder2D
	if not base_occ:
		return
		
	var cells = poly_shape.occupied_cells
	if cells.size() == 0:
		return
		
	# 設定第一個 cell 的 occluder 位置
	var cell0 = cells[0]
	base_occ.position = Vector2(cell0.x * PolyominoShape.BLOCK_SIZE, cell0.y * PolyominoShape.BLOCK_SIZE)
	
	# 移除舊的動態生成的 occluders (防止重複呼叫)
	for child in get_children():
		if child is LightOccluder2D and child != base_occ:
			child.queue_free()
			
	# 為剩下的 cell 生成新的 occluders
	for i in range(1, cells.size()):
		var cell = cells[i]
		var occ = LightOccluder2D.new()
		var poly = OccluderPolygon2D.new()
		var s = PolyominoShape.BLOCK_SIZE / 2.0
		poly.polygon = PackedVector2Array([
			Vector2(-s, -s),
			Vector2(s, -s),
			Vector2(s, s),
			Vector2(-s, s)
		])
		occ.occluder = poly
		occ.position = Vector2(cell.x * PolyominoShape.BLOCK_SIZE, cell.y * PolyominoShape.BLOCK_SIZE)
		add_child(occ)
		
	# 根據目前狀態決定是否開啟 SDF
	_set_occluders_enabled(state_machine.current_state == BlockStateMachine.State.BUILT)

## 設定所有 Occluder 的啟用狀態
func _set_occluders_enabled(enabled: bool) -> void:
	for child in get_children():
		if child is LightOccluder2D:
			child.visible = enabled

## 當狀態機切換為 BUILT 時呼叫
func on_built() -> void:
	_set_occluders_enabled(true)
	
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
