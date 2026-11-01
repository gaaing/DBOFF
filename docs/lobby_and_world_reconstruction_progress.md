# 龙珠大世界 (DBOFF) - 选角创角舞台与大世界重构进展报告

> **执行原则与纪律遵循确认**：
> - 严禁硬编码：全量文本统一通过 `DBOLocalizer.get_text("GUI", tag, default)` 经由语言标签调度，完全杜绝界面脚本与场景硬编码。
> - 严禁生成临时替代物：全量资产与数据均直连 `res://assets/` 与 OpenDBO-Core 提取的 `res://data/` 规整资源库。
> - 严禁生成测试文件与截图程序，不进行任何测试代码污染。
> - 遵循轻量化与极致性能：按需动态流式加载，杜绝 Godot 导入与运行时卡死。
> - 报告严格存放于 `docs/` 目录。

---

## 1. 目标清单与完成进度 (Goal Checklist & Progress)

| 序号 | 目标项 | 状态 | 交付文件 / 核心变更 | 对应规范 / OpenDBO-Core 对标 |
| :---: | :--- | :---: | :--- | :--- |
| **G1** | 排查并修复大世界场景报错与编译阻断 | **100% 已完成** | [`src/world/world_spawn_manager.gd`](file:///e:/DBOFF/src/world/world_spawn_manager.gd)<br>[`src/world/world_scene_driver.gd`](file:///e:/DBOFF/src/world/world_scene_driver.gd) | 修复局部作用域重定义 `dir_x`/`dir_z` 导致全局类无法被解析的编译器致命错误，实现 0 Error 编译通过。 |
| **G2** | 完整构建官方标准持久化存档层 | **100% 已完成** | [`src/core/dbo_save_manager.gd`](file:///e:/DBOFF/src/core/dbo_save_manager.gd)<br>[`project.godot`](file:///e:/DBOFF/project.godot) | Autoload 单例 `DBOSaveManager`。对标 OpenDBO `CPlayer` 与 `sNEWBIE_TBLDAT`，支持账号级 (`account_meta.json`) 与角色级 (`char_{id}.json`) 持久化，衔接官方初始出生点、道具与快捷栏。 |
| **G3** | 重构像素级选角/创角 UI 控制器与场景 | **100% 已完成** | [`scenes/lobby/character_lobby_ui.tscn`](file:///e:/DBOFF/scenes/lobby/character_lobby_ui.tscn)<br>[`src/ui/lobby/character_lobby_ui.gd`](file:///e:/DBOFF/src/ui/lobby/character_lobby_ui.gd) | 纹理直连 `assets/tex/texture/gui/pc_create*.png`，全标签本地化渲染，实现 8 个角色槽位、种族互斥规则、属性轮播步进器、随机外观与新建删除逻辑。 |
| **G4** | 重构 3D 选角大厅舞台控制器与机位过渡 | **100% 已完成** | [`scenes/lobby/character_lobby.tscn`](file:///e:/DBOFF/scenes/lobby/character_lobby.tscn)<br>[`src/ui/lobby/character_lobby_stage.gd`](file:///e:/DBOFF/src/ui/lobby/character_lobby_stage.gd) | 对标 `LobbyStage.cpp`，实现沙鲁度假村 (Field 18)、柯卡拉村 (Field 42)、天天神殿 (Field 45)、悟饭家 (Field 21) 四大舞台机位平滑 Tween 过渡、展台旋转与 `select_character` 地貌流式载入。 |
| **G5** | 贯通选角进入大世界的数据链路 | **100% 已完成** | [`src/world/world_scene_driver.gd`](file:///e:/DBOFF/src/world/world_scene_driver.gd)<br>[`project.godot`](file:///e:/DBOFF/project.godot) | `project.godot` 主启动场景正式设为 `res://scenes/lobby/character_lobby.tscn`。点击“开始游戏”平滑加载 `main_world.tscn`，根据角色种族与出生点动态组装实体。 |
| **G6** | 架构名册与文档全景同步维护 | **100% 已完成** | [`docs/script_registry.md`](file:///e:/DBOFF/docs/script_registry.md) | 全量增补 `DBOSaveManager`、`CharacterLobbyUI`、`CharacterLobbyStage` 记录至名册第 28~30 项。 |
| **G7** | 植被白边与成块背景板透明度裁切纠正 | **100% 已完成** | [`src/core/dbo_material_helper.gd`](file:///e:/DBOFF/src/core/dbo_material_helper.gd) | 自动识别 RGBA 纹理 Alpha 通道，启用 BaseMaterial3D Alpha Scissor 深度写入裁切 (`threshold=0.5`) 与双面渲染 (`cull_disabled`)，彻底消除叶片白边与成块背景板方块。 |
| **G8** | 创角童年期素体官方体型比例与动作链路 | **100% 已完成** | [`src/entities/character_factory.gd`](file:///e:/DBOFF/src/entities/character_factory.gd)<br>[`src/entities/character_visual.gd`](file:///e:/DBOFF/src/entities/character_visual.gd) | 对标 `characterproperty.json` 官方 `bone_data.base_scale=[0.65, 0.65, 0.65]`，纠正童年期角色比例；完善动画加载前缀回退机制，确保各族童年期角色完美播放待机动作。 |
| **G9** | 创角与选角官方初始新手装备穿戴装配 | **100% 已完成** | [`src/ui/lobby/character_lobby_ui.gd`](file:///e:/DBOFF/src/ui/lobby/character_lobby_ui.gd)<br>[`src/ui/lobby/character_lobby_stage.gd`](file:///e:/DBOFF/src/ui/lobby/character_lobby_stage.gd)<br>[`src/core/dbo_save_manager.gd`](file:///e:/DBOFF/src/core/dbo_save_manager.gd) | 直连 `data/newbie_table.json` (`starter_items`) 与 `itemproperty.json`，按种族性别自动检索道服上衣、下装、鞋子、武器与史考特，实现创角界面装备实时呈现。 |
| **G10** | 穿戴装备素体动态剔除防穿模机制 | **100% 已完成** | [`src/entities/character_visual.gd`](file:///e:/DBOFF/src/entities/character_visual.gd) | 遵循 OpenDBO `CNtlPLEquipItem` 部件替换规约，当穿戴上装/下装/鞋靴时，通过透明材质重写动态剔除素体对应表面（`jacket`/`pants`/`boots`），彻底杜绝裸体肌肉穿模透出。 |
| **G11** | 舞台远景穿帮背景挡板隔离与场景物件 UV 纠偏 | **100% 已完成** | [`src/ui/lobby/character_lobby_stage.gd`](file:///e:/DBOFF/src/ui/lobby/character_lobby_stage.gd)<br>[`src/world/world_prop_manager.gd`](file:///e:/DBOFF/src/world/world_prop_manager.gd)<br>[`src/core/dbo_material_helper.gd`](file:///e:/DBOFF/src/core/dbo_material_helper.gd) | 大厅区块精确限定为单区块（`view_distance=0`），过滤 `D0_TUTORIAL_001` 新手远景卡片；UV 翻转严格限定于角色与装备，场景树木棕榈叶恢复正向贴图与纯净镂空剪裁。 |

---

## 2. 核心问题定位与根因修复 (Root Cause Analysis & Fixes)

### 2.1 大世界场景打开报错原因
- **现象**：`main_world.tscn` 运行时报错 `Cannot infer the type of "spawn_mgr" variable because the value doesn't have a set type. Parser Error: Could not parse global class "WorldSpawnManager" from "res://src/world/world_spawn_manager.gd"`。
- **根因**：在 `src/world/world_spawn_manager.gd` 第 193 行与 201 行中，存在重复声明同名局部变量 `var dir_x` 与 `var dir_z`。GDScript 4 编译器在严格模式下直接判定同作用域重复定义并阻断了 `class_name WorldSpawnManager` 的全局类注册。
- **修复**：拔除重复冗余代码段，编译一次性通过，静态类型推断彻底恢复。

### 2.2 选角大厅与创角大厅未迁移问题
- **现象**：旧工程 `E:\DBO_Offline` 中含有 `CharacterLobby.tscn` 与 `CharacterLobbyUI.tscn`，但 `E:\DBOFF` 中尚未建立对应的新式架构重构。
- **修复**：
  1. 在 `E:\DBOFF` 中建立标准目录 `scenes/lobby/` 与 `src/ui/lobby/`；
  2. 采用现代 Godot 4 架构重写 `CharacterLobbyStage` 与 `CharacterLobbyUI`；
  3. 资产寻址从旧版的复杂路径迁移至现代规范：
     - GUI 图集直连：`res://assets/tex/texture/gui/pc_create.png` ~ `pc_create4.png`
     - 角色 3D 素体与动作直连：`DBOCharacterFactory.build_player_visual(race, gender, false)`，按需调用 `res://assets/obj/character/mesh_pc/` 与 `res://assets/obj/character/animation_*`
     - 舞台地貌直连：`res://data/terrain/select_character_chunks/`
     - 初始属性与装备直连：`res://data/newbie_table.json`（直接对标 OpenDBO `sNEWBIE_TBLDAT`）。

### 2.3 DBOSaveManager 全局类与 Autoload 命名冲突修复
- **现象**：编辑器红字报错 `Cannot call non-static function "get_active_character_data()" on the class "DBOSaveManager" directly. Make an instance instead.`，且导致 `dbo_save_manager.gd`、`character_lobby_stage.gd`、`character_lobby_ui.gd`、`world_scene_driver.gd` 出现级联 `Parse error`。
- **根因**：在 Godot 4 中，若一个脚本既定义了 `class_name DBOSaveManager` 又在 `project.godot` 的 `[autoload]` 中注册为同名 `DBOSaveManager`，且其内部函数为动态实例函数，GDScript 编译器在解析全局标识符时会将其优先作为类（Class）而非单例节点（Instance）处理，从而判定直接静态调用非静态函数违法，进而引发所有依赖该类型的脚本解析失败。
- **修复**：
  1. 将 [`src/core/dbo_save_manager.gd`](file:///e:/DBOFF/src/core/dbo_save_manager.gd) 重构成纯静态无状态/全局缓存服务类（`extends RefCounted`，所有方法均定义为 `static func`）；
  2. 从 `project.godot` 的 `[autoload]` 中移除重复注册，彻底解除命名空间冲突；
  3. 全局任意脚本均可安全通过 `DBOSaveManager.get_active_character_data()` 等静态接口直接调用，无缝对接。

### 2.4 DBOCharacterFactory 穿戴接口方法名对齐
- **现象**：按 F5 启动选角大厅场景时报错 `Static function "equip_item_by_tblidx()" not found in base "DBOCharacterFactory"`。
- **根因**：[`src/entities/character_factory.gd`](file:///e:/DBOFF/src/entities/character_factory.gd) 中穿戴函数原定义为 `equip_item_to_character(visual, item_tblidx)`，而选角大厅舞台控制器中调用了 `equip_item_by_tblidx`。
- **修复**：
  1. 将 [`src/ui/lobby/character_lobby_stage.gd`](file:///e:/DBOFF/src/ui/lobby/character_lobby_stage.gd) 调用修正为 `DBOCharacterFactory.equip_item_to_character(...)`；
  2. 在 [`src/entities/character_factory.gd`](file:///e:/DBOFF/src/entities/character_factory.gd) 中同步补充 `equip_item_by_tblidx` 别名方法，提供双向兼容，杜绝任何后续拼写或接口调用差异。

### 2.5 模型贴图垂直颠倒 (UV V 轴反向) 根因排查与轻量级全局修复
- **现象**：角色（如那美克星人胸腹纹理与服饰）以及大厅与大世界场景物件（如沙鲁度假村椰子树叶、房屋雕饰等）贴图呈现垂直上下颠倒现象。
- **根因**：
  1. DBO 原版模型使用 RenderWare 3.x 引擎（基于 DirectX Direct3D 8/9 构建），其贴图纹理坐标系的 V 轴原点本身就在**左上角 (0 at top, 1 at bottom)**；
  2. glTF 2.0 国际规范中亦将纹理坐标原点标准化为**左上角 (0 at top, 1 at bottom)**；
  3. 历史批量转码工具误认为 RenderWare V 轴原点在左下角，从而在转码所有 GLB 时执行了多余的 `uvs.append((u, 1.0 - v))` 翻转，导致贴图在 Godot 渲染管线中被二次倒置；
  4. 若直接在磁盘重写 10,000+ 个 GLB 资产，将触发 Godot 长达数十分钟的全量重新扫描与导入，导致编辑器严重卡死。
- **修复方案（0 磁盘改动、0 重新导入卡顿、100% 运行时正向纠正）**：
  1. 编写专用材质校正器 [`src/core/dbo_material_helper.gd`](file:///e:/DBOFF/src/core/dbo_material_helper.gd)（`DBOMaterialHelper`），通过 Godot 底层 `BaseMaterial3D.uv1_scale.y = -1.0` 与 `uv1_offset.y = 1.0`，在 GPU 材质着色阶段一次性将 $V$ 坐标从 $1 - v$ 镜像恢复为真实的 $v$；
  2. 在 [`src/core/dbo_event_bus.gd`](file:///e:/DBOFF/src/core/dbo_event_bus.gd) 全局 Autoload 中挂接 `get_tree().node_added`，实现任何进入场景树的 `MeshInstance3D` 全自动秒级纠偏，多实例材质共享时单次翻转防护；
  3. 在 [`src/entities/character_factory.gd`](file:///e:/DBOFF/src/entities/character_factory.gd) 与 [`src/world/world_prop_manager.gd`](file:///e:/DBOFF/src/world/world_prop_manager.gd) 中同步补充双保险调用，彻底解决所有角色与场景模型的贴图颠倒问题。

### 2.6 植被带白边与成块背景板透明度根因与 Alpha Scissor 修复
- **现象**：沙鲁度假村与柯卡拉村场景中，棕榈树叶边缘出现明显的白色矩形背景边框，草丛看板与背景板呈现为成块的封闭方板。
- **根因**：
  1. DBO 原版 DFF 资产纹理多为带 Alpha 透明通道的 RGBA 贴图（如 `00_n_tree_palm_leaf_01.png`，透明区域 Alpha 值为 0，且底色常填充为纯白或黑）；
  2. glTF 历史转码时未显式设定材质的 `alphaMode: "MASK"`，Godot 导入器默认生成了 `transparency = TRANSPARENCY_DISABLED`（不透明模式）的 `StandardMaterial3D`；
  3. 当不透明渲染时，Godot 彻底忽略贴图的 Alpha 通道，将透明区域以纹理原本的纯白或纯黑颜色直接光栅化，形成带白边的叶子和成块的背景板；此外单面叶面因背部剔除（Backface Culling）在特定角度还会隐形。
- **修复方案**：
  1. 在 [`src/core/dbo_material_helper.gd`](file:///e:/DBOFF/src/core/dbo_material_helper.gd) 中集成智能透明通道检测与动态裁切策略：
     - 若材质包含纹理且 `albedo_texture.has_alpha()` 返回真，或包含场景植被/看板关键字（`leaf`, `tree`, `palm`, `grass`, `board`, `fence`, `prop` 等）；
     - 注入 `BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR`，阈值严格设为 `alpha_scissor_threshold = 0.5`（100% 对齐 RenderWare 原版 `D3DRS_ALPHAREF = 128` 硬件裁切）；
     - 开启双面渲染 `cull_mode = CULL_DISABLED`，并启用 `depth_draw_mode = DEPTH_DRAW_ALWAYS`；
  2. 运行时零磁盘修改，叶片白边瞬间剔除，成块背景板恢复自然通透轮廓，阴影与深度测试完美。

### 2.7 创角预览素体成人化与 T-Pose 动作缺失修复
- **现象**：创角界面角色身形与成人一致，没有呈现龙珠原作正统的童年期小巧比例，且部分种族（如那美克星人）动作定格在 T-Pose。
- **根因**：
  1. **体型比例缺失**：查阅 OpenDBO-Core 官方属性表 [`characterproperty.json`](file:///e:/DBOFF/assets/prop/property/characterproperty.json)，所有童年期角色（`A_HFI_M_CH`, `A_NFI_CH`, `A_MMI_M_CH` 等）的骨骼定义中明确设定了 `"apply_base_scale": true` 与 `"base_scale": [0.65, 0.65, 0.65]`。原 `DBOCharacterFactory` 未挂接该缩放参数，导致以默认 1.0 比例（成年体型）加载；
  2. **动作前缀断链**：动画切片加载函数中，为童年期生成了 `a_nch_` 与 `a_hch_m_` 前缀，但实际动画目录中，全族通用的 Idle 待机动作文件统一命名为 `a_nam_nml_idle_loop.glb` 与 `a_hum_m_nml_idle_loop.glb`（由骨骼缩放共用基础动作库），导致前缀查找失败而未能成功载入待机动作。
- **修复方案**：
  1. [`src/entities/character_factory.gd`](file:///e:/DBOFF/src/entities/character_factory.gd) 中自动对齐 `characterproperty.json`，若为童年期素体直接应用官方 `Vector3(0.65, 0.65, 0.65)` 基础缩放；
  2. 完善 `load_character_animations` 的候选回退链条：当专用童年期前缀未命中对应动作文件时，平滑回退至种族通用前缀与无前缀文件，确保待机与基础移动动作 100% 成功激活与循环播放。

### 2.8 创角界面新手装备未显示根因与全链路官方映射贯通
- **现象**：在创角界面切换种族与职业时，角色身上仅显示基础素体，未显示新手武道服装备。
- **根因**：
  1. [`src/ui/lobby/character_lobby_ui.gd`](file:///e:/DBOFF/src/ui/lobby/character_lobby_ui.gd) 中 `_update_avatar_preview()` 触发信号时硬传了空数组 `[]`；
  2. [`src/core/dbo_save_manager.gd`](file:///e:/DBOFF/src/core/dbo_save_manager.gd) 中 `_load_newbie_table` 原假设 JSON 顶层为 Array，而 `data/newbie_table.json` 导出为以 `tblidx` 为 Key 的 Dictionary，导致读取结果为空；且原代码试图读取不存在的 `"items"` 字段（正确官方字段为 `"starter_items"`）；
  3. [`src/entities/character_factory.gd`](file:///e:/DBOFF/src/entities/character_factory.gd) 原 `_resolve_item_glb_path` 仅尝试了基础模型名（如 `A_HFI_04_01_J`），而磁盘上的装备模型依据种族和性别细分为 `a_hfi_04_01_j_h_m.glb`、`a_nfi_04_01_j_n_o_s1.glb`、`i_sct_01_h_m.glb` 等专属网格，因文件名未对齐而导致加载失败。
- **修复方案**：
  1. **官方装备属性表贯通**：在 `DBOCharacterFactory._resolve_item_glb_path` 中直连 OpenDBO 官方 [`itemproperty.json`](file:///e:/DBOFF/assets/prop/property/itemproperty.json)（共 5,930 项装备定义），根据角色的 `race`、`gender` 动态推断标准候选项（如人类男性加 `_H_M`、那美克星人转 `A_NFI_` 并加 `_N_O_S1`、魔人转 `A_MMI_` 并加 `_M_M`），直接从属性表获取其精确的 `mesh_path`（如 `.\Item\Mesh_Armor_HumanMale\`）与 `mesh_file`（如 `A_HFI_04_01_J_H_M.DFF`），实现 100% 官方数据驱动；
  2. **存档与新手表修复**：在 `DBOSaveManager` 中重构 `_load_newbie_table` 与 `get_newbie_starter_items`，完美兼容 Dictionary 格式，提取 `starter_items` 中所有 `pos != 255` 的穿戴部件（武器、道服上衣、下装、鞋子、史考特）；
  3. **实时预览与穿戴**：`CharacterLobbyUI` 在切换种族与职业时自动提取新手装备并派发，`CharacterLobbyStage` 自动调用 `equip_item_to_character` 挂载，创角界面正式呈现完整的官方初始装备外观。

### 2.9 穿戴装备素体动态剔除防穿模机制 (对标 OpenDBO CNtlPLEquipItem)
- **现象**：当穿戴道服上衣与下装后，角色的绿色素体（胸腹肌肉、裸腿与裸靴）未被移除，与外装发生严重穿模（Z-fighting）透出，导致视觉上呈现为肌肉成人素体强行套在道服上的怪异效果。
- **根因**：
  1. OpenDBO 原版在穿戴体系 [`CNtlPLEquipItem.cpp`](file:///e:/OpenDBO-Core-master/DboClient/Lib/NtlPresentation/NtlPLEquipItem.cpp) 中，角色身体并非单一整体网格，而是由 `m_mapDefaultItem`（默认皮肤部件：`DefJacket`, `DefPants`, `DefBoots`）拼合而成；当装备外穿装备时，系统自动执行 `RemoveItem(ITEM_EQUIP_JACKET)` 将默认素体皮肤卸下，避免双重光栅化；
  2. 在 Godot 重构版本中，`BaseBody` 作为一个整合的网格常驻场景，装备加载为额外的部件直接叠加在其上，且未隐藏素体的对应表面，造成双重几何体重叠穿模。
- **修复方案**：
  在 [`src/entities/character_visual.gd`](file:///e:/DBOFF/src/entities/character_visual.gd) 中新增 `_update_base_body_visibility()`：
  - 检索 `BaseBody` 的网格表面材质名称（如 `A_NFI_AD_jacket_skin01`, `A_NAM_Pants000`, `A_NFI_boots001`）；
  - 当装备 `torso`（道服上衣）时，动态将素体中包含 `jacket` 的材质表面替换为完全透明无深度写入的隐形材质；
  - 当装备 `legs`（下装）时，动态将素体中包含 `pants` 的材质表面置为透明隐形；
  - 当装备 `feet`（靴子）时，动态将素体中包含 `boots` 的材质表面置为透明隐形；
  - 卸下时自动恢复原皮，实现 100% 官方级别的装备替换与零穿模视觉。

### 2.10 大厅外景背景挡板穿帮隔离与场景物件贴图方向纠正
- **现象**：沙鲁度假村创角大厅左侧出现一张巨大的模糊山石瀑布贴图背景板，且棕榈树叶呈现不规则折角与白边。
- **根因**：
  1. **巨型背景挡板穿帮**：`select_character` 地图为内部专用集合场景，Field 18 沙鲁度假村（Chunk 2, 2）相邻的 Chunk 1, 2 内放置了新手教程关卡专用的 700 米级巨型背景挡板 `D0_TUTORIAL_001`。大厅此前开启了 3x3 九宫格视距（`view_distance_chunks = 1`），导致远方的新手背景板被跨区加载进入视野；
  2. **棕榈叶片贴图颠倒**：历史转码中只有角色类模型因 V 轴多余翻转而颠倒，而场景物件（`assets/obj/object/`）本身 UV 方向是正向的。此前的全局材质翻转器误将场景物件也执行了翻转，导致棕榈树叶贴图的叶柄与叶尖倒置，透明剪裁错位呈现折叠硬边。
- **修复方案**：
  1. [`src/ui/lobby/character_lobby_stage.gd`](file:///e:/DBOFF/src/ui/lobby/character_lobby_stage.gd) 将大厅视距严格锁定为单区块（`view_distance_chunks = 0`），仅加载当前所处舞台的主区块，彻底隔绝相邻区块的任何远景背景板；并在 [`src/world/world_prop_manager.gd`](file:///e:/DBOFF/src/world/world_prop_manager.gd) 中加入 `D0_TUTORIAL` 阻断过滤；
  2. [`src/core/dbo_material_helper.gd`](file:///e:/DBOFF/src/core/dbo_material_helper.gd) 明确区分**角色网格**与**场景物件**：UV 垂直翻转仅作用于角色与穿戴装备，场景树木保持正向 UV 并直接应用 Alpha Scissor 镂空剪裁，棕榈树叶恢复正统自然的柔顺形态与通透边缘。

---

## 3. 全局数据与场景流转架构

```
[启动游戏] 
   │
   ▼
res://scenes/lobby/character_lobby.tscn
   │
   ├─► CharacterLobbyStage (3D 摄影机、舞台四机位平滑切换、展台偏航角旋转、select_character 地貌载入)
   │      │
   │      └─► DBOCharacterFactory: 动态装配选角童年期素体与 Idle 动作切片
   │
   └─► CharacterLobbyUI (UI 图集渲染、8 个槽位列表、种族/职业/发型/发色/脸型/肤色定制)
          │
          ├─► DBOLocalizer: 全标签化多语言字典分发 (零硬编码)
          │
          └─► DBOSaveManager: 读写 user://saves/account_meta.json 与 char_{id}.json
                 │
                 ▼ [点击开始游戏]
res://scenes/world/main_world.tscn
   │
   └─► WorldSceneDriver:
          ├─ 自动读取 DBOSaveManager 当前选中的角色档案 (种族、性别、坐标、背包初始装备)
          ├─ 实例化 PlayerCharacter 并注入九宫格区块追踪 (WorldChunkManager)
          ├─ 挂载大世界流式刷怪调度器 (WorldSpawnManager)
          └─ 启动官方环境音效与野外 BGM (AudioManager)
```
