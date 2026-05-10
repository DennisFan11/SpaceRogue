extends Area2D
class_name Bullet

## 子彈：飛行並碰撞目標後呼叫 CombatManager 施加傷害

@export var speed: float = 500.0
@export var max_range: float = 600.0
@export var damage: float = 50.0
@export var team: int = Team.PLAYER

var _direction: Vector2 = Vector2.DOWN
var _traveled: float = 0.0
var _combat_manager: CombatManager # DI 注入

@onready var visual: Node2D = $Visual

func setup(dir: Vector2, dmg: float, source_team: int) -> void:
	_direction = dir.normalized()
	damage = dmg
	team = source_team
	rotation = _direction.angle() + PI / 2.0

func _ready() -> void:
	# 偵測敵人和地形，不碰飛船
	collision_layer = 0
	collision_mask = BitmaskManager.LAYER_ENEMY | BitmaskManager.LAYER_WALL
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	var move = _direction * speed * delta
	global_position += move
	_traveled += move.length()
	if _traveled >= max_range:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# 如果是地形，只產生碰撞(爆炸)，不造成傷害(不主動攻擊)
	if body.collision_layer & BitmaskManager.LAYER_WALL:
		_explode()
		return
		
	if _combat_manager:
		_combat_manager.apply_damage(body, global_position, damage, team)
	_explode()

func _on_area_entered(area: Area2D) -> void:
	# Area2D 本身不會是 Damageable (Damageable extends Node)
	# 改為嘗試從父節點取得 Damageable
	var parent = area.get_parent()
	if parent and _combat_manager:
		if _combat_manager.apply_damage(parent, global_position, damage, team):
			_explode()

func _explode() -> void:
	queue_free()
