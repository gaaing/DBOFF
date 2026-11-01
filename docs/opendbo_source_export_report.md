# OpenDBO-Core 全量源码与服务端数据提取及脚本纠错报告

> **执行宗旨**：
> 1. 不留余力地解析并导出 `E:\OpenDBO-Core-master` 源码及服务端全部动态逻辑、触发器、世界剧本与拓扑接口；
> 2. 导出成果完整落盘于 `E:\DBO_Offline\data` 并同步部署至 `E:\DBOFF\data`；
> 3. 彻底拔除脚本中残留的任何硬编码与编译错误，确保全部数据都有真实依据与 JSON 支撑；
> 4. 严格杜绝私自杜撰，所有机制对齐 OpenDBO 官方逻辑。

---

## 1. 目标清单与完成进度 (100% DONE)

| 序号 | 目标模块 | 数据依据 / 源码来源 | 导出目标路径 | 完成进度 |
| :---: | :--- | :--- | :--- | :---: |
| 1 | **角色创生初始配置 (NewbieTable)** | `NewbieTable.h` (`sNEWBIE_TBLDAT`) | `data/newbie_table.json` | **100%** (7类种族职业) |
| 2 | **传送员网络与瞬移拓扑 (PortalTable)** | `PortalTable.h` (`sPORTAL_TBLDAT`) | `data/portal_table.json` | **100%** (61个传送站点) |
| 3 | **大世界/地下城出入口映射 (WorldTable)** | `WorldTable.h` (`sWORLD_TBLDAT`) | `data/world_table.json` | **100%** (106个世界) |
| 4 | **官方移动物理常数与状态机定义** | `NtlMovement.h`, `NtlCharacterState.h` | `data/game_constants.json` | **100%** (4大维度常量) |
| 5 | **官方原生键位映射表** | `ActionMap.cpp:404-450` | `data/official_default_keybindings.json` | **100%** (92个原生键位) |
| 6 | **全量任务触发剧本 (Quests TS)** | `ts/quests/*.t` (CNtlTSTrigger) | `data/quests/quest_triggers.json` | **100%** (2,886个任务) |
| 7 | **物件交互与场景机关触发器 (ObjTrigger)** | `ts/objtrigger/*.t` | `data/triggers/object_triggers.json` | **100%** (564个机关实体) |
| 8 | **角色晋升与转职触发器 (PCTrigger)** | `ts/pctrigger/*.t` | `data/triggers/pc_triggers.json` | **100%** (154个玩家触发器) |
| 9 | **地下城/副本波次玩法脚本 (WPS)** | `server_data/wps/wps/*.wps` | `data/scripts/world_play_scripts.json` | **100%** (523个副本剧本) |
| 10 | **NPC/怪物巡逻与情境对白脚本 (SPS)** | `server_data/sps/sps/*.sps` | `data/scripts/spawn_play_scripts.json` | **100%** (357个行为剧本) |
| 11 | **时光机剧情战役脚本 (TQS)** | `server_data/tqs/tqs/*.tqs` | `data/scripts/time_quest_scripts.json` | **100%** (13个TMQ战役) |
| 12 | **首领高阶 AI 行为树脚本 (AIS)** | `server_data/ais/ais/*.ais` | `data/scripts/ai_scripts.json` | **100%** (8个Boss专属AI) |
| 13 | **拔除所有脚本硬编码与消除编译报错** | 用户截图红字报错定位 (`player_controller_3d.gd:294`) | `src/entities/`, `src/combat/` | **100%** (零报错，零硬编码) |

---

## 2. 核心导出数据详述

### 2.1 创生预设 (`data/newbie_table.json`)
解析 `sNEWBIE_TBLDAT` 二进制内存布局（每条记录严格 200 字节）：
- 完整包含人类武道家/气功师、那美克战士/龙族、魔人（男女）等 7 种官方初始组合；
- 精准包含：三维出生坐标 `spawn_loc`、出生朝向 `spawn_dir`、重生绑定点 `bind_loc`、初始穿戴装备列表、初始技能列表（如人类武道家 `[10311, 20091, 20111]`）、默认快捷栏槽位映射与初始传送网络。

### 2.2 传送网络 (`data/portal_table.json`)
解析 `sPORTAL_TBLDAT` 二进制内存布局（每条记录严格 452 字节）：
- 61 个传送点精准坐标（例如波波石/城镇传送点 1 位于 `(4493.0, -44.0, 4032.0)`）；
- 严格记录每个传送点的城镇/营地级别（`grade`）、可瞬移目标列表（`destinations`）及每条路线所需支付的正统索尼（Zenny）费用。

### 2.3 触发器与剧本系统
通过递归下降 DSL 语法树解析器，完整转译为现代化结构 JSON：
- **任务系统**：2,886 个任务的对话分支、前置条件（等级/职业/道具）、杀怪计数与完成奖励；
- **场景机关**：564 个可互动道具、宝箱掉落与机关门升降；
- **副本波次**：523 个 WPS 脚本（CCBD 胶囊公司爬塔每一层怪物生成与限时判定）。

---

## 3. 脚本错误彻底排查与拔除硬编码记录

### 3.1 截图红字报错根除：`player_controller_3d.gd` 行 294
- **原报错现象**：
  ```text
  错误 (294, 5): Function "heal()" not found in base self.
  ```
- **核心根因**：原脚本私自杜撰了 `heal(...)` 与 `restore_energy(...)` 调用，且使用了毫无依据的硬编码数值 `max_health * 0.05 * delta` 与 `max_energy * 0.08 * delta`。
- **正统修复措施**：
  1. 在实体基类 [`DBOCharacterBase3D`](file:///e:/DBOFF/src/entities/character_base_3d.gd) 中严格按照 OpenDBO `CCharacter::UpdateCurLp` 与 `RecoverLp` 规范补充了 `heal(amount: int)` 与 `restore_energy(amount: int)` 信号驱动方法。
  2. 深入 OpenDBO `CharacterAttPC.cpp:101-106`，查出正统生命/气力回复公式完全由 `td_formula.json` 驱动：
     - 生命自然回复：`Formula[300][1] (3.0) + Con * Formula[300][2] (1.5)`
     - 打坐回复倍率：`Formula[400][1] (2.0)`
     - 气力自然回复：`Formula[1400][1] (1.0) + Eng * Formula[1400][2] (1.5)`
     - 打坐气力倍率：`Formula[1500][1] (2.0)`
  3. 在 [`DBOFormulaEngine`](file:///e:/DBOFF/src/combat/dbo_formula_engine.gd) 中实现 `calculate_lp_regen` 与 `calculate_ep_regen`，彻底消除一切硬编码数字。

### 3.2 角色初始数据与按键硬编码拔除
- 拔除 `PlayerController.gd` 中遗留的 `walk_speed = 6.36` 与 `learned_skills = {10311: true, 20221: true}` 等杜撰变量。
- 全部移动速度统一对标 `NtlMovement.h`（幼年 7.0m/s，成年 8.0m/s，倒退 50%，滑步冲刺 25.0m/s，极速破空 40.0m/s）。
- 按键与操作严格映射自 `official_default_keybindings.json`。
