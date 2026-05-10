extends Node2D
class_name BulletManager

## 管理所有子彈的生命週期與發射

var _combat_manager: CombatManager # DI 注入

func _ready() -> void:
	DI.register("_bullet_manager", self)

func _on_injected() -> void:
	pass

## 發射一顆子彈
## bullet_id: BulletDB 中的 ID
## pos: 發射位置 (global)
## dir: 飛行方向 (不需要 normalized，函式內部會 normalize)
## team: 陣營 (Team.PLAYER / Team.ENEMY / etc.)
## damage: 傷害值
func fire(bullet_id: String, pos: Vector2, dir: Vector2, team: int, damage: float) -> void:
	var scene = BulletDB.get_bullet_scene(bullet_id)
	if not scene:
		push_warning("[BulletManager] 找不到子彈 ID: %s" % bullet_id)
		return

	var bullet = scene.instantiate() as Bullet
	if not bullet:
		return

	add_child(bullet)
	bullet.global_position = pos
	bullet.setup(dir, damage, team)
	
	# 注入 CombatManager
	if _combat_manager:
		bullet._combat_manager = _combat_manager
