extends CharacterBody2D
class_name CentipedeSegment

@export var speed: float = 160.0
@export var max_force: float = 8.0
@export var follow_distance: float = 24.0 # 節點距離
@export var is_head: bool = false
@export var damage_amount: float = 20.0
@export var damage_interval: float = 0.5
@export var initial_length: int = 0 # 只有初始頭部需要設定 > 0 來生成身體

var next_segment: CentipedeSegment = null
var prev_segment: CentipedeSegment = null

var _combat_manager: CombatManager
var _damage_timer: float = 0.0

@onready var damageable: Damageable = $Damageable
@onready var head_visual: Node2D = $CentipedeHeadVisual
@onready var body_visual: Node2D = $CentipedeBodyVisual

func _ready() -> void:
	collision_layer = BitmaskManager.LAYER_ENEMY
	collision_mask = BitmaskManager.LAYER_PLAYER | BitmaskManager.LAYER_SHIP | BitmaskManager.LAYER_WALL
	
	if damageable:
		damageable.destroyed.connect(_on_destroyed)
		
	var rt = RadarTarget.new()
	rt.display_name = "蜈蚣節點"
	if is_head:
		rt.display_name = "蜈蚣頭部"
	add_child(rt)
		
	call_deferred("_init_segments")

func _init_segments() -> void:
	_update_visuals()
	if is_head and initial_length > 1:
		_spawn_body(initial_length - 1)

func _spawn_body(count: int) -> void:
	var current: CentipedeSegment = self
	var scene = EnemyDB.get_enemy_scene("centipede")
	
	for i in range(count):
		var new_seg = scene.instantiate() as CentipedeSegment
		new_seg.is_head = false
		new_seg.initial_length = 0
		new_seg.follow_distance = follow_distance # 傳遞節點距離
		
		# 放置在後面
		new_seg.global_position = current.global_position - current.transform.x * follow_distance
		new_seg.rotation = current.rotation
		
		# 互相連結
		current.next_segment = new_seg
		new_seg.prev_segment = current
		
		get_parent().add_child(new_seg)
		current = new_seg

func _physics_process(delta: float) -> void:
	if is_head:
		_process_head_movement(delta)
	else:
		_process_body_movement(delta)
		
	_handle_contact_damage(delta)

func _process_head_movement(delta: float) -> void:
	var target_pos = Vector2.ZERO
	if _combat_manager:
		target_pos = _combat_manager.get_target_position()
		
	var desired_velocity = (target_pos - global_position).normalized() * speed
	var steering = (desired_velocity - velocity) * max_force * delta
	velocity += steering
	velocity = velocity.limit_length(speed)
	
	if velocity.length_squared() > 1.0:
		rotation = velocity.angle()
		
	move_and_slide()

func _process_body_movement(delta: float) -> void:
	if not is_instance_valid(prev_segment) or prev_segment.is_queued_for_deletion():
		# 如果前面的節點消失，自己變成頭
		become_head()
		return
		
	var target_pos = prev_segment.global_position
	var dist = global_position.distance_to(target_pos)
	
	if dist > follow_distance:
		# 跟隨前面的節點
		var dir = (target_pos - global_position).normalized()
		# 距離越遠，速度越快，確保不會脫節
		var current_speed = lerp(speed, speed * 2.0, clamp((dist - follow_distance) / follow_distance, 0.0, 1.0))
		velocity = dir * current_speed
		rotation = lerp_angle(rotation, dir.angle(), 15.0 * delta)
	else:
		# 太近則減速
		velocity = velocity.move_toward(Vector2.ZERO, speed * 5.0 * delta)
		
	move_and_slide()

func become_head() -> void:
	is_head = true
	prev_segment = null
	_update_visuals()

func _update_visuals() -> void:
	if is_head:
		head_visual.visible = true
		body_visual.visible = false
	else:
		head_visual.visible = false
		body_visual.visible = true

func _handle_contact_damage(delta: float) -> void:
	_damage_timer += delta
	if _damage_timer < damage_interval:
		return
		
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if _combat_manager:
			if _combat_manager.apply_damage(collider, collision.get_position(), damage_amount, Team.NEUTRAL):
				_damage_timer = 0.0
				break

func _on_destroyed() -> void:
	# 分裂邏輯：處理前後連結
	if is_instance_valid(prev_segment):
		prev_segment.next_segment = null
		
	if is_instance_valid(next_segment) and not next_segment.is_queued_for_deletion():
		next_segment.prev_segment = null
		next_segment.become_head()
		
	queue_free()
