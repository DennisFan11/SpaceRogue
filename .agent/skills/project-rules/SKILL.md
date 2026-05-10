---
name: project-rules
description: 這個技能描述了有關這個項目的規範 撰寫任意程式時務必完全遵守
---







## 核心架構
### 禁止使用autoload, 禁止使用zindex

### 1. 依賴注入系統 (DI)
- **核心文件**: `_Libs/DI.gd`
- **規範**: 
    - **DI會在 根節點ready 後注入**
    - **禁止在DI.gd內添加或修改功能，例如get_value ...等等**
    - **非必要所有的DI單例使用不該有任何空值防護 直接信任 DI 系統的注入**
    - **DI 單利的實例化僅能使用 GameLoop.tscn 嚴禁任何代碼實例化**
    - **宣告變數時，不賦予初始值 `= null`**。
    - 正確用法：`var _player_manager: PlayerManager`
    - 錯誤用法：`var _player_manager: PlayerManager = null`
- **機制**: 系統會在節點進入場景樹時自動解析依賴。支援 `_on_injected()` 回調以進行初始化。

### 2. 風格:
- **非必要禁止任何空值防護 應該直接抱錯**

### 3. Patterns
- 生成腳本 這是在_game_start 時自動 在其global_pos 使用manager生成的腳本 位於MapNode 節點底下

- 遊戲生命週期引導模式 (GameLoop Bootstrapping)
遊戲的核心控制流由 Scene/GameLoop/GameLoop.gd 掌握。為了解決 Godot 原生 _ready() 順序不可控導致的初始化衝突，專案引入了自定義的生命週期節點。

階段劃分：
_ready 階段：各節點創建(只能使用GameLoop.tscn 實例化)並將自己註冊至 DI 系統。
注入階段 (DI.injection)：GameLoop 在 _ready 後，主動對全樹進行遞歸注入，保證所有服務交叉綁定完成。
_game_start 階段：GameLoop 遞歸廣播 _game_start() 函式。所有需要依賴其他系統的初始化邏輯、生成邏輯都應該寫在這裡，而不是 _ready()。
4. 資料庫與管理器分離模式 (DB & Manager Separation)
專案強制將「靜態資料庫」與「動態管理實體」分離，形成配對的結構（例如 ResourceDB 與 ResourceManager，EnemyDB 與 EnemyManager）。

數據庫 (DB Classes)
職責：儲存配置、快取 PackedScene 模板，提供只讀查詢。
結構：使用 class_name 宣告，繼承 RefCounted（不上樹），並使用 static 靜態變數與靜態方法。
註冊：利用 Godot 的 static func _static_init(): 在類別載入時，直接使用 preload 硬編碼將場景綁定。
管理器 (Manager Classes)
職責：動態生成場景實例、管理節點生命週期、處理系統級別的事件邏輯。
結構：繼承 Node2D 或 Node，掛載於 GameLoop 下，並註冊進入 DI。
5. 實體生成工具模式 (Spawner Tool Pattern)
為了在 Editor 中能夠直觀佈置關卡與敵人，同時又將實際邏輯轉交給對應 Manager 處理，引入了 Tool Pattern。

運作流程 (以 EnemySpawnerTool.gd 為例)：
關卡設計師在 Editor 將 EnemySpawnerTool 放置於場景的指定位置。
啟動遊戲後，它會自動由 DI 注入 _enemy_manager。
攔截 _game_start() 呼叫，在當下的 global_position 要求 Manager 生成真正的實體節點 (spawn_enemy)。
呼叫 queue_free() 刪除這個佔位用的 Tool 節點。
TIP

任何靜態配置且需要動態生成的遊戲物件，都應實作專屬的 SpawnerTool 節點來處理 Editor 與 Runtime 的橋接。

6. 組件化設計模式 (Component / Composition Pattern)
為了應對高複雜度的遊戲物件，嚴格採用組合優於繼承 (Composition over Inheritance) 的模式。

不寫肥大的基底類別：例如不該有 DamageableEntity 或 BaseDestructible。
組件掛載：所有具備生命值、可受傷的物體（如玩家、敵人、飛船上的方塊）統一作為子節點掛載 Damageable.gd 組件。
統一通訊：外部系統（如射擊、碰撞管理器）只需查找碰撞體上是否有 Damageable 節點即可施加傷害 (take_damage)，並監聽其 destroyed 或 health_changed 信號。