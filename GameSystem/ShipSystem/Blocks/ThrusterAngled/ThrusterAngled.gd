extends BlockBase
class_name ThrusterAngled

## 15 度角推進器：1x1，提供偏轉 15° 的推力
## 用於複雜非對稱船體的推力補償
@export var angle_offset_deg: float = 15.0
@export var thrust_force: float = 600.0

var current_activation: float = 0.0
var current_gimbal: float = 0.0

func _process(delta: float) -> void:
	if current_activation > 0:
		current_activation = lerp(current_activation, 0.0, 15.0 * delta)
	if DebugSetting.show_thruster_vector:
		queue_redraw()

func _draw() -> void:
	if DebugSetting.show_thruster_vector and current_activation > 0.01:
		# 噴射方向為推力反方向
		var local_thrust_dir = Vector2.UP.rotated(deg_to_rad(current_gimbal))
		var exhaust_dir = -local_thrust_dir * (thrust_force * current_activation * DebugSetting.thruster_vector_scale)
		draw_line(Vector2.ZERO, exhaust_dir, Color(1, 0.5, 0, 1), 2.0)

func apply_thrust(physics_body: RigidBody2D, amount: float = 1.0, target_gimbal: float = 0.0) -> void:
	if not physics_body or amount <= 0.0: return
	current_activation = amount
	current_gimbal = clamp(target_gimbal, -angle_offset_deg, angle_offset_deg)
	
	var local_dir = Vector2.UP.rotated(deg_to_rad(current_gimbal))
	var world_dir = local_dir.rotated(global_rotation)
	physics_body.apply_force(world_dir * thrust_force * amount, global_position - physics_body.global_position)
