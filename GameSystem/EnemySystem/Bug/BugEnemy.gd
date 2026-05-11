extends CharacterBody2D
class_name BugEnemy

## 小蟲族：使用轉向行為移動，觸碰傷害 (不對地形造成傷害)

@export var speed: float = 150.0
@export var max_force: float = 5.0
@export var damage_amount: float = 10.0
@export var damage_interval: float = 0.5

var _player_manager: PlayerManager # DI 注入
var _enemy_manager: EnemyManager # DI 注入
var _combat_manager: CombatManager # DI 注入
var _damage_timer: float = 0.0

@onready var damageable: Damageable = $Damageable

func _ready() -> void:
	collision_layer = BitmaskManager.LAYER_ENEMY
	# 碰撞遮罩：玩家、飛船、牆體 (地形)
	collision_mask = BitmaskManager.LAYER_PLAYER | BitmaskManager.LAYER_SHIP | BitmaskManager.LAYER_WALL
	
	if damageable:
		damageable.destroyed.connect(_on_destroyed)
		
	var rt = RadarTarget.new()
	rt.display_name = "小蟲族"
	add_child(rt)

func _physics_process(delta: float) -> void:
	var target_pos = _get_target_position()
	_move_towards(target_pos, delta)
	_handle_contact_damage(delta)

func _get_target_position() -> Vector2:
	if _combat_manager:
		return _combat_manager.get_target_position()
	return Vector2.ZERO

func _move_towards(target_pos: Vector2, delta: float) -> void:
	var desired_velocity = (target_pos - global_position).normalized() * speed
	var steering = (desired_velocity - velocity) * max_force * delta
	velocity += steering
	velocity = velocity.limit_length(speed)
	
	if velocity.length_squared() > 1.0:
		rotation = velocity.angle()
		
	# 沒有重力，直接移動
	move_and_slide()

func _handle_contact_damage(delta: float) -> void:
	_damage_timer += delta
	if _damage_timer < damage_interval:
		return
		
	# 檢查碰撞
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		var point = collision.get_position()
		
		if _apply_damage(collider, point):
			_damage_timer = 0.0
			break # 每次間隔只造成一次傷害

func _apply_damage(collider: Object, point: Vector2) -> bool:
	if _combat_manager:
		return _combat_manager.apply_damage(collider, point, damage_amount, Team.NEUTRAL)
	return false
func _on_destroyed() -> void:
	# TODO: 播放爆炸特效
	queue_free()
