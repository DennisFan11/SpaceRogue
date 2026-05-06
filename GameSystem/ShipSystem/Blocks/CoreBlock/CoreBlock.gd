extends BlockBase
class_name CoreBlock

@onready var builder: Builder = $Builder
@onready var inventory: Inventory = $Inventory

var _player_manager: PlayerManager

func _ready() -> void:
	if has_node("Interactable"):
		$Interactable.interacted.connect(_on_interacted)
	
	if damageable:
		damageable.destroyed.connect(_on_damageable_destroyed)
	
	# 不呼叫 super._ready() 中的 BUILT 自動切換
	# CoreBlock 由外部明確呼叫

func _on_interacted(interactor: Node) -> void:
	_player_manager.enter_core(self)
	rotation_degrees = rotation_degrees_snap

func _on_damageable_destroyed() -> void:
	state_machine.transition_to(BlockStateMachine.State.DESTROYED)
	# 通知 GameLoop
	var game_loop = _find_game_loop()
	if game_loop and game_loop.has_method("on_core_destroyed"):
		game_loop.on_core_destroyed()

func _find_game_loop() -> Node:
	var node = get_tree().current_scene
	return node if node is GameLoop else null
