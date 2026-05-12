---
name: godot-project-rules
description: Godot 4 / GDScript 開發規範。撰寫任何遊戲邏輯、系統架構、場景腳本、管理器、資料庫類別、組件、或生成工具時務必使用此 skill。涵蓋：DI 依賴注入系統、GameLoop 生命週期、DB/Manager 分離模式、SpawnerTool 模式、組件化設計模式，以及全域禁止規則（autoload、z-index、空值防護）。
---

# Godot 4 開發規範

## ⛔ 全域禁止規則（最高優先）

| 禁止項目 | 原因 |
|----------|------|
| `autoload` | 一律使用 DI 系統取代 |
| `z_index` / `z_as_relative` | 禁止使用 |
| **任何形式的空值防護** | 應讓程式直接報錯，不靜默吞掉問題（見第 2 節） |
| 宣告時賦予 `= null` | `var _mgr: MyManager`，不寫 `= null` |
| 在 `DI.gd` 內增加或修改功能 | DI 是基礎設施，不可擴充 |
| 用程式碼實例化 DI 單例 | 僅允許 `GameLoop.tscn` 實例化 |
| 在 `_ready()` 中撰寫依賴其他系統的初始化邏輯 | 改寫在 `_game_start()` |

---

## 🚫 禁止空值防護（獨立大原則）

**任何情況下都不寫空值防護**，不論是 DI 注入、節點查找、字典取值、還是函式回傳值。

```gdscript
# ❌ 全部禁止
if node == null: return
if not _manager: return
var x = dict.get("key", null)
if x:
    x.do_something()
var child = get_node_or_null("Child")
if child:
    child.call()

# ✅ 正確——直接使用，讓錯誤報出來
_manager.do_something()
var x = dict["key"]
x.do_something()
get_node("Child").call()
```

> **為什麼**：空值防護會把 bug 藏起來，導致難以追蹤的沉默錯誤。讓程式崩潰才能立刻定位問題。

---

## 1. 依賴注入系統（DI）

**核心文件**：`_Libs/DI.gd`

DI 系統在根節點 `_ready()` 完成後，遞歸注入整棵場景樹。節點可實作 `_on_injected()` 回調執行注入後初始化。

### 正確宣告方式
```gdscript
# ✅ 正確
var _player_manager: PlayerManager
var _enemy_manager: EnemyManager

# ❌ 錯誤
var _player_manager: PlayerManager = null
```

### 注入回調
```gdscript
func _on_injected() -> void:
    # 此時所有 DI 變數均已注入，可安全使用
    _player_manager.connect("player_died", _on_player_died)
```

---

## 2. GameLoop 生命週期

**核心腳本**：`GameLoop.gd`
**核心場景**：`GameLoop.tscn`——所有 DI 單例皆作為子節點掛載於此場景內

子關卡與地圖一律透過**場景繼承 `GameLoop.tscn`** 來製作，不另起空場景再手動掛載單例。

### 三階段流程

```
_ready()          → 節點創建，向 DI 系統自我註冊
DI.injection()    → GameLoop 遞歸注入全樹，完成交叉綁定
_game_start()     → GameLoop 遞歸廣播；初始化邏輯、生成邏輯寫這裡
```

### `_on_injected()` vs `_game_start()`

- `_on_injected()`：該節點自身的依賴注入完成時觸發，但**不保證其他節點也已完成注入**。Manager 不應在此做跨系統操作。
- `_game_start()`：全樹注入完畢後才廣播，所有系統均可安全使用。**Manager 的初始化邏輯一律寫在這裡。**

### 實作範本
```gdscript
class_name EnemyManager extends Node2D

var _dungeon_generator: DungeonGenerator  # DI 注入，不寫 = null

func _game_start() -> void:
    # 全樹注入完畢，可安全跨系統操作
    _setup_initial_enemies()
```

---

## 3. DB & Manager 分離模式

### 資料庫（DB）
- **繼承**：`RefCounted`（不上樹）
- **宣告**：`class_name`、使用 `static` 變數與方法
- **初始化**：直接在 `static var` 宣告時賦值，用 `preload` 硬編碼綁定場景，**不使用 `_static_init()`**

```gdscript
class_name EnemyDB extends RefCounted

static var _scenes: Dictionary = {
    "slime": preload("res://Enemies/Slime/Slime.tscn"),
    "goblin": preload("res://Enemies/Goblin/Goblin.tscn"),
}

static func get_scene(enemy_id: String) -> PackedScene:
    return _scenes[enemy_id]  # 不做空值防護，直接信任 key 存在
```

### 管理器（Manager）
- **繼承**：`Node2D` 或 `Node`
- **掛載**：作為子節點存在於 `GameLoop.tscn` 內（場景繼承後自動帶入）
- **職責**：動態生成實例、管理節點生命週期、處理系統事件

```gdscript
class_name EnemyManager extends Node2D

func spawn_enemy(enemy_id: String, pos: Vector2) -> Node2D:
    var scene := EnemyDB.get_scene(enemy_id)
    var instance := scene.instantiate() as Node2D
    instance.global_position = pos
    get_parent().add_child(instance)  # 掛載至 MapNode
    return instance
```

---

## 4. SpawnerTool 模式

用於在 Editor 佈置關卡，Runtime 轉交 Manager 生成真實實體。

### 標準流程
1. 關卡設計師在 Editor 將 `XxxSpawnerTool` 放置於指定位置
2. 遊戲啟動後 DI 注入對應 Manager
3. `_game_start()` 觸發：呼叫 Manager 在 `global_position` 生成實體
4. 呼叫 `queue_free()` 刪除佔位用 Tool 節點

### 範本
```gdscript
class_name EnemySpawnerTool extends Node2D

@export var enemy_id: String = "slime"

var _enemy_manager: EnemyManager  # DI 注入

func _game_start() -> void:
    _enemy_manager.spawn_enemy(enemy_id, global_position)
    queue_free()
```

> **原則**：任何靜態配置且需要動態生成的物件，都應實作專屬 SpawnerTool 做 Editor / Runtime 橋接。

---

## 5. 組件化設計（Composition over Inheritance）

### 核心原則
- **不寫肥大基底類別**：禁止 `DamageableEntity`、`BaseDestructible` 等繼承鏈
- **組合掛載**：可受傷物體（玩家、敵人、方塊）統一掛載 `Damageable.gd` 子節點
- **統一介面**：外部系統查找碰撞體的 `Damageable` 子節點，呼叫 `take_damage()`，監聽 `destroyed` / `health_changed` 信號

### 使用範例
```gdscript
# 外部系統（如 BulletManager）施加傷害
func _on_bullet_hit(body: Node2D, damage: int) -> void:
    # 直接取節點，不做空值防護——設計上保證有 Damageable 的才會進這個碰撞層
    body.get_node("Damageable").take_damage(damage)
```

```gdscript
# Damageable.gd 組件本身
class_name Damageable extends Node

signal health_changed(current: int, max: int)
signal destroyed

@export var max_health: int = 100
var _current_health: int

func _game_start() -> void:
    _current_health = max_health

func take_damage(amount: int) -> void:
    _current_health -= amount
    health_changed.emit(_current_health, max_health)
    if _current_health <= 0:
        destroyed.emit()
```

---

## 6. 生成腳本（Generated Scripts）

- 在 `_game_start()` 時由對應 Manager 在 `global_position` 生成
- 生成後掛載於 `MapNode` 節點之下
- 不應在 `_ready()` 中進行任何跨系統操作

---

## 快速檢查清單

撰寫任何腳本前，確認以下：

- [ ] 沒有任何空值防護（`== null`、`if not x`、`get_node_or_null` + if）
- [ ] 沒有使用 `autoload`
- [ ] 沒有使用 `z_index`
- [ ] DI 變數宣告不含 `= null`
- [ ] 跨系統初始化邏輯在 `_game_start()`，不在 `_ready()`
- [ ] DB 類別繼承 `RefCounted`，用 `static`
- [ ] Manager 是 `GameLoop.tscn` 的子節點，繼承 `Node` 或 `Node2D`
- [ ] 不寫基底繼承類別，用組件掛載取代
- [ ] 需要 Editor 佈置的物件有對應 SpawnerTool