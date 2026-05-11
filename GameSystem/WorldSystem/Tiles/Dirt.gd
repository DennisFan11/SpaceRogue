extends BaseTileBlock
class_name DirtTile

## 基於 TilemapManager.BLOCK_SIZE 大小的泥土瓷磚

func _ready() -> void:
	super._ready()
	var rt = RadarTarget.new()
	rt.display_name = "泥土"
	add_child(rt)
