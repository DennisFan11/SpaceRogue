extends Resource
class_name ResourceType

## 定義遊戲中基礎資源種類 (例如：Metal, Energy)
@export var id: String = ""
@export var display_name: String = ""
@export var icon: Texture2D

## 資源掉落時對應的物理場景 (應為 BaseResourceItem 的繼承場景)
@export var world_scene: PackedScene
