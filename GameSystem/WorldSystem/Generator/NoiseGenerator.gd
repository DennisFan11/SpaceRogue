@tool
extends TilemapGenerator
class_name NoiseGenerator

## 基於 FastNoiseLite 的噪聲生成器

@export_group("Noise")
@export var noise: FastNoiseLite = FastNoiseLite.new():
	set(v):
		noise = v
		preview_dirty.emit()

@export_group("Sampling")
## 採樣門檻 (0~1)，超過此值則視為有影響
@export var threshold: float = 0.45:
	set(v): threshold = v; preview_dirty.emit()

## 採樣縮放 (影響圖案的密度)
@export var sampling_scale: Vector2 = Vector2(1.0, 1.0):
	set(v): sampling_scale = v; preview_dirty.emit()

## 採樣偏移
@export var sampling_offset: Vector2 = Vector2(0.0, 0.0):
	set(v): sampling_offset = v; preview_dirty.emit()

## 重複週期 (0 = 不重複)
## 若設為正整數，採樣座標將對此值取模，使地圖圖案可以無縫重複
@export var repeat: Vector2i = Vector2i(0, 0):
	set(v): repeat = v; preview_dirty.emit()

func _init() -> void:
	if not noise:
		noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.05

func samp(x: float, y: float) -> float:
	if not noise: return 0.0

	var sx = (x + sampling_offset.x) * sampling_scale.x
	var sy = (y + sampling_offset.y) * sampling_scale.y

	# 套用 repeat (循環採樣)
	if repeat.x > 0:
		sx = fmod(sx, float(repeat.x))
	if repeat.y > 0:
		sy = fmod(sy, float(repeat.y))

	# 將 [-1, 1] 映射到 [0, 1]
	return (noise.get_noise_2d(sx, sy) + 1.0) / 2.0

func get_influence(x: float, y: float) -> bool:
	return samp(x, y) > threshold
