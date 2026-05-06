extends Node
class_name ShipInput

var _player_manager: PlayerManager

## 取得移動輸入 (WASD 平移)
func get_movement_vector() -> Vector2:
	if not _player_manager.is_piloting: return Vector2.ZERO
	
	var vec = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W): vec.y -= 1
	if Input.is_physical_key_pressed(KEY_S): vec.y += 1
	if Input.is_physical_key_pressed(KEY_A): vec.x -= 1
	if Input.is_physical_key_pressed(KEY_D): vec.x += 1
	
	if vec.length_squared() > 1.0:
		vec = vec.normalized()
	return vec

## 取得轉向輸入 (QE 旋轉)
func get_rotation_input() -> float:
	if not _player_manager.is_piloting: return 0.0
	
	var rot = 0.0
	if Input.is_physical_key_pressed(KEY_Q): rot -= 1.0
	if Input.is_physical_key_pressed(KEY_E): rot += 1.0
	return rot

## 是否自動煞車
func should_auto_brake() -> bool:
	return true
