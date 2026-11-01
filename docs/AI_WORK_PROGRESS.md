# DBOFF AI Work Progress

> 本文档由 ChatGPT 维护，是当前项目状态记录。仓库中其他历史进度报告不作为本文件的事实来源。  
> 最后更新：2026-11-01

## 1. 当前项目阶段

**阶段：旧代码清理与架构重整中。**

当前目标是清理旧代码，逐个系统恢复清晰架构，并以 OpenDBO-Core 为功能参考进行对照。当前没有任何系统或功能可以被认定为完美完成。

## 2. 当前已知状态

以下内容来自用户在 2026-11-01 的明确说明，属于用户报告，尚未由 ChatGPT 对当前代码独立验证：

| 项目 | 当前状态 | 证据/说明 |
|---|---|---|
| 创建角色场面 | 已完成初步创建，仍有 Bug | 用户报告；Antigravity 正在修复 |
| 选择角色场面 | 已完成初步创建，仍有 Bug | 用户报告；Antigravity 正在修复 |
| 其他系统/功能 | 不认定为完美或完整 | 用户明确说明目前没有任何一个完美功能 |
| 旧代码清理 | 进行中 | 用户报告 |
| OpenDBO 功能对照 | 作为后续逐系统重构依据 | 项目工作方向 |

“创建/选择角色场面已完成初步创建”仅表示已有可继续修复的实现，不代表功能完整、稳定或已通过验收。

## 3. GitHub 仓库数据基线

2026-11-01 检查 GitHub 仓库 `gaaing/DBOFF` 的 `main` 分支后，确认该分支包含以下目录文件：

- `src/`
- `scenes/`
- `assets/tbl/`
- `data/`
- `docs/`
- 根目录 `project.godot` 与 `.gitignore`

GitHub 文件存在只证明这些文件已上传，不证明其内容正确或功能已实现。未上传的本地资源不能据此判定为不存在。

## 4. 历史文档的处理方式

仓库中原有的报告、路线图、审计文档和完成清单均属于历史材料。它们可以帮助定位文件、理解曾经采用的方案或提出待核实问题，但不得直接作为当前实现状态的依据。

特别注意：
- 历史文档中“100% 完成”“彻底修复”“完全对标”等表述均未自动获得认可。
- 旧报告中的代码路径、统计数字、功能结论必须回到当前分支重新核实。
- 历史报告之间若有冲突，不通过猜测调和；以当前代码、数据、OpenDBO 源码和运行证据重新判断。

## 5. 当前待处理事项

1. 持续清理旧代码，梳理真实职责与依赖关系。
2. 跟进创建角色与选择角色场面的现存 Bug；读取 Antigravity 修复后的实际文件，再判断修复范围。
3. 建立逐系统 OpenDBO-Core 对照记录。
4. 核对当前数据表、JSON 数据与 Godot 代码的真实连接关系。
5. 在证据充分前，不把任何系统标记为完整或完美。

## 6. 缺少的验证材料

当前尚未针对创建/选择角色场面完成新一轮独立代码审查，因此仍需按具体 Bug 获取：
- Antigravity 修复后的相关脚本与场景文件；
- 可复现的 Bug 描述、操作步骤和实际表现；
- 对应错误日志或运行结果（若有）；
- 涉及的 JSON、表格或资源文件（若 Bug 与数据/资源有关）；
- 对应 OpenDBO-Core 源码位置（如需判断原版行为）。

这些是后续具体审查所需材料，不代表它们在用户本地不存在。

## 7. 2026-11-01 首轮代码结构核查（ChatGPT 只读）

### 7.1 仓库结构与可见范围

- 当前 GitHub `main` 文件树包含 15,878 个 blob（本次递归树检查）；`src/` 下 82 个文件条目（含 .uid），`scenes/` 下 6 个场景，`assets/tbl/` 与 `data/` 已上传。
- 已确认 `.gitignore` 当前内容为白名单式规则，允许跟踪 `docs/`、`scenes/`、`src/`、`project.godot`、`assets/tbl/` 和 `data/`；与此前错误内容不同。
- 当前 GitHub 文件树中未见 `assets/obj/`、`assets/tex/`、`assets/prop/property/` 等运行时资源目录。此项只代表这些资源未出现在当前仓库文件树中，不能推断用户本地没有。
- `project.godot` 将 `scenes/lobby/character_lobby.tscn` 设为启动场景，并注册 9 个 Autoload；主场景引用角色大厅 UI 与 3D 舞台脚本。

### 7.2 首轮发现的架构与实现风险（尚非完整审计）

| 系统 | 当前代码证据 | 初步判断 / 待核实点 |
|---|---|---|
| 角色大厅 | `character_lobby_stage.gd` 589 行；`character_lobby_ui.gd` 849 行；场景脚本直接处理舞台、镜头、环境、角色预览与 UI 状态 | 职责集中，且舞台配置含硬编码场景坐标；需与 OpenDBO 的 Stage 生命周期、状态切换、模型与 UI 初始化顺序逐段比较。不能仅凭脚本头部“严格对标”注释认定一致。 |
| 地形 | `world_chunk_manager.gd` 根据 `zone_name` 读取 `data/terrain/{zone}_chunks/chunk_x_y.json`；`world_terrain_mesh_builder.gd` 将高度数组生成网格和碰撞 | 当前可见实现是高度网格 + 单一材质贴图路径；尚未看到完整的 NTLWE 地表属性混合、TileAttr/材质层混合和地表细节机制。需要检查 JSON schema、导出数据与纹理映射。 |
| 区块边界 | `world_pos_to_chunk_coord()` 将坐标固定映射并 clamp 到 0..7；仓库同时存在多个不同区块集，文件树中 `battle_002_chunks` 至少可见 0..15 的索引 | 通用区块坐标逻辑可能不适用于 8×8 以外的地图；需要按每个地图实际尺寸、原点和 chunk metadata 改为数据驱动，而不是统一假定 8×8。 |
| 世界场景驱动 | `world_scene_driver.gd` 先用相机位置驱动区块加载，之后创建玩家并把追踪目标切换为玩家；刷怪管理器在运行时动态创建 | 生命周期与初始化顺序需要验证；当前场景本身没有直接挂载 SpawnManager，依赖 Driver 运行时创建。需检查玩家相机、出生点、刷怪和区块首帧同步。 |
| 战斗 | `combat_engine.gd` 调用公式引擎并派发伤害、特效、受击、击退；当前可见代码把攻击/防御属性 NONE 传入，并读取 `is_critical`、`is_blocked` | 当前调用路径未展示技能命中区域、技能效果、属性相克实际参数、暴击/格挡判定或完整状态同步；结果字段存在不等于机制已经实现。需继续追踪 FormulaEngine 与状态组件。 |
| 背包 | `dbo_inventory_manager.gd` 用固定数组管理 6 个背包和 17 个装备槽；按 `item_type` 判断胶囊盒 | `add_item_to_bag()` 在先部分堆叠、后续无空槽时可能已修改现有堆叠却返回 false，存在非原子操作风险；还需核对装备槽合法性、物品类别和 OpenDBO 枚举。 |
| 存档 | `dbo_save_manager.gd` 是本地 JSON 存档，默认账号元数据含固定 account_id=1001、gm_level=10，角色默认 ID=100001 | 当前是离线本地存档雏形；需检查新建账号/角色 ID 生成、GM 权限默认值、版本迁移、损坏存档恢复、原子写入与删除确认。 |
| 数据服务 | `dbo_table_manager.gd` 从 `assets/tbl/` 惰性加载 JSON，并从 `assets/prop/property/` 读取属性文件 | 当前仓库没有上传 property 目录；本地是否存在未知。表格缺失/空表均返回空字典，业务层需要区分“合法空结果”和“数据文件缺失/解析失败”。 |

### 7.3 OpenDBO 初步对照依据

本轮已直接读取 OpenDBO-Core 的以下原版文件作为后续审查入口：
- `DboClient/Client/Stage/LobbyStage.cpp`
- `DboClient/Client/Stage/CharacterStage.cpp`
- `DboClient/Lib/NtlPresentation/NtlWorldField.cpp`
- `DboClient/Lib/NtlPresentation/NtlPLWorldEntity.cpp`
- `DboShared/NtlShared2/NtlItem.h`
- `DboShared/NtlShared2/NtlCharacterState.h`
- `DboClient/Lib/NtlSimulation/NtlFSMCharActState.cpp`
- `DboClient/Lib/NtlSimulation/NtlFSMCharController.cpp`
- `DboServer/Server/GameServer/CharacterAttPC.cpp`

这些文件体量远大于当前 Godot 对应脚本；当前阶段只确认了源码存在、职责范围和部分枚举/结构，不代表已完成逐函数对照。

特别风险：OpenDBO `NtlItem.h` 的 `eITEM_TYPE` 枚举中，`ITEM_TYPE_BAG` 位于武器/服装等类型之后；Godot 背包脚本注释却写 `ITEM_TYPE_BAG = 8`。在确认 JSON 导出字段是否保留原始枚举值之前，先标记为高风险数据映射疑点，不直接断言运行时一定错误。

### 7.4 本轮需要补充的材料

要把以上疑点升级为确定结论，仍需：
- 当前本地实际使用的 `assets/obj/`、`assets/tex/`、`assets/prop/property/` 资源目录清单或相关文件（仓库未上传不代表本地缺失）；
- `data/terrain/` 各地图 JSON 的完整字段样本，特别是高度、地表材质/TileAttr、props、地图尺寸和原点；
- Antigravity 修复后的角色大厅两个脚本与场景，以及每个 Bug 的复现步骤和运行日志；
- `DBOFormulaEngine`、`DBOCharacterVisual`、`DBOPlayerController3D`、`DBOBuffComponent`、`WorldPropManager` 等被调用类的完整当前版本；
- OpenDBO 对应函数的具体实现区段，继续核对而不是只根据文件名或注释判断。

本轮仅检查 GitHub 当前分支并读取 OpenDBO 源码，没有修改项目代码、场景或资源。

## 8. 更新记录

### 2026-11-01
- 建立本文件，记录用户确认的真实项目阶段。
- 明确创建角色和选择角色场面已有初步实现，但仍存在 Bug，Antigravity 正在修复。
- 明确当前没有任何功能可称为完美完成。
- 将仓库原有报告降级为历史线索，不再直接信任其中的完成状态。
- 确认 GitHub 已包含 `assets/tbl/` 与 `data/` 等数据目录；上传存在不等于实现正确。
- 新增首轮只读结构核查：读取当前核心场景/脚本与 OpenDBO 对应源码，记录职责耦合、地图尺寸假设、地形材质机制、战斗判定、背包操作原子性、存档默认值和资源上传范围等待核查点。
- 再次确认当前 `.gitignore` 已恢复为预期白名单规则。
