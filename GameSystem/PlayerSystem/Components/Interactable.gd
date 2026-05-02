extends Area2D
class_name Interactable

signal interacted(interactor: Node)

@export var prompt_text: String = "[F] Interact"
var _label: Label = null

func _ready() -> void:
	collision_layer = BitmaskManager.LAYER_INTERACTABLE
	collision_mask = 0
	
	# 動態建立碰撞形狀
	var shape_node = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 100.0 # 預設互動半徑
	shape_node.shape = circle
	add_child(shape_node)
	
	# 動態建立 Label 顯示提示
	_label = Label.new()
	_label.text = prompt_text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.visible = false
	# 稍微往上移避免擋住主角
	_label.position = Vector2(-50, -60)
	_label.custom_minimum_size = Vector2(100, 20)
	add_child(_label)

func show_prompt() -> void:
	if _label:
		_label.visible = true

func hide_prompt() -> void:
	if _label:
		_label.visible = false

func trigger_interaction(interactor: Node) -> void:
	interacted.emit(interactor)
