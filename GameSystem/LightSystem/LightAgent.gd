extends Node2D
class_name LightAgent

@export var radius: float = 500.0

var _light_manager: LightManager
var _light_node: LightNode

func _on_injected() -> void:
	_light_node = _light_manager.create_light()
	_light_node.set_radius(radius)

func _process(_delta: float) -> void:
	if _light_node and is_instance_valid(_light_node):
		# 更新光源位置為 LightAgent 的全域位置
		_light_node.global_position = global_position

func set_radius(r: float) -> void:
	radius = r
	if _light_node:
		_light_node.set_radius(r)

func set_enabled(enabled: bool) -> void:
	set_process(enabled)
	if _light_node and is_instance_valid(_light_node):
		_light_node.visible = enabled
		
func _exit_tree() -> void:
	# 當 LightAgent 離開場景樹時，釋放關聯的光源
	if _light_node and is_instance_valid(_light_node):
		_light_node.queue_free()
