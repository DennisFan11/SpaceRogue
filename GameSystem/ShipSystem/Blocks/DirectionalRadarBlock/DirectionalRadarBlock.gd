extends BlockBase

## 指向性雷達方塊：來回掃描前方45度

@export var sweep_angle: float = 15.0 # 總掃描角度 (度)
@export var sweep_speed: float = 5.0 # 擺動速度
@export var ray_length: float = 3000.0
@export var fire_interval: float = 0.05

var _ray_manager: RayManager # DI 注入
var _fire_timer: float = 0.0
var _sweep_time: float = 0.0
var _base_rotation: float = 0.0

func _ready() -> void:
	super._ready()
	_base_rotation = rotation
	# 隨機初始時間，避免多個同步
	_sweep_time = randf_range(0, TAU)

func _process(delta: float) -> void:
	if state_machine.current_state != BlockStateMachine.State.BUILT:
		return
		
	_sweep_time += delta * sweep_speed
	var offset = sin(_sweep_time) * deg_to_rad(sweep_angle / 2.0)
	rotation = _base_rotation + offset
	
	# 發射射線 (頻率控制)
	_fire_timer += delta
	if _fire_timer >= fire_interval:
		_fire_timer = 0.0
		var direction = Vector2.DOWN.rotated(global_rotation)
		if _ray_manager:
			_ray_manager.fire_radar_ray(self, global_position, direction, ray_length, Color.GREEN, true, true)
