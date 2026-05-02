extends Node
class_name Damageable

signal health_changed(current_hp: float, max_hp: float)
signal destroyed()

## 陣營 ID。用以區分敵我，避免誤傷
@export var team_id: int = 0
@export var max_hp: float = 100.0

var current_hp: float

func _ready() -> void:
	current_hp = max_hp

## 承受傷害，需傳入來源陣營以判定 Friendly Fire
func take_damage(amount: float, source_team_id: int) -> void:
	if source_team_id == team_id:
		return # 忽略同陣營傷害
		
	if current_hp <= 0:
		return
		
	current_hp = max(0.0, current_hp - amount)
	health_changed.emit(current_hp, max_hp)
	
	if current_hp <= 0:
		destroyed.emit()

## 回復生命
func heal(amount: float) -> void:
	if current_hp <= 0 or current_hp >= max_hp:
		return
		
	current_hp = min(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)
