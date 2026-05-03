extends Node
class_name BuildTool

var builder: ShipBuilder

func _init(p_builder: ShipBuilder) -> void:
	builder = p_builder

func on_activated() -> void:
	pass

func on_deactivated() -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	pass
