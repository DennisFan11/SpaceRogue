---
name: project-rules
description: 這個技能描述了有關這個項目的規範 撰寫任意程式時務必完全遵守
---







## 核心架構

### 1. 依賴注入系統 (DI)
- **核心文件**: `_Libs/DI.gd`
- **規範**: 
    - **DI會在 根節點ready 後注入**
    - **禁止在DI.gd內添加或修改功能，例如get_value ...等等**
    - **非必要所有的DI單例使用不該有任何空值防護 直接信任 DI 系統的注入**
    - **宣告變數時，不賦予初始值 `= null`**。
    - 正確用法：`var _player_manager: PlayerManager`
    - 錯誤用法：`var _player_manager: PlayerManager = null`
- **機制**: 系統會在節點進入場景樹時自動解析依賴。支援 `_on_injected()` 回調以進行初始化。

### 2. 風格:
- **非必要禁止任何空值防護 應該直接抱錯**