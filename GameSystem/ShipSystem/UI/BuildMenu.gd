extends Control
class_name BuildMenu

signal on_block_selected(block_id: String)

@onready var resource_display: RichTextLabel = $ResourcePanel/ResourceDisplay
@onready var grid_container: GridContainer = $Panel/GridContainer

## DI 自動注入
var current_core: CoreBlock = null

func _ready() -> void:
	visible = false

func toggle_ui(is_visible: bool) -> void:
	visible = is_visible
	if is_visible:
		_populate_block_buttons()

func _process(_delta: float) -> void:
	if visible and current_core and current_core.inventory:
		var text := ""
		for key in current_core.inventory.resources_set.resources.keys():
			var amount = current_core.inventory.resources_set.resources[key]
			text += "%s: %d\n" % [key, amount]
		resource_display.text = text if text != "" else "(無資源)"

## 動態產生方塊按鈕
func _populate_block_buttons() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	for block_id in ShipBlockDB.get_buildable_ids():
		var btn := Button.new()
		btn.text = ShipBlockDB.get_display_name(block_id)
		btn.custom_minimum_size = Vector2(60, 60)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_block_button_pressed.bind(block_id))
		grid_container.add_child(btn)

func _on_block_button_pressed(id: String) -> void:
	on_block_selected.emit(id)
