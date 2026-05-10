extends Node2D
class_name RangeIndicator

## 範圍提示元件：用於顯示武器射程、推進力道與旋轉範圍
## 以白邊的半透明扇形 (或圓形) 顯示

@export var radius: float = 100.0
@export var angle_degrees: float = 360.0
@export var direction: Vector2 = Vector2.DOWN # 預設朝下 (武器方向)
@export var segments: int = 32
@export var category: String = "weapon"

var _hint_range_manager: HintRangeManager # DI 注入

func _ready() -> void:
	# 直接信任 DI 系統
	_hint_range_manager.register_indicator(self)

func _exit_tree() -> void:
	if _hint_range_manager:
		_hint_range_manager.unregister_indicator(self)

## 供 HintRangeManager 呼叫以取得當前幀的世界座標頂點
func get_global_points() -> Dictionary:
	var should_show = false
	
	if DebugSetting.force_show_range_indicators:
		should_show = true
	elif BuildMenu.is_menu_open:
		should_show = true
	else:
		var parent = get_parent()
		if parent is BlockBase:
			if parent.state_machine.current_state == BlockStateMachine.State.BLUEPRINT:
				should_show = true
				
	if not should_show:
		return {}
		
	var is_full_circle = angle_degrees >= 360.0
	var local_points = _get_sector_points()
	var global_fill_points = PackedVector2Array()
	for p in local_points:
		global_fill_points.append(to_global(p))
		
	var global_border_points = global_fill_points.duplicate()
	if is_full_circle:
		if global_fill_points.size() > 0:
			global_border_points.append(global_fill_points[0]) # 閉合圓形
	else:
		global_border_points.append(to_global(Vector2.ZERO)) # 閉合扇形到圓心
		
	return {
		"fill": global_fill_points,
		"border": global_border_points,
		"category": category
	}

func _get_sector_points() -> PackedVector2Array:
	var points = PackedVector2Array()
	var is_full_circle = angle_degrees >= 360.0
	
	if not is_full_circle:
		points.append(Vector2.ZERO)
	
	var base_angle = direction.angle()
	var half_angle = deg_to_rad(angle_degrees) / 2.0
	var angle_step = (half_angle * 2.0) / segments
	
	var steps = segments if is_full_circle else segments + 1
	for i in range(steps):
		var current_angle = base_angle - half_angle + i * angle_step
		points.append(Vector2(cos(current_angle), sin(current_angle)) * radius)
		
	return points
