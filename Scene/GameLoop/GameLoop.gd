extends Node
class_name GameLoop

signal game_over(reason: String)

func _ready() -> void:
	# DI 會透過 node_added 信號自動注入新節點
	# GameLoop ready 後對整棵樹做一次遞歸重新注入，確保所有依賴就位
	await DI.injection(self, true)

func on_player_died() -> void:
	push_warning("Game Over: Player Died")
	game_over.emit("player_died")

func on_core_destroyed() -> void:
	push_warning("Game Over: Core Destroyed")
	game_over.emit("core_destroyed")
