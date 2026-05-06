extends Resource
class_name ResourceType

## 定義遊戲中基礎資源種類 (例如：Metal, Energy)
@export var type: ResourceDB.Type
@export var id: String = ""
@export var display_name: String = ""
@export var icon: Texture2D ## UI 圖示
@export var world_icon: Texture2D ## 世界實體圖示 (若不設定則使用 UI 圖示)

## 資源掉落時對應的物理場景 (應為 BaseResourceItem 的繼承場景)
@export var world_scene: PackedScene
