extends BlockBase
class_name RadarBlock

## 雷達方塊：360度持續發出射線掃描

@export var rotation_speed: float = 1.0 # 旋轉速度 (弧度/秒)
@export var ray_length: float = 3000.0
@export var fire_interval: float = 0.1 # 發射間隔 (秒)

var _ray_manager: RayManager # DI 注入

var _radar_index: int = 0
var _radar_count: int = 1
var _update_timer: float = 1.0 # 初始為 1.0 確保立刻更新一次
var _fire_timer: float = 0.0
var _group_name: String = ""

func _ready() -> void:
	super._ready()
	var ship = get_parent().get_parent()
	if ship:
		_group_name = "radars_" + str(ship.get_instance_id())
		add_to_group(_group_name)

func _process(delta: float) -> void:
	if state_machine.current_state != BlockStateMachine.State.BUILT:
		return
		
	# 定期更新雷達數量與索引 (降低開銷)
	_update_timer += delta
	if _update_timer >= 1.0 and _group_name != "":
		_update_timer = 0.0
		var radars = get_tree().get_nodes_in_group(_group_name)
		_radar_count = radars.size()
		_radar_index = radars.find(self)
		
	# 基於時間與索引計算角度，確保完美平均分配與同步旋轉
	var current_time = Time.get_ticks_msec() / 1000.0
	var base_angle = current_time * rotation_speed
	var step = TAU / _radar_count
	
	rotation = base_angle + _radar_index * step
	
	# 發射射線 (頻率控制)
	_fire_timer += delta
	if _fire_timer >= fire_interval:
		_fire_timer = 0.0
		var direction = Vector2.RIGHT.rotated(rotation)
		_ray_manager.fire_radar_ray(self, global_position, direction, ray_length)
