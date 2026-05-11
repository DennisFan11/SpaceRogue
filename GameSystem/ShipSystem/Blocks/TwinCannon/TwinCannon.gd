extends BlockBase
class_name TwinCannon

## 雙管砲艙：自動鎖定並攻擊追蹤範圍內的敵人

@export var fire_rate: float = 2.0        # 每秒開火次數 (兩管合計)
@export var damage_per_bullet: float = 40.0
@export var tracking_radius: float = 250.0
@export var rotation_speed: float = 8.0   # 砲管旋轉速度
@export var indicator_angle_degrees: float = 360.0

@onready var turret_head: Node2D = $Visual/TurretHead
@onready var left_muzzle: Marker2D = $Visual/TurretHead/LeftMuzzle
@onready var right_muzzle: Marker2D = $Visual/TurretHead/RightMuzzle
@onready var tracking_area: Area2D = $Visual/TrackingArea

var _bullet_manager: BulletManager # DI 注入
var _ray_manager: RayManager # DI 注入
var _fire_timer: float = 0.0
var _fire_left_next: bool = true    # 交替兩管
var _physics_body: RigidBody2D = null

func _ready() -> void:
	super._ready()
	_apply_tracking_radius()
	call_deferred("_setup_references")
	
	var indicator = RangeIndicator.new()
	indicator.radius = tracking_radius
	indicator.angle_degrees = indicator_angle_degrees
	indicator.direction = Vector2.DOWN
	add_child(indicator)

func _apply_tracking_radius() -> void:
	var shape_node = tracking_area.get_node("CollisionShape2D")
	if shape_node and shape_node.shape is CircleShape2D:
		# 複製一份 Shape，避免修改到共享資源
		shape_node.shape = shape_node.shape.duplicate()
		shape_node.shape.radius = tracking_radius

func _setup_references() -> void:
	var container = get_parent()
	if container:
		_physics_body = container.get_parent() as RigidBody2D

func _physics_process(delta: float) -> void:
	if state_machine.current_state != BlockStateMachine.State.BUILT:
		return
	
	var target = _find_best_target()
	
	if target:
		_rotate_turret_towards(target.global_position, delta)
		_fire_timer += delta
		var fire_interval = 1.0 / fire_rate
		if _fire_timer >= fire_interval:
			_fire_timer = 0.0
			_shoot(target)
	else:
		# 沒有目標時緩慢回正
		turret_head.rotation = lerp_angle(turret_head.rotation, 0.0, rotation_speed * 0.3 * delta)

func _find_best_target() -> Node2D:
	var bodies = tracking_area.get_overlapping_bodies()
	var best: Node2D = null
	var min_dist_sq = INF
	
	for body in bodies:
		if body == _physics_body:
			continue
		# 只鎖定敵人 (collision_layer == LAYER_ENEMY)
		if body.collision_layer & BitmaskManager.LAYER_ENEMY == 0:
			continue
		var d = global_position.distance_squared_to(body.global_position)
		if d < min_dist_sq:
			if _is_within_angle_limit(body.global_position):
				min_dist_sq = d
				best = body
	
	# 飛船砲台視野內沒有敵人時 能夠主動攻擊 被標記的視野外最近敵人
	if not best:
		var tagged_enemy = _ray_manager.get_nearest_tagged_enemy(global_position)
		if tagged_enemy and _is_within_angle_limit(tagged_enemy.global_position):
			best = tagged_enemy
	
	return best

func _is_within_angle_limit(target_pos: Vector2) -> bool:
	if indicator_angle_degrees >= 360.0:
		return true
		
	var dir_to_target = (target_pos - global_position).normalized()
	# 砲管預設朝下 (Vector2.DOWN)，所以基準方向是向下
	var target_angle = dir_to_target.angle()
	
	var base_rotation = 0.0
	if turret_head.get_parent() is Node2D:
		base_rotation = turret_head.get_parent().global_rotation
		
	# 砲管預設朝下，所以要加上 PI/2 來對齊
	var angle_diff = abs(angle_difference(base_rotation + PI/2, target_angle))
	return angle_diff <= deg_to_rad(indicator_angle_degrees / 2.0)


func _rotate_turret_towards(target_pos: Vector2, delta: float) -> void:
	var dir_to_target = (target_pos - turret_head.global_position).normalized()
	# 計算目標在全局空間的角度，減去 PI/2 是因為砲管預設朝下 (Vector2.DOWN)
	var desired_global_rotation = dir_to_target.angle() - PI/2
	
	# 轉換為本地旋轉角度 (相對於父節點)
	var parent_global_rot = 0.0
	if turret_head.get_parent() is Node2D:
		parent_global_rot = turret_head.get_parent().global_rotation
		
	var desired_local_rot = desired_global_rotation - parent_global_rot
	
	turret_head.rotation = lerp_angle(turret_head.rotation, desired_local_rot, rotation_speed * delta)

func _shoot(target: Node2D) -> void:
	if not _bullet_manager:
		return
	
	var muzzle: Marker2D = left_muzzle if _fire_left_next else right_muzzle
	_fire_left_next = !_fire_left_next
	
	var fire_pos = muzzle.global_position
	# 沿著炮管的方向發射 (預設朝下，所以用 Vector2.DOWN 旋轉)
	var fire_dir = Vector2.DOWN.rotated(turret_head.global_rotation)
	
	_bullet_manager.fire("default", fire_pos, fire_dir, Team.PLAYER, damage_per_bullet)
