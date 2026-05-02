extends RefCounted
class_name BitmaskManager

## 集中管理所有碰撞層與遮罩 (靜態類別)

const LAYER_PLAYER: int = 1
const LAYER_SHIP: int = 2
const LAYER_PROJECTILE: int = 4
const LAYER_WALL: int = 8
const LAYER_INTERACTABLE: int = 16

## 將多個層級組合成一個 Mask
static func create_mask(layers: Array[int]) -> int:
	var mask = 0
	for layer in layers:
		mask |= layer
	return mask
