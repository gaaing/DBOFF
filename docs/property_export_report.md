# DBO 属性与导演演出配置文件导出报告 (Property & Direction Assets)

## 1. 任务概述与完成清单

按照要求，已将 `E:\DBO_Offline\pipeline\raw_source\extracted\prop\property\` 下的原版 6 个核心二进制属性及演出配置彻底破译反序列化，并无损转码为适合 Godot 4 解析的结构化 JSON 格式，统一放置于 `E:\DBOFF\assets\prop\property\`。

### 目标进度清单
- [x] **目标 1**: 破译并导出 `characterproperty.rdf` -> `characterproperty.json` (1,499 角色属性, 34.28 MB)
- [x] **目标 2**: 破译并导出 `itemproperty.rdf` -> `itemproperty.json` (5,930 道具装备属性, 15.94 MB)
- [x] **目标 3**: 破译并导出 `objectproperty.rdf` -> `objectproperty.json` (4,521 场景物体属性, 5.49 MB)
- [x] **目标 4**: 破译并导出 `direct.dsf` -> `direct_splines.json` (679 条过场摄像机样条曲线轨迹, 1.29 MB)
- [x] **目标 5**: 破译并导出 `direct.dpf` -> `direct_project.json` (704 个导演树层级节点 / 25 目录, 89.89 KB)
- [x] **目标 6**: 破译并导出 `tenkaichidirection.dtf` -> `tenkaichi_direction.json` (11 组天下第一武道会主持与观众控制器, 9.06 KB)
- [x] **目标 7**: 编写详细作用说明文档与架构集成指南

---

## 2. 导出文件清单与规格统计

| 原始文件 | 导出目标 (Godot JSON) | 数据条目数 | 导出文件大小 | 对应核心 C++ 类 (OpenDBO-Core) |
| :--- | :--- | :--- | :--- | :--- |
| `characterproperty.rdf` | [`characterproperty.json`](file:///e:/DBOFF/assets/prop/property/characterproperty.json) | 1,499 | 34.28 MB | `CNtlPLCharacterProperty` |
| `itemproperty.rdf` | [`itemproperty.json`](file:///e:/DBOFF/assets/prop/property/itemproperty.json) | 5,930 | 15.94 MB | `CNtlPLItemProperty` |
| `objectproperty.rdf` | [`objectproperty.json`](file:///e:/DBOFF/assets/prop/property/objectproperty.json) | 4,521 | 5.49 MB | `CNtlPLObjectProperty` |
| `direct.dsf` | [`direct_splines.json`](file:///e:/DBOFF/assets/prop/property/direct_splines.json) | 679 | 1.29 MB | `CNtlDTContainer` / `CNtlDTSpline` |
| `direct.dpf` | [`direct_project.json`](file:///e:/DBOFF/assets/prop/property/direct_project.json) | 704 (25目录+679对象) | 89.89 KB | `CDTEditorDoc` / `CObjectPane` |
| `tenkaichidirection.dtf` | [`tenkaichi_direction.json`](file:///e:/DBOFF/assets/prop/property/tenkaichi_direction.json) | 11 状态机控制器 | 9.06 KB | `CNtlSLTBCrowdManager` / `CNtlSLCENode` |

---

## 3. 六大文件的具体功能与在游戏开发中的作用详解

### 3.1 `characterproperty.rdf` (`characterproperty.json`) - 角色模型与动作事件核心属性表
- **定位**：游戏内所有角色、怪物、NPC、载具的**动作触发引擎**。
- **核心数据内容**：
  1. **网格与贴图关联**：`mesh_file`、`mesh_path`、`texture_path`、`sound_path`。
  2. **动画映射与事件表 (`animation_table`)**：每个动画不仅记录了动作名与时长，还嵌入了精确到毫秒的时间轴事件（`events`）：
     - `EVENT_ANIM_HIT`：攻击判定帧、击中伤害、击飞/击退模式（`TARGET_BEHAVIOR_PUSH` / `KNOCK_DOWN`）、气功弹类型（能量弹、魔贯光杀炮、气圆斩、追尾气功弹、死亡光线）、发射骨骼（`chBoneName`）、弹道飞行速度、受击音效与震屏参数（`camera_shake_factor`）。
     - `EVENT_ANIM_FOOT_STEP`：脚步接触地面的时间点与左右脚标记，用于触发扬尘粒子和地面材质脚步声。
     - `EVENT_ANIM_VISUAL_EFFECT` & `EVENT_ANIM_LINK_EFFECT`：在动作特定帧绑定气劲、爆气、聚气发光等粒子特效。
  3. **骨骼缩放矩阵与变形 (`bone_data`)**：记录了体型调整（如魔人肥胖/矮小、那美克星人修长）的各个骨骼缩放系数。
  4. **特写摄像机坐标 (`face_camera`)**：NPC 对话时摄像机的最佳 Focus 位置与 LookAt 目标点。
  5. **移动基础移速 (`speed`)**：角色的标准前向步行速度与冲刺奔跑速度。

### 3.2 `itemproperty.rdf` (`itemproperty.json`) - 道具武器挂接与强化光效属性表
- **定位**：所有武器、防具、饰品、背部挂件在角色身体上的**空间定位与强化特效库**。
- **核心数据内容**：
  1. **挂接骨骼与槽位**：`equip_slot_type` 与 `attach_offset`（精确到三维空间向量），用于让单手剑、法杖、机械枪炮、龟壳、翅膀等精确挂在玩家的左右手、背部或腰部骨骼上。
  2. **刀光轨迹与残影系统 (`trace_event`)**：挥动冷兵器或拳脚时拖尾残影（Trace）的起点骨骼（`strStartBoneName`）、末端骨骼（`strEndBoneName`）、残影生命周期、采样点数与渐变颜色（`start_color`, `end_color`）。
  3. **装备强化特效矩阵 (`upgrade_effect`)**：装备从 +1 到 +15 强化时，绑定的 16 级光效粒子名（`szEffect`），以及发光起点与终点骨骼（`bone1`, `bone2`）。

### 3.3 `objectproperty.rdf` (`objectproperty.json`) - 大世界场景物件交互与物理属性表
- **定位**：世界地图中 4,500 多个独立场景装饰、房屋建筑、废墟、机关门、树木草丛的**渲染/物理/声效配置库**。
- **核心数据内容**：
  1. **物理碰撞与包围盒 (`bbox`, `collision`)**：是否阻挡玩家移动、服务端与客户端的精准轴对齐包围盒（AABB Min/Max）。
  2. **可见性裁切与阴影 (`culling_distance`, `shadow`, `apply_pvs`)**：远距离 LOD 裁切距离、动态阴影投射标记、是否参与潜在可见集（PVS）剔除以保证超大地图帧率稳定。
  3. **UV 动画与动态机关 (`uv_anim_speed`, `anim_file`)**：瀑布水流、传送带、闪烁霓虹灯等材质 UV 移动速率，以及门打开、升降机运转等物件动画。
  4. **场景环境音效 (`sound_property`)**：如营地篝火噼啪声、工厂机械轰鸣声、风铃声的衰减距离（`sound_dist`, `sound_decay_dist`）与循环属性。

### 3.4 `direct.dsf` (`direct_splines.json`) - 剧情过场摄像机空间轨迹样条库
- **定位**：时光机任务（TMQ）、主线剧情过场（TLQ）、必杀技特写动画的**3D 摄像机与角色飞行导轨**。
- **核心数据内容**：
  - 共 679 条样条曲线（Splines）。
  - **控制点 (`control_points`)**：空间三维坐标、三轴旋转角与到达时间点。
  - **平滑插值样条点 (`curve_points`)**：基于 Catmull-Rom 或 Bezier 生成的高密度平滑轨迹，每个采样点包含世界位置 `pos` 与旋转四元数 `quat`，确保摄像机在镜头运镜推拉摇移时丝滑无卡顿。
  - **运镜音效绑定 (`custom_sound_data`)**：在镜头运镜经过特定帧时同步播放的环境转场音效。

### 3.5 `direct.dpf` (`direct_project.json`) - 导演演出工程树状结构组织表
- **定位**：导演演出工具（DTEditor）的**项目工程组织树**。
- **核心数据内容**：
  - 维护了 25 个顶层分类文件夹（如 `TMQ_01`, `HTB_Human`, `HTB_Namek`, `HTB_Majin`, `TLQ_Cutscenes`, `Vehicle_Intro` 等）。
  - 将 679 个样条对象组织成层级结构（`hierarchy`），指明每一条摄像机曲线属于哪个 TMQ 关卡、哪种合体必杀技（HTB）或哪段剧情动画，供游戏引擎在触发特定剧情事件时按树状层级索引并调用。

### 3.6 `tenkaichidirection.dtf` (`tenkaichi_direction.json`) - 天下第一武道会赛场导演与气氛控制器
- **定位**：天下第一武道会（Budokai Tournament）的**赛场气氛与裁判演出状态机**。
- **核心数据内容**：
  - 包含 11 个比赛阶段的控制器：
    1. `Basic_Step`（基础环境循环）
    2. `Match_Ready`（参赛选手入场准备）
    3. `Stage_Ready`（擂台倒计时准备）
    4. `Stage_Run`（激烈交战期）
    5. `Knock_Down`（击倒击飞倒数）
    6. `KO`（彻底击败震撼时刻）
    7. `HTB`（爆发高级连击终结技）
    8. `End_Time`（时间耗尽判定）
    9. `Stage_Finish`（单局结束）
    10. `Match_Finish`（全场比赛决胜）
    11. `Award`（颁奖典礼与狂欢）
  - **节点驱动 (`nodes`)**：
    - `JUDGE`：裁判员移动位置（`referee_pos`）、转向（`angle_y`）、奔跑/慢步速度（`move_speed`）、裁判倒数解说文本语音 ID（`narration_ids`）。
    - `EFFECT`：擂台四周烟花、聚光灯、彩带喷射效果。
    - `SOUND`：万名观众欢呼、呐喊、倒喝彩与解说员广播。

---

## 4. 在 Godot 4 项目中的集成方案

1. **角色控制器加载**：通过 `FileAccess.get_file_as_string("res://assets/prop/property/characterproperty.json")` 解析，在角色播放特定动画时，使用定时器或 `AnimationPlayer` 方法轨道精准响应 `EVENT_ANIM_HIT` 发射气功弹，以及根据 `bbox_anim` 调整角色碰撞体高宽。
2. **场景物件实例化**：在大世界加载区块时，读取 `objectproperty.json`，根据 `collision` 决定是否附加 `CollisionShape3D`，根据 `culling_distance` 设置网格的 `visibility_range_end`。
3. **TMQ 与必杀技摄像机运镜**：读取 `direct_splines.json`，在 Godot 中通过 `Path3D` + `PathFollow3D` 映射 `curve_points` 的位置和四元数，即可 100% 还原端游高水准的运镜特写效果。
