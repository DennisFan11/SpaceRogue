extends Node2D
## VFX 管理器：負責處理全局視覺特效

@onready var damage_particles_scene: PackedScene = load("res://GameSystem/VFXSystem/DamageParticles.tscn")
@onready var smoke_particles_scene: PackedScene = load("res://GameSystem/VFXSystem/SmokeParticles.tscn")

var vfx_container: CanvasGroup
var direct_container: Node2D

func _ready() -> void:
	DI.register("_vfx_manager", self)
	
	# 建立一般容器 (非 Metaball)
	direct_container = Node2D.new()
	add_child(direct_container)
	
	# 建立 CanvasGroup 用於 Metaball 效果 (煙霧)
	vfx_container = CanvasGroup.new()
	add_child(vfx_container)
	
	# 套用 Metaball Shader
	var mat = ShaderMaterial.new()
	mat.shader = load("res://GameSystem/VFXSystem/Metaball.gdshader")
	vfx_container.material = mat


## 在指定位置播放受傷粒子
func play_damage_particles(global_pos: Vector2, color: Color, direction: Vector2 = Vector2.ZERO) -> void:
	var particles = damage_particles_scene.instantiate() as GPUParticles2D
	direct_container.add_child(particles)
	
	particles.position = direct_container.to_local(global_pos)
	particles.modulate = color
	
	if direction != Vector2.ZERO:
		particles.rotation = direction.angle()
	
	particles.emitting = true

## 在指定位置播放煙霧粒子 (推進器噴射)
func play_thruster_smoke(global_pos: Vector2, direction: Vector2, power: float) -> void:
	var particles = smoke_particles_scene.instantiate() as GPUParticles2D
	
	# 先設定生命時間，避免加入場景樹後修改造成閃爍/重置
	particles.lifetime = clamp(power / 200.0, 0.2, 2.0)
	particles.rotation = direction.angle()
	
	# 將粒子加入容器
	vfx_container.add_child(particles)
	# 加入後再設定位置
	particles.position = vfx_container.to_local(global_pos)
	particles.emitting = true
