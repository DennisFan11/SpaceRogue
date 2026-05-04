@tool
extends TilemapGenerator
class_name TextureGenerator

## 貼圖採樣生成器：將 Texture2D 自動縮放至整張地圖範圍進行採樣

@export_group("Texture")
## 採樣貼圖 (黑白遮罩，亮色 = 有瓷磚)
@export var mask_texture: Texture2D:
	set(v):
		mask_texture = v
		_mask_image = null # 清除快取
		preview_dirty.emit()

@export_group("Sampling")
## 採樣門檻 (0~1)，超過此值則視為有影響
@export var threshold: float = 0.5:
	set(v): threshold = v; preview_dirty.emit()

## 是否反向 (暗色 = 有瓷磚)
@export var invert: bool = false:
	set(v): invert = v; preview_dirty.emit()

# 快取
var _mask_image: Image
var _map_width: int = 0
var _map_height: int = 0

func _ready() -> void:
	super._ready()
	_fetch_map_size()

## 從父節點 TilemapManager 獲取地圖尺寸
func _fetch_map_size() -> void:
	var parent = get_parent()
	if parent is TilemapManager:
		_map_width = parent.map_width
		_map_height = parent.map_height

func samp(x: float, y: float) -> float:
	if not mask_texture: return 0.0

	# 延遲初始化快取
	if not _mask_image:
		_mask_image = mask_texture.get_image()
	if not _mask_image: return 0.0

	# 確保地圖尺寸有效
	if _map_width <= 0 or _map_height <= 0:
		_fetch_map_size()
	if _map_width <= 0 or _map_height <= 0: return 0.0

	# 將網格座標映射到貼圖 UV [0, 1]
	var u = x / float(_map_width)
	var v = y / float(_map_height)

	# 映射到像素座標
	var px = int(u * _mask_image.get_width())
	var py = int(v * _mask_image.get_height())

	# 限制在貼圖範圍內
	px = clampi(px, 0, _mask_image.get_width() - 1)
	py = clampi(py, 0, _mask_image.get_height() - 1)

	var value = _mask_image.get_pixel(px, py).r
	return 1.0 - value if invert else value

func get_influence(x: float, y: float) -> bool:
	return samp(x, y) > threshold
