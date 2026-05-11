extends "res://GameSystem/ShipSystem/Blocks/RadarBlock/RadarBlock.gd"

## 追擊雷達方塊：有標記敵人時，會改為主動往最近標記掃描來回 10度

@export var pursuit_sweep_angle: float = 20.0 # 掃描總角度 (度)
@export var sweep_speed: float = 3.0 # 掃描擺動速度

var _sweep_time: float = 0.0
var _last_target_position: Vector2 = Vector2.ZERO
var _lost_target_timer: float = 0.0

func _ready() -> void:
	super._ready()
	# 隨機初始擺動時間，避免多個追擊雷達同步擺動
	_sweep_time = randf_range(0, TAU)

func _process(delta: float) -> void:
	if state_machine.current_state != BlockStateMachine.State.BUILT:
		return
		
	# 定期更新雷達數量與索引 (降低開銷，與父類別同步)
	_update_timer += delta
	if _update_timer >= 1.0 and _group_name != "":
		_update_timer = 0.0
		var radars = get_tree().get_nodes_in_group(_group_name)
		_radar_count = radars.size()
		_radar_index = radars.find(self)
		
	var target = null
	if _ray_manager:
		target = _ray_manager.get_nearest_tagged_enemy(global_position)
		
	var ray_color = Color.GREEN
	
	if target and is_instance_valid(target):
		_last_target_position = target.global_position
		_lost_target_timer = 5.0 # 記憶 5 秒
		
	if _lost_target_timer > 0.0:
		# 有目標或在記憶時間內，主動往目標方向掃描來回
		var dir_to_target = (_last_target_position - global_position).normalized()
		var target_angle = dir_to_target.angle()
		
		_sweep_time += delta * sweep_speed
		var offset = sin(_sweep_time) * deg_to_rad(pursuit_sweep_angle / 2.0)
		
		rotation = lerp_angle(rotation, target_angle + offset, 0.1)
		ray_color = Color.RED
		
		if not (target and is_instance_valid(target)):
			_lost_target_timer -= delta
	else:
		# 沒目標且過期，回到一般雷達行為 (360度旋轉，完美均分)
		var current_time = Time.get_ticks_msec() / 1000.0
		var base_angle = current_time * rotation_speed
		var step = TAU / _radar_count
		
		rotation = base_angle + _radar_index * step
		
	# 發射射線 (頻率控制，繼承自父類別)
	_fire_timer += delta
	if _fire_timer >= fire_interval:
		_fire_timer = 0.0
		var direction = Vector2.RIGHT.rotated(rotation)
		_ray_manager.fire_radar_ray(self, global_position, direction, ray_length, ray_color)
