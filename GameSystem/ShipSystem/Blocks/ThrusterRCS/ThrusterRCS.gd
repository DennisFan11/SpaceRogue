extends BlockBase
class_name ThrusterRCS

## RCS 姿態控制推進器：1x1，支援全向微調推力
## 通常由 ThrusterController 依質心差計算分配推力
@export var thrust_force: float = 200.0

var current_activation: float = 0.0
var _current_direction: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	if current_activation > 0:
		current_activation = lerp(current_activation, 0.0, 15.0 * delta)
	if DebugSetting.show_thruster_vector:
		queue_redraw()

func _draw() -> void:
	if DebugSetting.show_thruster_vector and current_activation > 0.01:
		var end_point = -_current_direction.normalized().rotated(-global_rotation) * (thrust_force * current_activation * DebugSetting.thruster_vector_scale)
		draw_line(Vector2.ZERO, end_point, Color(1, 0.5, 0, 0.8), 2.0)

func apply_thrust(physics_body: RigidBody2D, direction: Vector2, amount: float = 1.0) -> void:
	if not physics_body or amount <= 0.0 or direction.length_squared() < 0.01: return
	current_activation = amount
	_current_direction = direction
	physics_body.apply_force(direction.normalized() * thrust_force * amount, global_position - physics_body.global_position)
