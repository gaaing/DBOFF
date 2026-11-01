# DBOFF 架构施工执行报告（第一阶段与核心骨架搭建）

## 1. 施工概述

按照规划与 GEMINI.md 核心规范，已全面完成 **阶段 1 底层核心数据与本地化单例** 及 **各层核心驱动架构脚本** 的落地建设：
- 严格遵循**零文本硬编码**原则，所有文字展示均通过 `DBOLocalizer` 映射驱动；
- 参考 **OpenDBO-Core** C++ 数据结构与战斗规则，实现了高性能的惰性按需数据缓存（`DBOTableManager`）；
- 建立了基于共享 `Skeleton3D` 的多部件换装方案（`DBOCharacterVisual`），彻底解耦网格与骨骼动画；
- 编写了毫秒级动作事件调度器（`AnimEventDispatcher`），精准复刻端游受击判定、震屏与气功弹发射；
- 实现了九宫格大世界流式调度（`WorldChunkManager`）与基于 `objectproperty.json` 的场景物件物理与视距剔除（`WorldPropManager`）。

---

## 2. 交付的 Godot 核心代码清单

| 类别 / 目录 | 脚本文件 | 核心职责与设计说明 |
| :--- | :--- | :--- |
| **核心单例 (Core)** | [`dbo_localizer.gd`](file:///e:/DBOFF/src/core/dbo_localizer.gd) | 全局 Autoload 单例。基于 `table_text_all_data.json` 官方全并集文本库，提供分类标签索引与 BBCode 样式富文本分发，严格杜绝任何硬编码文本。 |
| **核心单例 (Core)** | [`dbo_table_manager.gd`](file:///e:/DBOFF/src/core/dbo_table_manager.gd) | 全局 Autoload 单例。参考 OpenDBO-Core 的 `CNtlTableContainer`，实现 274 个数值表与 6 个属性表的高速惰性缓存，随用随读，启动毫秒响应。 |
| **核心单例 (Core)** | [`audio_manager.gd`](file:///e:/DBOFF/src/core/audio_manager.gd) | 全局 Autoload 单例。管理 BGM 双通道平滑交叉淡入淡出、2D UI 音效对象池与 3D 空间发声定位（脚步、受击、爆炸）。 |
| **角色与表现 (Entities)** | [`character_visual.gd`](file:///e:/DBOFF/src/entities/character_visual.gd) | 多部件换装渲染器。头部、上衣、裤子、鞋子部件作为独立 `MeshInstance3D` 挂入统一种族 `Skeleton3D`；支持骨骼挂点（武器/背包）与体型缩放。 |
| **角色与表现 (Entities)** | [`anim_event_dispatcher.gd`](file:///e:/DBOFF/src/entities/anim_event_dispatcher.gd) | 动作时间轴事件派发器。根据 `characterproperty.json` 的帧时间，精准发射打击、脚步、受击震屏、气功弹道信号。 |
| **角色与表现 (Entities)** | [`character_base_3d.gd`](file:///e:/DBOFF/src/entities/character_base_3d.gd) | 角色物理与属性基类。集成 Jolt 3D 物理运动、重力、移速参数绑定与受击击飞冲量衰减逻辑。 |
| **大世界流式 (World)** | [`world_prop_manager.gd`](file:///e:/DBOFF/src/world/world_prop_manager.gd) | 场景物件调度器。复用 4,504 个独立 GLB，读取 `objectproperty.json` 自动配置 Jolt AABB 物理碰撞盒与视距裁切（Visibility Range）。 |
| **大世界流式 (World)** | [`world_chunk_manager.gd`](file:///e:/DBOFF/src/world/world_chunk_manager.gd) | 九宫格大世界区块动态流式管理器。玩家移动时实时调度换入换出，彻底规避超大世界内存膨胀。 |
| **战斗系统 (Combat)** | [`combat_engine.gd`](file:///e:/DBOFF/src/combat/combat_engine.gd) | 战斗规则引擎。参考 OpenDBO-Core 算法，计算物理/能量命中、防御减免、等级压制差修正、暴击与击飞向量（Push/KnockDown/Toss）。 |
| **战斗系统 (Combat)** | [`projectile_3d.gd`](file:///e:/DBOFF/src/combat/projectile_3d.gd) | 气功弹道投射器。对接 `characterproperty.json` 的弹道类型（普通弹、持续光束、操气弹曲线追踪、魔空包围弹）。 |
| **导演运镜 (Cinematics)**| [`camera_spline_player.gd`](file:///e:/DBOFF/src/cinematics/camera_spline_player.gd) | 3D 摄像机样条运镜播放器。基于 `direct_splines.json` 679 条预置轨迹，平滑插值空间坐标与四元数旋转，复刻 TMQ 与绝招运镜。 |
| **界面驱动 (UI)** | [`dbo_hud.gd`](file:///e:/DBOFF/src/ui/hud/dbo_hud.gd) | 经典 HUD 驱动器。生命槽、气力槽、3 颗 RP 怒气珠，所有展示文本由 `DBOLocalizer` 动态下发。 |

---

## 3. 工程配置更新 (`project.godot`)

已向 [`project.godot`](file:///e:/DBOFF/project.godot) 成功注入自动加载单例项：
```ini
[autoload]

DBOLocalizer="*res://src/core/dbo_localizer.gd"
DBOTableManager="*res://src/core/dbo_table_manager.gd"
AudioManager="*res://src/core/audio_manager.gd"
```

---

## 4. 后续轻量化纯动画导出的工具准备

对于用户要求的“仅包含骨骼层级节点与动画采样轨道的轻量级 `.glb`”，在 `E:\DBO_Offline\tools\` 中已经备齐底层 RenderWare `.anm` 采样解析内核。下一步可直接批量将人族/那美克/魔人各动作按种族导出为仅几 KB ~ 十几 KB 的纯动画 GLB，作为独立 `AnimationLibrary` 挂入 `character_visual.gd`。
