extends Node2D
class_name CombatManager

## 集中管理戰鬥邏輯，如傷害判定與目標獲取

var _player_manager: PlayerManager

func _ready() -> void:
	DI.register("_combat_manager", self)

func _on_injected() -> void:
	pass

## 獲取敵人目標位置 (玩家或玩家飛船)
func get_target_position() -> Vector2:
	if _player_manager:
		if _player_manager.is_piloting and _player_manager.current_piloted_core:
			return _player_manager.current_piloted_core.global_position
		elif _player_manager.current_player_instance:
			return _player_manager.current_player_instance.global_position
	return Vector2.ZERO

## 對目標施加傷害 (封裝玩家、飛船與敵人的傷害邏輯)
func apply_damage(collider: Object, point: Vector2, amount: float, team: int = Team.NEUTRAL) -> bool:
	if not collider:
		return false
		
	# 處理有自帶 damage 方法的對象 (舊有系統相容或特殊處理)
	if collider.has_method("damage"):
		collider.damage(amount, team, point)
		return true
		
	# 處理帶有 Damageable 組件的對象 (如 Enemy, Player)
	if collider.has_node("Damageable"):
		var dmg = collider.get_node("Damageable")
		if dmg and dmg is Damageable:
			dmg.take_damage(amount, team, point)
			return true
			
	# 處理本身就是 Damageable 的對象
	if collider is Damageable:
		collider.take_damage(amount, team, point)
		return true

	# 處理飛船 (飛船是由 RigidBody2D 作為碰撞體，內部包含多個方塊)
	if collider is RigidBody2D:
		var parent = collider.get_parent()
		if parent is Ship:
			var block = parent.get_block_at_global_pos(point)
			if block and block.damageable:
				block.damageable.take_damage(amount, team, point)
				return true

	return false
