# 致命 Bug 修复、全量去硬编码与 UI 表驱动架构实施报告

## 目标清单与完成进度

- [x] **任务 0：GUI 资源全量提取与解析** (进度: 100%)
  - 将 `E:\DBO_Offline\pipeline\raw_source\extracted\gui\gui` 下 639 个文件（311 个 `.frm`、228 个 `.srf`、74 个 `.rsr` 及相关字体粒子）全量提取至 `E:\DBOFF\assets\gui`。
  - 编写解析管线，将全量 `.srf`、`.rsr` 与 `.frm` 编译生成统一索引字典 `ui_atlas_dictionary.json`（收录 5959 个切片表面）与 `ui_layout_dictionary.json`（收录 311 个窗口布局定义）。
- [x] **任务 1：致命 Bug 与脚本冲突按优先级修复** (进度: 100%)
  - `src/entities/dbo_buff_component.gd`：修复 DOT 伤害导致遍历字典时被修改崩溃问题。
  - `src/entities/mob_entity_3d.gd` & `src/entities/npc_entity_3d.gd`：修复未声明方法调用 `DBOLocalizer.get_text_by_tag`。
  - `src/world/world_spawn_manager.gd`：修复对怪物写入未声明属性 `wander_range`。
  - `src/entities/anim_event_dispatcher.gd`：切断 Tween 闭包对 `evt` 的变量捕获。
  - `src/entities/player_controller_3d.gd`：消除普攻双重扣血，统一收口打击管线。
  - `src/ui/lobby/character_lobby_stage.gd`：修复模型换装帧内同名节点重影与摄像机矩阵空指针。
- [x] **任务 2：硬编码全量清理与表驱动重构** (进度: 100%)
  - UI 切片坐标去硬编码：`character_lobby_ui.gd` 上百处 `Rect2` 全部迁移为 `DBOUIManager.create_atlas` / `get_srf_rect` 动态表驱动。
  - 捏脸变换与地面偏移去硬编码：常量字典剥离为 `res://assets/prop/property/character_offsets.json` 并由 `DBOTableManager` 动态提供。
  - 战斗免伤、格挡减伤、冲量数值与命中常数去硬编码：严格从 `td_formula.json` 通过 `DBOTableManager.get_formula_rate()` 动态检索。
  - 内联 Shader 字符串彻底剥离：独立化为 `.gdshader` 独立文件并通过 `preload()` 挂载。
- [x] **任务 3：UI 双风格热切换架构支撑** (进度: 100%)
  - 构建 `DBOUIManager` 核心管理系统并注册至 `project.godot` 全局单例。
  - 抽象出 `CLASSIC_BITMAP`（原版位图九宫格）与 `MODERN_VECTOR`（现代矢量 StyleBoxFlat/Shader）无缝切换体系。
- [x] **任务 4：擂台、远景山体与角色视觉恢复与着色器深度冲突排查** (进度: 100%)
  - 根除 `sky_layer.gdshader` 与 `sky_gradient.gdshader` 中多余的 `depth_test_disabled;`，恢复正常深度测试管线。
  - 扩展大厅天球半径（`sky_scale = 3.0`），彻底解决云层与死白遮挡覆写擂台、角色、树干与远景山体的问题。

---

## 一、 致命 Bug 修复详情

### 1. `src/entities/dbo_buff_component.gd`（遍历字典时修改闪退）
- **问题定位**：在 `_process` 周期内遍历 `_active_buffs.keys()` 时，当 DOT 触发目标 `take_damage()`，可能打断睡眠 Buff 或使角色死亡触发结算，导致 `remove_buff()` 在迭代循环内直接修改 `_active_buffs`，抛出引擎级闪退 `Dictionary was modified during iteration`。
- **修复方案**：
  - 遍历键列表显式调用浅拷贝：`for b_id in _active_buffs.keys().duplicate():`；
  - 循环内部增加存在性防御检查：`if not _active_buffs.has(b_id): continue`；
  - 在 `_apply_buff_tick()` 执行后再次防御：若 Buff 在滴答中被清理则立即跳过。

### 2. `src/entities/mob_entity_3d.gd` & `src/entities/npc_entity_3d.gd`（未声明方法调用）
- **问题定位**：实体加载表格名字时调用了不存在的方法 `DBOLocalizer.get_text_by_tag("MOB_DATA", ...)`。
- **修复方案**：
  - 统一修正为 `DBOLocalizer.get_text("MOB_DATA", mob_tblidx)` 与 `DBOLocalizer.get_text("NPC_DATA", npc_tblidx)`。

### 3. `src/world/world_spawn_manager.gd`（怪物属性名不匹配）
- **问题定位**：刷怪管理器尝试向怪物节点写入 `mob_node.wander_range`，而基类/怪物实体定义的游走巡逻半径实际为 `patrol_radius`。
- **修复方案**：
  - 修正为 `mob_node.patrol_radius = float(entry.get("wander_range", 10.0))`。

### 4. `src/entities/anim_event_dispatcher.gd`（闭包变量捕获覆盖）
- **问题定位**：在循环创建 Tween 事件回调时使用 `func(): _dispatch_single_event(evt)`，因闭包捕获了循环变量 `evt` 的引用，当动画触发时所有事件回调全部只派发该动作的最后一个事件。
- **修复方案**：
  - 切断闭包引用，改用 Godot 原生 Callable 参数绑定：`tween.tween_callback(_dispatch_single_event.bind(evt))`。

### 5. `src/entities/player_controller_3d.gd`（伤害双重扣除）
- **问题定位**：在 `_process_auto_attack_step` 计时结束时直接调用了一次 `target.take_damage()`；而随后动画播放由 `AnimEventDispatcher` 派发 `hit_event_triggered` 时，又通过 `DBOCombatEngine.calculate_attack` 结算了一次伤害，导致 1 次攻击产生 2 次扣血。
- **修复方案**：
  - 移除了 `_process_auto_attack_step` 中直接扣血的逻辑；
  - 连接 `event_dispatcher.hit_event_triggered` 至 `_on_anim_hit_event`；
  - 普攻连击段数的加成比例（`chain_bonus_rate`）作为参数打包入打击判定事件，统一交付 `DBOCombatEngine.calculate_attack` 结算，确保全游戏单次打击入口唯一。

### 6. `src/ui/lobby/character_lobby_stage.gd`（同名节点重影与矩阵空指针）
- **重影问题**：在 `_load_character_model` 与初始化清理中遍历 `model_mount.get_children()` 调用 `queue_free()`，因帧内未脱离场景树，下一行立即 `add_child` 造成同名节点重影冲突。
  - **修复**：在 `child.queue_free()` 之前显式调用 `model_mount.remove_child(child)` 立即物理剥离。
- **矩阵空指针**：`_on_lens_flare_draw` 在摄像机或自身未完全就绪进入树时执行 `lobby_camera.unproject_position()`。
  - **修复**：函数入口增加严密防御：`if not is_inside_tree() or lobby_camera == null or not lobby_camera.is_inside_tree() ...: return`。

---

## 二、 全量硬编码清理与表驱动重构

### 1. UI 切片坐标迁移至表驱动
- **现状**：`character_lobby_ui.gd` 原先写死近百处手写 `Rect2(x, y, w, h)` 裁剪坐标。
- **改造后**：
  - 编写并执行了 `.srf` / `.frm` / `.rsr` 统一编译脚本，生成 `res://assets/gui/ui_atlas_dictionary.json`；
  - `character_lobby_ui.gd` 全面迁移为通过 `_get_srf_atlas("srfKey")` 与 `get_srf_rect("srfKey")` 动态取值；
  - 支持官方原版切片名（如 `srfBtnLeftRotUp`, `srfNormalBtnUp`, `srfDelBtlUp`）以及功能标识映射。

### 2. 捏脸变换矩阵与地面偏移配置化
- **现状**：`character_visual.gd` 的 `HEAD_TRANSFORM_CONFIGS` 与 `character_factory.gd` 的 `MODEL_GROUND_OFFSETS` 写死在代码中。
- **改造后**：
  - 移出至标准 JSON 配置文件：`res://assets/prop/property/character_offsets.json`；
  - 在 `DBOTableManager` 扩充 `get_character_offsets()`；
  - 脚本内部通过静态缓存按需载入，支持热更新调整全种族脚底地面高度对齐与头部发型缩放。

### 3. 战斗公式数值与冲量参数去硬编码
- **现状**：
  - 基础免伤：`damage - int(def * 0.3)`
  - 格挡减伤：`damage * 0.4`
  - 击飞冲量：`Vector3(8.0, 14.0, 16.0)`
  - 命中判定：`check_hit(50, 20, ...)`
- **改造后**：
  - 在 `DBOTableManager` 增加 `get_formula_rate(formula_index, rate_idx, fallback)` 统一查询接口；
  - `character_base_3d.gd` 基础免伤系数通过 `DBOTableManager.get_formula_rate(3200, 1, 0.3)` 检索；
  - `player_controller_3d.gd` 格挡减伤比例通过 `DBOTableManager.get_formula_rate(102, 3, 0.4)` 检索（对标 OpenDBO: `FormulaTable[102][3]`）；
  - `combat_engine.gd` 击退/击倒/HTB浮空冲量分别通过公式 `7400[2]` (8.0)、`6400[3]` (14.0)、`7400[1]` (6.0)、`6400[4]` (16.0) 检索；
  - `dbo_formula_engine.gd` 命中基准数值通过 `5900[1]` (50.0) 与 `5600[2]` (20.0) 检索，彻底消灭脚本内硬编码数值。

### 4. 内联 Shader 字符串彻底剥离
- 全部剥离并创建独立着色器文件：
  - [sky_gradient.gdshader](file:///e:/DBOFF/src/shaders/sky_gradient.gdshader)
  - [sky_layer.gdshader](file:///e:/DBOFF/src/shaders/sky_layer.gdshader)
  - [character_face.gdshader](file:///e:/DBOFF/src/shaders/character_face.gdshader)
  - [character_skin.gdshader](file:///e:/DBOFF/src/shaders/character_skin.gdshader)
  - [foliage_sway.gdshader](file:///e:/DBOFF/src/shaders/foliage_sway.gdshader)
- 对应脚本（`world_skybox.gd`, `character_visual.gd`, `dbo_material_helper.gd`）均改用 `preload()` 挂载，提升引擎编译性能与维护灵活性。

---

## 三、 UI 双风格热切换架构与全局单例

### 1. 全局单例与自动加载规范对齐
- **Autoload 命名规范**：遵循 Godot 规范，去除了 `dbo_ui_manager.gd` 顶部的 `class_name DBOUIManager`，与工程其他 Autoload（`DBOTableManager`、`DBOLocalizer`、`DBOEventBus`）保持一致，彻底根除了 `Class "DBOUIManager" hides an autoload singleton` 的编译冲突；
- **接口全局可用性**：作为全局 Autoload 节点注入 `/root/DBOUIManager`，对外提供标准的实例方法与信号（`get_srf_rect`, `create_atlas`, `get_srf_entry`, `ui_style_changed`），支持工程各处直接调用；
- 维护 `UIStyleMode` 枚举：
  - `CLASSIC_BITMAP`：原版 DBO 位图切片模式（输出 `AtlasTexture` / `StyleBoxTexture` 九宫格）；
  - `MODERN_VECTOR`：现代纯矢量/着色器模式（输出带圆角、流光与半透明扁平背景的 `StyleBoxFlat`）；
- 双风格切换信号统一打通至全局总线 `DBOEventBus.ui_style_changed` 与 `DBOUIManager.ui_style_changed`；
- 业务 UI 脚本仅负责业务状态、选角数据流转与信号广播，实现逻辑层与视觉表现层彻底解耦。

---

## 五、 擂台、远景山体与角色视觉恢复与着色器深度冲突排查

### 1. 现象与冲突定位
- **问题现象**：在选角/创角大厅中，沙鲁游戏擂台（`08_C_CELLRING_003`）、素体角色（Avatar）以及远景山体（`D0_TUTORIAL_002`）完全消失不可见，画面中下部被大片实心白云墙覆盖，仅上方悬浮有部分椰子树叶。
- **根本原因排查**：
  1. **透明通道着色器深度测试被禁用冲突**：
     - 在内联 Shader 剥离过程中，`res://src/shaders/sky_layer.gdshader` 与 `sky_gradient.gdshader` 的 `render_mode` 中误加入了 `depth_test_disabled;`。
     - 在 Godot 4 的多渲染管线中，不透明几何体（角色位于 4m、擂台位于 6m、远景山体位于 384m）在 Opaque Pass 首先渲染并写入深度缓冲（Z-buffer）。
     - 随后的 Transparent Pass 中，天穹模型（`sky_blended0t.glb`）使用 `sky_layer.gdshader` 渲染官方云层贴图 `cloud_011.png`。
     - 由于 `depth_test_disabled;` 指示光栅化器彻底无视深度缓冲比较，导致原本应在视线后方的天穹云层网格强制覆写了整个画面的前景色。而 `cloud_011.png` 下半部为不透明死白云块，进而将更靠近摄像机的擂台、角色与山体完全遮挡掩埋。
  2. **天穹半径与远景山体物理跨度匹配**：
     - 官方大厅场景远景山体（如 `D0_TUTORIAL_002`）在世界坐标中距离擂台中心直线距离约为 384.4 米。
     - 初始天穹穹顶缩放 `sky_scale = 1.0` 使得天穹半径约为 338 米，导致远景山体物理位置穿透到了天球外侧。

### 2. 修复实施
- **着色器深度测试恢复**：
  - 从 [sky_layer.gdshader](file:///e:/DBOFF/src/shaders/sky_layer.gdshader) 与 [sky_gradient.gdshader](file:///e:/DBOFF/src/shaders/sky_gradient.gdshader) 中彻底移除 `depth_test_disabled;`，严格保留 `depth_draw_never;`。
  - 透明云层与天穹网格恢复默认 Z-test（`GL_LEQUAL`）：当光栅化发现像素深度大于深度缓冲中已存在的不透明物体（4m~384m）时，深度测试失败，自动放弃绘制该像素；仅在天空留白背景处执行渲染。
- **天穹视距与包围盒适配**：
  - 在 [character_lobby_stage.gd](file:///e:/DBOFF/src/ui/lobby/character_lobby_stage.gd) 中将 `_skybox_instance.sky_scale` 调整为 `3.0`，使天球有效半径延伸至 1014 米，完整包裹视距内的远景地貌与山体模型，实现正统远景景深与无限远流云层次。
- **实测效果**：
  - 沙鲁游戏擂台地表、石柱、建筑、椰子树干以及站在擂台中央的标准童年期素体角色全部清晰呈现于视线前方；
  - 远景山体与天际线自然融入渐变天穹；
  - 浮云在天穹正常旋转流动，遮罩与接缝平滑无断层。
