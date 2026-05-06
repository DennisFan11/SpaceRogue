extends BlockBase

@export var damage_per_second: float = 1000.0
@onready var drill_area: Area2D = $Visual/DrillArea

var _damage_timer: float = 0.0
const DAMAGE_INTERVAL: float = 0.01

func _physics_process(delta: float) -> void:
	# 只有在已建造狀態才發揮作用
	if state_machine.current_state != BlockStateMachine.State.BUILT:
		return
		
	_damage_timer += delta
	if _damage_timer >= DAMAGE_INTERVAL:
		_damage_timer = 0.0
		_apply_drill_damage()

func _apply_drill_damage() -> void:
	var damage_amount = damage_per_second * DAMAGE_INTERVAL
	var source_pos = drill_area.global_position
	
	# 處理物理實體 (TileBlocks, Ships)
	var bodies = drill_area.get_overlapping_bodies()
	for body in bodies:
		if body == get_parent().get_parent(): # 排除自己的飛船 (RigidBody2D)
			continue
			
		if body.has_method("damage"):
			body.damage(damage_amount, Team.PLAYER, source_pos)
		elif body.has_node("Damageable"):
			body.get_node("Damageable").take_damage(damage_amount, source_pos)

	# 處理區域 (其他 Damageable 組件)
	var areas = drill_area.get_overlapping_areas()
	for area in areas:
		if area == damageable: continue # 排除自己
		
		var parent = area.get_parent()
		if parent == self: continue
		
		if area is Damageable:
			area.take_damage(damage_amount, source_pos)
		elif parent.has_node("Damageable"):
			parent.get_node("Damageable").take_damage(damage_amount, source_pos)
