# SpaceRogue

一個基於 Godot 4.6 開發的太空模擬與飛船建造遊戲。

## 項目概述
SpaceRogue 核心圍繞著**飛船自定義建造**與**真實物理驅動的操控**。項目採用高度模塊化的架構，利用自定義 DI 系統實現組件間的低耦合交互。

---

## 核心架構

### 1. 依賴注入系統 (DI)
- **核心文件**: `_Libs/DI.gd`
- **規範**: 
  - **宣告變數時，不賦予初始值 `= null`**。
  - 正確用法：`var _player_manager: PlayerManager`
  - 錯誤用法：`var _player_manager: PlayerManager = null`
- **機制**: 系統會在節點進入場景樹時自動解析依賴。支援 `_on_injected()` 回調以進行初始化。

### 2. 飛船系統 (Ship System)
- **物理驅動**: 飛船本體為 `RigidBody2D`，方塊碰撞體動態附加。
*   **多連塊 (Polyomino)**：支援單個組件佔用多個網格坐標。
*   **結構完整性**：基於 BFS 算法檢查方塊與核心的連通性，斷連方塊會自動剝離。

### 3. 建造系統 (Ship Builder)
- **快捷鍵**: `B` 鍵進入/退出建造模式。
- **預覽顏色規則**：
  - **紅色 (Red)**：不合法（重疊或完全懸空）。
  - **黃色 (Yellow)**：潛在合法（已連接，但超出目前建造範圍或前置方塊未完成）。
  - **灰色 (Gray)**：當前合法（可立即進行實體建造）。
- **回收機制**: 拆除方塊可獲得 50% 的資源返還。

### 4. 裝備系統 (Equipment System)
- **實體化**: 裝備為 `RigidBody2D` 實體，具備地面掉落與持用兩種狀態。
- **操作**: 
  - `E`: 撿起地上的裝備（需手中無裝備）。
  - `Q`: 丟出手中的裝備（朝向鼠標方向）。
  - `滑鼠左鍵`: 觸發裝備功能（如鑽頭旋轉與挖掘）。
- **持久性**: 玩家進入/離開飛船時，裝備會自動暫存並恢復，確保跨場景不丟失。
- **互動提示**: 整合 `Interactable` 組件，靠近時顯示 UI 提示，文字自動鎖定水平旋轉。

### 5. 資源與世界系統 (Resource & World)
- **數據驅動**: 使用 `ResourceDB` 與 `TileBlockDB` 管理資源與方塊類型。
- **挖掘機制**: 鑽頭可對具備 `Damageable` 的方塊（如 `BaseTileBlock`）造成傷害。
- **銅礦 (Copper)**: 專屬礦石方塊，被破壞時會掉落物理銅礦資源。

---

## 開發指南

### 座標系統轉換
飛船相關邏輯請統一使用 `Ship.gd` 提供的轉換接口：
- `global_to_grid(pos)`: 全局轉網格
- `grid_to_local(grid_pos)`: 網格轉局部
- `local_to_grid(local_pos)`: 局部轉網格

### 物理層級 (Bitmask)
請參考 `BitmaskManager.gd` 使用靜態常量：
- `LAYER_PLAYER`: 1
- `LAYER_SHIP`: 2
- `LAYER_WALL`: 8
- `LAYER_PROJECTILE`: 4
- `LAYER_INTERACTABLE`: 16
- `LAYER_RESOURCE`: 32
- `LAYER_EQUIPMENT`: 64
