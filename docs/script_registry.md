# Dragon Ball Online Offline (DBOFF) - 脚本与源码对齐全景名册 (Script Registry)

> **核心维护规范（严格准则）**：
> 1. 本名册专门记录 DBOFF 项目中创建的所有 Godot 脚本文件。
> 2. 详细列明：**脚本路径**、**职责作用**、**对标 OpenDBO-Core 源码文件**、**底层数据引用源**、**所实现或关联的系统与功能**。
> 3. **每次编写、重构或新增脚本时，必须同步更新维护此文件**。
> 4. **禁止硬编码、禁止杜撰、禁止臆想、禁止遗漏**；每一项必须有据可查、实打实对应 OpenDBO-Core 源码及官方 JSON 资源。

---

## 1. 核心架构单例层 (Core Singletons)

### 1.1 `src/core/dbo_localizer.gd`
- **文件路径**：[`src/core/dbo_localizer.gd`](file:///e:/DBOFF/src/core/dbo_localizer.gd)
- **职责作用**：全局 Autoload 单例（注册名称 `DBOLocalizer`），负责全项目文本多语言检索与富文本标签化分发。严格消灭一切硬编码中文字符串。（注：作为 Autoload 全局节点注册，不加 local `class_name` 避免 Godot 4 全局命名空间冲突）。
- **对标 OpenDBO-Core 源码**：
  - `DboClient/Lib/NtlLocalize/NtlLocalize.h` & `NtlLocalize.cpp`
  - `DboClient/Client/Gui/LocalizeStringTable.h`
- **数据引用处**：
  - [`res://assets/tbl/table_text_all_data.json`](file:///e:/DBOFF/assets/tbl/table_text_all_data.json)（官方全并集繁体映射表，涵盖 `ACTION_DATA`, `ITEM_DATA`, `SKILL_DATA`, `MOB_DATA`, `NPC_DATA`, `NPC_DIALOG`, `QUEST_ITEM_DATA`, `MAP_NAME`, `ETC_TEXT` 等 28 个大类）。
- **实现系统与功能**：
  - 全局文本零硬编码本地化下发；
  - 标签化富文本包裹（`STYLE_TAGS`：稀有度颜色、NPC名称高亮、警报颜色）；
  - 动态参数模板格式化（`format_text`，如 `"获得了 %s 个 %s"`）。

### 1.2 `src/core/dbo_table_manager.gd`
- **文件路径**：[`src/core/dbo_table_manager.gd`](file:///e:/DBOFF/src/core/dbo_table_manager.gd)
- **职责作用**：全局 Autoload 单例（注册名称 `DBOTableManager`），负责 274 个数值表格与 6 个属性表格的高性能**惰性按需缓存**（Lazy Loading），杜绝启动时一次性加载爆内存卡死。（注：作为 Autoload 全局节点注册，不加 local `class_name` 避免 Godot 4 全局命名空间冲突）。
- **对标 OpenDBO-Core 源码**：
  - `DboShared/NtlGameTable/TableContainer.h` (`CNtlTableContainer`)
  - `DboClient/Lib/NtlPresentation/NtlPLPropertyContainer.h` (`CNtlPLPropertyContainer`)
  - `DboShared/NtlGameTable/ItemTable.h` (`CItemTable`)
  - `DboShared/NtlGameTable/SkillTable.h` (`CSkillTable`)
  - `DboShared/NtlGameTable/MobTable.h` (`CMobTable`)
  - `DboShared/NtlGameTable/NpcTable.h` (`CNpcTable`)
  - `DboShared/NtlGameTable/ExpTable.h` (`CExpTable`)
  - `DboShared/NtlGameTable/WorldTable.h` (`CWorldTable`)
  - `DboShared/NtlGameTable/FormulaTable.h` (`CFormulaTable`)
- **数据引用处**：
  - 数值表：[`res://assets/tbl/table_item_data.json`](file:///e:/DBOFF/assets/tbl/table_item_data.json), `table_skill_data.json`, `table_mob_data.json`, `table_npc_data.json`, `table_exp_data.json`, `td_formula.json` 等。
  - 属性表：[`res://assets/prop/property/characterproperty.json`](file:///e:/DBOFF/assets/prop/property/characterproperty.json), `itemproperty.json`, `objectproperty.json`, `direct_splines.json`, `direct_project.json`, `tenkaichi_direction.json`。
- **实现系统与功能**：
  - 物品/技能/怪物/NPC/经验属性精确索引；
  - 角色动作帧、装备挂点、场景物理碰撞体与导轨样条按需检索。

### 1.3 `src/core/audio_manager.gd`
- **文件路径**：[`src/core/audio_manager.gd`](file:///e:/DBOFF/src/core/audio_manager.gd)
- **职责作用**：全局 Autoload 单例（注册名称 `AudioManager`），负责 BGM 双通道平滑交叉淡入淡出、2D UI 界面音效池与 3D 空间音频定位。（注：作为 Autoload 全局节点注册，不加 local `class_name` 避免 Godot 4 全局命名空间冲突）。
- **对标 OpenDBO-Core 源码**：
  - `DboClient/Lib/NtlSound/NtlSoundManager.h` & `NtlSoundManager.cpp`
  - `DboClient/Lib/NtlSound/NtlSoundDefines.h`
- **数据引用处**：
  - [`res://assets/sound/`](file:///e:/DBOFF/assets/sound/) 全量音频库（含 `bgm/`, `effect/`, `environment/`, `footsteps/`, `monster/`, `npc/`, `object/`, `skill/`, `system/`, `tlq/`, `tmq/`, `vehicle/`, `voice/` 等 13 个子库，支持 `.wav` 与 `.ogg` 智能多目录匹配）。
  - `characterproperty.json`（`sound_name1` ~ `sound_name4`）与 `objectproperty.json`（`sound_property`）。
- **实现系统与功能**：
  - 地图切换时 BGM 交叉渐变；
  - 动作事件中的脚步声（`EVENT_ANIM_FOOT_STEP`）、打击音效、气功波爆炸 3D 空间衰减播放。

### 1.4 `src/core/free_look_camera_3d.gd`
- **文件路径**：[`src/core/free_look_camera_3d.gd`](file:///e:/DBOFF/src/core/free_look_camera_3d.gd)
- **职责作用**：大世界自由巡视 3D 摄像机（`Camera3D`）。支持鼠标捕获平滑旋转偏航/俯仰角、键盘 WASD 空间六向平移、Shift 极速巡航与鼠标滚轮实时调节移速。用于全景视察与无缝大世界飞行漫游。
- **对标 OpenDBO-Core 源码**：
  - `DboClient/Lib/NtlPresentation/NtlPLCamera.h` & `NtlPLCamera.cpp` (`CNtlPLCamera`)
  - `DboClient/Client/Camera/FreeCamera.h` & `FreeCamera.cpp`
- **数据引用处**：
  - 无需硬编码数据，直接读取输入映射与相机投影参数。
- **实现系统与功能**：
  - 空间 6 自由度巡检漫游；
  - 动态鼠标灵敏度与视平线极限俯仰角限制（-89.0° ~ +89.0°）。

---

### 2.1 `src/combat/dbo_formula_engine.gd`
- **文件路径**：[`src/combat/dbo_formula_engine.gd`](file:///e:/DBOFF/src/combat/dbo_formula_engine.gd)
- **职责作用**：底层纯静态公式机。严格依据 OpenDBO-Core 源码与表格计算命中率、穿透防御减免、伤害浮动、等级最大连锁攻击数（Chain Attack Sequence）与 6x6 战斗属性相克矩阵。
- **对标 OpenDBO-Core 源码**：
  - `DboServer/Server/GameServer/battle.cpp` (命中公式 L64, 技能成功率 L81, 穿透防御 L167/L407, 浮动 L615-620)
  - `DboShared/NtlShared2/NtlBattle.cpp` (L99: `NtlGetBattleChainAttackBounsRate`, L123: `NtlGetBattleChainAttackSequence`, L150: `afBattleAttributeBonusRate[6][6]`)
  - `DboServer/Server/GameServer/char_battle.cpp`
  - `DboShared/NtlGameTable/FormulaTable.cpp` (`CFormulaTable::m_afRate`)
- **数据引用处**：
  - [`res://assets/tbl/td_formula.json`](file:///e:/DBOFF/assets/tbl/td_formula.json)：
    - ID `3100` (`Rate[3100][1] = 45.0`)：穿透防御除数常数；
    - ID `3700` (`Rate[3700][1] = 2.6`)：命中闪避衰减系数；
    - ID `3900` (`Rate[3900][1] = 2.8`)：异常技能成功率常数；
    - ID `3500` (`[0.95, 0.0, 1.05, 0.0]`)：95% ~ 105% 伤害浮动。
  - `NtlBattle.cpp`：
    - `s_afChainAttackBonusRate[6] = [0.0, 0.5, 1.0, 2.0, 3.0, 4.0]` 连锁攻击伤害百分比加成；
    - `afBattleAttributeBonusRate[6][6]` 六属性相克百分比矩阵（NONE, HONEST, STRANGE, WILD, ELEGANCE, FUNNY）。
- **实现系统与功能**：
  - 严格按等级计算玩家最大连锁段数（Lv<4 为 1 段，Lv4-7 为 2 段，Lv8-11 为 3 段，Lv12-15 为 4 段，Lv16-19 为 5 段，Lv20+ 为 6 段）；
  - 连锁段数伤害加成计算；
  - 6x6 正统属性相克系数判定；
  - 正统防御抵扣公式与浮动伤害计算。

### 2.2 `src/combat/combat_engine.gd`
- **文件路径**：[`src/combat/combat_engine.gd`](file:///e:/DBOFF/src/combat/combat_engine.gd)
- **职责作用**：高层战斗调度器。整合 `DBOFormulaEngine` 计算结果，施加击退/击飞冲量，打断目标受创状态。
- **对标 OpenDBO-Core 源码**：
  - `DboServer/Server/GameServer/char_battle.cpp`
  - `DboShared/NtlGameTable/GraphicDataTable.h` (`ETargetBehavior`)
- **数据引用处**：
  - `characterproperty.json` 中的 `target_behavior`（0: None, 1: Push 平移击退, 2: KnockDown 击飞倒地, 3: Toss 浮空）。
- **实现系统与功能**：
  - 物理与能量攻击打击判定与受击血量扣除；
  - 受击打断睡眠（Sleep Break）；
  - 空间 3D 击退击飞冲量施加。

### 2.3 `src/combat/projectile_3d.gd`
- **文件路径**：[`src/combat/projectile_3d.gd`](file:///e:/DBOFF/src/combat/projectile_3d.gd)
- **职责作用**：3D 飞行弹道实体（Area3D），用于气功弹、光束射线、追踪弹的飞行推进与接触碰撞检测。
- **对标 OpenDBO-Core 源码**：
  - `DboClient/Lib/NtlPresentation/NtlAnimEventData.h` (`EProjectileEffectType`, `SHissidanData`)
  - `DboClient/Lib/NtlSimulation/NtlSobProjectile.h`
- **数据引用处**：
  - `characterproperty.json` 中的 `projectile_effect_type`（2000: Ball, 2001: Beam, 2002: Hissidan 操气弹, 2003: Hellzone 魔空包围弹）与 `projectile_speed`。
- **实现系统与功能**：
  - 气功波沿发射朝向或向目标飞行；
  - 操气弹（Hissidan）平滑四元数/方向向量追踪（Slerp）；
  - 击中目标后触发 `DBOCombatEngine.calculate_attack()` 并自动销毁。

---

## 3. 实体、表现与形态系统 (Entities & Presentation)

### 3.1 `src/entities/character_visual.gd`
- **文件路径**：[`src/entities/character_visual.gd`](file:///e:/DBOFF/src/entities/character_visual.gd)
- **职责作用**：角色多部件解耦换装渲染器。将头、身、腿、鞋等独立部件挂接到统一 `Skeleton3D` 下，通过 `AnimationPlayer` 载入轻量骨骼动画库。
- **对标 OpenDBO-Core 源码**：
  - `DboClient/Lib/NtlPresentation/NtlPLCharacter.h` (`CNtlPLCharacter`)
  - `DboClient/Lib/NtlPresentation/NtlPLItem.h` (`CNtlPLItem`)
- **数据引用处**：
  - 角色素体与装备零件网格：[`res://assets/obj/item/`](file:///e:/DBOFF/assets/obj/item/)（包含 `mesh_armor_*`, `mesh_weapon/`, `mesh_costume/`, `mesh_scouter/` 共 5,000+ 个轻量 GLB 部件）；
  - 角色纯骨骼动作库：[`res://assets/obj/character/`](file:///e:/DBOFF/assets/obj/character/)（包含 `animation_humanmale/`, `animation_humanfemale/`, `animation_namek/`, `animation_majinmale/`, `animation_majinfemale/`, `animation_mob/`, `animation_npc/`, `animation_vehicle/` 共 13,000+ 个动画切片 GLB）；
  - `itemproperty.json` 中的 `attach_offset` 与装备槽类型；
  - `characterproperty.json` 中的 `bone_data`（体型缩放）。
- **实现系统与功能**：
  - 动态换装（`equip_mesh_part`）；
  - 独立武器/挂件骨骼绑定（`attach_object_to_bone`，通过 `BoneAttachment3D`）；
  - 魔人/那美克星人体型缩放（`apply_bone_scaling`）；
  - 共享动作库（`AnimationLibrary`）播放控制。

### 3.2 `src/entities/anim_event_dispatcher.gd`
- **文件路径**：[`src/entities/anim_event_dispatcher.gd`](file:///e:/DBOFF/src/entities/anim_event_dispatcher.gd)
- **职责作用**：动作事件派发器。在动作播放到 `characterproperty.json` 定义的精确毫秒时间戳时，派发打击、脚步、受击震屏、气功弹道发射信号。
- **对标 OpenDBO-Core 源码**：
  - `DboClient/Lib/NtlPresentation/NtlAnimEventData.h` (`SEventAnimHit`, `SEventFootStep`, `SEventSound`, `SEventVisualEffect`)
  - `DboClient/Lib/NtlPresentation/NtlTypeAnimData.cpp` (`CNtlTypeAnimTable::LoadSerialize`)
- **数据引用处**：
  - `characterproperty.json` 的 `animation_table` -> `animations` -> `events` 字典（含时间 `time`、事件 ID、气功弹类型、震屏系数）。
- **实现系统与功能**：
  - 攻击判定点触发打击伤害；
  - 触发主摄像机震屏（`camera_shake_requested`）；
  - 触发左右脚地面脚步声（`foot_step_triggered`）；
  - 触发气功弹实体生成（`projectile_spawn_requested`）。

### 3.3 `src/entities/character_base_3d.gd`
- **文件路径**：[`src/entities/character_base_3d.gd`](file:///e:/DBOFF/src/entities/character_base_3d.gd)
- **职责作用**：所有可动角色（玩家、怪物、NPC）的物理与属性抽象基类（CharacterBody3D）。
- **对标 OpenDBO-Core 源码**：
  - `DboServer/Server/GameServer/CCharacter.h` (`CCharacter`)
  - `DboServer/Server/GameServer/CPlayer.h` (`CPlayer`)
  - `DboServer/Server/GameServer/CMonster.h` (`CMonster`)
- **数据引用处**：
  - `characterproperty.json` 中的 `speed.walk_front` 与 `speed.run_front`（真实前向移速参数）；
  - `table_mob_data.json` / `table_npc_data.json`（基础攻防生命数据）。
- **实现系统与功能**：
  - Jolt 3D 物理运动与重力下坠；
  - 移速参数对接；
  - 受到击退/击飞冲量衰减（`move_toward`）；
  - 生命/气力/RP 数值监听与阵亡状态机切换。

### 3.4 `src/entities/dbo_buff_component.gd`
- **文件路径**：[`src/entities/dbo_buff_component.gd`](file:///e:/DBOFF/src/entities/dbo_buff_component.gd)
- **职责作用**：持续状态与 Buff/Debuff 容器组件。处理 DOT 掉血、HOT 回复、行动限制（眩晕、催眠、麻痹、变糖果）。
- **对标 OpenDBO-Core 源码**：
  - `DboServer/Server/GameServer/BuffManager.h` & `BuffManager.cpp` (`CBuffManager`)
  - `DboServer/Server/GameServer/Buff.h` & `Buff.cpp` (`CBuff`)
  - `DboShared/NtlShared2/NtlSharedDef.h` (`eCHARCOND_FLAG`)
- **数据引用处**：
  - `table_skill_data.json`（Buff 持续时间、系统效果代码、数值系数）。
- **实现系统与功能**：
  - 状态位掩码判定（`can_move()`, `can_attack()`, `can_cast_skills()`）；
  - 周期性 DOT/HOT 滴答（Tick）；
  - 催眠受创即醒（`on_damaged_break_sleep`）。

### 3.5 `src/entities/dbo_aspect_component.gd`
- **文件路径**：[`src/entities/dbo_aspect_component.gd`](file:///e:/DBOFF/src/entities/dbo_aspect_component.gd)
- **职责作用**：形态变身控制器。严格对应 OpenDBO-Core 的五大变身状态机与状态转换表。
- **对标 OpenDBO-Core 源码**：
  - `DboServer/Server/GameServer/AspectState.h`
  - `DboServer/Server/GameServer/AspectState_SuperSaiyan.cpp`
  - `DboServer/Server/GameServer/AspectState_GreatNamek.cpp`
  - `DboServer/Server/GameServer/AspectState_PureMajin.cpp`
  - `DboServer/Server/GameServer/AspectState_Kaioken.cpp`
  - `DboServer/Server/GameServer/AspectState_Vehicle.cpp`
  - `DboShared/NtlGameTable/StatusTransformTable.h` (`sSTATUS_TRANSFORM_TBLDAT`)
- **数据引用处**：
  - [`res://assets/tbl/table_status_transform_data.json`](file:///e:/DBOFF/assets/tbl/table_status_transform_data.json)（通过 Godot 4 原生 `hex_decode()` 二进制解包获取真实的 18 个浮点字段，含 `fEP_Consume_Rate`, `fLP_Consume_Rate`, `fAttack_Speed_Transform`, `fDodge_Rate_Transform`, `dwDuration`）。
- **实现系统与功能**：
  - 超级赛亚人变身与气力持续扣除，气力不足 10% 自动解除；
  - 那美克超巨体化与体型缩放；
  - 纯粹魔人小布欧形态转换；
  - 界王拳生命持续扣除；
  - 胶囊机车载具骑乘与受创击落；
  - 退出变身后自动挂载 `CHARCOND_AFTEREFFECT` 脱力状态。

### 3.6 `src/entities/character_factory.gd`
- **文件路径**：[`src/entities/character_factory.gd`](file:///e:/DBOFF/src/entities/character_factory.gd)
- **职责作用**：模块化角色解耦组装工厂。将玩家（人类男女/那美克/魔人男女）、怪物与 NPC 的三维素体、换装装备、独立骨骼层级与按需切片动画动态拼接，实现极致轻量化装配。
- **对标 OpenDBO-Core 源码**：
  - `DboClient/Lib/NtlPresentation/NtlPLCharacter.cpp` (`CNtlPLCharacter`)
  - `DboClient/Lib/NtlPresentation/NtlPLItem.cpp` (`CNtlPLItem`)
  - `DboClient/Lib/NtlSimulation/NtlBehaviorChar.cpp:713-740` (`CNtlBehaviorCharNormalAttack::SetAnim`: `ATK_DEF_1 ~ 6`)
  - `DboServer/Server/GameServer/CPlayer.cpp` & `CMonster.cpp`
- **数据引用处**：
  - `res://assets/obj/character/mesh_pc/` (10 种基础人体/魔人/那美克素体)；
  - `res://assets/obj/character/animation_*/` (13,199 个纯骨骼采样动画切片 GLB，装配正统 `atk_def_1` ~ `atk_def_6`、`sit_down/idle/up`、`block_start/loop/end`、`charge_start/loop/end`)；
  - `res://assets/tbl/table_item_data.json`、`table_mob_data.json`、`table_npc_data.json`。
- **实现系统与功能**：
  - 玩家素体自动匹配与 OpenDBO 正统 6 段普攻动画链装配；
  - 怪物族系（Mob Family，如 `m_akm`）动画自动目录匹配与装配；
  - 装备部位（武器、防具、战斗服、探测器）动态槽位解析与模型换装。

### 3.7 `src/entities/player_controller_3d.gd`
- **文件路径**：[`src/entities/player_controller_3d.gd`](file:///e:/DBOFF/src/entities/player_controller_3d.gd)
- **职责作用**：第三人称玩家全功能控制器。继承自 `DBOCharacterBase3D`，100% 沿用 OpenDBO 官方默认按键映射（ActionMap.cpp）与状态机，消灭一切硬编码与臆想。
- **对标 OpenDBO-Core 源码**：
  - `DboClient/Lib/NtlSimulation/ActionMap.cpp:404-450`（全量默认按键：W/S/A/D/Q/E 位移，Space 跳跃，X 打坐，Z 蓄气，R 格挡，Tab 选敌，F 自动攻击，~ 选己，1-0 快捷键）
  - `DboClient/Client/Main/AvatarController.cpp` (`ActionCharging`, `ActionAutoAttack`, `ActionSitAndStand`, `ActionBlocking`)
  - `DboServer/Server/GameServer/BotState_Charging.cpp` & `CPlayer.cpp:2232-2320`（RP 蓄气逻辑：仅充能 100 RP 与 3 颗气珠，绝不恢复 EP）
  - `DboServer/Server/GameServer/BotState_Sitting.cpp`（打坐获得 HOT/EOT 生命气力加速恢复）
  - `DboServer/Server/GameServer/char_battle.cpp:53-93` & `NtlBattle.cpp:99-141`（连锁普攻判定：按等级决定最大连击段数，加成 0%~4% 伤害）
- **数据引用处**：
  - `characterproperty.json` (walk/run 真实移速参数)；
  - `assets/sound/footsteps/` (真实脚步声)；
  - `assets/sound/skill/` (蓄气与挥拳打击声)。
- **实现系统与功能**：
  - OpenDBO 官方 ActionMap.cpp 全量默认按键响应；
  - Tab 自动选取 35 米内最近敌人，鼠标屏幕拾取目标；
  - F 键自动靠近并触发正统等级连锁普攻（1~6 段循环，驱动 `atk_def_1` ~ `atk_def_6`）；
  - Z 键蓄气（仅增加 RP，蓄满 100 RP 点亮一颗气珠，上限 3 颗）；
  - X 键打坐起立切换，打坐期间享受生命与气力周期性百分比回升；
  - R 键格挡削减 60% 物理受创；
  - 帧事件驱动地面脚步声与受击震屏。

### 3.8 `src/entities/mob_entity_3d.gd`
- **文件路径**：[`src/entities/mob_entity_3d.gd`](file:///e:/DBOFF/src/entities/mob_entity_3d.gd)
- **职责作用**：野外怪物与敌对生物实体。继承自 `DBOCharacterBase3D`，实现 OpenDBO 经典的怪物 AI 状态机（待机、巡逻游荡、仇恨追逐、近战攻击、脱战回血、死亡重生）。
- **对标 OpenDBO-Core 源码**：
  - `DboServer/Server/GameServer/CMonster.h` & `CMonster.cpp`
  - `DboServer/Server/GameServer/BotAiState.cpp` (`CBotAiState_Patrol`, `CBotAiState_Chase`, `CBotAiState_Attack`)
  - `DboServer/Server/GameServer/char_battle.cpp:62`（怪物攻击序列 `rand() % 2` 随机触发主/次普攻 `atk_def_1`/`atk_def_2`）
  - `DboShared/NtlGameTable/MobTable.h` (`sMOB_TBLDAT`)
- **数据引用处**：
  - `assets/tbl/table_mob_data.json` (怪物基础血量、防御、等级、模型名)；
  - `assets/tbl/table_text_all_data.json` (`MOB_DATA` 分类怪物本地化名)；
  - `assets/sound/monster/` (怪物打击与阵亡咆哮音效)。
- **实现系统与功能**：
  - 怪物基础属性与模型完全从表格动态读取；
  - 注册入 `mobs` 与 `enemies` 节点组，供玩家 Tab 索敌；
  - 攻击通过 `DBOFormulaEngine.resolve_battle_strike` 正统公式结算打击伤害，杜绝随机数硬编码；
  - 仇恨范围感知与追逐玩家；
  - 超出脱战半径（30m）强制返回出生点并瞬间回满生命（OpenDBO 正统机制）；
  - 死亡播放倒地动画并在计时结束后无缝重生。
- **数据引用处**：
  - `assets/tbl/table_mob_data.json` (怪物基础血量、防御、等级、模型名)；
  - `assets/tbl/table_text_all_data.json` (`MOB_DATA` 分类怪物本地化名)；
  - `assets/sound/monster/` (怪物打击与阵亡咆哮音效)。
- **实现系统与功能**：
  - 怪物基础属性与模型完全从表格动态读取；
  - 仇恨范围（Aggro Radius）感知与追逐玩家；
  - 超出脱战半径（30m）强制返回出生点并瞬间回满生命（OpenDBO 正统机制）；
  - 死亡播放倒地动画并在计时结束后无缝重生。

### 3.9 `src/entities/npc_entity_3d.gd`
- **文件路径**：[`src/entities/npc_entity_3d.gd`](file:///e:/DBOFF/src/entities/npc_entity_3d.gd)
- **职责作用**：大世界城镇与野外 NPC 实体。继承自 `DBOCharacterBase3D`，实现玩家靠近感知、平滑转向注视打招呼（Greeting / Courtesy）与交互请求分发。
- **对标 OpenDBO-Core 源码**：
  - `DboServer/Server/GameServer/CNpc.h` & `CNpc.cpp`
  - `DboShared/NtlGameTable/NpcTable.h` (`sNPC_TBLDAT`)
  - `DboClient/Client/Stage/WorldStage.cpp`
- **数据引用处**：
  - `assets/tbl/table_npc_data.json` (NPC 基础数据与模型)；
  - `assets/tbl/table_text_all_data.json` (`NPC_DATA` 分类 NPC 繁体名)；
  - `assets/sound/npc/` (NPC 交互问候音效)。
- **实现系统与功能**：
  - NPC 零硬编码本地化名称与模型装配；
  - 玩家接近感知与礼貌动作（`soc_courtesy` / `soc_hi`）播放；
  - 面向玩家平滑转向注视；
  - 交互触发信号分发（用于对接后续任务或对话系统）。

---

## 4. 大世界场景与流式管理 (World & Environment)

### 4.1 `src/world/world_prop_manager.gd`
- **文件路径**：[`src/world/world_prop_manager.gd`](file:///e:/DBOFF/src/world/world_prop_manager.gd)
- **职责作用**：场景独立物件调度器。复用已转换的 4,504 个独立 GLB 资产，结合 `objectproperty.json` 自动配置 AABB 碰撞体与视距裁切。
- **对标 OpenDBO-Core 源码**：
  - `DboClient/Lib/NtlPresentation/NtlPLObjectProperty.h` (`CNtlPLObjectProperty`)
  - `DboClient/Lib/NtlPresentation/NtlPLObject.h` (`CNtlPLObject`)
- **数据引用处**：
  - [`res://assets/obj/object/mesh/`](file:///e:/DBOFF/assets/obj/object/mesh/)（4,504 个独立物件模型与材质）；
  - [`res://assets/prop/property/objectproperty.json`](file:///e:/DBOFF/assets/prop/property/objectproperty.json)（物体的 `bbox`, `collision`, `culling_distance`）。
- **实现系统与功能**：
  - 场景物件动态实例化；
  - 基于真实 AABB 生成 Jolt 物理 `BoxShape3D`；
  - 远景视距裁切（`visibility_range_end`），保证超大世界流畅不卡顿。

### 4.2 `src/world/world_chunk_manager.gd`
- **文件路径**：[`src/world/world_chunk_manager.gd`](file:///e:/DBOFF/src/world/world_chunk_manager.gd)
- **职责作用**：大世界九宫格流式区块调度器。根据跟踪目标（玩家/观察摄像机）世界坐标计算区块行列号，按需异步解析 JSON 地形区块数据、通过 `WorldTerrainMeshBuilder` 构建地形网格物理碰撞，并通过 `WorldPropManager` 批量生成场景物体；自动卸载超出视距的远端区块。
- **对标 OpenDBO-Core 源码**：
  - `DboClient/Lib/NtlPresentation/NtlWorldSectorPVS.cpp`
  - `DboServer/Server/GameServer/WorldManager.cpp` & `WorldCell.cpp`
- **数据引用处**：
  - [`res://data/terrain/`](file:///e:/DBOFF/data/terrain/)（50 块大世界地形网格与物件坐标 JSON 数据，如 `res://data/terrain/default_chunks/chunk_10_10.json`）。
- **实现系统与功能**：
  - 空间三维坐标与网格索引转换（`world_to_chunk_coord`）；
  - 九宫格区域动态加载与超视距垃圾回收；
  - 地形网格与物体场景统一管理生命周期。

### 4.3 `src/world/world_skybox.gd`
- **文件路径**：[`src/world/world_skybox.gd`](file:///e:/DBOFF/src/world/world_skybox.gd)
- **职责作用**：大世界多层天空盒控制器。挂载并渲染 OpenDBO 官方提取的 10 款天空盒模型，每帧平滑锁死跟踪当前活动摄像机的全局位移，同时忽略摄像机旋转，完美营造远景无限远的天穹沉浸感。
- **对标 OpenDBO-Core 源码**：
  - `DboClient/Lib/NtlPresentation/NtlPLSky.h` & `NtlPLSky.cpp` (`CNtlPLSky`)
  - `DboClient/Lib/NtlPresentation/NtlWorldSky.cpp`
- **数据引用处**：
  - [`res://assets/obj/world/mesh/`](file:///e:/DBOFF/assets/obj/world/mesh/) 下的 10 款天空盒模型（如 `sky_base.glb`, `sphere_sky_base.glb`, `sky_01.glb` 等）。
- **实现系统与功能**：
  - 动态切换天空球/天空穹顶网格；
  - 摄像机空间位移无死角实时锁定（Camera Tracking）；
  - 天穹自转角度缓慢偏转仿真（天象流转效果）。

### 4.4 `src/world/world_terrain_mesh_builder.gd`
- **文件路径**：[`src/world/world_terrain_mesh_builder.gd`](file:///e:/DBOFF/src/world/world_terrain_mesh_builder.gd)
- **职责作用**：大世界地形网格与物理碰撞生成器。读取 65x65 高度场数据（4,225 个真实顶点高度），使用 Godot 4 原生 `SurfaceTool` 构建 4,096 个地形表面四边形（8,192 个三角面），生成精确的法线、切线与 UV 纹理坐标，并绑定 Jolt 物理引擎的高性能 `ConcavePolygonShape3D`（Trimesh 静态地形碰撞体）。
- **对标 OpenDBO-Core 源码**：
  - `DboClient/Lib/NtlPresentation/NtlWorldSector.h` & `NtlWorldSector.cpp`
  - `DboClient/Lib/NtlPresentation/NtlWorldField.cpp`
- **数据引用处**：
  - 地形高程 JSON 数据（`heights` 浮点数组，网格间距 `step = 4.0` 米，每区块跨度 256.0 米）。
- **实现系统与功能**：
  - 高性能程序化网格生成；
  - 法线平滑插值与 UV 贴图展开；
  - Jolt 物理凹多面体地面碰撞生成。

### 4.5 `src/world/world_scene_driver.gd`
- **文件路径**：[`src/world/world_scene_driver.gd`](file:///e:/DBOFF/src/world/world_scene_driver.gd)
- **职责作用**：大世界主场景总控驱动器（加载于 `scenes/world/main_world.tscn`）。统一协调日光定向光源（DirectionalLight3D）、天空盒（WorldSkybox）、ACES 色调映射环境（WorldEnvironment）、区块流式调度器（WorldChunkManager）、场景物件调度器（WorldPropManager）以及背景音乐（AudioManager）。
- **对标 OpenDBO-Core 源码**：
  - `DboClient/Client/Main/DboMain.cpp`
  - `DboClient/Client/Stage/WorldStage.cpp`
- **数据引用处**：
  - `res://data/terrain/` 与 `table_world_data.json`、`assets/sound/bgm/`。
- **实现系统与功能**：
  - 日漫风格太阳光与软阴影初始化；
  - ACES 高动态范围色调映射与环境光遮蔽（SSAO）；
  - 主摄像机自由漫游与追踪目标绑定；
  - 区域背景音乐自动启播。

---

## 5. 剧情导演与用户界面 (Cinematics & UI)

### 5.1 `src/cinematics/camera_spline_player.gd`
- **文件路径**：[`src/cinematics/camera_spline_player.gd`](file:///e:/DBOFF/src/cinematics/camera_spline_player.gd)
- **职责作用**：3D 摄像机样条运镜播放器。读取 679 条官方样条曲线采样点，平滑插值空间坐标与四元数旋转，复刻时光机（TMQ）过场与绝招特写。
- **对标 OpenDBO-Core 源码**：
  - `DboClient/Lib/NtlSimulation/NtlDTProp.h` & `NtlDTProp.cpp` (`CNtlDTSpline`, `SSplineCurvePt`)
  - `DboClient/Lib/NtlSimulation/NtlSLApi.cpp` (`API_GetDTContainter`)
- **数据引用处**：
  - [`res://assets/prop/property/direct_splines.json`](file:///e:/DBOFF/assets/prop/property/direct_splines.json)（679 条样条曲线与高密度四元数采样点）。
- **实现系统与功能**：
  - 3D 摄像机空间样条运镜平滑播放；
  - 剧情过场镜头推拉摇移；
  - 对应帧触发自定义音效。

### 5.2 `src/ui/hud/dbo_hud.gd`
- **文件路径**：[`src/ui/hud/dbo_hud.gd`](file:///e:/DBOFF/src/ui/hud/dbo_hud.gd)
- **职责作用**：经典龙珠 HUD 界面驱动器。展示生命槽（HP）、气力槽（EP）、怒气槽（3 颗 RP 气珠）与等级徽章。全文本由 `DBOLocalizer` 驱动。
- **对标 OpenDBO-Core 源码**：
  - `DboClient/Client/Gui/SideDialogManager.cpp`
  - `DboClient/Client/Gui/StatusWindowGui.cpp`
- **数据引用处**：
  - `table_text_all_data.json`（`ETC_TEXT` 分类下称号与等级模板）。
- **实现系统与功能**：
  - 玩家生命与气力动态平滑条展示；
  - 3 颗 RP 气珠逐级点亮视觉表现；
  - 纯多语言标签驱动的名称与等级徽章渲染。

---

## 6. 脚本全量盘点索引表

| 序号 | 脚本相对路径 | 类型 / 类名 | 对标 OpenDBO-Core 模块 | 数据依赖文件 |
| :---: | :--- | :--- | :--- | :--- |
| 1 | `src/core/dbo_localizer.gd` | Autoload 单例 (`DBOLocalizer`) | `NtlLocalize` / `LocalizeStringTable` | `assets/tbl/table_text_all_data.json` |
| 2 | `src/core/dbo_table_manager.gd` | Autoload 单例 (`DBOTableManager`) | `CNtlTableContainer` / `CNtlPLPropertyContainer` | `assets/tbl/*.json`, `assets/prop/property/*.json` |
| 3 | `src/core/audio_manager.gd` | Autoload 单例 (`AudioManager`) | `NtlSoundManager` | `assets/sound/*`, `characterproperty.json` |
| 4 | `src/combat/dbo_formula_engine.gd` | `class_name DBOFormulaEngine` | `battle.cpp` / `CFormulaTable` | `assets/tbl/td_formula.json` (3100, 3700, 3900, 3500) |
| 5 | `src/combat/combat_engine.gd` | `class_name DBOCombatEngine` | `char_battle.cpp` / `ETargetBehavior` | `characterproperty.json` (`target_behavior`) |
| 6 | `src/combat/projectile_3d.gd` | `class_name DBOProjectile3D` | `NtlSobProjectile` / `EProjectileEffectType` | `characterproperty.json` (`projectile_effect_type`) |
| 7 | `src/entities/character_visual.gd` | `class_name DBOCharacterVisual` | `CNtlPLCharacter` / `CNtlPLItem` | `assets/obj/object/mesh/*.glb`, `itemproperty.json` |
| 8 | `src/entities/anim_event_dispatcher.gd` | `class_name AnimEventDispatcher` | `SEventAnimHit` / `CNtlTypeAnimTable` | `characterproperty.json` (`animation_table`) |
| 9 | `src/entities/character_base_3d.gd` | `class_name DBOCharacterBase3D` | `CCharacter` / `CPlayer` / `CMonster` | `characterproperty.json` (`speed.walk/run_front`) |
| 10 | `src/entities/dbo_aspect_component.gd` | `class_name DBOAspectComponent` | `AspectState*.cpp` / `StatusTransformTable` | `assets/tbl/table_status_transform_data.json` |
| 11 | `src/entities/dbo_buff_component.gd` | `class_name DBOBuffComponent` | `CBuffManager` / `CBuff` / `eCHARCOND_FLAG` | `assets/tbl/table_skill_data.json` |
| 12 | `src/world/world_prop_manager.gd` | `class_name WorldPropManager` | `CNtlPLObject` / `CNtlPLObjectProperty` | `assets/obj/object/mesh/*.glb`, `objectproperty.json` |
| 13 | `src/world/world_chunk_manager.gd` | `class_name WorldChunkManager` | `WorldManager` / `WorldCell` / `PVS` | `data/terrain/*.json` |
| 14 | `src/world/world_skybox.gd` | `class_name WorldSkybox` | `CNtlPLSky` / `NtlWorldSky` | `assets/obj/world/mesh/*.glb` |
| 15 | `src/world/world_terrain_mesh_builder.gd` | `class_name WorldTerrainMeshBuilder` | `NtlWorldSector` / `NtlWorldField` | `data/terrain/*.json` (heights, step) |
| 16 | `src/world/world_scene_driver.gd` | `class_name WorldSceneDriver` | `DboMain` / `WorldStage` | `scenes/world/main_world.tscn`, `assets/sound/bgm/` |
| 17 | `src/core/free_look_camera_3d.gd` | `class_name FreeLookCamera3D` | `CNtlPLCamera` / `FreeCamera` | 鼠标与按键输入系统 |
| 18 | `src/cinematics/camera_spline_player.gd` | `class_name CameraSplinePlayer` | `CNtlDTSpline` / `API_GetDTContainter` | `assets/prop/property/direct_splines.json` |
| 19 | `src/ui/hud/dbo_hud.gd` | `class_name DBOHUD` | `StatusWindowGui` | `table_text_all_data.json` |
| 20 | `src/entities/character_factory.gd` | `class_name DBOCharacterFactory` | `CNtlPLCharacter` / `CNtlPLItem` | `assets/obj/character/*`, `table_item/mob/npc_data.json` |
| 21 | `src/entities/player_controller_3d.gd` | `class_name DBOPlayerController3D` | `ThirdPersonCamera` / `CPlayer` | `characterproperty.json`, `assets/sound/*`, `data/game_constants.json` |
| 22 | `src/entities/mob_entity_3d.gd` | `class_name DBOMobEntity3D` | `CMonster` / `CBotAiState_*` | `table_mob_data.json`, `table_text_all_data.json` |
| 23 | `src/entities/npc_entity_3d.gd` | `class_name DBONpcEntity3D` | `CNpc` / `WorldStage` | `table_npc_data.json`, `table_text_all_data.json` |
| 24 | `src/core/dbo_event_bus.gd` | Autoload 单例 (`DBOEventBus`) | `NtlSimulation` / `EventBus` | 全局事件解耦总线（数值、战斗、目标、任务、UI广播） |
| 25 | `src/core/dbo_inventory_manager.gd` | Autoload 单例 (`DBOInventoryManager`) | `ItemTable` / `NewbieTable` / `NtlItem` | `data/newbie_table.json`, `assets/tbl/table_item_data.json` |
| 26 | `src/core/dbo_quest_manager.gd` | Autoload 单例 (`DBOQuestManager`) | `CNtlTSTrigger` / `CQuest` / `DboTSMain` | `data/quests/quest_triggers.json` (2,886个任务剧本) |
| 27 | `src/world/world_spawn_manager.gd` | `class_name WorldSpawnManager` | `SpawnTable` / `BotState_Spawning` | `assets/tbl/spawn_mob_*.json`, `assets/tbl/spawn_npc_*.json` |
| 28 | `src/core/dbo_save_manager.gd` | `class_name DBOSaveManager` | `CPlayer` / `NewbieTable` / `NtlItem` | `user://saves/account_meta.json`, `user://saves/char_*.json` |
| 29 | `src/ui/lobby/character_lobby_ui.gd` | `class_name CharacterLobbyUI` | `LocalizeStringTable` / `CharacterStage` | `assets/tex/texture/gui/pc_create*.png`, `data/newbie_table.json` |
| 30 | `src/ui/lobby/character_lobby_stage.gd` | `class_name CharacterLobbyStage` | `LobbyStage.cpp` / `CharacterStage.cpp` | `data/terrain/select_character_chunks/`, `assets/obj/character/*` |
| 31 | `src/core/dbo_material_helper.gd` | `class_name DBOMaterialHelper` | `CNtlPLCharacter` / `CNtlPLObject` (UV Pipeline) | `assets/obj/**`, `assets/tex/**` |

---

## 7. 服务端与源码衍生数据仓库索引表 (Server & Source Extracted Data)

依据 OpenDBO-Core 全量源码与私服执行环境解析提取，并持久化落盘至 `E:/DBO_Offline/data` 与 `E:/DBOFF/data`：

| 数据文件路径 | 记录数 / 规模 | 对应 OpenDBO-Core 原版结构体 / 源码文件 | 包含核心内容 |
| :--- | :--- | :--- | :--- |
| `data/newbie_table.json` | 7 类种族职业预设 | `sNEWBIE_TBLDAT` (`NewbieTable.h`) | 各族初始出生点、朝向、绑定点、初始穿戴装备、初始技能槽、快捷栏配置 |
| `data/portal_table.json` | 61 个传送点拓扑 | `sPORTAL_TBLDAT` (`PortalTable.h`) | 全世界城镇/营地传送网络、三维落脚点 `vLoc`、朝向 `vDir`、索尼费用消耗表 |
| `data/world_table.json` | 106 个世界空间 | `sWORLD_TBLDAT` (`WorldTable.h`) | 大世界/地下城/城镇出入口坐标 `outWorldLoc`、出生点 `start1/2`、关联 WPS |
| `data/game_constants.json` | 4 大核心维度 | `NtlMovement.h`, `NtlCharacterState.h`, `CharacterAttPC.cpp` | 正统幼年/成年跑速 (7.0/8.0m/s)、滑步冲刺 (25.0m/s)、极速破空 (40.0m/s)、26 类状态机枚举与回气回血公式 |
| `data/official_default_keybindings.json` | 92 个按键动作映射 | `ActionMap.cpp:404-450`, `NtlActionMapDef.h` | 官方原生键位映射（Tab 选怪、F 攻击、X 打坐、Z 聚气、R 格挡等） |
| `data/quests/quest_triggers.json` | 2,886 个任务剧本 | `CNtlTSTrigger` (`ts/quests/*.t`) | 全游戏任务触发树：对话、击杀目标、搜集道具、侦察镜扫描、结算奖励 |
| `data/triggers/object_triggers.json` | 564 个交互实体 | `ts/objtrigger/*.t` | 场景机关门升降、神龙祭坛、宝箱开启、时空裂缝光圈交互 |
| `data/triggers/pc_triggers.json` | 154 个角色触发器 | `ts/pctrigger/*.t` | 转职仪式、等级里程碑、新手教学触发逻辑 |
| `data/scripts/world_play_scripts.json` | 523 个副本波次 | `wps/wps/*.wps` | CCBD 爬塔怪物波次、地下城机关限时判定与通关条件 |
| `data/scripts/spawn_play_scripts.json` | 357 个行为脚本 | `sps/sps/*.sps` | NPC/怪物巡逻路点、特定位置冒泡对白与情境动作 |
| `data/scripts/time_quest_scripts.json` | 13 个时光战役 | `tqs/tqs/*.tqs` | TMQ 电影级时空战役剧本推进 |
| `data/scripts/ai_scripts.json` | 8 个高阶首领 AI | `ais/ais/*.ais` | 顶级 Boss 特殊阶段技能与狂暴行为树 |

