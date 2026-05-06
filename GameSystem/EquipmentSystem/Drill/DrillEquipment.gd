extends BaseEquipment
class_name DrillEquipment

## 鑽頭裝備：用於挖掘與戰鬥

@export var damage_per_second: float = 50.0
@export var damage_interval: float = 0.1 # 傷害頻率

@onready var ray_cast: RayCast2D = $RayCast2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_using: bool = false
var damage_timer: float = 0.0

func _ready() -> void:
	equipment_id = "Drill"
	super._ready()
	# 設定 RayCast2D 偵測牆壁與敵人
	ray_cast.enabled = true
	ray_cast.collision_mask = BitmaskManager.LAYER_WALL | BitmaskManager.LAYER_SHIP | BitmaskManager.LAYER_INTERACTABLE

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if current_state == State.HELD and is_using:
		_process_drilling(delta)

func use_start() -> void:
	is_using = true
	if animation_player:
		animation_player.play("drill_active")

func use_stop() -> void:
	is_using = false
	if animation_player:
		animation_player.play("RESET")

func _process_drilling(delta: float) -> void:
	damage_timer += delta
	if damage_timer >= damage_interval:
		damage_timer = 0.0
		_apply_drill_damage()

func _apply_drill_damage() -> void:
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		if collider:
			# 嘗試尋找 Damageable 組件或 damage 方法
			if collider.has_method("damage"):
				collider.damage(damage_per_second * damage_interval)
			elif collider.has_node("Damageable"):
				collider.get_node("Damageable").take_damage(damage_per_second * damage_interval, Team.NEUTRAL)
			elif collider is Damageable:
				collider.take_damage(damage_per_second * damage_interval, Team.NEUTRAL)
