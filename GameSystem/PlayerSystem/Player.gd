extends CharacterBody2D
class_name Player

@export var move_speed: float = 300.0

func _ready() -> void:
	collision_layer = BitmaskManager.LAYER_PLAYER
	# 玩家不與飛船 (LAYER_SHIP) 發生物理碰撞
	collision_mask = BitmaskManager.LAYER_WALL

func _physics_process(_delta: float) -> void:
	var vec = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W): vec.y -= 1
	if Input.is_physical_key_pressed(KEY_S): vec.y += 1
	if Input.is_physical_key_pressed(KEY_A): vec.x -= 1
	if Input.is_physical_key_pressed(KEY_D): vec.x += 1
	
	if vec.length_squared() > 1.0:
		vec = vec.normalized()
		
	velocity = vec * move_speed
	move_and_slide()
