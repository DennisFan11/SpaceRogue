extends GPUParticles2D

func _ready() -> void:
	finished.connect(queue_free)
	# emitting 由 VFXManager 設定位置後手動啟動
