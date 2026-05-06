extends BlockBase

@export var damage_per_second: float = 1500.0
@export var laser_range: float = 300.0
@export var laser_color: Color = Color("0c8599")
@export var tracking_angle: float = 15.0 # 追蹤角度限制 (度)
@export var rotation_speed: float = 10.0 # 旋轉速度
@export var max_laser_width: float = 8.0

@onready var laser_head: Node2D = $Visual/LaserHead
@onready var ray_cast: RayCast2D = $Visual/LaserHead/RayCast2D
@onready var line_2d: Line2D = $Visual/LaserHead/Line2D
@onready var tracking_area: Area2D = $Visual/TrackingArea

var _is_active: bool = false
var _is_firing: bool = false
var _damage_timer: float = 0.0
const DAMAGE_INTERVAL: float = 0.05

var _physics_body: RigidBody2D = null
var _width_tween: Tween = null

func _on_injected() -> void:
	pass

func _ready() -> void:
	super._ready()
	line_2d.points = [Vector2.ZERO, Vector2.ZERO]
	line_2d.default_color = laser_color
	# 稍微也把基座調色，讓整體視覺更一致 (可選)
	# visual.modulate = laser_color.lerp(Color.WHITE, 0.7)
	
	line_2d.width = 0
	line_2d.visible = false
	ray_cast.target_position = Vector2(0, laser_range)
	
	# 設定碰撞遮罩：飛船與牆體
	ray_cast.collision_mask = BitmaskManager.create_mask([BitmaskManager.LAYER_SHIP, BitmaskManager.LAYER_WALL])
	
	# 延遲設定例外
	call_deferred("_setup_references")

func _setup_references() -> void:
	var parent_container = get_parent()
	if parent_container:
		_physics_body = parent_container.get_parent() as RigidBody2D
		if _physics_body:
			ray_cast.add_exception(_physics_body)

func _physics_process(delta: float) -> void:
	if state_machine.current_state != BlockStateMachine.State.BUILT:
		_set_laser_active(false)
		return
		
	_set_laser_active(true)
	
	if _is_active:
		_update_tracking(delta)
		_update_laser(delta)

func _set_laser_active(active: bool) -> void:
	if _is_active == active:
		return
	_is_active = active
	ray_cast.enabled = active
	if not _is_active:
		_set_firing(false)

func _set_firing(firing: bool) -> void:
	if _is_firing == firing:
		return
	_is_firing = firing
	
	if _width_tween:
		_width_tween.kill()
	_width_tween = create_tween()
	
	if _is_firing:
		line_2d.default_color = laser_color
		line_2d.visible = true
		_width_tween.tween_property(line_2d, "width", max_laser_width, 0.1).set_trans(Tween.TRANS_CUBIC)
	else:
		_width_tween.tween_property(line_2d, "width", 0.0, 0.15).set_trans(Tween.TRANS_CUBIC)
		_width_tween.tween_callback(func(): line_2d.visible = false)

func _update_tracking(delta: float) -> void:
	var target = _find_best_target()
	var target_rot = 0.0
	
	if target:
		var local_pos = to_local(target.global_position)
		target_rot = Vector2.DOWN.angle_to(local_pos)
		# 限制追蹤角度
		target_rot = clamp(target_rot, deg_to_rad(-tracking_angle), deg_to_rad(tracking_angle))
	
	# 平滑旋轉雷射頭
	laser_head.rotation = lerp_angle(laser_head.rotation, target_rot, rotation_speed * delta)

func _find_best_target() -> Node2D:
	var bodies = tracking_area.get_overlapping_bodies()
	var best_target: Node2D = null
	var min_dist_sq = INF
	
	for body in bodies:
		if body == _physics_body: continue
		
		var local_pos = to_local(body.global_position)
		var angle_to_target = Vector2.DOWN.angle_to(local_pos)
		
		# 只追蹤前方 +/- tracking_angle 範圍內的目標
		if abs(rad_to_deg(angle_to_target)) <= tracking_angle * 2.0:
			var dist_sq = local_pos.length_squared()
			if dist_sq < min_dist_sq:
				min_dist_sq = dist_sq
				best_target = body
				
	return best_target

func _update_laser(delta: float) -> void:
	ray_cast.force_raycast_update()
	
	var is_colliding = ray_cast.is_colliding()
	_set_firing(is_colliding)
	
	if not _is_firing and line_2d.width <= 0.1:
		return
		
	var hit_pos = ray_cast.target_position
	if is_colliding:
		var collider = ray_cast.get_collider()
		var collision_point = ray_cast.get_collision_point()
		hit_pos = ray_cast.to_local(collision_point)
		
		# 傷害邏輯
		_damage_timer += delta
		if _damage_timer >= DAMAGE_INTERVAL:
			_damage_timer = 0.0
			_apply_damage(collider, collision_point)
			
		# 特效：受傷粒子
		if _vfx_manager:
			_vfx_manager.play_damage_particles(collision_point, laser_color, ray_cast.get_collision_normal())
	
	# 更新雷射線段視覺
	line_2d.set_point_position(1, hit_pos)
	
	# 只有在發射且寬度大於0時增加抖動 (由於 tween 正在控制 width，這裡微調會產生閃爍感)
	if _is_firing:
		line_2d.width = max_laser_width + randf() * 2.0

func _apply_damage(collider: Object, hit_point: Vector2) -> void:
	var damage_amount = damage_per_second * DAMAGE_INTERVAL
	var source_team = Team.PLAYER
	
	if collider.has_method("damage"):
		collider.damage(damage_amount, source_team, hit_point)
	elif collider.has_node("Damageable"):
		collider.get_node("Damageable").take_damage(damage_amount, source_team, hit_point)
	elif collider is Damageable:
		collider.take_damage(damage_amount, source_team, hit_point)
