extends Node2D
class_name LightManager

const LIGHT_NODE_SCENE = preload("res://GameSystem/LightSystem/LightNode.tscn")

@onready var _canvas_group: CanvasGroup = $CanvasGroup

func _ready() -> void:
	DI.register("_light_manager", self)

## 建立並返回一個 LightNode 實例
func create_light() -> LightNode:
	var light = LIGHT_NODE_SCENE.instantiate() as LightNode
	_canvas_group.add_child(light)
	return light
