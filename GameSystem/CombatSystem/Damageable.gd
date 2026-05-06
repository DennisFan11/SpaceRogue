extends Node
class_name Damageable

signal health_changed(current_hp: float, max_hp: float)
signal destroyed()
signal hit(amount: float, source_position: Vector2)

## 陣營 ID。用以區分敵我，避免誤傷 (使用 Team 類定義的常量)
@export var team_id: int = Team.NEUTRAL
@export var max_hp: float = 100.0

var current_hp: float

func _ready() -> void:
	current_hp = max_hp

## 承受傷害，需傳入來源陣營以判定 Friendly Fire
func take_damage(amount: float, source_team_id: int, source_position: Vector2 = Vector2.ZERO) -> void:
	# 如果來源陣營與自身陣營相同，且不是中立陣營，則忽略傷害 (Friendly Fire Off)
	if source_team_id != Team.NEUTRAL and source_team_id == team_id:
		return
		
	if current_hp <= 0:
		return
		
	current_hp = max(0.0, current_hp - amount)
	health_changed.emit(current_hp, max_hp)
	hit.emit(amount, source_position)
	
	if current_hp <= 0:
		destroyed.emit()

## 回復生命
func heal(amount: float) -> void:
	if current_hp <= 0 or current_hp >= max_hp:
		return
		
	current_hp = min(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)
