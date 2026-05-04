extends RefCounted
class_name Team

## 陣營 ID 定義 (靜態類)

const NEUTRAL = 0
const PLAYER = 1
const ENEMY = 2
const PIRATE = 3

## 輔助方法：判斷兩者是否為敵對
static func is_hostile(id_a: int, id_b: int) -> bool:
	if id_a == NEUTRAL or id_b == NEUTRAL:
		return false # 中立陣營不主動敵對
	return id_a != id_b
