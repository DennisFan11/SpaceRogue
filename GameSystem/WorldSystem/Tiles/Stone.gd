extends BaseTileBlock
class_name StoneTile

## 64x64 岩石瓷磚

func _ready() -> void:
	super._ready()
	var rt = RadarTarget.new()
	rt.display_name = "石頭"
	add_child(rt)
