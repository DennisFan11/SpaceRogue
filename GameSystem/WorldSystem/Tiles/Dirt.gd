extends BaseTileBlock
class_name DirtTile

## 64x64 泥土瓷磚

func _ready() -> void:
	super._ready()
	var rt = RadarTarget.new()
	rt.display_name = "泥土"
	add_child(rt)
