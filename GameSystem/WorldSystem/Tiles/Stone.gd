extends BaseTileBlock
class_name StoneTile

## 基於 TilemapManager.BLOCK_SIZE 大小的岩石瓷磚

func _ready() -> void:
	super._ready()
	var rt = RadarTarget.new()
	rt.display_name = "石頭"
	add_child(rt)
