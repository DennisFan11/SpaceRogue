extends Node
class_name GameLoop

signal game_over(reason: String)

@onready var ship_manager: ShipManager = $ShipManager
@onready var player_manager: PlayerManager = $PlayerManager
@onready var ship_builder: ShipBuilder = $ShipBuilder
@onready var camera: Camera2D = $Camera2D
@onready var build_menu: BuildMenu = $CanvasLayer/BuildMenu

func _ready() -> void:
	# DI 會透過 node_added 信號自動注入新節點
	# GameLoop ready 後對整棵樹做一次遞歸重新注入，確保所有依賴就位
	await DI.injection(self, true)
	
	# 初始化通用的管理組件連接
	ship_builder.build_menu = build_menu
	build_menu.on_block_selected.connect(ship_builder.select_block)
	
	# 設定相機給 PlayerManager
	player_manager.main_camera = camera

func on_player_died() -> void:
	push_warning("Game Over: Player Died")
	game_over.emit("player_died")

func on_core_destroyed() -> void:
	push_warning("Game Over: Core Destroyed")
	game_over.emit("core_destroyed")
