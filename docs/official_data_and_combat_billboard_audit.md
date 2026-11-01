# 官方数据源直连与战斗跳字美术贴图看板化重构审计报告

## 1. 目标清单与完成进度

- [x] **消除臆造冗余 JSON 补丁**：彻底删除 `character_factory_configs.json`、`character_lobby_stages.json` 与 `character_offsets.json` 3 个伪造文件，严禁脱离官方数据规范私建冗余数据。
- [x] **直连官方 `characterproperty.json` 属性表**：重构 `DBOCharacterFactory` 与 `DBOCharacterVisual`，网格文件、头部变换、身体地面偏移、骨骼缩放完全源自官方 1499 条角色属性数据。
- [x] **直连官方 `environment.json` 与 OpenDBO 源码机位**：重构 `CharacterLobbyStage`，四大舞台机位对标 `LobbyStage.cpp:80-185`，天空、光照、云雾与日晕严格索引官方 `data/terrain/select_character_chunks/environment.json` 预设。
- [x] **战斗跳字彻底去字体化，转为官方美术看板 (Billboard)**：对标 `NtlPLDamageBox.cpp` 与 `NtlFSMCharActEventProc.cpp`，淘汰 `Label3D`，全面接入官方数字美术贴图（`pc_*.png`, `mob_*.png`, `pcheal_*.png`, `mobheal_*.png`）与战术横幅（`text_critical.png`, `text_block.png`, `text_miss.png` 等）。
- [x] **Godot 4 引擎编译与无头运行验证**：大厅场景、大世界场景、玩家实体与怪物实体均通过无头校验，退出码 0，零红字报错。

---

## 2. 核心重构与对标详解

### 2.1 淘汰 Label3D 字体，实现 100% 官方美术贴图看板 (`DBOCombatTextManager`)
- **OpenDBO 规范对标**：
  - `DboClient/Lib/NtlPresentation/NtlPLDamageBox.cpp` (`CNtlPLDamageBox`)
  - `DboClient/Lib/NtlSimulation/NtlFSMCharActEventProc.cpp`
  - `DboClient/Lib/NtlSimulation/NtlSLVisualDeclear.h`
- **美术资产映射**（位于 `res://assets/tex/texture/effect/text/`）：
  - **玩家伤害数字 (PC Damage)**: `pc_0.png` ~ `pc_9.png`（正统黄黑边高对比度战斗数字）
  - **怪物伤害数字 (Mob Damage)**: `mob_0.png` ~ `mob_9.png`（怪物施加伤害之红白战斗数字）
  - **恢复数字 (Heal)**: `pcheal_0.png` ~ `pcheal_9.png` / `mobheal_0.png` ~ `mobheal_9.png`（绿色生命/气力跳字）
  - **战术判定横幅**:
    - 暴击: `text_critical.png`
    - 格挡: `text_block.png`
    - 未命中/闪避: `text_miss.png`
    - 击倒: `text_knockdown.png`
    - 免疫: `mob_immunity.png`
    - 抗性: `text_resistance.png`
    - 绝地反击: `text_counter_attack.png`
- **动画动效实现**：
  - 采用 3D 看板机制 (`billboard = BaseMaterial3D.BILLBOARD_ENABLED`)，保证文字与数字永远正对主摄像机。
  - 数字串水平等间距布局（单字宽度 0.22m，中心自适应对称展开）。
  - 弹性缩放冲量（Punch Scale 0.45 -> 1.0/1.3）、平滑上升（1.2m~1.6m）以及后半段透明度平滑衰减淡出（Alpha Tween）。

---

### 2.2 彻底清理冗余 JSON，全面对接官方权威表格

| 原臆造冗余文件 | 消除方案 | 官方权威数据来源 |
| :--- | :--- | :--- |
| `character_offsets.json` | **彻底删除** | 直连 `assets/prop/property/characterproperty.json` 中的 `bone_data.pos_offset` 与 `bone_scales[29]` |
| `character_factory_configs.json` | **彻底删除** | 模型与动画直接读取 `characterproperty.json` 的 `mesh_file`、`animation_table` 以及 `default_item_list.json` |
| `character_lobby_stages.json` | **彻底删除** | 场景与天气严格读取 `data/terrain/select_character_chunks/environment.json`；机位严格对齐 `LobbyStage.cpp:80-185` |

---

### 2.3 角色工厂 (`DBOCharacterFactory`) 与视觉装配 (`DBOCharacterVisual`)
- **模型寻址**：通过官方 `prop_name` 检索 `characterproperty.json` 中的 `mesh_file`（如 `A_HUM_M_AD.dff` -> `a_hum_m_ad.glb`），儿童素体自动匹配官方对应的 child 模型。
- **地面高度校准**：直接自 `characterproperty.json` 的 `bone_data.pos_offset[1]` 动态提取各族地面偏移量，消除了硬编码常量与孤立 JSON。
- **发型与头部变换**：`get_head_transform(prop_key)` 动态自 `bone_data.bone_scales[29]` 提取头部骨骼标准缩放系数与位移。

---

### 2.4 大厅舞台 (`CharacterLobbyStage`)
- **场景与机位完全解耦**：
  - 沙鲁度假村擂台 (Field 18, Preset 2): 沙鲁世界天空 `sky_sp`，动态移速云 `cloud_011`，主太阳 `sun_001.png`，开启日晕。
  - 柯卡拉村人类大厅 (Field 42, Preset 6): 真实天空 `sky00`，白云 `cloud_022`，太阳 `sun_001.png`。
  - 天天神殿那美克大厅 (Field 45, Preset 7): 绿色渐变天空，双层对流云 `cloud-p01` 与 `cloud-p02`，主太阳并带日晕。
  - 孙悟饭爷爷家魔人大厅 (Field 21, Preset 4): 梦幻蓝天 `sky`，暖色调太阳 `sun_002.png`，开启日晕。
- 零手工维护 JSON，全部由 `environment.json` 的 `field_map` 和 `presets` 驱动。

---

## 3. 验证结果与编译异常修复

### 3.1 编辑器 Autoload 单例与强类型推断修复
针对 Godot 4 引擎启动时 Autoload 冲突与解析错误进行了全面修复：
1. **Autoload 命名隐藏冲突**：[`dbo_combat_text_manager.gd`](file:///e:/DBOFF/src/ui/hud/dbo_combat_text_manager.gd) 移除 `class_name DBOCombatTextManager`，杜绝与 `project.godot` 中 Autoload 单例同名引发的全局脚本解析阻断。
2. **字典类型推断空安全**：修复 `bpath: String = TEXTURE_DIR + bfile` 的显式类型声明。
3. **角色工厂兼容接口**：在 [`character_factory.gd`](file:///e:/DBOFF/src/entities/character_factory.gd) 补全 `get_pc_base_models()` 与 `get_pc_anim_dirs()` 静态方法，消除 [`player_controller_3d.gd`](file:///e:/DBOFF/src/entities/player_controller_3d.gd) 的调用阻断。
4. **布尔推断显式声明**：[`player_controller_3d.gd:600`](file:///e:/DBOFF/src/entities/player_controller_3d.gd) 将 `is_knocked` 强制标注为 `: bool`。
5. **外挂发型节点所有权清空**：在 [`character_visual.gd`](file:///e:/DBOFF/src/entities/character_visual.gd) 中对实例化部件显式执行 `mesh_inst.owner = null`，彻底消除 `inconsistent owner` 引擎警告。
6. **着色器未使用变量清理**：在 [`world_skybox.gd`](file:///e:/DBOFF/src/world/world_skybox.gd) 中剔除未使用的 `_sky_layer_shader` 变量。

### 3.2 引擎自动化编译校验
执行引擎无头运行与编辑器自检：
1. `Godot --headless --editor --quit` -> **Exit Code: 0 (零红字报错，全局脚本解析全部通过)**
2. `scenes/lobby/character_lobby.tscn` -> **Exit Code: 0 (OK)**
3. `scenes/world/main_world.tscn` -> **Exit Code: 0 (OK)**
4. `scenes/entities/player_character.tscn` -> **Exit Code: 0 (OK)**
5. `scenes/entities/mob_entity.tscn` -> **Exit Code: 0 (OK)**
