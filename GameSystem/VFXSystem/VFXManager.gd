extends Node2D
## VFX 管理器：負責處理全局視覺特效

@onready var damage_particles_scene: PackedScene = load("res://GameSystem/VFXSystem/DamageParticles.tscn")

func _ready() -> void:
	DI.register("_vfx_manager", self)

## 在指定位置播放受傷粒子
func play_damage_particles(global_pos: Vector2, color: Color, direction: Vector2 = Vector2.ZERO) -> void:
	var particles = damage_particles_scene.instantiate() as GPUParticles2D
	add_child(particles)
	
	particles.global_position = global_pos
	particles.modulate = color
	
	if direction != Vector2.ZERO:
		particles.rotation = direction.angle()
	
	# 粒子會自動在播放結束後 queue_free (見 DamageParticles.tscn 腳本)
