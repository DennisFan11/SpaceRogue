# SpaceRogue

## 開發規範

### DI 注入 (Dependency Injection)
- **宣告變數時，不賦予初始值 `= null`**。
- 正確用法：`var _player_manager: PlayerManager`
- 錯誤用法：`var _player_manager: PlayerManager = null`
- 系統會在 `_ready` 期間自動解析並填入實例。絕對不可呼叫不存在的 `DI.resolve` 函式。

### 飛船建造系統 (Ship Builder)
- **預覽顏色規則**：
  - **紅色 (Red)**：永遠不合法（與現有方塊重疊、或者完全懸空沒有連接任何方塊）。重疊絕對不允許放置。
  - **黃色 (Yellow)**：未來合法（有連接到現有方塊，但目前不在無人機建造範圍內，或鄰居尚未建造完成）。
  - **灰色 (Gray)**：當前合法（有連接到已建成的方塊，且在無人機建造範圍內），可以立刻進行實體建造。
