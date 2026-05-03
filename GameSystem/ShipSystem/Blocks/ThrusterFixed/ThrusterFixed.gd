extends BlockBase
class_name ThrusterFixed

## 單向固定推進器：2x1，只往 -Y (上) 方向噴射
## 旋轉後噴射方向隨 rotation_degrees_snap 改變
var thrust_force: float = 800.0

var current_activation: float = 0.0

func _process(delta: float) -> void:
	if current_activation > 0:
		current_activation = lerp(current_activation, 0.0, 15.0 * delta)
	if DebugSetting.show_thruster_vector:
		queue_redraw()

func _draw() -> void:
	if DebugSetting.show_thruster_vector and current_activation > 0.01:
		# 噴射方向為推力反方向 (Vector2.DOWN)，從噴口 cell (0, 1) 的位置發出
		var nozzle_pos = Vector2(0, Ship.CELL_SIZE)
		var exhaust_dir = Vector2.DOWN * (thrust_force * current_activation * DebugSetting.thruster_vector_scale)
		draw_line(nozzle_pos, nozzle_pos + exhaust_dir, Color(1, 0.5, 0, 1), 2.0)

func apply_thrust(physics_body: RigidBody2D, amount: float = 1.0) -> void:
	if not physics_body or amount <= 0.0: return
	current_activation = amount
	# 推力方向為局部 -Y，需依旋轉轉為全局方向
	var dir = Vector2.UP.rotated(global_rotation)
	# 施力在推進器的位置，自然產生力矩
	physics_body.apply_force(dir * thrust_force * amount, global_position - physics_body.global_position)
