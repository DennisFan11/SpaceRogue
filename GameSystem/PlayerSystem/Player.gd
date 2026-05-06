extends CharacterBody2D
class_name Player

@export var move_speed: float = 300.0

var current_equipment: BaseEquipment = null

@onready var equipment_anchor: Node2D = $EquipmentAnchor
@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	collision_layer = BitmaskManager.LAYER_PLAYER
	collision_mask = BitmaskManager.LAYER_WALL
	
	# 如果 PlayerManager 有暫存的裝備，在這裡重新掛載 (這部分由 PlayerManager 處理，或由 Player 初始化)

func _physics_process(_delta: float) -> void:
	_handle_movement()
	_handle_equipment_input()

func _handle_movement() -> void:
	var vec = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W): vec.y -= 1
	if Input.is_physical_key_pressed(KEY_S): vec.y += 1
	if Input.is_physical_key_pressed(KEY_A): vec.x -= 1
	if Input.is_physical_key_pressed(KEY_D): vec.x += 1
	
	if vec.length_squared() > 1.0:
		vec = vec.normalized()
		
	velocity = vec * move_speed
	move_and_slide()

func _handle_equipment_input() -> void:
	# 丟下 (Q)
	if Input.is_key_pressed(KEY_Q): # 暫時用 KEY_Q，最好用 Input Map
		if current_equipment:
			_drop_equipment()
	
	# 使用 (滑鼠左鍵)
	if current_equipment:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			current_equipment.use_start()
		else:
			current_equipment.use_stop()


func pick_up_equipment(equip: BaseEquipment) -> void:
	current_equipment = equip
	# Reparent
	if equip.get_parent():
		equip.get_parent().remove_child(equip)
	equipment_anchor.add_child(equip)
	equip.pick_up(self)

func _drop_equipment() -> void:
	var equip = current_equipment
	current_equipment = null
	
	# Unparent
	equipment_anchor.remove_child(equip)
	get_tree().current_scene.add_child(equip)
	
	# 計算丟出的衝量
	var drop_dir = (get_global_mouse_position() - global_position).normalized()
	equip.global_position = equipment_anchor.global_position
	equip.drop(drop_dir * 300.0)
