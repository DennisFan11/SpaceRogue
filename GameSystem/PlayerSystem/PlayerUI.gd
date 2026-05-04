extends CanvasLayer

@onready var fps_label: Label = $Control/FPSLabel

func _process(_delta: float) -> void:
	# 每幀獲取 FPS 並更新文字
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
