# DBOFF AI Work Progress

> 本文档由 ChatGPT 维护，是当前项目状态记录。仓库中其他历史进度报告不作为本文件的事实来源。  
> 最后更新：2026-11-02

## 1. 当前项目阶段

**阶段：资产/数据基线阶段性整理已提交，进入系统性修复、源码对齐、实现评价与逐步还原阶段。**

注意：2026-11-02 的最终资产报告声明 P0/P1 资产和 236 张服务端表已补齐；但完整 1.69 TW 客户端根目录扫描、全部 PAK 解码覆盖、非 PAK 资源归类与运行时资源可用性仍未全部独立验证。该报告结论不能替代后续系统级审查。

2026-11-02 的资产与服务端数据报告声称已完成 1.69 TW 客户端资产（112,881 项）与 OpenDBO-Core 服务端数据（236 表）的补齐。当前可确认的是报告已提交、部分 JSON 已从 GitHub 读取并完成结构检查；完整客户端根目录清单、PAK 解码覆盖、二进制资源质量及全部运行时引用尚不能仅凭该报告认定为独立验收通过。后续资产问题按具体系统和证据补查，不阻塞现有代码系统审查。

## 2. 当前已知状态

| 项目 | 当前状态 | 证据/说明 |
|---|---|---|
| 客户端核心资产 | 报告声明 P0/P1 补齐；完整来源与运行可用性待独立核实 | 依据 2026-11-02 最终资产报告；完整客户端根目录与 PAK 审计仍有缺口 |
| 本地化多语言体系 | 报告声明已建立；当前待系统级核查 | 语言包文件是否已进入当前本地运行路径、加载行为和多语言覆盖需结合当前代码/资源验证 |
| 服务端数据对齐 | 报告声明 236/236 表对应；字段/行为语义待抽样与系统级核实 | 表名和记录数对应不自动证明字段映射、枚举、默认值及业务行为一致 |
| 属性与动作引用 | 报告声明引用闭包通过；存在待核实异常 | 2026-11-02 JSON 审查发现 itemproperty.upgrade_effect.effect 非文本值及 objectproperty bbox min/max 异常，须回查原始结构 |
| 创建角色场面 | 已完成初步创建，仍有 Bug | 用户报告；Antigravity 正在修复 |
| 选择角色场面 | 已完成初步创建，仍有 Bug | 用户报告；Antigravity 正在修复 |
| 其他系统/功能 | 不认定为完美或完整 | 用户明确说明目前没有任何一个完美功能 |
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

### 2026-11-02
- **全项目资产与数据映射工程完成**：
  - 建立了总索引文档 `docs/ASSET_DATA_MAPPING.md` 以及 7 个子系统映射目录 `docs/ASSET_MAPPING_DETAILS/`。
  - **数据表映射** (`01_DATA_TABLE_MAPPING.md` + `table_registry.json`)：完成 280 张数据表（275 张位于 `assets/tbl/`，5 张位于 `data/`）的字段、主键与 OpenDBO 源码结构登记。
  - **角色与职业映射** (`02_CHARACTER_AND_CLASS_MAPPING.md` + `character_class_mapping.json`)：完成 6 大种族/性别素体模型路径及 12 种基础/进阶职业与 NewbieTable 出生配置的绑定。
  - **装备与物品映射** (`03_EQUIPMENT_AND_ITEM_MAPPING.md` + `equipment_item_mapping.csv` + `equipment_item_mapping.json`)：P0 级新手装备链打通（NewbieTable -> Item ID -> ItemTable -> ItemProperty -> 槽位 -> 对应成人/儿童模型 -> 贴图/骨骼/皮肤），明确区分儿童角色素体自带新手服装与成人模块化装备挂载机制。
  - **动画映射** (`04_ANIMATION_MAPPING.md` + `animation_mapping.json`)：完成 5,302 个 GLB 动作动画分类注册，梳理 CharacterAnimation 与 ItemTable 武器战斗待机/攻击动画映射逻辑。
  - **模型材质贴图映射** (`05_MODEL_MATERIAL_TEXTURE_MAPPING.md` + `model_texture_mapping.json`)：登记本地存在的 30,894 个 GLB 模型与 28,577 个 PNG 贴图资源库分布。
  - **大世界与地图映射** (`06_WORLD_AND_MAP_MAPPING.md` + `world_map_mapping.json`)：登记 106 个 WorldTable 世界及 50 个已就绪地形区域（共 15,453 个地形切片区块）。
  - **NPC、怪物、技能与特效映射** (`07_NPC_MOB_SKILL_EFFECT_MAPPING.md` + `npc_mob_skill_mapping.json`)：完成 3,169 个 NPC、7,125 个怪物及 2,663 个技能的数据表与模型特效对应关系整理。
  - 所有映射均按照 `VERIFIED`、`PARTIAL`、`INFERRED`、`MISSING`、`UNKNOWN` 严格标注证据等级，彻底解决今后跨模块调用与资产查证信息缺失问题。

### 2026-11-01
- 建立本文件，记录用户确认的真实项目阶段。
- 明确创建角色和选择角色场面已有初步实现，但仍存在 Bug，Antigravity 正在修复。
- 明确当前没有任何功能可称为完美完成。
- 将仓库原有报告降级为历史线索，不再直接信任其中的完成状态。
- 确认 GitHub 已包含 `assets/tbl/` 与 `data/` 等数据目录；上传存在不等于实现正确。
- 新增首轮只读结构核查：读取当前核心场景/脚本与 OpenDBO 对应源码，记录职责耦合、地图尺寸假设、地形材质机制、战斗判定、背包操作原子性、存档默认值和资源上传范围等待核查点。
- 再次确认当前 `.gitignore` 已恢复为预期白名单规则。


## 9. 产品目标与长期架构原则（用户于 2026-11-01 明确）

### 9.1 产品目标

用户明确要求：DBOFF 的目标是**忠实还原原版 Dragon Ball Online（DBO）的游戏内容与行为，同时将实现升级为更先进、更完整、更轻量的现代架构**。不是制作一个只借用 DBO 题材的简化游戏。

- 游戏机制、职业、技能、战斗、装备、地图、任务、NPC、怪物、动画、交互和成长规则，以原版 DBO 的实际数据和行为为还原目标。
- 底层代码、资源组织、数据管线、渲染、加载、缓存、网络和资产压缩允许采用现代方案。
- 不得以“架构现代化”为理由擅自简化原版玩法；也不得为了逐行模仿原版而保留不必要的旧技术缺陷。
- 用户确认目前素体已采用烘焙为包含完整组件的方向；具体实现质量和覆盖范围仍需检查当前资产与脚本。

### 9.2 Local-first 原则

目标是让游戏尽可能依靠本地运行，服务器只承担确实需要在线协调、分发、授权或跨设备同步的职责。

**本地优先范围（目标，不代表当前已实现）：**
- 世界、地形、角色控制、NPC/怪物 AI、战斗、技能、动画、任务、背包、装备和单人游戏逻辑；
- 本地存档和离线游戏；
- 可缓存的数据表、全局配置与资源。

**在线服务范围（目标，不代表当前已实现）：**
- 游戏下载、版本检查和更新分发；
- 账号身份认证；
- 云存档同步；
- GM 临时权限授予、撤销和审计；
- 全局规则/活动配置发布；
- 好友、邀请、组队发现和会话协调；
- 需要跨玩家一致性的交易、物品转移和重要奖励记录。

服务器不应无必要地承担整个世界的持续模拟。离线玩法不能因为服务器暂时不可用而被整体阻断。

### 9.3 在线规则配置建议（架构提案，尚未实现）

建议设计 Global Rules / 全局规则配置服务：
- 服务端发布有版本号、生效时间、过期时间和签名的规则包；
- 客户端验证并缓存规则包，游戏读取本地缓存；
- 网络不可用时依照明确的离线策略使用最后有效版本；
- 对必须在线校验的奖励、交易和竞争行为，不能仅依赖客户端本地配置；
- 规则配置应可审计、可回滚，并定义过期和签名验证失败时的行为。

候选配置包括等级上限、活动开关、活动时间和经设计允许动态调整的倍率。字段与安全策略尚待设计，不把示例 JSON 当成正式协议。

### 9.4 玩家间数据交换建议（架构提案，尚未实现）

沿用用户此前选择的队长 Host 模型 B 作为合作玩法候选：
- 队长 Host 承担合作会话中的主要模拟；
- 在线服务负责身份认证、会话发现、邀请和必要的中继；
- 普通合作状态可由 Host 协调；
- 交易、物品所有权变更、重要奖励领取等需要防复制/防重放的操作，应由可信服务验证并记录；
- PvP 或竞争性玩法需要单独定义权威性与作弊防护，不能直接沿用普通合作信任模型。

此为架构建议，尚未进行威胁建模、网络测试或正式定案。

### 9.5 资产变体压缩提案

用户提出：官方同一装备可能存在多个版本（例如五个版本），可分析版本间差异，将可表达的差异提取为变形数据，以减少重复完整模型资源。

建议研究流程：
1. 对同组模型做拓扑、顶点数量/顺序、索引、法线、UV、骨骼、权重、材质和部件差异分析；
2. 若拓扑和顶点对应关系一致，评估基础网格 + 顶点/法线差异数据的可行性；
3. 若拓扑不一致，识别独立部件、局部替换网格或其他表达方式，不强行使用顶点偏移；
4. 保留原版外观、装备遮挡、挂点和动画行为；
5. 比较压缩前后磁盘体积、运行时内存、加载时间、渲染成本和视觉误差；
6. 先做小规模样本验证，再决定是否批量处理。

该方向暂命名为 **DBOFF Asset Variant Compression**，是研究提案，不代表已实施或已证明能够压缩所有装备。

### 9.6 AI 协作分工（用户提出由 ChatGPT 接手 Bug 修复方向）

用户提出让 ChatGPT 承担主要 Bug 定位与修复工作，并让 Antigravity 退出日常 Bug 修复；以下为建议分工：

| 角色 | 建议职责 |
|---|---|
| ChatGPT | 总体架构、OpenDBO 机制对照、Bug 定位、修复代码、重构审查、验收标准和 AI 基准文档维护 |
| Antigravity | 批量资产/数据解析、原始资源导出、格式转换、模型版本差异提取、自动化检查和可重复的数据管线 |
| Gemini | 独立源码研究、复杂格式分析、机制调用链梳理、方案反向审查和交叉验证 |

协作约束：
- 同一核心文件避免多个 AI 同时修改；
- Antigravity/Gemini 的分析结果必须保留输入文件、工具版本、输出和可复现步骤；
- 不把 AI 生成的报告直接视为事实，ChatGPT 需回到原始文件、代码或运行证据核验；
- 当前既有的只读约束仍然有效：未经用户明确授权，ChatGPT 不直接改项目代码/场景/资源；修复代码先在聊天中提供或审查用户/Antigravity 应用后的版本。

## 10. 后续架构工作顺序建议（提案）

1. 继续梳理现有核心代码和 OpenDBO 行为，确定真实系统边界，不在旧架构上继续堆补丁。
2. 定义原版机制与现代实现的映射规范：每个系统记录原版行为、数据、状态流、Godot 实现和差异。
3. 先把本地游戏核心做成不依赖在线服务的可运行闭环。
4. 设计在线服务边界与协议：身份、全局规则、云存档、会话协调、交易/奖励校验。
5. 建立可复现的资产解析和导出管线。
6. 以小样本验证素体标准化和装备变体压缩，再决定全量处理。
7. 每个系统通过代码、数据、OpenDBO 对照和运行行为验收后，才记录限定范围的验证结论。

以上均为方向和提案；除本文件记录的用户明确目标外，不代表已批准的具体技术实现。

## 11. 更新记录补充

### 2026-11-02
- **全项目资产与数据映射工程完成**：
  - 建立了总索引文档 `docs/ASSET_DATA_MAPPING.md` 以及 7 个子系统映射目录 `docs/ASSET_MAPPING_DETAILS/`。
  - **数据表映射** (`01_DATA_TABLE_MAPPING.md` + `table_registry.json`)：完成 280 张数据表（275 张位于 `assets/tbl/`，5 张位于 `data/`）的字段、主键与 OpenDBO 源码结构登记。
  - **角色与职业映射** (`02_CHARACTER_AND_CLASS_MAPPING.md` + `character_class_mapping.json`)：完成 6 大种族/性别素体模型路径及 12 种基础/进阶职业与 NewbieTable 出生配置的绑定。
  - **装备与物品映射** (`03_EQUIPMENT_AND_ITEM_MAPPING.md` + `equipment_item_mapping.csv` + `equipment_item_mapping.json`)：P0 级新手装备链打通（NewbieTable -> Item ID -> ItemTable -> ItemProperty -> 槽位 -> 对应成人/儿童模型 -> 贴图/骨骼/皮肤），明确区分儿童角色素体自带新手服装与成人模块化装备挂载机制。
  - **动画映射** (`04_ANIMATION_MAPPING.md` + `animation_mapping.json`)：完成 5,302 个 GLB 动作动画分类注册，梳理 CharacterAnimation 与 ItemTable 武器战斗待机/攻击动画映射逻辑。
  - **模型材质贴图映射** (`05_MODEL_MATERIAL_TEXTURE_MAPPING.md` + `model_texture_mapping.json`)：登记本地存在的 30,894 个 GLB 模型与 28,577 个 PNG 贴图资源库分布。
  - **大世界与地图映射** (`06_WORLD_AND_MAP_MAPPING.md` + `world_map_mapping.json`)：登记 106 个 WorldTable 世界及 50 个已就绪地形区域（共 15,453 个地形切片区块）。
  - **NPC、怪物、技能与特效映射** (`07_NPC_MOB_SKILL_EFFECT_MAPPING.md` + `npc_mob_skill_mapping.json`)：完成 3,169 个 NPC、7,125 个怪物及 2,663 个技能的数据表与模型特效对应关系整理。
  - 所有映射均按照 `VERIFIED`、`PARTIAL`、`INFERRED`、`MISSING`、`UNKNOWN` 严格标注证据等级，彻底解决今后跨模块调用与资产查证信息缺失问题。

### 2026-11-01
- 用户明确产品目标：忠实还原原版 DBO 的游戏内容与行为，同时采用更先进、更完整、更轻量的实现技术。
- 用户明确 Local-first 目标：游戏尽可能本地运行，在线服务只承担下载更新、云存档、GM 临时授权及确实需要跨玩家协调的功能。
- 记录全局规则配置、队长 Host 合作会话、关键资产操作服务端校验等架构提案，均标记为尚未实现/尚待定案。
- 记录用户提出的装备多版本差异分析与变形数据压缩方向。
- 记录建议的 AI 分工：ChatGPT 负责架构、Bug 分析与修复审查；Antigravity 负责资产/数据工程；Gemini 负责独立研究与交叉验证。具体执行需按用户后续任务安排。


## 12. 六大长期目标与完整系统地图要求（用户于 2026-11-01 明确）

用户明确要求：不能先做一部分、做到中途才发现原版还有整套系统遗漏。必须先建立覆盖 DBO 全貌的系统地图，再按优先级实施。六个方向是长期总目标，不是互斥的六个开发阶段。

### 12.1 六大目标

1. **先可玩：基础功能形成完整闭环。** 不做孤立展示原型；基础闭环至少覆盖启动/进入、账号与角色流程、进入世界、移动和交互、战斗与技能、成长、任务、物品装备、本地存档、退出和继续游戏。此为初始清单，须由原版证据继续补全；先可玩不等于永久删减原版系统。
2. **修复 Bug，并形成差异化特性。** 建立复现、根因、修复、回归验证链。在原版还原基础上实现项目扩展，用户明确举例为 Doll。Doll 的玩法、数据、权限、离线/在线边界尚需需求材料，不能仅凭名称臆定。
3. **挖掘并复原原版未完成内容。** 调查已实现未启用、流程未完成、客户端/服务端未闭环、遗留数据资源、源码占位和有证据支持的设计意图。必须区分原版证据与新设计推断，记录证据等级、原版限制、当前可实现条件、依赖和验收标准；不能把猜测称为“DBO 真意”。
4. **资产重构：轻量、现代、可操作。** 不只减体积，还要减少重复、改善加载缓存、便于编辑组合、保留原版视觉动画并形成可重复管线。研究素体标准化、装备版本差异、模型/材质/纹理复用、动画挂点和导入规范；先小样本验证外观、拓扑、动画、遮挡、内存、加载与运行成本。
5. **保留可重复游玩内容。** 不止一次性通关或进入世界；调查原版副本/挑战、周期活动、收集、制作强化、经济交易、社交组队、竞争玩法等实际存在的循环，记录入口、条件、奖励、周期限制、成长、多人依赖、离线能力和防重复领取。上述是调查类别，不预设每项原版状态。
6. **代码干净、轻量、无冲突。** 明确模块边界、单一职责、数据契约、生命周期和依赖；避免重复实现、循环依赖、全局状态滥用、硬编码、隐式资源路径、临时补丁及不一致的枚举/序列化。清洁度贯穿所有阶段，现代化不等于堆叠抽象层。

### 12.2 全量系统地图的起始覆盖面

系统地图至少调查以下领域，并继续依据 OpenDBO-Core、客户端/服务端代码、数据、资源、协议和可观察行为扩展：

- 玩家流程与客户端框架：启动、更新、登录、服务器/频道、创建/选择角色、加载、世界切换、UI、输入、设置、退出。
- 世界与空间：地图、区域、地形、区块、天气/昼夜（如原版支持）、传送、出生点、碰撞、环境物件、交互物、小地图。
- 角色与表现：种族、职业、转职、属性、状态机、移动、战斗动作、动画、骨骼、装备外观、挂点、变身/姿态、成长。
- 战斗与技能：目标、普通攻击、施法、命中、范围、伤害公式、属性、暴击/格挡、Buff/Debuff、控制、仇恨、死亡/复活、冷却、资源消耗、战斗反馈。
- NPC/怪物/AI：出生刷新、巡逻、感知、仇恨、战斗、掉落、交互、商店、训练、任务对话、脚本事件。
- 任务与叙事：主支线、重复任务、条件阶段、对话、剧情事件、奖励、状态持久化。
- 物品与经济：背包、装备槽、胶囊、消耗品、材料、掉落拾取、商店、交易、货币、制作/强化/升级、邮件/仓库（以原版证据为准）。
- 副本与重复内容：入口、队伍要求、实例生命周期、Boss 机制、奖励结算、重置周期、活动和挑战。
- 社交与多人：好友、聊天、组队、公会/社群（如原版支持）、邀请、交易、PvP/竞技、Host 合作会话、断线恢复。
- 数据与内容管线：原始数据解析、表格、脚本事件、资源索引、模型/纹理/材质/动画导出、版本追踪、校验、可重复构建。
- 在线与运营：认证、更新分发、云存档、全局规则、GM 临时授权、活动配置、玩家间数据交换、审计和反作弊边界。
- 项目扩展：Doll 等非原版内容，独立标注来源、规则、数据所有权、在线依赖和原版接口。
- 工程交付：模块依赖、性能、内存、加载、错误处理、存档迁移、自动化/回归测试、日志、构建、安装、更新和恢复。

这只是地图骨架，不是已经穷尽的原版清单。不得因当前仓库没有对应脚本就判定原版不存在该功能。

### 12.3 每个系统的统一档案

每个系统/子系统必须记录：原版玩家可见行为与规则；源码/数据/资源/协议/界面/运行证据；原版状态（完整、部分、未启用、疑似废弃、未知）；当前 DBOFF 状态；缺失代码/数据/资源/工具/运行证据；上下游依赖；本地与在线边界及离线降级；现代化实现方案；重复游玩价值；验收标准；证据等级与未知项。

### 12.4 规划完整性与开发优先级

- **规划先求全**：正式大规模实施前尽可能完成原版系统、数据、资源、未完成内容和依赖关系盘点；未知项必须显式登记，不得默认不存在。
- **开发先求可玩**：先打通基础闭环、修复关键 Bug；其他系统仍保留在全局地图和路线图中。
- **原版还原与项目扩展分开建档**：Doll 等扩展不混入原版机制结论。
- **资产和架构贯穿推进**：每个系统实施时同步确定数据契约、资源规范和模块边界。
- **重复游玩作为验收维度**：不能只以“能进世界/能打怪”定义可玩。
- **未知项可追溯**：记录搜索范围、已查来源和证据缺口；只有充分调查后才能判定“不存在/不适用”。

### 12.5 证据与当前状态

本节六大目标来自用户 2026-11-01 明确指示，属 **D：用户目标**；系统分类和档案字段是 ChatGPT 提出的规划方法。当前尚未完成 OpenDBO 全量客户端/服务端、数据表、资源、协议和运行行为盘点，**不能声称系统地图已经完整**。下一步先填充系统清单与依赖图，再排基础可玩闭环；每轮记录覆盖范围、未覆盖范围和新增发现。

### 2026-11-02
- **全项目资产与数据映射工程完成**：
  - 建立了总索引文档 `docs/ASSET_DATA_MAPPING.md` 以及 7 个子系统映射目录 `docs/ASSET_MAPPING_DETAILS/`。
  - **数据表映射** (`01_DATA_TABLE_MAPPING.md` + `table_registry.json`)：完成 280 张数据表（275 张位于 `assets/tbl/`，5 张位于 `data/`）的字段、主键与 OpenDBO 源码结构登记。
  - **角色与职业映射** (`02_CHARACTER_AND_CLASS_MAPPING.md` + `character_class_mapping.json`)：完成 6 大种族/性别素体模型路径及 12 种基础/进阶职业与 NewbieTable 出生配置的绑定。
  - **装备与物品映射** (`03_EQUIPMENT_AND_ITEM_MAPPING.md` + `equipment_item_mapping.csv` + `equipment_item_mapping.json`)：P0 级新手装备链打通（NewbieTable -> Item ID -> ItemTable -> ItemProperty -> 槽位 -> 对应成人/儿童模型 -> 贴图/骨骼/皮肤），明确区分儿童角色素体自带新手服装与成人模块化装备挂载机制。
  - **动画映射** (`04_ANIMATION_MAPPING.md` + `animation_mapping.json`)：完成 5,302 个 GLB 动作动画分类注册，梳理 CharacterAnimation 与 ItemTable 武器战斗待机/攻击动画映射逻辑。
  - **模型材质贴图映射** (`05_MODEL_MATERIAL_TEXTURE_MAPPING.md` + `model_texture_mapping.json`)：登记本地存在的 30,894 个 GLB 模型与 28,577 个 PNG 贴图资源库分布。
  - **大世界与地图映射** (`06_WORLD_AND_MAP_MAPPING.md` + `world_map_mapping.json`)：登记 106 个 WorldTable 世界及 50 个已就绪地形区域（共 15,453 个地形切片区块）。
  - **NPC、怪物、技能与特效映射** (`07_NPC_MOB_SKILL_EFFECT_MAPPING.md` + `npc_mob_skill_mapping.json`)：完成 3,169 个 NPC、7,125 个怪物及 2,663 个技能的数据表与模型特效对应关系整理。
  - 所有映射均按照 `VERIFIED`、`PARTIAL`、`INFERRED`、`MISSING`、`UNKNOWN` 严格标注证据等级，彻底解决今后跨模块调用与资产查证信息缺失问题。

### 2026-11-01 更新记录
- 将用户提出的六大长期目标和“先建立完整系统地图，再按优先级开发”的要求纳入项目基准。
- 新增全量系统地图起始分类、统一系统档案字段及规划完整性规则。
- 明确此为规划框架，尚非原版全量审计完成证明。


## 13. R2 资产存储与 AI 可读取方式（2026-11-01 讨论）

用户询问将 DBO 资产放入 Cloudflare R2 后，ChatGPT 是否能够直接查看。结论：**可以把 R2 作为资产分发/审查来源，但仅仅上传到 R2 并不会自动赋予 ChatGPT 访问权限。** 必须提供可访问的对象 URL，或提供受控的临时读取链接；并且需要有对象清单，不能假设可浏览整个 bucket。

### 13.1 可行访问模式

- **公开读取桶 + 自定义域名**：为专门用于审查的资产桶启用公开 GET/HEAD 访问，提供具体对象 URL。Cloudflare 官方文档说明 public bucket 可通过自定义域名或 r2.dev 暴露对象；默认 R2 桶为私有，公开访问需明确启用。r2.dev 有速率限制，官方定位为开发用途；长期使用优先考虑自定义域名。来源：https://developers.cloudflare.com/r2/buckets/public-buckets/
- **Presigned GET URL**：为单个对象生成限时读取链接，不需要公开整个 bucket。链接持有者在过期前可访问该对象，因此应当像 bearer token 一样保管，不要把 URL 当作无害普通链接。R2 presigned URL 有效期最长 7 天。来源：https://developers.cloudflare.com/r2/api/s3/presigned-urls/
- **私有 Worker/认证代理**：可由用户自己的 Worker 在授权后按需读取对象；但当前 ChatGPT 已连接的 Cloudflare 工具只提供文档检索和账号身份等能力，本轮未发现可直接列举/读取用户 R2 对象的工具。因此不能假设仅连接 Cloudflare 就能读取私有 bucket。若采用代理，仍需给审查流程一个可访问的受控 URL。

### 13.2 推荐的 DBOFF 用法（提案，尚未配置）

1. 建立独立的审查用途 bucket 或前缀，例如 dboff-review/，不要直接把所有生产资产或敏感文件公开。
2. 对不含密钥、账号信息、私人数据的可审查资产，优先使用独立只读公开域名；若不希望公开，则按批次生成短期 presigned GET URL。
3. 在 bucket 内维护 manifest.json，记录相对路径、文件名、格式、字节数、SHA-256、资产类别、来源/版本和关联数据 ID。公开桶根路径不能列举对象，因此 manifest 是发现文件的关键入口。
4. 对大规模资产先提供目录清单和小批样本，再按系统/地图/模型组分批读取；不要一开始把整个数 GB 资源包设为公开或要求单次读取。
5. 可直接下载的常见文本/JSON/XML/CSV 可用于内容审查；二进制模型/纹理/动画需要实际下载后用对应解析工具检查，能访问 URL 不等于已自动解析全部格式。
6. 不要提供 R2 API Secret、Access Key、Cloudflare Global API Token 或其他长期凭据。Presigned URL 本身具备访问能力，分享前确认其对象范围和过期时间。

### 13.3 访问能力边界

- 上传到 R2 ≠ ChatGPT 自动可见。
- 公开 bucket 通常只允许通过已知对象路径读取对象；Cloudflare 文档说明 bucket 根路径不提供对象列表。因此需要明确对象 URL 或 manifest.json。
- 对于私有 bucket，普通 URL 无法读取；需要临时签名 URL 或经过授权的读取代理。
- URL 可访问不保证所有格式都能在网页端直接预览；部分二进制资产需要下载、解包或专用工具分析。
- 本轮仅记录访问架构建议；没有创建 bucket、修改 Cloudflare 配置、上传或公开任何 DBOFF 资产。


## 14. OpenDBO-Core 全量客户端/服务端审计启动（2026-11-01）

### 14.1 审计基准与仓库规模

本轮开始按用户要求扩大 OpenDBO-Core 审计范围，不再将此前少数入口文件的阅读称为完整对照。

- 上游仓库：`OpenDBO/OpenDBO-Core`
- 分支：`master`
- 本轮锁定的 HEAD commit：`23cb305a6cf20048fec75595a8fa1ee2f1a0e83d`
- commit 时间：`2026-10-29T22:42:53Z`
- commit 信息：`Merge pull request #147 from riagoncalves/feat/event-reward-npc`
- 对应 Git tree SHA：`9b1885340a9d41f8a9a56fcdb54b30d75c63b3ae`
- 递归 tree 检查：43,728 个条目，GitHub 返回 `truncated=false`。

按顶层目录统计的条目数（包含文件和目录，不等于源文件数）：

| 顶层目录 | 条目数 | 当前观察 |
|---|---:|---|
| DboClient | 10,671 | 客户端、客户端库、编辑器和工具 |
| DboServer | 30,562 | 六类服务端程序、数据库、运行环境和大量服务端数据 |
| DboShared | 669 | 客户端/服务端共享结构、数据表定义、触发器 |
| NtlLib | 1,822 | 网络、引擎、工具和共享基础库 |

扩展名统计显示，DboClient 有 2,569 个 .cpp、4,335 个 .h；DboServer 有 771 个 .cpp、777 个 .h。DboServer/ExecutionEnv 有 28,976 个 tree 条目，其中可见 23,082 个 .dat、237 个 .rdf、352 个 .cf、352 个 .pf、357 个 .sps、534 个 .wps、3,604 个 .t 等数据文件。上述统计来自 Git tree，不代表每个文件都已阅读或已判定用途。

README 明确说明：
- DboServer/Server 包含 AuthServer、CharServer、ChatServer、GameServer（每个频道一个进程）、MasterServer、QueryServer；QueryServer 是唯一直接与数据库交互的服务。
- DboShared 放置两端共用的 packet definitions、game tables、triggers。
- DboServer/ExecutionEnv 包含配置、server_data 和启动脚本。
- DboClient 包含 Client、presentation/simulation/GUI/sound libraries，以及世界、模型、GUI、任务编辑器、PackEditor 和 DBOLauncher 等工具。

### 14.2 协议审计的首轮源码证据

已读取：
- `DboShared/NtlShared2/NtlPacketAll.h`（blob SHA `ab0a442fa02c67e67aeb4e0ab73780722396983b`）
- `DboShared/NtlShared2/NtlPacketCommon.h`（blob SHA `2bf4f83750d4f4d915514cd5d896e023c2d288de`）
- `DboShared/NtlShared2/NtlPacketUG.h`（blob SHA `5cf298d285b710e5c86467d5b33ec794a4308c6d`）
- `DboShared/NtlShared2/NtlPacketGU.h`（blob SHA `604d0f37295c7076fdc692d0a02590ad22c6f6b5`）
- `DboShared/NtlShared2/NtlPacketUA.h`（blob SHA `e5401e9b7d25bfc2c811fef1f935acec59b88f23`）
- `DboShared/NtlShared2/NtlPacketAU.h`（blob SHA `feff488c76e49f82672160282d1ce015f55543c6`）
- 客户端 `DboClient/Client/Main/PacketProc.cpp`（blob SHA `1bd07d230e15cd28656a2801140a8e0a51800ad5`）
- 客户端 `DboClient/Client/Main/DboPacketHandler.cpp`（blob SHA `b2f939619d6e2c1bf47de7d946b8d733b0a3c9d2`）
- GameServer `ug_opcodes.cpp/.h`（请求分派表；blob SHA 分别为 `6d2376f191847fb21d85b28ec1ee2cef3eca20e6`、`6583a400c7559f0c527d892f231817a3c4c4dab3`）
- ChatServer `tg_opcodes.cpp/.h`（GameServer 与 ChatServer 方向的分派表；blob SHA 分别为 `433445d362760e09e688631924cf4e2e448078e6`、`be6b1f3200c6b247d0da8e29e815d542c2265e93`）

首轮可确认：
1. `NtlPacketAll.h` 规定了按通信双方命名的协议族：U=游戏客户端、A=Auth、C=Character、G=Game、T=Community/Chat、M=Master、Q=Query、N=NPC、L=Log、W=Web、X=未定义/其他；例如 UG 是 User→Game，GU 是 Game→User。
2. 同一文件规定 opcode 数值区间，例如 UA 100–999、AU 1000–1999、UG 4000–4999、GU 5000–5999、UT 6000–6999、TU 7000–7999，以及多个服务器间通信区间。协议审计必须覆盖全部方向，不能只看客户端与 GameServer。
3. `NtlPacketCommon.h` 的当前 packet header 结构可见字段为 WORD wOpCode；旧版带 sequence/checksum 的结构被注释掉。具体线上帧格式、编码/加密、长度和可靠性语义仍需结合 NtlLib 网络层验证，不能仅凭该结构断言完整 wire format。
4. UG 定义客户端向 GameServer 发出的移动/状态、进入世界、技能、Buff、物品、商店、组队、银行、任务、交易、公会、龙珠、TimeQuest、RankBattle、传送和私人商店等请求类别；GU 定义服务器回传角色/世界信息、对象创建销毁、移动状态、战斗/技能/Buff、物品、组队及其他系统结果/通知。
5. GameServer 的 `ug_opcodes.cpp` 将 UG opcode 注册到具体 `CClientSession` 处理函数，并标注 PROCESS_INPLACE / PROCESS_THREADUNSAFE 等处理模式。这意味着协议清单必须进一步追到每个 handler 的校验、状态变更、持久化和回包，而不是停留在 packet struct。
6. Auth 登录协议 UA/AU 已可见请求/响应结构：请求包含用户 ID、加密密码字段、版本字段和网卡地址；响应包含结果码、用户 ID、Auth Key、账号 ID、上次服务器农场 ID、开发者权限、GM 标志和服务器列表。后续需核对密码处理、版本校验、Auth Key 生命周期、角色/频道连接链和失败状态。

### 14.3 首轮审计方向与未完成项

后续按以下链路逐步核查，并记录 packet struct → client generator → server opcode registration → handler → cross-server/query/database → response/notification → client handler → player-visible state：

- 登录、认证、服务器农场/频道选择、角色列表、创建/删除/选择角色、进入世界、加载完成、断线与重连；
- GameServer 与 ChatServer/Community、MasterServer、QueryServer、CharServer 的跨服务消息和状态同步；
- 角色移动、战斗、技能、Buff、物品、任务、NPC/怪物、掉落、交易、商店、背包/仓库；
- 组队、好友、聊天、公会/道场、邮件、私人商店、拍卖；
- TimeQuest、Dungeon/World Concept、Budokai、RankBattle、FreeBattle、Dragonball Scramble、动态世界事件、活动奖励、车辆、宠物/Mascot 等；
- 客户端表现与 UI 是否实际接收并执行相应消息；
- 未注册 opcode、未调用函数、仅有结构无 handler、仅有 handler 无客户端入口、宏/配置关闭、数据库表有数据但业务未接通、注释掉的代码、遗留版本分支和运行资源缺失。

### 14.4 当前缺少的材料与证据边界

本轮可通过公开 GitHub 读取上游源码和被跟踪的 ExecutionEnv 数据；但若要验证完整编译、运行行为和所有资源依赖，还缺少：
- 与该 commit 配套的 OpenDBO-Assets 客户端资源包及第三方依赖仓库/版本；
- 可运行的原版客户端文件（README 说明 DboClient/DragonBall 运行文件不在 Core 仓库跟踪）；
- 与此版本匹配的数据库实际实例、配置和可复现账号/角色数据（SQL schema/seed 只能说明初始化结构，不能替代运行实例）；
- 若要确认“实际游戏行为”，需要能运行的服务端/客户端环境、日志、封包或用户提供的录屏/操作复现；静态源码审计只能确认代码路径和设计，不自动证明运行时路径可达；
- 若要对照 DBOFF 的实现，还需随审计模块提供当前 DBOFF 对应脚本、场景、数据和资源。当前阶段不要求用户立即分类资产；后续可通过自动 manifest 和文件指纹盘点。

当前已完成的是仓库规模/结构摸底和协议入口首轮读取，**不是完整客户端、完整服务端或协议审计完成**。尤其尚未逐个读取所有服务端 handler、全部共享 packet 结构、数据库访问链和实际运行流程。

### 2026-11-02
- **全项目资产与数据映射工程完成**：
  - 建立了总索引文档 `docs/ASSET_DATA_MAPPING.md` 以及 7 个子系统映射目录 `docs/ASSET_MAPPING_DETAILS/`。
  - **数据表映射** (`01_DATA_TABLE_MAPPING.md` + `table_registry.json`)：完成 280 张数据表（275 张位于 `assets/tbl/`，5 张位于 `data/`）的字段、主键与 OpenDBO 源码结构登记。
  - **角色与职业映射** (`02_CHARACTER_AND_CLASS_MAPPING.md` + `character_class_mapping.json`)：完成 6 大种族/性别素体模型路径及 12 种基础/进阶职业与 NewbieTable 出生配置的绑定。
  - **装备与物品映射** (`03_EQUIPMENT_AND_ITEM_MAPPING.md` + `equipment_item_mapping.csv` + `equipment_item_mapping.json`)：P0 级新手装备链打通（NewbieTable -> Item ID -> ItemTable -> ItemProperty -> 槽位 -> 对应成人/儿童模型 -> 贴图/骨骼/皮肤），明确区分儿童角色素体自带新手服装与成人模块化装备挂载机制。
  - **动画映射** (`04_ANIMATION_MAPPING.md` + `animation_mapping.json`)：完成 5,302 个 GLB 动作动画分类注册，梳理 CharacterAnimation 与 ItemTable 武器战斗待机/攻击动画映射逻辑。
  - **模型材质贴图映射** (`05_MODEL_MATERIAL_TEXTURE_MAPPING.md` + `model_texture_mapping.json`)：登记本地存在的 30,894 个 GLB 模型与 28,577 个 PNG 贴图资源库分布。
  - **大世界与地图映射** (`06_WORLD_AND_MAP_MAPPING.md` + `world_map_mapping.json`)：登记 106 个 WorldTable 世界及 50 个已就绪地形区域（共 15,453 个地形切片区块）。
  - **NPC、怪物、技能与特效映射** (`07_NPC_MOB_SKILL_EFFECT_MAPPING.md` + `npc_mob_skill_mapping.json`)：完成 3,169 个 NPC、7,125 个怪物及 2,663 个技能的数据表与模型特效对应关系整理。
  - 所有映射均按照 `VERIFIED`、`PARTIAL`、`INFERRED`、`MISSING`、`UNKNOWN` 严格标注证据等级，彻底解决今后跨模块调用与资产查证信息缺失问题。

### 2026-11-01 更新记录
- 锁定 OpenDBO-Core master commit `23cb305a6cf20048fec75595a8fa1ee2f1a0e83d`，记录对应 tree SHA。
- 对递归 Git tree 进行完整性检查，确认 43,728 条目且未被 GitHub API 截断；记录客户端、服务端、共享库和 NtlLib 的规模。
- 阅读上游 README、共享 packet 总入口/通用头、UA/AU/UG/GU 协议头、客户端 PacketProc/主 packet handler、GameServer UG opcode 分派表和 ChatServer TG opcode 分派表。
- 建立从 packet struct 到玩家可见状态的端到端协议审计链路与待查项目。
- 明确缺少运行版客户端资产、第三方依赖、数据库实例和运行日志等材料；这些缺口影响运行行为验证，不妨碍继续静态源码审计。


## 15. Antigravity 资产修复结束后的全量盘点与 R2 交付（2026-11-01）

### 15.1 当前状态（用户报告）
- 用户确认 Antigravity 本轮修复工作已经完成。
- 用户确认模型、贴图和动画已完整提取；其他资产类型是否完整提取尚不能保证。
- 用户目前不希望承担人工资产分类工作；分类、格式识别、关联关系和完整性盘点应尽量由自动化扫描完成。
- 本节只记录用户报告与后续工作要求；尚未读取本轮 Antigravity 的最终导出目录、日志或报告，因此不能独立确认实际提取覆盖率。

### 15.2 全量扫描范围
盘点不得只扫描模型/纹理/动画目录。至少扫描：
- 模型与几何：OBJ、DFF、GLB、网格、骨骼、模型变体；
- 纹理、图集、材质、Shader 和材质参数；
- 动画片段、骨骼绑定、动作映射和动画配置；
- 粒子、技能/环境特效；
- UI 图片、图标、图集、字体；
- BGM、环境音、技能音效、语音；
- 地图、地形、区块、TileAttr/地表属性、碰撞、地图对象；
- NPC、怪物、道具、建筑、载具、交互对象；
- RDF、DAT、CF、PF、SPS、WPS、TBL、XML、JSON 等数据；
- 任务、技能、掉落、对话、事件、触发器及其他脚本配置；
- 所有未知扩展名、无扩展名和暂不能识别的二进制文件。
未知文件必须保留并进入待识别清单，不得因扩展名未知而删除或跳过。

### 15.3 每个文件的资产记录
后续 manifest 至少记录：
- 稳定 asset_id；
- original_path（相对原始资源根目录）；
- exported_path（相对导出根目录，可空）；
- extension、size_bytes、SHA-256；
- 自动识别的 asset_type 和识别置信度；
- source_version、export_tool/version；
- export_status、错误信息；
- references（与模型、材质、贴图、骨骼、动画、数据 ID 等关联）；
- notes。
同时保留原始文件、导出文件、失败清单、未知文件清单、重复文件清单、关联关系和可复现导出日志。不得把转换成功等同于资源完整性验收；仍需检查贴图引用、骨骼/动画兼容、模型变体覆盖和资源引用闭环。

### 15.4 本地路径可变更的设计
- manifest 中禁止把机器绝对路径作为资产身份或稳定引用。
- 路径以相对路径表示，并在扫描/同步配置中单独指定本地 source_root、export_root 和 R2 destination prefix。
- 本地目录移动后，只需更新根目录映射，不应改变 asset_id、SHA-256 或对象身份。
- R2 object key 使用稳定前缀和相对路径；避免把 Windows 盘符、用户名或本机绝对路径写入对象 key。
- 同步应支持 dry-run、增量上传、失败重试、断点续传、远端校验和显式删除保护；默认不得因本地某次扫描缺失就删除 R2 对象。
- 上传完成后生成远端 manifest 与上传报告，按 SHA-256/大小核对，不以 ETag 代替 SHA-256。

### 15.5 R2 容量和上传能力（Cloudflare 官方文档，2026-11-01 检索）
- R2 单桶存储容量不限、每桶对象数不限；默认每账户 bucket 数上限 100,000，超过部分按官方定价收费。
- 单对象最大 5 TiB（官方限制表精确表述为 5 GiB less than 5 TiB）；单次普通 PUT 最大 5 GiB less 5 MiB，超大对象应使用 multipart。
- Multipart 最多 10,000 个 part；每个 part 5 MiB 至 5 GiB（最后一个 part 可小于 5 MiB）；支持并行和失败分片重试。未完成 multipart 默认 7 天后自动中止。
- Wrangler 单文件上传上限 315 MB 且一次一个对象，不适合本项目的大批量资产同步；官方文档推荐大文件/批量使用 rclone 或 S3-compatible 工具。
- 当前官方 Standard 定价为 $0.015/GB-month；每月免费额度 10 GB-month、1M Class A、10M Class B；互联网出口流量免费。Infrequent Access 为 $0.01/GB-month，但有读取/检索费用和 30 天最低存储期，不适合频繁审查和频繁读取的工作资产。
- 生产分发建议使用自定义域名；r2.dev 仅用于开发测试并有可变速率限制。
- 私有对象可用短期 presigned GET/PUT；URL 是 bearer token，应限制有效期和对象范围。公开 bucket 需明确开启，不能默认公开整个资产库。
- 来源：
  - https://developers.cloudflare.com/r2/platform/limits/
  - https://developers.cloudflare.com/r2/objects/upload-objects/
  - https://developers.cloudflare.com/r2/pricing/
  - https://developers.cloudflare.com/r2/api/s3/presigned-urls/
  - https://developers.cloudflare.com/r2/buckets/public-buckets/

### 15.6 R2 对象分区提案（尚未配置）
建议用一个专用 DBOFF R2 bucket，按用途分前缀，而不是将所有内容混成一个目录：
- assets/raw/：原始提取资产，保留原格式；
- assets/exported/：转换后的可用资产；
- assets/manifests/：完整 manifest、分类索引、关系索引、校验报告；
- assets/review/：供审查使用的抽样或明确授权读取资产；
- releases/client/<version>/：未来客户端安装包/压缩包；
- releases/metadata/：版本清单、SHA-256、签名、更新说明和平台信息；
- backups/：仅在明确需要时存放备份。
以上是逻辑前缀，不要求创建真实目录对象。R2 不限制单桶对象数量/容量，资产和安装包可放同一桶，但权限、公开域名、缓存策略和生命周期应按前缀隔离。
不建议将全部原始资产公开。优先保持私有，通过受控 Worker 或短期 presigned URL 提供指定对象访问；若将来要公开分发客户端安装包，应只公开 releases 中经过签名和校验的发布对象。

### 15.7 尚需用户/Antigravity 提供的材料
当前缺少：
1. Antigravity 本轮修复完成后的最终导出目录树；
2. 原始资源根目录和已导出模型/纹理/动画的路径（可只提供根目录，不要求人工分类）；
3. 本轮提取脚本/工具名称与版本、执行日志、成功/失败统计；
4. 现有导出是否保留原始格式文件，以及是否有资源 ID/引用关系输出；
5. R2 当前 bucket 是否已创建、bucket 名称、现有自定义域名/访问策略（只需非秘密配置状态，不要提供 API Secret/Access Key）。
在取得这些材料前，不估算总资产数量/容量，不宣称提取完整，也不创建或公开 R2 bucket。

### 15.8 后续工作
1. 先让 Antigravity 生成全盘扫描报告与机器可读 manifest，不要立刻批量上传。
2. 核对已导出的模型/纹理/动画覆盖率，列出未导出和未知文件。
3. 根据扫描总容量、文件分布和读取需求确定 R2 前缀、访问策略和同步工具。
4. 先上传小样本，验证路径映射、断点续传、SHA-256、远端读取和本地根目录变更。
5. 验证通过后再全量上传，并将资产 manifest 与 OpenDBO 功能审计系统关联。

### 2026-11-02
- **全项目资产与数据映射工程完成**：
  - 建立了总索引文档 `docs/ASSET_DATA_MAPPING.md` 以及 7 个子系统映射目录 `docs/ASSET_MAPPING_DETAILS/`。
  - **数据表映射** (`01_DATA_TABLE_MAPPING.md` + `table_registry.json`)：完成 280 张数据表（275 张位于 `assets/tbl/`，5 张位于 `data/`）的字段、主键与 OpenDBO 源码结构登记。
  - **角色与职业映射** (`02_CHARACTER_AND_CLASS_MAPPING.md` + `character_class_mapping.json`)：完成 6 大种族/性别素体模型路径及 12 种基础/进阶职业与 NewbieTable 出生配置的绑定。
  - **装备与物品映射** (`03_EQUIPMENT_AND_ITEM_MAPPING.md` + `equipment_item_mapping.csv` + `equipment_item_mapping.json`)：P0 级新手装备链打通（NewbieTable -> Item ID -> ItemTable -> ItemProperty -> 槽位 -> 对应成人/儿童模型 -> 贴图/骨骼/皮肤），明确区分儿童角色素体自带新手服装与成人模块化装备挂载机制。
  - **动画映射** (`04_ANIMATION_MAPPING.md` + `animation_mapping.json`)：完成 5,302 个 GLB 动作动画分类注册，梳理 CharacterAnimation 与 ItemTable 武器战斗待机/攻击动画映射逻辑。
  - **模型材质贴图映射** (`05_MODEL_MATERIAL_TEXTURE_MAPPING.md` + `model_texture_mapping.json`)：登记本地存在的 30,894 个 GLB 模型与 28,577 个 PNG 贴图资源库分布。
  - **大世界与地图映射** (`06_WORLD_AND_MAP_MAPPING.md` + `world_map_mapping.json`)：登记 106 个 WorldTable 世界及 50 个已就绪地形区域（共 15,453 个地形切片区块）。
  - **NPC、怪物、技能与特效映射** (`07_NPC_MOB_SKILL_EFFECT_MAPPING.md` + `npc_mob_skill_mapping.json`)：完成 3,169 个 NPC、7,125 个怪物及 2,663 个技能的数据表与模型特效对应关系整理。
  - 所有映射均按照 `VERIFIED`、`PARTIAL`、`INFERRED`、`MISSING`、`UNKNOWN` 严格标注证据等级，彻底解决今后跨模块调用与资产查证信息缺失问题。

### 2026-11-01 更新记录
- 用户确认 Antigravity 本轮修复已结束；模型、贴图和动画已完整提取，但其他资产覆盖率未知。
- 将后续任务改为自动化全盘发现、提取覆盖率核对和未知文件保留，不要求用户人工分类。
- 根据 Cloudflare 官方最新文档补充 R2 容量、对象大小、multipart、上传工具、价格、访问策略和未来客户端安装包分区方案。
- 明确目前尚未确认 R2 bucket 已创建，也未进行任何 R2 配置或上传。


## 16. OpenDBO-Core 协议覆盖扩展：角色、社区、服务器协调与数据库消息（2026-11-01）

审计仍固定在 OpenDBO-Core master commit 23cb305a6cf20048fec75595a8fa1ee2f1a0e83d，不将其他版本的协议定义混入本轮统计。

### 16.1 新增读取的共享协议头
本轮继续读取：
- NtlPacketUC.h / NtlPacketCU.h：客户端与 CharServer；
- NtlPacketUT.h / NtlPacketTU.h：客户端与 Community/Chat；
- NtlPacketMG.h / NtlPacketGM.h：Master/服务器协调方向；
- NtlPacketGQ.h / NtlPacketQG.h：GameServer 与 QueryServer；
并重新读取 UA/AU、UG/GU 作为同一版本统计基线。

### 16.2 目前读取的 12 个协议族初步计数
按共享头文件 enum 中实际命名的 opcode 项目初步计数（排除 BEGIN/END/DUMMY 标记；尚未完成与注册表逐项对账）：

| 协议族 | 初步 opcode 数 | 主要覆盖 |
|---|---:|---|
| UA | 2 | 客户端认证请求 |
| AU | 2 | 认证结果/断开响应 |
| UC | 12 | CharServer 登录、服务器列表、角色创建/删除/选择/加载/退出、等待队列、改名 |
| CU | 22 | 角色服务响应、角色信息、服务器/频道列表、排队通知、断开与角色通知 |
| UG | 322 | 客户端到 GameServer 的游戏行为请求/通知 |
| GU | 681 | GameServer 到客户端的状态、对象、战斗、系统响应/通知 |
| UT | 46 | 聊天、好友、公会、排名、TMQ 记录、Budokai、客服 Petition、Dojo、HLS |
| TU | 96 | 社区响应/广播、公会/好友/排名、TMQ/Budokai、Petition、Dojo、HLS |
| MG | 27 | 服务器信息、服务状态、世界分配、版本/人数、踢人、频道切换/跨服传送协调 |
| GM | 18 | 服务器注册/心跳/负载/人数报告、登录/登出、玩家迁移、关闭与活动状态通知 |
| GQ | 252 | 角色持久化、物品/技能/Buff/任务/邮件/宠物/商店/公会银行/Budokai/拍卖/现金商城/称号/活动奖励等数据库请求 |
| QG | 243 | 对应查询/持久化响应及数据载荷 |
| **合计** | **1,723** | 以上 12 个已读取协议头的初步 enum 项目数 |

计数是协议定义规模，不等于 1,723 个可供玩家使用的独立功能；其中包含请求、响应、通知、数据分片、内部管理消息和可能遗留的 opcode。还必须核查 opcode 是否注册、处理函数是否有业务闭环、客户端是否有调用/显示、配置和数据是否支持。

### 16.3 新增确认的系统范围
- 角色服务 UC/CU 不只是角色创建/选择，还包含服务器农场列表、单服务器列表、等待队列检查/取消、角色删除取消和改名。UC opcode 注册表中可见多个请求被绑定到 CClientSession 方法；本轮只截取验证了前段注册，尚未逐项统计全表。
- 社区服务 UT/TU 明确不只是聊天。协议头还覆盖好友黑名单、公会管理/职位、Dojo、RankBattle 排名查询、TMQ 记录、Budokai 赛事信息、客服 Petition 和 HLS Slot Machine。必须把社区服务作为独立系统审计。
- Master/服务器协调 MG/GM 覆盖服务器注册信息、心跳、负载、在线人数、服务器/频道列表更新、版本通知、强制踢人、玩家频道切换、CharServer teleport 和服务器关闭。玩家跨频道/跨服流程不能只看客户端 UG/GU。
- GameServer/QueryServer GQ/QG 的数据库消息远超角色基础存档，包含角色、背包、装备耐久、技能、Buff、任务状态、宠物、交易、邮件、私人商店、排名/Budokai、Hoipoi Mix、现金物品、拍卖、称号、Mascot、Dynamic Field、Event Reward 等持久化/查询接口。需要逐项确认 QueryServer handler、数据库表/事务、失败处理和 GameServer 回包。

### 16.4 当前审计边界与下一批工作
目前没有完成：
1. 12 个协议族所有 opcode 与服务端注册表逐项差异比对；
2. AuthServer、CharServer、GameServer、ChatServer、MasterServer、QueryServer 的全部分派表及 handler 调用链；
3. 客户端全部 packet send/generator 与 receive handler 的对照；
4. GQ/QG 对应 QueryServer 处理函数、SQL、表结构和事务闭环；
5. UT/TU 社区消息的 ChatServer/CommunityServer 业务路径及与 GameServer 的桥接；
6. 服务器迁移、跨频道、登录等待队列的时序和失败路径；
7. 代码存在但未注册、注册但未调用、客户端 UI 不可达、宏/配置关闭和数据缺失等功能状态判定。
本轮通过 GitHub connector 直接按固定 commit 读取了共享协议头；尝试的部分服务端 opcode 文件路径未命中，不能据此断言不存在，后续需要从仓库实际路径搜索定位。

### 2026-11-02
- **全项目资产与数据映射工程完成**：
  - 建立了总索引文档 `docs/ASSET_DATA_MAPPING.md` 以及 7 个子系统映射目录 `docs/ASSET_MAPPING_DETAILS/`。
  - **数据表映射** (`01_DATA_TABLE_MAPPING.md` + `table_registry.json`)：完成 280 张数据表（275 张位于 `assets/tbl/`，5 张位于 `data/`）的字段、主键与 OpenDBO 源码结构登记。
  - **角色与职业映射** (`02_CHARACTER_AND_CLASS_MAPPING.md` + `character_class_mapping.json`)：完成 6 大种族/性别素体模型路径及 12 种基础/进阶职业与 NewbieTable 出生配置的绑定。
  - **装备与物品映射** (`03_EQUIPMENT_AND_ITEM_MAPPING.md` + `equipment_item_mapping.csv` + `equipment_item_mapping.json`)：P0 级新手装备链打通（NewbieTable -> Item ID -> ItemTable -> ItemProperty -> 槽位 -> 对应成人/儿童模型 -> 贴图/骨骼/皮肤），明确区分儿童角色素体自带新手服装与成人模块化装备挂载机制。
  - **动画映射** (`04_ANIMATION_MAPPING.md` + `animation_mapping.json`)：完成 5,302 个 GLB 动作动画分类注册，梳理 CharacterAnimation 与 ItemTable 武器战斗待机/攻击动画映射逻辑。
  - **模型材质贴图映射** (`05_MODEL_MATERIAL_TEXTURE_MAPPING.md` + `model_texture_mapping.json`)：登记本地存在的 30,894 个 GLB 模型与 28,577 个 PNG 贴图资源库分布。
  - **大世界与地图映射** (`06_WORLD_AND_MAP_MAPPING.md` + `world_map_mapping.json`)：登记 106 个 WorldTable 世界及 50 个已就绪地形区域（共 15,453 个地形切片区块）。
  - **NPC、怪物、技能与特效映射** (`07_NPC_MOB_SKILL_EFFECT_MAPPING.md` + `npc_mob_skill_mapping.json`)：完成 3,169 个 NPC、7,125 个怪物及 2,663 个技能的数据表与模型特效对应关系整理。
  - 所有映射均按照 `VERIFIED`、`PARTIAL`、`INFERRED`、`MISSING`、`UNKNOWN` 严格标注证据等级，彻底解决今后跨模块调用与资产查证信息缺失问题。

### 2026-11-01 更新记录
- 增加 UC/CU、UT/TU、MG/GM、GQ/QG 八个共享协议头的读取记录。
- 对 UA/AU、UC/CU、UG/GU、UT/TU、MG/GM、GQ/QG 共 12 个方向协议族作出 1,723 项初步 enum 计数，明确这不是功能完成度或玩家可用功能数。
- 识别社区、服务器协调和数据库持久化协议中此前未纳入首轮摘要的系统范围。
- 将协议定义与 opcode 注册、handler、SQL、客户端 UI/行为之间的差异核查列为后续工作。


## 17. 修正资产提取链路、暂停资产 R2 存储并扩大数据文件对照（2026-11-01）

### 17.1 资产真实来源链路（用户澄清，优先于第 15 节的泛化表述）
- 原始资产并非直接以普通散文件目录提供，而是封装在原版 `.pak` 资源包中。
- Antigravity 先解码 `.pak`，生成 `raw/` 文件夹；再从 `raw/` 中导出/转换资源。
- 用户确认模型、贴图、动画已完成提取；除此之外的资源类型是否完整尚未确认。
- 因此本轮审计的核心比较对象是：`raw` 解码文件清单 ↔ 当前全部导出文件清单，并结合解码/导出日志与 OpenDBO-Core 数据文件清单追踪覆盖率。
- 不能只比较文件名或要求转换前后 SHA-256 相同。应优先利用原始路径、资源 ID、内部名称、导出日志、引用关系和格式特征建立对应；SHA-256 仅用于判断原文件是否原样复制或重复。
- raw 中所有未知扩展名、无扩展名和二进制文件都必须纳入清单，不能因为不认识就视为无用。

### 17.2 R2 方案调整
- 用户认为 Cloudflare R2 每月 10 GB 免费存储额度对于资产库和未来客户端安装包均较紧张，决定现阶段放弃将完整资产库放入 R2。
- 暂停资产上传、R2 bucket/prefix 设计实施和资产公开读取方案；不创建、不上传、不公开任何资产。
- 资产继续由用户本地保存；先建立本地 manifest、索引、覆盖率报告和可重复扫描流程。
- R2 未来仅作为客户端安装包/正式发布物的候选分发存储，待实际安装包体积、版本数量、下载需求和预算明确后重新评估。不得把之前的 R2 资产仓库提案当成已批准实施方案。
- 本地路径可变更仍然是 manifest/扫描工具的要求：使用相对路径、稳定 ID 和 SHA-256；不把盘符或绝对路径写入稳定资产身份。

### 17.3 OpenDBO-Core ExecutionEnv 数据文件基准（需逐项核验）
此前对固定 commit `23cb305a6cf20048fec75595a8fa1ee2f1a0e83d` 的递归 Git tree 统计显示 DboServer/ExecutionEnv 下存在以下扩展名数量：

| 扩展名 | Git tree 统计数 |
|---|---:|
| .dat | 23,082 |
| .rdf | 237 |
| .cf | 352 |
| .pf | 352 |
| .sps | 357 |
| .wps | 534 |
| .t | 3,604 |

这些是 OpenDBO-Core 仓库特定 commit 中的文件数量基准，不表示它们都应存在于 `.pak` 解码结果，也不表示都属于客户端资源。尤其 ExecutionEnv 是服务端运行环境目录，必须依据具体路径、文件名、内容结构、加载代码和配置，区分服务端运行数据、客户端资源、共享数据、配置/脚本及未知数据。不能将“raw 中没有该文件”直接定性为资产提取遗漏。

后续需要建立按扩展名、相对路径、文件名/ID、数据结构和加载代码引用的双向对照表，并标注每项结论：
- raw 中存在且导出/保留；
- raw 中存在但未导出；
- OpenDBO 服务端专有数据（不应期待在客户端 pak）；
- 客户端/共享数据，需进一步查找对应来源；
- 同扩展名但用途不同；
- 版本差异/无法匹配/未知。

### 17.4 Antigravity 只读审计任务
已向用户提供可直接交给 Antigravity 的完整只读任务指令，要求它：
1. 盘点 `.pak` 解码后的完整 raw 目录；
2. 盘点当前全部导出目录；
3. 建立 raw→export 映射及缺失、失败、未知、重复清单；
4. 检查解码/导出脚本过滤条件和遗漏风险；
5. 统计 .dat/.rdf/.cf/.pf/.sps/.wps/.t 等类型并对照 OpenDBO-Core；
6. 输出 Markdown、CSV、JSON 报告，不改动任何原始文件或项目代码。

预期报告：ASSET_AUDIT_REPORT.md、raw_inventory.csv、export_inventory.csv、raw_to_export.csv、missing_exports.csv、failed_exports.csv、unknown_files.csv、duplicate_files.csv、opendbo_data_comparison.csv、opendbo_missing_data.csv、extraction_coverage.json、data_type_inventory.json。

### 17.5 当前缺失材料与审计边界
尚未收到 Antigravity 实际扫描结果、raw 目录位置、所有导出目录位置、解码/导出日志或工具版本。因此目前不能报告 raw 文件总量、导出覆盖率、缺失数量，也不能断言已提取的模型/贴图/动画经过独立核验。
下一步先取得 Antigravity 报告，再由 ChatGPT 对照 OpenDBO-Core 固定 commit 的真实文件清单、目录归属和加载代码，判定哪些是客户端资产缺失、哪些是服务端专有数据、哪些是版本差异或未识别数据。

### 2026-11-02
- **全项目资产与数据映射工程完成**：
  - 建立了总索引文档 `docs/ASSET_DATA_MAPPING.md` 以及 7 个子系统映射目录 `docs/ASSET_MAPPING_DETAILS/`。
  - **数据表映射** (`01_DATA_TABLE_MAPPING.md` + `table_registry.json`)：完成 280 张数据表（275 张位于 `assets/tbl/`，5 张位于 `data/`）的字段、主键与 OpenDBO 源码结构登记。
  - **角色与职业映射** (`02_CHARACTER_AND_CLASS_MAPPING.md` + `character_class_mapping.json`)：完成 6 大种族/性别素体模型路径及 12 种基础/进阶职业与 NewbieTable 出生配置的绑定。
  - **装备与物品映射** (`03_EQUIPMENT_AND_ITEM_MAPPING.md` + `equipment_item_mapping.csv` + `equipment_item_mapping.json`)：P0 级新手装备链打通（NewbieTable -> Item ID -> ItemTable -> ItemProperty -> 槽位 -> 对应成人/儿童模型 -> 贴图/骨骼/皮肤），明确区分儿童角色素体自带新手服装与成人模块化装备挂载机制。
  - **动画映射** (`04_ANIMATION_MAPPING.md` + `animation_mapping.json`)：完成 5,302 个 GLB 动作动画分类注册，梳理 CharacterAnimation 与 ItemTable 武器战斗待机/攻击动画映射逻辑。
  - **模型材质贴图映射** (`05_MODEL_MATERIAL_TEXTURE_MAPPING.md` + `model_texture_mapping.json`)：登记本地存在的 30,894 个 GLB 模型与 28,577 个 PNG 贴图资源库分布。
  - **大世界与地图映射** (`06_WORLD_AND_MAP_MAPPING.md` + `world_map_mapping.json`)：登记 106 个 WorldTable 世界及 50 个已就绪地形区域（共 15,453 个地形切片区块）。
  - **NPC、怪物、技能与特效映射** (`07_NPC_MOB_SKILL_EFFECT_MAPPING.md` + `npc_mob_skill_mapping.json`)：完成 3,169 个 NPC、7,125 个怪物及 2,663 个技能的数据表与模型特效对应关系整理。
  - 所有映射均按照 `VERIFIED`、`PARTIAL`、`INFERRED`、`MISSING`、`UNKNOWN` 严格标注证据等级，彻底解决今后跨模块调用与资产查证信息缺失问题。

### 2026-11-01 更新记录
- 用户澄清资产从 `.pak` 解码至 `raw/` 后再导出；修正此前将其泛化为普通原始目录扫描的描述。
- 用户决定现阶段放弃将完整资产库放入 R2；暂停资产上传计划，未来 R2 只重新评估客户端发布物分发。
- 将 raw→export 覆盖率对比和 OpenDBO-Core ExecutionEnv 数据文件清单核对设为两项明确任务。
- 强调 ExecutionEnv 扩展名数量是服务端仓库统计基准，不等于客户端 pak 预期数量；必须按路径和加载代码判定用途。


## 18. Antigravity 全量资产审计报告首轮核查（2026-11-01）

### 18.1 GitHub 交付物与审计范围

用户确认已将报告和所需清单推送至 GitHub。已检查 `gaaing/DBOFF` 的 `main` 分支，最新提交为 `c297e0f723b3e1b996280b4003c1d0f33da5544e`（本地时间 2026-11-01 21:08 左右）。该提交新增 `docs/asset_audit/` 下 12 个审计工件：
- `ASSET_AUDIT_REPORT.md`
- `raw_inventory.csv`
- `export_inventory.csv`
- `raw_to_export.csv`
- `missing_exports.csv`
- `failed_exports.csv`
- `unknown_files.csv`
- `duplicate_files.csv`
- `opendbo_data_comparison.csv`
- `opendbo_missing_data.csv`
- `extraction_coverage.json`
- `data_type_inventory.json`

已读取综合报告、覆盖率 JSON、类型识别 JSON、失败清单和未知文件清单；核对了 GitHub commit 文件变更统计及当前仓库目录。大型 CSV（数 MB 至 30 MB）已确认存在并核对 GitHub 行数/文件大小元数据，但当前读取接口无法返回其完整正文，因此尚未逐行独立重算映射结果。

### 18.2 报告数字（均为 Antigravity 扫描结果，尚非独立重扫）

报告声称：
- 原始客户端 pak：469 个、合计 8.08 GB；
- 解码 raw：120,234 个文件、7,921,411,207 bytes（约 7.377 GB）；
- 本地 Godot 导出目录：129,928 个文件、4,790,934,092 bytes（约 4.462 GB），其中 78,562 个纯资产/数据文件及 51,366 个 `.import` 元数据；
- raw 状态分布：52,997 已转换导出、7,806 直接保留、47,915 重复副本、11,478 尚未导出、38 暂时无法识别；
- 16,336 个重复组，涉及 64,251 个文件；重复副本数 47,915；
- 失败清单只有 CSV 表头，覆盖率 JSON 各类型 `failed_count` 均为 0；
- 66 个 `sound*.pak`（报告估算 1.25 GB）尚未解包，raw 的 `extracted/sound` 为空。

覆盖率 JSON 的状态总数可正确相加：52,997 + 7,806 + 47,915 + 11,478 + 38 = 120,234。已匹配/转换数 60,803 = 52,997 + 7,806。以上只反映该次报告记录的本地扫描结果，不证明资源运行质量或完整可用。

### 18.3 已发现的报告内部矛盾与分类问题

1. **动画覆盖率百分比计算错误**：JSON 给出 26,398 个 `.anm`，其中 13,320 个重复、12,936 个已匹配、142 个未匹配；唯一文件数为 13,078。按报告所列分子/分母计算，12,936 / 13,078 ≈ **98.91%**，不是摘要所写的 **99.46%**。若 142 个确实全部属于杂项动作，必须给出可复核的分类清单，才能单独声称“核心动作 100%”。
2. **SWF 数量混淆**：扩展名统计和 JSON 均为 `.swf` raw_count=427、duplicate=1、unmatched=426；报告另一处却称“1,812 个 .swf”。1,812 是 `extracted/flash` 目录总文件数，不是报告自身统计的 `.swf` 文件数。应更正为 427 个 SWF，并另外说明 flash 目录其余文件的类型。
3. **未知文件清单误分类**：`unknown_files.csv` 中包含 15 个以 `glTF`（`676c5446`）开头的标准 GLB 文件、带 UTF-16 BOM 的 HTML 页面，以及以 OLE Compound File 签名 `D0 CF 11 E0` 开头的 `thumbs.db`。这些至少应先归为已识别格式/候选格式，不能全部描述成空文件、损坏碎片或未知二进制。未知清单应区分“格式已知但用途待判”和“格式本身未知”。
4. **missing_exports.csv 口径需说明**：GitHub commit 显示该文件有 11,516 条数据记录（另有表头），正好等于 11,478 个未导出状态 + 38 个暂时无法识别项。因此它并非全部都是“已确认有效资产缺失”；应拆分有效未导出、未知待识别、疑似无用/缓存等类别。
5. **失败数为零不等于转换过程没有失败**：`failed_exports.csv` 只有表头；报告同时指出部分工具使用 `except Exception: pass` 静默吞错。故当前只能说“没有记录到失败条目”，不能据此证明转换失败为零。
6. **ExecutionEnv 汇总数字不一致**：报告表格所列七种扩展名的本地实际数量相加为 28,517（23,082 + 237 + 352 + 352 + 357 + 533 + 3,604），但表格总计写 28,817，报告开头/CSV 行数又指向 28,821。至少有 300/304 个文件未在七类扩展名明细中解释，且表格总计与目录文件总数还差 4。需要从 `opendbo_data_comparison.csv` 明确列出其他扩展名、目录过滤规则和计数口径。
7. **OpenDBO 版本基准未锁定**：报告使用本地 `E:\\OpenDBO-Core-master`，未记录 commit SHA。此前 DBOFF 审计锁定的参考版本为 `23cb305a6cf20048fec75595a8fa1ee2f1a0e83d`。在确认本地 checkout 与该 commit 一致前，不得把本次本地数量直接替换固定版本基线。
8. **RDF 文件数不能代表有效解析率**：报告称 raw 有 251 个 RDF、200 个 JSON 导出，其中 50 个重复、1 个唯一文件未导出；同时指出仅 4 张表有真实解析器，其余 196 张导出为仅含文件大小/十六进制样本的占位 JSON。因此“导出 200 个”不能表述成“成功解析 200 张表”，实际具备结构化字段解析的表目前报告为 4 张。
9. **文件数量覆盖不等于模型质量覆盖**：报告自己指出模型导出会丢失单 Geometry 多材质表面。即使 12,561 个 DFF 都有 GLB 对应，也不代表几何、材质分面、贴图引用和视觉表现正确。

### 18.4 首轮可采纳的资产缺口

以下按报告中的 raw/coverage 数据可作为高优先级待处理项，但仍需后续清单和源码核验：
- 1,385 个 TGA，其中 785 个重复，约 600 个唯一文件未导出；
- 427 个 SWF，其中 1 个重复，约 426 个唯一文件未导出（不能写成 1,812 个 SWF）；
- 311 个 FRM（300 个非重复未导出）；
- 229 个 SRF（221 个非重复未导出）；
- 19 个 SCR 未导出；
- 142 个非重复 ANM 未匹配（其“杂项”分类尚待证明）；
- 2 个独立 DFF 未匹配：报告列为 `mesh_npc/e_pos_a1.dff` 与 `effect/magma_03.dff`；
- 66 个 sound pak 尚未解码，意味着 raw 目录并不覆盖全部原始 pak 内容；
- RDF 其余 196 张表仍是占位导出，不应接入正式玩法逻辑作为真实表数据。

### 18.5 GitHub 当前可见范围与缺少材料

当前 `gaaing/DBOFF` 的根目录仅有 `assets/tbl/` 等白名单目录；`.gitignore` 明确忽略 `assets/` 下除 `assets/tbl/` 以外的内容。当前仓库中没有上传报告所统计的完整模型/贴图/动画二进制导出库，也没有 `tools/` 目录。
本次尝试在 `gaaing/DragonballOfflineClient/tools/` 读取报告点名的脚本也未找到。因此，以下材料仍缺少，不能独立确认报告中的源码结论：
- `batch_export_all_items.py`
- `batch_convert_textures.py`
- `export_all_rdf_to_dboff.py`
- `batch_master_asset_pipeline.py`
- `batch_sync_audio_and_tga.py`
- `build_dboff_all_worlds.py`
- 实际解码器/ pak 解码脚本及版本；
- 原始 pak 文件清单（特别是 66 个 sound pak 的准确文件名、大小和解码状态）；
- 若要验证模型转换质量，需提供报告点名的 DFF 样本及对应 GLB，或允许从用户本地导出目录抽样核验。

大型 CSV 已上传，但当前连接读取接口无法返回其完整正文；后续仍需通过可读取的分段/抽样方式核查具体路径映射，特别是 `raw_to_export.csv`、`missing_exports.csv` 和 `opendbo_data_comparison.csv`。

### 2026-11-02
- **全项目资产与数据映射工程完成**：
  - 建立了总索引文档 `docs/ASSET_DATA_MAPPING.md` 以及 7 个子系统映射目录 `docs/ASSET_MAPPING_DETAILS/`。
  - **数据表映射** (`01_DATA_TABLE_MAPPING.md` + `table_registry.json`)：完成 280 张数据表（275 张位于 `assets/tbl/`，5 张位于 `data/`）的字段、主键与 OpenDBO 源码结构登记。
  - **角色与职业映射** (`02_CHARACTER_AND_CLASS_MAPPING.md` + `character_class_mapping.json`)：完成 6 大种族/性别素体模型路径及 12 种基础/进阶职业与 NewbieTable 出生配置的绑定。
  - **装备与物品映射** (`03_EQUIPMENT_AND_ITEM_MAPPING.md` + `equipment_item_mapping.csv` + `equipment_item_mapping.json`)：P0 级新手装备链打通（NewbieTable -> Item ID -> ItemTable -> ItemProperty -> 槽位 -> 对应成人/儿童模型 -> 贴图/骨骼/皮肤），明确区分儿童角色素体自带新手服装与成人模块化装备挂载机制。
  - **动画映射** (`04_ANIMATION_MAPPING.md` + `animation_mapping.json`)：完成 5,302 个 GLB 动作动画分类注册，梳理 CharacterAnimation 与 ItemTable 武器战斗待机/攻击动画映射逻辑。
  - **模型材质贴图映射** (`05_MODEL_MATERIAL_TEXTURE_MAPPING.md` + `model_texture_mapping.json`)：登记本地存在的 30,894 个 GLB 模型与 28,577 个 PNG 贴图资源库分布。
  - **大世界与地图映射** (`06_WORLD_AND_MAP_MAPPING.md` + `world_map_mapping.json`)：登记 106 个 WorldTable 世界及 50 个已就绪地形区域（共 15,453 个地形切片区块）。
  - **NPC、怪物、技能与特效映射** (`07_NPC_MOB_SKILL_EFFECT_MAPPING.md` + `npc_mob_skill_mapping.json`)：完成 3,169 个 NPC、7,125 个怪物及 2,663 个技能的数据表与模型特效对应关系整理。
  - 所有映射均按照 `VERIFIED`、`PARTIAL`、`INFERRED`、`MISSING`、`UNKNOWN` 严格标注证据等级，彻底解决今后跨模块调用与资产查证信息缺失问题。

### 2026-11-01 更新记录
- 读取 GitHub `docs/asset_audit/ASSET_AUDIT_REPORT.md`、`extraction_coverage.json`、`data_type_inventory.json`、`failed_exports.csv`、`unknown_files.csv`，并检查最新提交新增的 CSV 清单及文件行数。
- 记录 raw 120,234 个/7.377 GB、导出 129,928 个/4.462 GB 等为 Antigravity 报告值，而非独立重扫结论。
- 发现并记录 ANM 百分比、SWF 数量、未知文件类型、missing_exports 口径、ExecutionEnv 总数、OpenDBO commit 锁定及 RDF 占位解析等问题。
- 确认 DBOFF GitHub 当前没有上传完整导出二进制资源和报告引用的工具脚本；后续源码/模型质量核验仍受这些缺失材料限制。


## 19. 修正资产审计基准：先完整解包 pak，再进行工程双向对照（2026-11-01）

### 19.1 用户指出的审计方向问题（本节作为第 18 节当前结论的修正）
- 用户指出工程目录中实际存在音频文件，而本轮报告却以 raw 中 `extracted/sound` 为空为依据，将音频判定为 0/未提取。这种结论不成立：raw 不包含尚未解码的 sound pak 内容，不能以 raw 的缺失推导工程没有音频，也不能用不完整 raw 作为唯一审计基准。
- 用户进一步指出，正确的对照不应只有 `raw → project`，还必须从工程现有文件反向追溯至原版来源；同时，raw 中仍有未解包 pak，说明 raw 目录自身尚未形成完整基准。
- 采纳此修正：第 18 节所有 raw→export 缺失数量均暂时视为“当前 raw 快照下未匹配”，不得作为完整资产缺失的最终结论。音频尤其需要重新核查。

### 19.2 正确的三阶段审计基准
必须先完成源 pak 的全量盘点和可靠解包，再建立工程资产的双向对应关系：

**阶段 A：原版 pak → 完整解包资产（source completeness）**
1. 从原版安装目录/资源包目录枚举全部 pak，保存相对路径、文件名、大小、SHA-256、包类型及版本信息。
2. 逐个解码全部 pak，包括此前报告指出的 66 个 `sound*.pak`；不能因目录名或扩展名预设只处理模型/贴图/动画。
3. 每个 pak 必须有处理状态：成功、部分成功、失败、跳过（必须有理由）；记录解码器名称/版本、命令参数、日志、输出文件数/容量、错误和警告。
4. 验证输出完整性：包内目录/资源条目数（若格式支持）、偏移/长度边界、CRC 或其他校验、截断错误、未识别条目、重复条目及嵌套包。不能只看解包程序退出码为 0。
5. 保留原始 pak 清单与解包日志。只有全部 pak 均已处理且未解释条目已分类后，才能把解包输出称为完整 raw 基准。

**阶段 B：完整解包资产 ↔ 工程现有资产（双向覆盖）**
1. 同时扫描完整解包目录和工程全部资产目录，工程侧不能只扫已知模型/贴图/动画目录；音频、UI、特效、字体、配置、表格、脚本、场景和其他文件都必须纳入。
2. 正向核对：原版解包资源中哪些已进入工程、哪些经过格式转换、哪些直接保留、哪些缺失。
3. 反向核对：工程现有每个资产能否追溯到原版 pak/条目；无法追溯的标记为自制资源、第三方资源、生成文件、缓存/元数据或来源未知，不可直接判为错误。
4. 匹配应优先使用 pak 内部路径/资源 ID/条目 ID、内部名称、导出日志和引用关系；再使用文件名、尺寸、内容签名、音频时长/采样率、图像尺寸、模型结构等辅助特征。SHA-256 只适用于原样文件或重复文件，不可用于不同格式转换结果的直接对应。
5. 生成双向映射表，并将一对多、多对一、拆分/合并、转换格式、同名异内容、重复资源分别标记；不能强行一对一匹配。

**阶段 C：工程运行可用性验证（functional validation）**
1. 文件存在/对应不等于可用。对音频检查解码、时长、采样率、声道、播放引用和实际播放；对模型检查几何、材质分面、贴图引用、骨骼/动画；对 UI 检查资源能否被解析和显示。
2. 统计“原版来源覆盖率”“工程来源可追溯率”“成功转换率”“运行可用率”四类独立指标，不得混成一个百分比。
3. 对于工程已有但原版来源未匹配的音频，优先检查其是否来自 sound pak、是否经过重命名/转码/合并，以及是否存在资源索引或播放清单引用。

### 19.3 音频统计修正
- 本轮报告中 raw 的 `extracted/sound` 为空，只能说明本轮所扫描的 raw 路径下没有该目录或没有扫描到音频解包输出；不能说明工程音频数量为 0。
- 用户明确指出工程目录下存在音频文件。工程侧音频的实际文件数、格式、容量和路径尚未由当前 GitHub 资产清单独立确认，因为完整二进制资产未上传仓库且相关目录受 `.gitignore` 过滤。
- 66 个 sound pak 尚未解码（按第 18 节 Antigravity 报告），所以在完成这些 pak 解包前，音频的源资源总量和工程覆盖率均为未知。
- 下一轮必须先对工程中已有音频做独立清点，再从 sound pak 完整解包结果匹配。不得再使用“raw 音频为 0”作为“工程音频为 0”或“工程缺失音频”的依据。

### 19.4 当前必须补齐的材料
- 原版 pak 全量清单及 66 个 sound pak 的具体文件名/大小/哈希；
- 解码器和完整解包脚本的源码、版本、配置与逐包日志；
- 全部 pak 解包后的新 raw 根目录（无需上传大体积二进制，可由本地扫描工具生成 manifest）；
- 工程全部音频文件的清单（相对路径、扩展名、大小、SHA-256；另附可读取的时长/采样率/声道元数据）；
- 工程完整资产目录清单及扫描排除规则；
- 音频播放索引/资源引用（若项目中存在）。

### 2026-11-02
- **全项目资产与数据映射工程完成**：
  - 建立了总索引文档 `docs/ASSET_DATA_MAPPING.md` 以及 7 个子系统映射目录 `docs/ASSET_MAPPING_DETAILS/`。
  - **数据表映射** (`01_DATA_TABLE_MAPPING.md` + `table_registry.json`)：完成 280 张数据表（275 张位于 `assets/tbl/`，5 张位于 `data/`）的字段、主键与 OpenDBO 源码结构登记。
  - **角色与职业映射** (`02_CHARACTER_AND_CLASS_MAPPING.md` + `character_class_mapping.json`)：完成 6 大种族/性别素体模型路径及 12 种基础/进阶职业与 NewbieTable 出生配置的绑定。
  - **装备与物品映射** (`03_EQUIPMENT_AND_ITEM_MAPPING.md` + `equipment_item_mapping.csv` + `equipment_item_mapping.json`)：P0 级新手装备链打通（NewbieTable -> Item ID -> ItemTable -> ItemProperty -> 槽位 -> 对应成人/儿童模型 -> 贴图/骨骼/皮肤），明确区分儿童角色素体自带新手服装与成人模块化装备挂载机制。
  - **动画映射** (`04_ANIMATION_MAPPING.md` + `animation_mapping.json`)：完成 5,302 个 GLB 动作动画分类注册，梳理 CharacterAnimation 与 ItemTable 武器战斗待机/攻击动画映射逻辑。
  - **模型材质贴图映射** (`05_MODEL_MATERIAL_TEXTURE_MAPPING.md` + `model_texture_mapping.json`)：登记本地存在的 30,894 个 GLB 模型与 28,577 个 PNG 贴图资源库分布。
  - **大世界与地图映射** (`06_WORLD_AND_MAP_MAPPING.md` + `world_map_mapping.json`)：登记 106 个 WorldTable 世界及 50 个已就绪地形区域（共 15,453 个地形切片区块）。
  - **NPC、怪物、技能与特效映射** (`07_NPC_MOB_SKILL_EFFECT_MAPPING.md` + `npc_mob_skill_mapping.json`)：完成 3,169 个 NPC、7,125 个怪物及 2,663 个技能的数据表与模型特效对应关系整理。
  - 所有映射均按照 `VERIFIED`、`PARTIAL`、`INFERRED`、`MISSING`、`UNKNOWN` 严格标注证据等级，彻底解决今后跨模块调用与资产查证信息缺失问题。

### 2026-11-01 更新记录
- 接受用户对审计方向的修正：raw 存在未解包 pak，不能作为完整原版资产基准。
- 明确工程中存在音频文件；报告的 raw sound 为空不能推出工程音频为零。
- 将工作流调整为 pak 全量清点与解包 → 完整源资产与工程双向映射 → 运行可用性验证。
- 第 18 节 raw→export 未匹配数字降级为当前 raw 快照的初步观察，不作为完整资产缺失的最终结论。


## 20. 原版资源基准版本调整：采用 DBO_CT_TW 1.69 TW PAK（2026-11-01）

### 20.1 用户确认的版本选择

用户提出：OpenDBO 的 assets/raw 中可能混有相当一部分私服自定义、替换或其他非原版资源；因此 DBOFF 不应直接把 OpenDBO 提取资源作为原版资产母库。用户决定优先直接使用 DBO_CT_TW（1.57.51；用户说明其对应 1.69 TW）的 PAK 作为原版资源来源。用户此前已针对 All Text Table 引入该版本的数据文件。

证据等级：这是用户明确提供的版本选择与来源判断（D）。当前尚未取得完整 PAK 清单、包内版本标识或逐包校验材料，故“全部 PAK 均属于该版本且完整”仍待验证。

### 20.2 来源职责重新划分

- **权威原版资源来源候选：** DBO_CT_TW 1.69 TW PAK。后续原始资源母库应以该版本的原始 PAK 及其完整解包输出为核心；原始包只读保存。
- **OpenDBO-Core：** 独立的代码/机制/数据结构参考源，用于研究客户端与服务端逻辑、资源引用、行为和格式；不得因其位于 OpenDBO 仓库就默认其 assets/raw 是官方原版资源。
- **OpenDBO assets/raw：** 降级为非权威参考材料。每个文件必须先确认来源、版本和是否经过私服修改，才可作为比对线索；不得未经核验合并进 1.69 TW 权威母库。
- **All Text Table：** 用户报告已引入 DBO_CT_TW 1.57.51（用户说明对应 1.69 TW）文件。后续需核实具体文件清单、版本标识及与 PAK 资源的版本一致性。

### 20.3 资产审计流程调整

1. 先对用户指定的 1.69 TW PAK 建立完整清单：相对路径、大小、SHA-256、包内版本/区域标识（若可读取）、包类型和解码支持状态。
2. 审查解包器能否处理该版本的所有 PAK，包括 sound、UI、特效和其他非模型资源；不得沿用“已有 raw 即完整”的假设。
3. 将 1.69 TW PAK 解包到全新隔离目录，保留逐包日志和完整性校验；不覆盖旧 raw 或工程资源。
4. 以 1.69 TW 完整解包结果建立 source inventory，再与工程全部资源做双向映射。
5. 对 OpenDBO assets/raw 单独建立参考来源清单；比较同名/同内容/相似资源，标记来源差异、私服修改候选和无法确认项。不能仅凭文件名或相似度断定为官方资源。
6. 如果发现 OpenDBO 资源与 1.69 TW 资源不同，先保留两者并记录差异；不得自动覆盖、删除或合并。
7. 现有已提取模型、贴图、动画和音频继续保留，按证据分为可追溯到 1.69 TW、疑似其他版本/私服修改、来源未知、转换有损/待复核等状态，不因基准调整而全部推倒重做。

### 20.4 当前缺少的材料

- 1.69 TW PAK 的完整文件清单、相对路径、大小和 SHA-256；
- 能证明 PAK 版本/区域归属的包内元数据或客户端版本信息；
- 当前使用的 PAK 解码器源码/版本、配置、批处理脚本及逐包日志；
- 当前 OpenDBO assets/raw 的目录清单及其提取来源/版本信息；
- All Text Table 的具体文件清单及版本标识；
- 当前工程完整资源清单（包括音频、UI、特效和字体），用于和 1.69 TW 解包结果双向比对。

缺少上述材料表示目前无法独立验证来源完整性，不表示这些文件在用户本地不存在。

### 2026-11-02
- **全项目资产与数据映射工程完成**：
  - 建立了总索引文档 `docs/ASSET_DATA_MAPPING.md` 以及 7 个子系统映射目录 `docs/ASSET_MAPPING_DETAILS/`。
  - **数据表映射** (`01_DATA_TABLE_MAPPING.md` + `table_registry.json`)：完成 280 张数据表（275 张位于 `assets/tbl/`，5 张位于 `data/`）的字段、主键与 OpenDBO 源码结构登记。
  - **角色与职业映射** (`02_CHARACTER_AND_CLASS_MAPPING.md` + `character_class_mapping.json`)：完成 6 大种族/性别素体模型路径及 12 种基础/进阶职业与 NewbieTable 出生配置的绑定。
  - **装备与物品映射** (`03_EQUIPMENT_AND_ITEM_MAPPING.md` + `equipment_item_mapping.csv` + `equipment_item_mapping.json`)：P0 级新手装备链打通（NewbieTable -> Item ID -> ItemTable -> ItemProperty -> 槽位 -> 对应成人/儿童模型 -> 贴图/骨骼/皮肤），明确区分儿童角色素体自带新手服装与成人模块化装备挂载机制。
  - **动画映射** (`04_ANIMATION_MAPPING.md` + `animation_mapping.json`)：完成 5,302 个 GLB 动作动画分类注册，梳理 CharacterAnimation 与 ItemTable 武器战斗待机/攻击动画映射逻辑。
  - **模型材质贴图映射** (`05_MODEL_MATERIAL_TEXTURE_MAPPING.md` + `model_texture_mapping.json`)：登记本地存在的 30,894 个 GLB 模型与 28,577 个 PNG 贴图资源库分布。
  - **大世界与地图映射** (`06_WORLD_AND_MAP_MAPPING.md` + `world_map_mapping.json`)：登记 106 个 WorldTable 世界及 50 个已就绪地形区域（共 15,453 个地形切片区块）。
  - **NPC、怪物、技能与特效映射** (`07_NPC_MOB_SKILL_EFFECT_MAPPING.md` + `npc_mob_skill_mapping.json`)：完成 3,169 个 NPC、7,125 个怪物及 2,663 个技能的数据表与模型特效对应关系整理。
  - 所有映射均按照 `VERIFIED`、`PARTIAL`、`INFERRED`、`MISSING`、`UNKNOWN` 严格标注证据等级，彻底解决今后跨模块调用与资产查证信息缺失问题。

### 2026-11-01 更新记录
- 根据用户提出的来源污染风险，将 DBO_CT_TW 1.69 TW PAK 设为 DBOFF 首选原版资源基准（版本对应关系按用户报告记录，待包级证据核实）。
- 将 OpenDBO assets/raw 降级为非权威参考材料；OpenDBO-Core 继续作为机制与代码参考。
- 规定现有工程资源保留并追溯来源，不因版本基准调整而全量重做。


## 21. 指定本地 1.69 TW 客户端根目录与 Antigravity 只读审查任务（2026-11-02 修订）

用户确认已下载其认定为关服前最后一次更新的 1.69 TW 客户端，PAK 位于本机 `E:\DBO_CT_TW(1.57.51)\pack`。该路径是用户本机输入位置，本助手无法直接访问或验证目录内容。

### 21.1 本轮工作决定

- 将 `E:\DBO_CT_TW(1.57.51)\pack` 指定为本轮 1.69 TW PAK 清点的唯一首选输入目录。
- 首先交由 Antigravity 在本机执行只读清点与工具审查；本轮不授权批量解包、转换、移动、重命名、覆盖、删除或上传。
- OpenDBO assets/raw 仅作为独立参考源，不用于替代这套客户端 PAK。

### 21.2 Antigravity 只读任务要求

1. 从客户端根目录递归枚举全部文件与子目录，生成完整根目录 manifest：相对路径、扩展名、大小、SHA-256、文件数量和总字节数。必须包含 `pack\\` 以及 pack 以外的所有目录/文件；不得只扫描 `.pak` 或只扫描资源类扩展名。
2. 将根目录内容分为至少两组：PAK/容器文件（重点标出 `pack\\`）与 PAK 外部文件。对 PAK 外部文件按可观察的扩展名、文件签名、目录位置和元数据做轻量分类（如可执行文件、配置、语言/表格、脚本、音频、图片、模型、UI、插件、补丁清单、未知等）；不确定标记为 unknown，不要猜测。对 PAK 文件再按文件名/结构识别 sound、world、texture、model、UI 等类别。
3. 审查客户端根目录版本信息、更新/补丁清单、可执行文件版本资源、配置、语言目录和其他元数据；记录证据路径和字段，用于判断客户端版本/区域以及哪些资源位于 PAK 外。不要仅凭文件夹名断言版本。
4. 定位现有 PAK 解码器、源码、依赖、配置、批处理脚本和历史日志；说明其支持的容器版本、输入限制、过滤规则、异常处理、同名输出策略及是否会静默跳过。
5. 检查工具能否覆盖 pack 内全部文件类型；特别确认 sound PAK 和非模型资源。对每个包给出 supported / unsupported / uncertain 状态及依据。
6. 设计在全新隔离目录解包的计划和验证办法（逐包日志、输入/输出计数、大小、校验、失败重试、冲突检测）。
7. 输出清单、版本证据、工具审查、风险与执行计划后停止，等待用户批准。

### 21.3 安全约束

- 不写入或修改 `E:\DBO_CT_TW(1.57.51)\pack`。
- 不执行批量解包，不覆盖现有 raw 或 DBOFF 工程资源。
- 不删除、移动、重命名、转换或上传任何文件。
- 不把文件数量或扩展名统计当作解包完整性证明。
- 如果发现目录缺失、权限错误、哈希计算失败或无法识别的容器，明确报告，不自行修复。

### 21.4 待用户提供的审查结果

需要 Antigravity 回传完整客户端根目录 manifest、PAK 子目录清单、PAK 外部文件清单与分类、客户端版本证据、解码工具定位及兼容性报告、风险列表和隔离解包计划。清单文件应作为机器可读附件保存（CSV/JSON）；聊天中只需汇报总量、分类汇总、异常和关键结论，不要粘贴数千行清单，以节省 Token。收到后再决定是否批准解包。


## 22. 审计范围修正：完整客户端根目录，不限于 PAK（2026-11-02）

用户补充指出：1.69 TW 客户端根目录中还存在 PAK 以外的资源。此前将 `E:\\DBO_CT_TW(1.57.51)\\pack` 当作审计入口过于狭窄。现修正为：

- **审计根目录：** `E:\\DBO_CT_TW(1.57.51)\\`。
- **PAK 子目录：** `pack\\`，作为容器资源单独清点和解包。
- **非 PAK 内容：** 根目录下其余全部文件/目录均纳入清点，不能预设它们只是启动器、缓存或无关文件；应先按路径、扩展名、文件签名和元数据分类，再判断其资源用途。
- **资源母库边界：** 最终原版 Source Archive 应覆盖该客户端中所有确认属于原版客户端发行内容的资源来源，包括 PAK 解包结果和 PAK 外部原始文件。客户端程序、工具、缓存、临时文件等应单独分类，不自动混入游戏资源集合，也不能在未经判断时直接排除。
- **完整性证明：** 需要同时证明根目录扫描覆盖完整、所有 PAK 处理完整、所有 PAK 外文件均已分类；仅完成 PAK 解包不能宣称整个客户端母库完整。
- **Token 控制：** 文件哈希、扩展名、大小、目录统计由脚本批量生成 CSV/JSON；Antigravity 只需阅读摘要、异常和少量关键元数据，不得把完整清单逐行贴入聊天，也不重新解析旧 raw。

本次修正只扩大只读清点范围，不代表批准解包、转换、移动、重命名、覆盖、删除或上传。


## 23. 本地资源目录补充：effect / gui / prop/property（2026-11-01）

用户确认本地 DBOFF 工程中存在以下目录：
- `E:\\DBOFF\\assets\\effect`
- `E:\\DBOFF\\assets\\gui`
- `E:\\DBOFF\\assets\\prop\\property`

这修正了此前仅根据 GitHub 文件树得出的可见范围：这些目录此前未出现在 GitHub，并不代表用户本地缺少。当前仓库根目录 `.gitignore` 对 `assets/` 使用白名单规则，只明确放行了 `assets/tbl/`，因此上述三个目录目前被 Git 忽略的可能性很高。

后续上传前应先只读统计三个目录的文件数、总容量、最大单文件、扩展名分布，并检查是否包含缓存/临时文件或超过 GitHub 单文件限制的文件；确认后再最小化修改 `.gitignore` 并仅暂存这三个指定路径，不要暂存整个 `assets/`。

`assets/gui/` 中是否包含 SWF 转换后的两个 JSON，以及其结构是否完整，尚未直接读取验证；此前 426 个 SWF unmatched 不能据此判定 UI 资源缺失。

本次只更新项目记录，没有修改本地资源、代码或 GitHub 忽略规则。


## 24. 资源目录白名单暂存检查（2026-11-02）

用户在本地修正 .gitignore 的 assets 规则后，执行了以下暂存操作：
- git restore --staged assets/
- 分别暂存 assets/tbl/、assets/effect/、assets/gui/、assets/prop/property/ 和 .gitignore。
- git status --short 显示本轮新增暂存文件为 effect 下 2 个 JSON、gui 下 2 个 JSON、prop/property 下 7 个 JSON，以及 .gitignore 修改。
- 用户随后运行白名单检查：git diff --cached --name-only | Select-String -Pattern '^assets/(?!tbl/|effect/|gui/|prop/property/)'，无输出，说明当前暂存清单中没有匹配到白名单以外的 assets 路径；本次误放行的 GLB 未出现在贴出的暂存清单中。
- assets/tbl/ 未出现在状态输出中，表示本次没有显示其新增/修改暂存项，不代表该目录未被 Git 跟踪。
- Git 对若干 JSON 提示 CRLF 将规范化为 LF；这是换行符提示，不是文件损坏报告。
- docs/pak_audit_1_69/ 显示为未跟踪（??），尚未暂存；其内容和是否应纳入仓库需另行检查。

当前状态只依据用户贴出的本地命令输出；尚未看到修正后的完整 .gitignore、暂存 diff、文件大小统计或最终提交结果。不要 commit/push，先检查暂存差异和未跟踪审计目录。


## 16. Staged data review and local audit CSV inspection (2026-11-02)

The user supplied the next local PowerShell outputs:

- `git diff --cached --stat` reports 12 staged files and 2,392,365 insertions: `.gitignore` plus 11 JSON files across `assets/effect/` (2), `assets/gui/` (2), and `assets/prop/property/` (7).
- The staged `.gitignore` contains the intended narrow rules: allow `assets/`, ignore its children by default, then allow only `tbl/`, `effect/`, `gui/`, and `prop/property/`; under `prop/`, ignore other children. No trailing newline is present in the staged file. This does not change the matching behavior, but adding a final newline is recommended for file hygiene.
- The local `docs/pak_audit_1_69/` directory currently contains only `pak_inventory.csv`, reported size 79,872 bytes. Its contents have not been inspected, so its purpose, provenance, completeness and suitability for version control remain unknown.
- No commit or push has been reported. Keep the change set uncommitted until the CSV header/sample and staged contents are reviewed.

Next evidence requested: show the first several CSV rows (including the header) and, if needed, its column names/row count. Do not add the audit directory wholesale before review. The current staged asset whitelist appears correct based on the supplied diff and earlier staged-path filter; this does not validate the semantic correctness or completeness of the JSON data.


## 17. PAK inventory CSV schema inspected (2026-11-02)

The user supplied the CSV header and first 9 data rows from `docs/pak_audit_1_69/pak_inventory.csv`. The schema is:

`relative_path, source_pack_dir, file_name, extension, size_bytes, size_mb, sha256, category, role, indexed_files_count`.

The visible sample contains entries under `localize\\TAIWAN\\pack\\`, all with `.pak` extensions. The `flash.pak` row is categorized as UI / Flash Interactivity (SWF, GFX), role `header_index`, and reports `indexed_files_count=798`; the visible `flash0.pak` through `flash15.pak` rows are categorized as data volumes. This indicates a PAK-focused inventory with package hashes and some role/category metadata. It does **not** establish that the CSV covers the complete client root, non-PAK files, every package directory, or successful extraction. The 798 value is the indexed-files count reported for the flash header entry, not a verified total of all extracted files.

The CSV's full row count, category/role distribution, path coverage, generation timestamp/tool, and relationship to the full-root inventory remain unknown. Do not yet describe it as a complete 1.69 TW client manifest. The user also appended a final newline to local `.gitignore` and ran `git add .gitignore`; Git's CRLF-to-LF warning is a line-ending normalization notice, not a failure.

Next: inspect CSV row count and group by category, role, and source_pack_dir; confirm whether every row is a PAK and whether paths span only `localize\\TAIWAN\\pack\\` or additional directories. Keep the CSV untracked until its scope and reproducibility are clear. No commit/push has been reported.


## 25. GitHub 资产白名单数据首次结构审查（2026-11-02）

用户确认已推送 11 个 JSON 与 pak_inventory.csv。已从当前 main 读取并解析全部 11 个 JSON；以下是仓库文件的直接检查结果（证据等级 A），不代表原始 PAK 或运行行为已验证。

### 25.1 assets/effect/
- visualeffect_01.json 与 visualeffect_02.json 的 Git blob SHA 完全相同；两者均为 310 字节、total=2，含 2 条 effect 记录。
- 第一条名称为 IK_GKN_SKL_A02_02，第二条名称为空。无法仅凭当前导出判断是原始内容相同还是导出/命名流程重复；暂不删除或合并。

### 25.2 assets/gui/
- ui_atlas_dictionary.json：6,071 个字典键、3,039 个不同 surface_name、107 个纹理名、57 个不同 resource_file；发现 3,032 组大小写折叠后重名的键，其中 3,028 组内容完全相同，另有 4 组包含不同资源定义（DlgMain、srfBackground、srfHuman_fighter、srfcbbStatic）。因此不能对键名统一转小写或无条件合并；必须保留原始大小写，并在加载器中处理大小写冲突。
- ui_layout_dictionary.json：311 个 .frm、5,423 个控件，包含 dialog、button、staticbox、panel、flash、progressbar、scrollbar、combobox 等类型。
- 布局引用 1,255 个不同 surface 名称，其中 30 个未在 atlas 字典找到；引用 190 个不同 .srf 文件，其中 30 个未出现在 atlas 的 srf_file 集合。这里只能认定两份字典间存在未闭合引用，不能直接断言原版 UI 资源丢失；需按 .frm → .srf → .rsr/纹理文件链继续核对。

### 25.3 assets/prop/property/
- characterproperty.json：1,499 条角色记录；35,620 个动画条目、11,802 个不同动画名、37,495 个动画事件，事件包括声音、特效、命中、脚步、技能取消、子武器、透明度/颜色变化等。
- default_item_list.json：10 种种族/年龄/性别体型配置；10 组的 default_parts、scouter_attach_info、face_ani_multi_texture、head_base_texture 均为空对象。空值不能证明对应机制不存在。
- direct_project.json：704 个节点，25 个文件夹、679 个对象。
- direct_splines.json：声明及实际 spline 均为 679；全部 679 个 spline 名称均能在 direct_project 对象节点找到，未发现名称孤儿。
- itemproperty.json：5,930 条物品记录；76,512 个 upgrade_effect.effects[] 条目，其中 63,549 个 effect 字符串含控制字符或非 ASCII 字符，12,963 个为可打印 ASCII。该字段存在明显非文本/编码异常风险，可能是二进制字段误解释、编码转换或导出器字段偏移；回查原始结构前，不得当作正常特效名称或直接清洗。
- objectproperty.json：4,521 条对象记录，1,141 个动画条目、440 个动画事件；3,729 条记录至少一个轴向出现 bbox.min > bbox.max。可能涉及字段命名或坐标约定，必须对照原始结构，暂不批量交换 min/max。
- tenkaichi_direction.json：11 个 controller、33 个节点（27 EFFECT、6 SOUND）。

### 25.4 pak_inventory.csv 范围确认
- 469 条记录，全部为 .pak；来源目录 pack 427 条、localize\\TAIWAN\\pack 42 条。
- 类别：World/Terrain Mesh & Heightfield 163；3D Model & Animation 106；Audio/Sound 66；Texture 64；UI/Flash 50；其余 RDF/EDF、FRM/SRF、语言字符串、GUI/Quest 脚本、Engine Properties、World/Terrain Index 合计 20。
- 角色：453 data_volume、16 header_index。
- CSV 覆盖 pack 与 localize\\TAIWAN\\pack 两处，但仍只是 PAK 清单，不含非 PAK 文件，也不证明解包成功、包内条目完整或客户端根目录扫描完整。

### 25.5 当前结论
1. 11 个 JSON 均可解析；direct_project 与 direct_splines 的 679 个对象/spline 名称完全对应。
2. GUI 字典存在 30 个 surface 名称与 30 个 SRF 文件的跨文件未匹配项。
3. itemproperty 的 upgrade_effect.effect 大量非文本值是优先级较高的数据解析风险。
4. objectproperty bbox 的 min/max 方向待原始结构核对。
5. 两个 visualeffect 文件完全相同，保留待查。
6. 本轮只读审查 GitHub 数据并维护文档；未修改本地代码、场景、JSON 或二进制资产。


## 26. GitHub Markdown 全量目录核对与文档路径纠正（2026-11-02）

### 26.1 仓库文档实际位置
- 当前仓库为 `gaaing/DBOFF`，分支 `main`。
- 通过 Git tree 递归清单确认，当前仓库共有 **49 份 Markdown 文件**，全部位于 `docs/` 或其子目录。
- 核心协作文档实际路径为：
  - `docs/AI_DEVELOPMENT_RULES.md`
  - `docs/AI_WORK_PROGRESS.md`
- 此前对根目录路径 `AI_WORK_PROGRESS.md`、`VALIDATION_LOG.md`、`OFFICIAL_DATA_INDEX.md`、`AI_DEVELOPMENT_RULES.md` 的读取返回 404，是因为路径/文件名假设错误；不能据此推断文档不存在或文件太大。
- 本次已按实际 Git tree 读取仓库 49 份 Markdown 文档，并分段读取大型文档。后续开始 DBOFF 工作必须先读 `docs/AI_DEVELOPMENT_RULES.md` 与 `docs/AI_WORK_PROGRESS.md`，再根据任务读取相关报告。

### 26.2 文档证据规则再次确认
- `AI_DEVELOPMENT_RULES.md` 明确规定：历史报告、完成勾选和“100%”措辞均不是当前实现证据；当前代码、数据、OpenDBO 对照和运行证据优先。
- 历史报告中存在互相冲突的技术结论与旧实现状态。不得把它们直接合并成当前事实；必须回到当前代码/数据核验。
- `AI_WORK_PROGRESS.md` 是当前项目状态记录：当前阶段仍为旧代码清理与架构重整；创角/选角已有初步实现但仍有 Bug；当前没有任何系统可认定为完美完成。该状态与历史报告中的大量“100% 已完成”声明冲突时，以本文件的证据规则为准。

### 26.3 当前审计任务的文档基准
- 原版资源审计根目录是用户本机 `E:\\DBO_CT_TW(1.57.51)\\` 的完整客户端根目录，不限于 `pack\\`。
- `docs/pak_audit_1_69/pak_inventory.csv` 目前只证明 469 个 PAK 条目（427 个位于 `pack\\`，42 个位于 `localize\\TAIWAN\\pack\\`）；它不是完整客户端根目录清单，也不证明包内资源已成功解码。
- 仍缺少完整客户端根目录 manifest（包含 PAK 外文件）、版本证据、解码器源码/版本/配置、逐包解码兼容性与日志，以及经批准后生成的完整解包验证结果。
- 本次 GitHub 文档核对为只读检查；未修改代码、场景或资产，也未执行本地 PAK 解包。


## 27. 系统性开发地图正式建立（2026-11-02）

- 已在 `docs/DBOFF_DEVELOPMENT_MAP.md` 建立长期开发地图，并提交至 GitHub main。
- 用户确认的开发总顺序为：**先修复现有实现 → 充分对齐原版源码/数据/行为 → 评价当前实现并比较更好的实现方式 → 有依据地优化 → 逐步还原缺失系统 → 全局整合验收**。
- 开发地图建立 12 个系统域（基础框架、数据与存档、角色生命周期、角色表现、玩家控制、世界地形、世界实体、战斗技能、成长物品、任务剧情、原版内容、UI/社交/在线服务），并规定每个系统必须完成现状审计、原版对照、方案评价、优化和限定范围验收。
- 角色创建/选择仍由 Antigravity 处理；不打断当前修复。收到修复后的脚本、场景、复现步骤和运行证据后，由 ChatGPT 独立审查。
- 第一轮系统开发从基础依赖开始，按真实调用关系推进；不机械按文件列表改动，不同时修改同一核心文件。
- 资产最终报告中的完整性声明降级为“报告声明，待按系统证据核实”。尤其完整 1.69 TW 客户端根目录 manifest、全部 PAK 解码覆盖、非 PAK 文件归类和运行时资源可用性仍需独立证据。
- 本次只更新项目 Markdown；未修改 GDScript、场景、资源或本地文件，也未执行代码提交以外的任何工程操作。

### 当前启动所需材料（按系统分批提供，不要求一次性上传全部工程）
1. 角色大厅修复后的两个脚本、对应场景、Bug 复现步骤与 Godot 日志。
2. 首个系统开始审查时，从当前 GitHub main 读取其完整脚本/场景和被调用模块；若有未推送本地差异，提供对应 diff 或文件。
3. 对照 OpenDBO 时提供对应源码仓库/路径；若 OpenDBO-Core 仓库已连接或公开可读，直接按系统逐段读取，不要求重复打包全部源码。
4. 涉及本地二进制资产时，只提供该系统所需资源或机器生成的 manifest；不要求重新制作全仓库文件索引。


## 28. S01 客户端基础与全局服务初步审查（2026-11-02）

> 状态：**已发现实现 + 存在架构风险（初步静态审查）**。本节不是完整验收，不代表已修复。

### 28.1 本轮直接读取的 DBOFF 文件

- `project.godot`
- `src/core/dbo_event_bus.gd`
- `src/core/audio_manager.gd`
- `src/core/dbo_material_helper.gd`
- `src/ui/dbo_ui_manager.gd`（仅用于检查全局服务交互）
- 当前 `src/` 递归文件树（确认脚本目录和 Autoload 声明）

### 28.2 当前全局服务布局

`project.godot` 注册 9 个 Autoload：DBOEventBus、DBOLocalizer、DBOTableManager、AudioManager、DBOInventoryManager、DBOQuestManager、DBOUIManager、DBOCombatTextManager、DBOEffectManager。

初步观察：
- 全局节点同时承载基础设施和领域服务；事件、音频、语言、数据表、背包、任务、UI、战斗文字、特效均为 Autoload。后续需检查初始化顺序、依赖方向和生命周期，不预设必须全部改为 Autoload。
- `DBOSaveManager` 当前是 `RefCounted` 的静态工具类，不在 Autoload 列表中；其数据生命周期和全局状态属于 S02 范围。
- 当前可见 `src/core/` 文件中没有独立的 Logger、配置服务或通用资源管理服务入口；这只表示当前目录树未见独立模块，不排除相关职责写在其他脚本中。

### 28.3 DBOEventBus 初步发现

当前脚本声明玩家属性/经验、目标选择、战斗伤害/死亡、NPC交互/对话、传送、背包/装备、任务、通知、地图切换和 UI 风格等全局信号。

**确定的职责混杂风险：**
- `DBOEventBus._ready()` 订阅整个 SceneTree 的 `node_added`。
- `_on_node_added_global()` 对每个新加入场景树的 `MeshInstance3D` 调用 `DBOMaterialHelper.fix_mesh_materials()`。
- 因此事件总线不只是事件分发，还承担了全局模型材质修正；事件基础设施与渲染/资源导入规则形成硬耦合。该副作用会覆盖所有动态加入的网格节点，是否造成重复处理、共享材质污染或额外开销需结合模型实例和运行时验证。

**事件语义与原版对照：**
- OpenDBO-Core 的 `DboClient/Lib/NtlCore/ceventhandler.h`、`ceventhandler.cpp` 使用 `CEventHandler`、`CEventId`、`CMsg`、`CLinkedMsg`、`CRegisteredMsgs`。
- 原版事件系统提供多发送者/多接收者关系、接收者优先级、Active 状态控制、显式 Link/UnLink 和注册计数；处理期间解除订阅会延迟清理，另有安全删除事件处理器的机制。
- `SendMsgToEventHandler()` 直接调用接收者的 `HandleEvents()`，因此该源码路径的事件派发是同步调用，不应简单把原版描述成异步系统。
- DBOFF 使用 Godot typed signals 是合理的现代实现候选，但目前单靠信号声明并不能证明原版优先级、接收者启停、事件生命周期和安全销毁语义均已覆盖。应按具体事件需要决定是否补充，不必机械复刻 C++ 事件框架。
- DBOEventBus 注释称提供“全生命周期异步事件通知”，但当前没有显式 deferred dispatch/队列；Godot 信号默认连接也不是自动异步。注释与实际语义不一致，需在后续确定事件契约时修正。

### 28.4 DBOMaterialHelper 与全局挂接风险

- `DBOMaterialHelper` 会直接修改 `BaseMaterial3D` 的 UV、透明模式、Alpha Scissor、Cull 和 Depth Draw 属性。
- 其判断依赖 MeshInstance 名称、父节点名称、材质名和贴图路径关键字；这些规则需要对照资产来源与材质实例化方式验证。
- 若多个网格共享同一 Material 资源，直接修改材质资源可能影响其他使用者；是否已通过资源本地化/实例化隔离，当前尚未验证。
- 该类还包含 GLB 安全载入与无效贴图 URI 替换逻辑，职责已超出单纯材质助手；是否拆分为导入校验、GLB 修复与运行时材质策略，需在审查完整调用方后评价。
- 初步建议：将材质修正规则从 EventBus 移出，改为明确的资源导入/实例化流程或专用模型初始化组件；最终方案需在查清所有模型入口后决定，本轮不修改代码。

### 28.5 AudioManager 初步发现

当前实现包括双 BGM 播放器交叉淡入淡出、固定 8 个 2D SFX 播放器、按名称查找资源、AudioStream 缓存，以及每次播放创建一个 3D AudioStreamPlayer3D 并在 finished 后释放。

待处理风险：
- 2D 音效池全部占用时，`_get_available_sfx_player()` 会返回第 0 个播放器，即使它仍在播放；新音效可能截断旧音效，且没有优先级/抢占策略。
- BGM 淡入淡出 Tween 没有保存和取消管理；快速连续切换或 stop/play 交错时，需要验证多个 Tween 是否对同一播放器属性产生竞争。
- 请求的 BGM 找不到时，只要文件名包含 `bgm`，就回退播放固定的 `bgm_share_plain1.ogg`。这会掩盖资源路径错误，让错误曲目被当作成功加载；应评估改为显式 fallback 状态或仅由调用方指定回退曲目。
- `_sound_cache` 没有容量、引用或清理策略；是否需要 LRU/分组释放取决于实际音频规模和内存测量，不应先验增加复杂度。
- 3D 音效采用每次创建节点的方式，需结合最大同时发声量、场景切换和 finished 信号验证节点释放及性能。
- 当前统一使用 Master bus；尚未看到 BGM、SFX、环境音、语音的独立音量控制/混音策略，需后续核查。

### 28.6 跨系统发现

`src/ui/dbo_ui_manager.gd` 的 `set_ui_style_mode()` 使用 `Engine.has_singleton("DBOEventBus")` / `Engine.get_singleton("DBOEventBus")` 查找 Autoload。Godot Engine singleton 与项目 Autoload 节点不是同一概念；按当前 `project.godot` 注册方式，这条查找路径高度疑似无法取得 DBOEventBus，导致跨系统 `ui_style_changed` 广播不触发。需要在运行时验证并纳入 UI 系统修复，不在本轮擅自修改。

### 28.7 本轮源码对照结论与下一步

- 已读取 OpenDBO-Core 的事件处理器头文件和实现，确认事件订阅、优先级、Active、Link/UnLink、安全删除和同步派发等基础语义。
- 当前 DBOFF EventBus 的 typed signal 方案可保留为候选，但必须建立逐事件语义映射；材质自动修正应从事件基础设施中解耦。
- 下一步先完成 S01 其余调用方与资源生命周期检查，再决定事件总线和音频服务的修复边界。此后进入 S02 数据表/属性/存档，逐项核对原版字段与行为。
- 当前缺少的验证材料：完整的 EventBus/AudioManager 调用方清单（当前 GitHub 搜索未返回可用索引结果，需通过完整脚本读取或本地只读搜索生成命中清单）；Godot 运行日志/复现证据；本地音频资源 manifest 与实际同时播放压力结果；共享材质资源是否被多个场景/网格复用的证据。
- 本轮只读审查 GitHub 与 OpenDBO-Core 公开源码；未修改 GDScript、场景、资源或配置。



### 28.8 调用方追踪补充（2026-11-02）

本轮额外读取了 `combat_engine.gd`、`dbo_inventory_manager.gd`、`dbo_quest_manager.gd`、`world_scene_driver.gd`、`player_controller_3d.gd`、`dbo_hud.gd`、`mob_entity_3d.gd`、`npc_entity_3d.gd`、`character_base_3d.gd`、`dbo_character_state_machine.gd`、`anim_event_dispatcher.gd`、`world_spawn_manager.gd`、`world_prop_manager.gd` 与 `dbo_effect_manager.gd` 的相关调用位置。

**发现一项可由当前代码直接确认的音频路径问题：**
- `AudioManager.load_sound()` 只有在输入以 `res://` 开头时才将其视为完整资源路径。
- 但 `player_controller_3d.gd`、`mob_entity_3d.gd`、`npc_entity_3d.gd` 等调用方传入的是 `assets/sound/.../file.wav`，没有 `res://` 前缀。
- 由于这些字符串包含目录分隔符，加载器不会再逐个搜索 SOUND_SUBDIRS，而会拼接成 `res://assets/sound/assets/sound/.../file.wav`。这与预期资源路径不符，相关 3D 音效请求会无法命中，除非工程中恰好存在该重复目录。
- 该结论是路径拼接逻辑的静态证据；实际资源是否有重复目录仍需本地文件系统验证。修复应统一资源路径契约，并扫描全部调用点，不能只改一处。

其他调用关系：
- `dbo_quest_manager.gd` 订阅 `combat_entity_died`，并派发任务状态/目标进度事件。
- `dbo_inventory_manager.gd` 派发背包和装备更新事件。
- `player_controller_3d.gd` 派发 NPC 交互和传送菜单事件，并多处调用 3D 音频。
- `world_scene_driver.gd` 以短名称请求 BGM（`BGM_Field_01`），与加载器的子目录搜索策略不同于上述错误的完整相对路径调用。
- `world_prop_manager.gd` 在 `add_child(prop_inst)` 之前已主动调用 `DBOMaterialHelper.fix_node_materials(prop_inst)`；加入场景树后 EventBus 的全局 `node_added` 回调还会再次处理其中的 MeshInstance3D，形成重复处理路径。需确认是否保留显式调用或全局自动调用，不应两套机制长期并存。

### 28.9 OpenDBO 音频管理机制入口

已定位并读取：
- `DboClient/Lib/NtlSound/NtlSoundManager.h`
- `DboClient/Lib/NtlSound/NtlSoundManager.cpp`

OpenDBO 的 `CNtlSoundManager` 是 FMOD 系统管理入口，包含初始化/释放、Listener 位置与朝向、播放/重播、系统 Update、Master Volume/Mute、Channel Group 管理和环境音更新；其 Update 还处理通道组更新与环境声音优先级重播。由此可见，当前 DBOFF AudioManager 只覆盖了基本 BGM/SFX 播放，不应标记为完整对齐。后续至少需核查声音分类/通道组、音量设置、3D Listener、环境音/循环音、优先级、最大同时播放数、资源缓存与生命周期；具体还原范围以原版调用和游戏行为为准。


## 29. 双轨服务器接入决策与旧项目隔离（2026-11-02）

### 29.1 用户确认的架构决策（证据 D）

用户明确选择 **C：Cloudflare 基础服务 + OpenDBO Auth/Char/Game Server 两条线都接入**。

职责边界：
- Cloudflare / dbo-web：账号认证、会话、GM 权限、在线状态、配置分发，以及后续云存档和在线社交业务。
- OpenDBO AuthServer / CharServer / GameServer：原版登录、角色、频道、世界和游戏协议/权威行为的研究与逐步接入。
- Godot DBOFF：离线核心玩法继续本地运行，通过统一网络层接入在线服务，不让业务脚本各自直接处理 HTTP、令牌和协议。

接入顺序：
1. 先保持 Godot 工程可独立运行，建立可重复的开发运行/导出基线。
2. 审查当前 DBOFF 网络层与 dbo-web 实际 Worker/API 后，再确定统一客户端网络层契约。
3. Cloudflare 先接开发最小闭环：健康/版本、登录、会话验证/登出、权限读取和必要配置。
4. 并行研究 OpenDBO Auth/Char/Game 协议和服务端处理链，不因协议研究暂停现有客户端 Bug 修复。
5. 在线业务按系统需要逐步接入；云存档、社交、组队、交易和重要奖励分别设计数据权威边界。
6. 启动器暂缓，待导出、版本清单、更新/补丁接口与恢复策略稳定后再做。

该决策是架构方向批准，不表示任何 API、协议或客户端网络层已经实现/验证。队长 Host 合作模型仍为候选方向，安全模型尚待独立设计。

### 29.2 用户报告：旧项目工作目录已删除（证据 D）

用户说明：此前旧项目文件夹及其中工具已删除，目的是隔离旧工程，避免 Antigravity 再次引用或找回旧项目。若后续确实需要某个旧工具，用户会按具体需要从回收站恢复。

执行边界：
- 旧项目路径、旧脚本和旧工具一律视为当前不可用，不得作为 DBOFF 依赖或默认工作目录。
- 不能因为历史对话或旧文档出现某个工具路径，就假定该工具仍然存在。
- 只有在某个具体任务确实需要时，先列出准确文件/工具名、用途和必要性，再由用户决定是否恢复；不要求恢复整个旧项目。
- 新代码和配置不得残留旧工程的绝对路径或隐式依赖。

### 29.3 最新 Git 推送的初步核对（证据 A/D）

用户报告已推送修复旧项目引用路径的变更。当前 GitHub gaaing/DBOFF main 的最新可见提交序列包含：
- 4db0be5a93e7f96b7b3fd476f5aaa2c596db9f9e — 修复路径引用错误，大量bug存在
- 6ba2b949118a141103ab8ad8ed45ac8c2a015b0c — merge commit，时间为 2026-11-02。

已读取 4db0be5 的提交 diff，确认 src/entities/character_factory.gd 移除了两组指向 E:/DBO_Offline/assets/models/items/... 的旧项目绝对路径回退；相关查找改为使用当前工程 res://assets/obj/item/... 路径。src/entities/character_visual.gd 的史考特纹理名解析也改为使用传入模型名或 GLB 文件名，而不再直接依赖旧变量。另有 dbo_material_helper.gd 的 GLB URI 修正规则调整，以及儿童角色装备挂载分支变化。

注意：本轮只确认提交 diff 中的具体变更，不代表整个仓库所有文件已完成旧路径扫描，也不代表这些改动已通过 Godot 运行验收。GitHub 代码搜索没有返回可用命中，但不能将其视为完整仓库无旧路径的证明；后续仍需在当前完整工程范围内做一次只读旧路径扫描。

### 29.4 本轮新增材料缺口

当前不能直接进入接口实现，仍缺：
- dbo-web 的架构/开发 Markdown、Worker 路由、认证 API 定义和部署配置。已确认 gaaing/dbo-web 是私有仓库，但尝试读取根目录 README.md 返回 404；尚未获得其实际文档路径和文件内容。
- DBOFF 当前网络层/会话/HTTP/WebSocket 相关脚本与调用方的完整审查结果。
- OpenDBO AuthServer、CharServer、GameServer 的协议握手、packet 定义和服务端处理链的系统性对照。
- 可用于开发验证的 API 基址与脱敏请求/响应样本；不得提供或写入密码、令牌、密钥。

以上缺口是“当前尚未从仓库读取/验证”，不代表用户本地不存在。

### 29.5 当前下一步

1. 先对当前 DBOFF main 做一次只读旧项目绝对路径/资源引用扫描，确认用户本轮路径清理覆盖范围；不要求恢复旧项目。
2. 定位并读取 dbo-web 的实际 Markdown 与 Worker 文件，再确定 Cloudflare 最小闭环，不臆造 API。
3. 逐段研究 OpenDBO Auth/Char/Game 协议入口和服务端处理链，建立 packet/state 映射。
4. 检查 DBOFF 当前网络接入点，提出统一网络层设计；在证据齐备前不把具体接口写死。
5. 保持角色创建/选择等现存 Bug 修复工作继续推进；服务器接入研究不应阻断客户端修复。

本轮只更新项目规划与进度记录；未修改 GDScript、场景、资源、Worker 代码或本地工程。


## 30. 当前网络接入点与旧路径初步扫描（2026-11-02）

### 30.1 DBOFF 当前分支只读扫描（证据 A）

- 当前 GitHub main 的递归 Git tree 返回 15,961 个条目。
- 对 project.godot、src 下 GDScript 和 scenes 下场景文件进行第一轮文本扫描，共 42 个文件。
- 该 42 文件范围内未命中 E:/DBO_Offline、旧仓库 DragonballOfflineClient、DBO_Offline_V2 等旧项目路径/名称。
- 同一范围内未发现 HTTPRequest、HTTPClient、WebSocketPeer、WebSocketMultiplayerPeer、ENetMultiplayerPeer、PacketPeer、session_token、/api/session/check、/api/login、/api/logout 或 /api/register 等客户端网络/认证接入代码标记。
- 当前结论：在已扫描的客户端脚本、场景与项目配置范围内，尚未发现可复用的统一网络层或账号 API 客户端。此为静态搜索结果，不排除其他未扫描文件、插件、导出配置或本地未推送差异中存在相关实现。
- 尚未扫描所有资产 JSON、资源二进制、仓库全部 Markdown 与未推送本地文件；因此不能声称整个仓库已经完全清除旧引用。

### 30.2 dbo-web 当前架构文档与目录（证据 A）

- 已定位并读取私有仓库 gaaing/dbo-web 根目录 ARCHITECTURE.md；之前 README.md 返回 404 是因为该路径不存在，当前架构文档实际位于根目录 ARCHITECTURE.md。
- 当前根目录可见 ARCHITECTURE.md、functions/、worker/、index.html、login.html 与 favicon.ico。
- functions/api/[[path]].js 将 canonical 生产 Pages 主机 dbo-web.pages.dev 的请求转发到 dbo-account-api.hoipoi.workers.dev；其他 Pages 预览主机转发到 dbo-account-api-staging.hoipoi.workers.dev。
- 本轮目录核查未见根目录 wrangler.toml、wrangler.jsonc 或 package.json；这不排除部署配置由 Cloudflare Dashboard 或其他外部流程管理，仍需核实实际 Worker/D1 绑定和当前部署版本。

### 30.3 当前 dbo-account-api Worker 源码路由（证据 A，仅源码，不代表线上部署版本）

已读取 worker/worker.js，当前源码可见路由：
- POST /api/register：普通注册固定创建 PLAYER，创建账号、设备绑定和会话。
- POST /api/login：验证账号密码、设备封禁与绑定，创建会话；支持旧 SHA-256 密码哈希登录后升级为 PBKDF2。
- POST /api/logout：根据提交的 session_token 摘要撤销服务端会话。
- POST /api/session/check：检查会话是否存在、未过期且账号 ACTIVE，返回 account_type。
- POST /api/admin/set-role：仅 ADMIN 会话可修改目标账号为 PLAYER 或 GM。
- POST /api/gm/stats、/api/gm/list-accounts、/api/gm/ban-chain、/api/gm/delete-account、/api/gm/unban-account：GM/ADMIN 管理操作，按源码中的权限检查执行。

当前源码还包含：16 KiB 请求体上限、登录/注册 IP 限流、登录账号标识限流、PBKDF2-HMAC-SHA-256（100,000 iterations）新密码哈希、旧 64 位十六进制 SHA-256 渐进升级逻辑，以及对 dbo-web Pages 生产/预览域名的 CORS 来源限制。上述均为源码观察，尚未在本轮验证当前生产 Worker 与仓库源码一致。

**未发现** /api/health 或 /api/version 路由。因此 Cloudflare 最小接入第一阶段应先使用现有登录/会话/登出/权限接口；健康检查与版本接口需先评估是否有必要新增，不能把它们写成现有能力。

### 30.4 当前缺少的材料与证据

- DBOFF 当前本地网络相关脚本/插件/未推送差异的清单；当前 GitHub 已扫描范围未找到网络客户端实现。
- dbo-account-api 当前生产与 staging Worker 的实际部署版本、D1 binding 和非敏感配置清单；仓库源码不等于线上运行版本。
- DBOFF 客户端准备使用的开发 API 基址，以及脱敏的登录/会话/登出请求响应样本。
- OpenDBO AuthServer、CharServer、GameServer 的具体握手流程、packet 定义、状态转换和服务端处理调用链；本轮尚未完成该部分对照。
- 如果需要新增 API health/version，需要明确它服务于什么客户端行为、是否需要鉴权、版本兼容规则和失败降级策略。

### 30.5 下一步

1. 先检查当前本地 DBOFF 是否存在未推送的网络脚本或插件差异；若没有，按新建统一网络层进行设计，而不是寻找旧项目代码搬运。
2. 读取 Cloudflare 当前生产与 staging Worker 部署配置，确认源码版本、域名和 D1 绑定；先保持只读。
3. 从 OpenDBO Auth/Char/Game Server 源码建立协议流程与 packet 对照，不将 Cloudflare 账号 API 误当作原版 MMO 登录协议。
4. 基于现有 Worker 契约设计 Godot 账号服务客户端，先完成登录/会话/登出/权限读取的最小闭环设计。
5. 继续推进角色创建/选择等客户端 Bug 修复，不等待服务器接入研究完成。

本轮只读检查 GitHub 源码和文档，并维护 DBOFF 文档；没有修改游戏代码、场景、资源、Worker 或 Cloudflare 部署。


## 31. OpenDBO Auth / Char / Game Server 协议首轮映射（2026-11-02）

### 31.1 审计版本与源码范围

- OpenDBO-Core 仓库：OpenDBO/OpenDBO-Core，分支 master。
- 当前锁定 HEAD：23cb305a6cf20048fec75595a8fa1ee2f1a0e83d，提交时间 2026-10-29T22:42:53Z。
- 已读取 README.md、NtlPacketUA.h、NtlPacketAU.h、NtlPacketUC.h、NtlPacketCU.h、NtlPacketUG.h、NtlPacketGU.h、NtlPacketCM.h、NtlPacketMC.h、NtlPacketGM.h、NtlPacketMG.h、NtlPacketCommon.h、NtlPacket.h/.cpp、NtlClientNet.cpp、NtlNetSender.cpp，以及 AuthServer、CharServer、MasterServer、GameServer 的相关 packet/session 处理函数和客户端 LogInStage/CharStage 状态流程。
- 这是登录与进入世界链路的首轮映射，不代表所有认证分支、加密细节、断线恢复或服务器迁移已审计完成。

### 31.2 原版连接与协议形态（证据 B）

- 原版客户端通过 NtlClientNet 的 socket 网络层与 AuthServer、CharServer、GameServer 建立独立连接；连接入口使用 IP/端口，不是 HTTP REST 或 WebSocket JSON。
- NtlPacket.h 的 STHeaderBase 使用 15-bit packet length、1-bit encrypt 标志和 16-bit packet sequence；包体包含 opcode 和对应 packed C/C++ protocol struct。NtlPacketCommon.h 定义包体 opcode 结构。
- 当前已见 AuthServer/CharServer 连接路径显式使用 NETCLIENT_ENCODE_NONE，但不能据此推断 GameServer 的全部传输加密/编码配置；需继续检查各连接和运行配置。

### 31.3 AuthServer 登录

关键文件：
- DboShared/NtlShared2/NtlPacketUA.h / NtlPacketAU.h
- DboServer/Server/AuthServer/ClientSession.cpp
- DboServer/Server/AuthServer/PacketAuthServer.cpp
- DboServer/Server/AuthServer/MasterServerPacket.cpp
- DboClient/Client/Stage/LogInStage.cpp / LogInStageState.cpp
- DboClient/Client/Main/DboPacketGenerator.cpp

流程：
1. 客户端连接配置中的 AuthServer IP/port。
2. 客户端发送 UA_LOGIN_REQ：用户名、密码字段、客户端 L/R 版本、MAC 地址。
3. AuthServer 检查客户端版本、账号长度/密码长度、临时封锁、账号数据库记录、密码校验、账号封禁/连接锁定、CharServer 负载和重复在线状态；并向 MasterServer 请求在线状态协调。
4. MasterServer 返回结果后，AuthServer 发 AU_LOGIN_RES。成功响应结构包含 result code、用户 ID、AuthKey、accountId、lastServerFarmId、开发功能权限、GM 标志及 CharServer 列表。
5. 客户端根据返回的服务器信息进入 CharServer 连接状态；原版状态机还管理连接超时、登录请求超时和 AuthServer 断开后的状态切换。

### 31.4 CharServer 角色大厅

关键文件：
- DboShared/NtlShared2/NtlPacketUC.h / NtlPacketCU.h
- DboServer/Server/CharServer/ClientSession.cpp / PacketCharServer.cpp / MasterServerPacket.cpp
- DboClient/Client/Stage/CharStageState.cpp / CharacterStage.cpp
- DboClient/Client/Main/DboPacketGenerator.cpp

流程：
1. 客户端向 CharServer 发送 UC_LOGIN_REQ，字段为 accountId、AuthKey 和 serverFarmId；CharServer 将 CM_LOGIN_REQ 发给 MasterServer 验证 AuthKey。
2. 角色数据加载通过 UC_CHARACTER_LOAD_REQ 等请求进入 CharServer，再由 CharServer 向 QueryServer 请求数据库数据。
3. 创建角色使用 UC_CHARACTER_ADD_REQ；服务端检查名称、种族/外观字段范围、允许种族、角色槽位数量及账号角色归属，然后转发 QueryServer 写入。删除、恢复和重命名也由 CharServer 校验归属和条件。
4. 选择角色使用 UC_CHARACTER_SELECT_REQ（charId、serverChannelId）。服务端校验角色是否属于当前账号、服务器频道是否 UP/可见/未锁定以及负载限制。
5. CharServer 通过 CM_MOVE_REQ 向 MasterServer 请求迁移认证；MasterServer 生成新的 AuthKey。CharServer 返回 CU_CHARACTER_SELECT_RES，包含角色 ID、AuthKey、GameServer 公网 IP 和客户端端口。

### 31.5 GameServer 进入游戏

关键文件：
- DboShared/NtlShared2/NtlPacketUG.h / NtlPacketGU.h / NtlPacketGM.h / NtlPacketMG.h
- DboServer/Server/GameServer/PacketGameServer.cpp / MasterServerPacket.cpp
- DboServer/Server/MasterServer/GamePacket.cpp

流程：
1. 客户端连接 CharServer 返回的 GameServer IP/port。
2. 客户端发送 UG_GAME_ENTER_REQ：accountId、charId、AuthKey、tutorial mode。
3. GameServer 检查 ID 和当前对象冲突，再向 MasterServer 发送 GM_LOGIN_REQ（accountId、AuthKey、serverFarmId、serverChannelId）。
4. MasterServer 校验 AuthKey；GameServer 收到 MG_LOGIN_RES 后返回 GU_GAME_ENTER_RES。之后客户端继续发送进入世界请求，服务端加载世界信息、位置/状态并完成 loading/ready 流程。

### 31.6 与 Cloudflare 账号体系的关键差异

- dbo-account-api 当前使用 Cloudflare D1 的账号记录与 session_token；登录/会话/登出接口属于 HTTP JSON API。
- OpenDBO AuthServer 当前从自己的账号数据库查询 accounts 表，并以 OpenDBO 的账号记录、在线状态、AuthKey 机制完成认证；accountId 是原版内部标识。
- Cloudflare session_token、OpenDBO accountId、OpenDBO AuthKey 不是同一数据类型，也不是同一信任域。现有源码中没有发现把 Cloudflare session_token 兑换成 OpenDBO AuthKey 的桥接接口。
- 因此 C 方案必须明确账号桥接设计：Cloudflare 账号如何映射到 OpenDBO accountId，以及由哪个可信服务端验证 Cloudflare 会话并发放/交换原版 AuthKey。不能让客户端伪造 AuthKey，也不能直接把 session_token 填入 AuthKey 字段。

### 31.7 当前尚缺的协议材料

- 完整 AuthServer 密码校验/密码编码函数与客户端密码生成路径；本轮只确认请求字段与服务器验证位置。
- MasterServer AuthKey 生成、有效期、一次性消费、账号绑定和迁移时序的完整实现。
- 完整 TCP 帧拼接/拆包、大小端、序号、加密位、编码器选择及各服务器配置的核对。
- CharServer 的完整角色列表响应、创建角色默认装备/出生点字段和 QueryServer 数据结构映射。
- GameServer 登录成功后的完整世界进入、数据加载、断线重连和跨频道迁移流程。
- Cloudflare 与 OpenDBO 账号 ID 映射、唯一账号体验、账号恢复和封禁同步策略的用户决策与实现方案。

本轮只读检查 OpenDBO-Core 与 DBOFF/dbo-web 文档源码；未连接或启动任何游戏服务器，未执行数据库写入，也未修改 OpenDBO 源码。


## 32. Cloudflare Worker 当前部署状态只读核对（2026-11-02）

### 32.1 生产 Worker

- 账户：DragonBallOffline（account ID abd019218b27f70e7c90ac6fc54563b3）。
- Worker：dbo-account-api。
- 当前最新部署：version 14，version ID ad2618da-0e09-4884-97d9-dba86f064351；deployment ID 32ffd587-5398-4678-82de-ca702bb9ff36。
- 流量：100% 指向 version 14；部署时间 2026-10-23T00:15:38Z。
- D1 binding DB 指向生产数据库 ID edb91621-24f3-47af-8798-54d1b3914154。
- Worker script-settings 返回 observability=null；本轮未改变该设置。

### 32.2 Staging Worker

- Worker：dbo-account-api-staging。
- 当前最新部署：version 10，version ID f5bdf929-66f1-4c8d-a2c8-a818a8cd7281；deployment ID cf0df87e-8cfd-4496-b908-4940d7ce9642。
- 流量：100% 指向 version 10；部署时间 2026-10-23T00:01:20Z。
- D1 binding DB 指向独立 staging 数据库 ID 0d555faf-0ae3-486e-bafd-b3100534f7de。
- Observability 已启用，head_sampling_rate=1；invocation logs、logs persist 与 traces persist 均已启用，destinations 为 cloudflare。

### 32.3 核对限制

- 生产与 staging 的部署 version 元数据均已从 Cloudflare API GET 读取；两者 script etag 相同（d4a095c5efe4e5f1dc2499174678ad9706febcabad15dde617a6567c81582f9a）。
- 本轮未下载当前部署包并与 GitHub worker/worker.js 做字节级对比，不能据相同 etag 推断仓库源码与部署内容一定完全一致。
- 当前部署时间为 2026-10-23；没有证据表明本轮之后有新部署。Worker 源码中路由的存在仍不能替代线上 HTTP 行为测试。
- 本轮全部是 Cloudflare API GET 只读操作，没有修改生产/staging Worker、D1、Pages、Secrets、绑定或流量分配。


## 33. OpenDBO 服务端职责盘点与无中心社交方案（2026-11-02）

### 33.1 用户本轮新增决策边界（证据 D）

- 好友、公共大厅、组队尚未决定采用服务器方案；必须先寻找完全不依赖中心服务器的方案。
- OpenDBO 原版服务器功能必须先明确列出，再逐项决定是否保留服务器依赖；用户预计最终只有极少数功能会继续依靠服务器。
- 不得默认把 Cloudflare Worker 作为好友、公共大厅、组队的必需后端。
- 不得因 OpenDBO 原版采用服务端权威架构，就要求 DBOFF 离线单机流程也依赖远端服务器。

### 33.2 OpenDBO-Core 服务器清单（证据 B）

已重新读取 OpenDBO-Core README.md：服务器进程为 AuthServer、CharServer、ChatServer、GameServer（每个频道一个进程）、MasterServer、QueryServer；README 明确说明 QueryServer 是唯一直接访问数据库的服务器。

已读取 GameServer/PacketGameServer.cpp（约 645 KB），通过处理函数名盘点到 309 个 CClientSession 请求处理入口，覆盖世界进入/退出、移动、战斗、技能、任务、背包、商店、银行、邮件、交易、拍卖、队伍、匹配、公会、Dojo、Budokai、TimeQuest、Dragonball Scramble、宠物/吉祥物、载具等大量系统。具体完整分类见 docs/OPENDBO_SERVER_FUNCTION_AUDIT.md。

已读取 ChatServer/PacketChatServer.cpp 与 ClientSession.cpp 的相关范围，确认其处理 Say、Shout、Whisper、Party Chat、Guild Chat、Trade Chat、Find Party Chat，以及公会邀请响应、解散、离会、踢人、任命副会长、公告等社区操作；公会持久化请求交由 QueryServer。

### 33.3 初步架构判断（不是最终批准）

- AuthServer / CharServer / MasterServer / QueryServer 是原版 MMO 认证、角色大厅、服务协调和数据库访问架构；DBOFF 的离线角色与存档可采用本地机制替代。
- GameServer 承载大量原版权威游戏规则；这些规则需要在 DBOFF 还原，但不等于必须部署远端 GameServer，单机可由本地 Godot 承担。
- ChatServer 的聊天和社区广播可研究 P2P；好友、公会与在线状态仍需继续追踪完整 handler 和数据流。
- 组队合作战斗可研究房主权威 P2P；全球公共大厅、离线消息、全局在线状态和全局排行榜存在发现/持久化/权威性问题，不能承诺在无任何在线节点时仍能提供完整全球服务。
- 完全不依赖第三方基础设施时，LAN 发现和手动公网直连/端口转发可行；STUN/TURN 会引入外部映射发现或中继服务。

### 33.4 新增审计文档

- 新增 docs/OPENDBO_SERVER_FUNCTION_AUDIT.md，列出六类原版服务职责、GameServer/ChatServer 功能面、无中心服务可行边界、材料缺口与后续审计顺序。
- 当前只完成第一轮职责盘点，不代表全部服务器功能已经逐函数审计，也未决定最终保留哪些在线功能。
- 本轮未修改 Godot 代码、OpenDBO 源码、Cloudflare Worker、D1 或 R2。


## 34. Doll 默认共斗模式与真人联机边界（2026-11-02）

### 34.1 用户明确的产品规则（证据 D）
- 传统意义上的真人组队不是 DBOFF 默认组队模式。通常不联网，直接由玩家存档生成 Doll 参与组队。
- Doll 可以来自自己的玩家存档，也可以来自其他玩家的存档。
- 原版大多数需要玩家共斗或对战的行为，原则上改为与 Doll 进行；不默认要求其他真人玩家在线。
- 真人玩家之间实时组队/共斗才需要 P2P，或由轻量服务器提供连接发现与握手信令。
- 不考虑穿透失败后的中继服务；NAT/CGNAT 穿透失败时，该次真人联机失败即可，不部署 TURN，不承担流量转发。
- 信令服务器只负责建立连接前的握手/连接信息交换，不作为 GameServer，不负责战斗模拟或转发游戏流量。

### 34.2 对此前方案的修正
- 第 33 节中“组队合作战斗可研究房主权威 P2P”的表述仅适用于用户明确选择真人玩家同场的可选模式，不再代表默认组队架构。
- 默认路线应是本地 Doll 组队与共斗；P2P 是真人玩家联机的可选连接能力。
- OpenDBO 原版队伍、匹配、副本、PVP/竞赛等功能应逐项检查能否改由 Doll 参与，不得直接照搬为真人在线功能。

### 34.3 待补材料与未决项
- 尚未读取 DBOFF 当前 Doll 生成、存档序列化、战斗 AI 和 Doll 参与玩法的具体实现文件。
- 尚缺玩家存档中可供 Doll 使用的字段清单，以及跨玩家 Doll 分享/导入的具体数据方式。
- 尚未逐项审计 OpenDBO 共斗/对战玩法的参与者限制、奖励归属和持久化逻辑。
- 本轮只更新产品边界记录，未修改 Godot、Worker、D1、R2 或 OpenDBO 源码。


## 35. 本地存档、账号与云存档接入基线审计（2026-11-02）

### 35.1 本阶段范围（用户明确）
当前只接通三项基础能力：本地存档、Cloudflare 云存档、账号身份。暂不开发启动器、好友、公共大厅、Doll 分享、P2P、真人组队或其他在线功能；遇到明确需求时再处理。

### 35.2 当前 DBOFF 代码证据（A）
已读取 `src/core/dbo_save_manager.gd`、`src/ui/lobby/character_lobby_ui.gd`、`src/world/world_scene_driver.gd`、背包/任务管理器及 `project.godot`：
- 本地存档路径：`user://saves/account_meta.json`、`user://saves/char_{id}.json`。
- 创建角色时会写入本地角色数据、角色简报和最后选择角色；大厅读取账号元数据/角色数据，世界场景读取激活角色数据。
- 目前未发现 60 秒自动保存调度、完整运行时状态回写、云上传/下载、冲突修订号、原子写入或损坏恢复。
- 当前 JSON 直接以 `FileAccess.WRITE` 覆盖；`DEFAULT_ACCOUNT_META` 中的 account_id=1001、username=dbo_player、gm_level=10 是本地占位值，不得作为真实账号身份或权限。
- 当前 main scene 是角色大厅；`project.godot` 没有账号/API/云同步 Autoload。DBOSaveManager 以静态 class_name 使用。
- 旧文档中 `src/managers/dbo_save_manager.gd` 的路径记录已更正；当前实际路径是 `src/core/dbo_save_manager.gd`。

### 35.3 dbo-web 与 Cloudflare 当前证据（A）
已读取 `dbo-web/worker/worker.js`、`functions/api/[[path]].js`、`ARCHITECTURE.md`：
- 当前 Worker 有注册、登录、登出、session check 和 GM/ADMIN API；没有云存档上传/下载/元数据 API。
- 注册/登录成功返回 account_id、username、account_type、session_token；session 有效期 30 天。注册要求 device_id 与 public_key；登录要求 device_id。
- Godot 应直接配置 Worker API 基址，开发使用 `https://dbo-account-api-staging.hoipoi.workers.dev`，生产使用 `https://dbo-account-api.hoipoi.workers.dev`，不依赖 Pages 相对路径代理。
- 生产 Worker version 14 仅绑定生产 D1；staging version 10 仅绑定 staging D1；两个版本都没有 R2 binding。
- 生产与 staging D1 当前只有账号/会话/设备/封禁/限流相关表，没有云存档元数据表。
- Cloudflare R2 bucket 列表 API 返回 HTTP 403 / code 10042，提示需先在 Dashboard 启用 R2。当前没有可用 R2 bucket 证据。

### 35.4 本阶段实施顺序
1. 修复本地存档写入可靠性，并建立运行时完整状态快照/回写。
2. Godot 内接账号注册、登录、session check、logout；离线模式不得被登录阻断。
3. 用户启用 R2 后，先建立 staging bucket/binding 和 D1 云存档元数据表。
4. staging Worker 实现 session 鉴权的云存档上传、下载与 revision 冲突保护。
5. Godot 按 30 分钟上传 dirty revision，并预留特殊动作前的统一 checkpoint 入口。
6. 通过 staging 端到端验证后，才考虑生产部署。

### 35.5 缺失材料与操作
- 需用户在 Cloudflare Dashboard 启用 R2；当前 API 明确报告未启用。
- 需要继续追踪完整运行时状态持有者与回写点，尤其世界位置、属性、背包/装备、技能、任务。
- 特殊动作清单与上传失败策略未定义；暂不擅自阻止任何游戏动作。
- 本轮只读审查并更新文档；未修改 Godot 源码、Worker、D1 schema、R2 或 Cloudflare 部署。


## 36. 2026-11-02 游客优先与 R2 零超额费用要求

用户明确确认：
- 未登录玩家可直接创建角色、正常进入游戏并保存本地进度；并且产品应主动偏向游客/离线体验，尽量不诱导联网。
- 账号、云存档是可选服务，不是单机游戏的入口门槛；以后主动登录时再处理本地与云端存档关联，冲突不得静默覆盖。
- R2 云存档达到免费额度安全阈值前必须自动暂停，用户不接受任何超额账单；费用安全优先于云功能可用性。

2026-11-02 Cloudflare API 只读复核：
- 用户已在 Dashboard 启用 R2。
- bucket 列表 API 已成功返回，当前 bucket 数量为 0。
- R2 metrics 的 Standard / Infrequent Access uploaded 与 published 对象数、payloadSize、metadataSize 均为 0。
- 尚未创建 DBOFF staging bucket、尚未绑定 Worker；没有执行任何 R2 写入。

官方 R2 Standard 免费额度（查阅 2026-11-02 官方 Pricing）：10 GB-month、1M Class A/月、10M Class B/月，出站免费；Infrequent Access 不享有免费额度。R2 超额用量按账户计费。Cloudflare 未提供可依赖的原生“免费额度硬封顶”配置，因此 DBOFF 必须在 Worker 层实现 fail-closed 用量账本和硬停止。

拟定保护阈值：DBOFF 使用量达到免费额度的 70% 即暂停云存档，即最多 7 GB 活跃对象、700,000 Class A/月、7,000,000 Class B/月；此为待实现设计值，不代表当前已配置。暂停上传和下载等 R2 读写，但不影响本地保存/游戏。所有 R2 访问必须经过私有 bucket + Worker，禁止客户端直连。若用量账本、metrics 状态或月度周期状态不明，默认暂停。

当前缺少/待办：
1. 尚未创建 staging bucket 和 Worker R2 binding。
2. 尚未实现 D1 用量账本、配额检查、quota_paused 状态与客户端提示。
3. 尚未核对 Cloudflare 账户是否有其他项目/服务消耗 R2 免费额度；必须保留安全余量。
4. 尚未设计本地游客存档在后续登录时的无损关联/冲突选择界面。

本轮仅审计并更新 Markdown，没有创建 R2 bucket、修改 D1/Worker、部署代码或调整账单设置。


## 37. 2026-11-02 启动器产品定位与云存档交互（用户明确确认）

### 37.1 启动器定位（证据 D）
- 启动器是一个尚未创建的轻量独立程序，不是现有工程；此前 GitHub 找不到启动器代码是正常情况，不应再把它描述为“遗失/待用户提供”。
- 启动器职责包括：游戏版本检查与更新、可选云存档同步、GM 发放相关能力。
- 启动器不是游戏运行的强制前置条件；游客/离线玩家仍应能直接运行游戏并保存本地进度。
- 本轮没有确定启动器使用的语言/UI 框架、安装包形式、更新清单格式，也没有定义 GM 发放的具体操作、权限和数据结构；这些属于后续设计材料，不得自行假设。

### 37.2 云存档上传交互（用户明确确认）
- 取消游戏运行期间每 30 分钟上传云存档的方案。
- 游戏只负责本地存档；启动器负责云端同步。游戏运行期间不上传，也不读取正在变化的存档。
- 玩家关闭启动器时，若存在尚未同步的本地存档，向玩家提供明确选项：**上传存档**或**不上传并关闭**。不得静默自动上传。
- 选择上传时，必须先确认游戏进程已经完全退出、存档写入结束、文件稳定且快照可校验，再执行 dirty/hash/revision 检查和上传。
- 选择不上传时，保留本地存档和待同步状态，正常关闭启动器；下次启动器运行时仍可再次询问。
- 上传失败时保留本地数据和 pending revision，明确告知失败；不得删除本地存档或阻断离线游玩。失败后仍可关闭启动器，但必须保留待同步状态。
- 无变化时不上传；上传前可检查轻量云端 metadata/revision，避免重复传输。恢复/迁移时才由用户主动触发完整下载。
- Worker 负责 session 验证、设备/账号授权、R2 配额保护、revision 冲突控制和全部 R2 读写；启动器不持有 R2/S3 凭据。

### 37.3 已取消的方向
- 不实现异地登录后远程通知旧设备上传。
- 不实现远程唤醒、常驻代理、WebSocket 或轮询信令；减少请求、后台常驻和潜在 Cloudflare 费用。
- 不再把“旧设备启动器是否在线”作为云存档同步流程的前提。

### 37.4 当前材料与设计缺口
- 启动器工程尚未创建，因此不存在可供代码审查的启动器源码、场景或工程配置；这是计划中的新项目，不是仓库遗漏。
- 尚待确定启动器技术栈、Windows 安装/便携形式、游戏更新 manifest/差分包与回滚策略。
- 尚待明确 GM 发放能力的具体范围、GM 身份验证方式、发放对象、审计记录和 Worker API；GM 权限必须由服务端验证，不能信任启动器本地标记。
- 尚待设计关闭确认弹窗的触发条件、上传进度/失败提示，以及云端与本地 revision 冲突时的用户选择流程。
- 游戏端完整运行时状态回写、本地存档原子写入/校验和、Worker 云存档接口、R2 staging bucket 与 quota ledger 仍未实现或未验证，不能因为启动器承担上传就跳过这些依赖。

本轮只更新架构与进度文档；没有创建启动器工程、修改 Godot/Worker/D1/R2 或部署。


## 38. 2026-11-02 本地存档闭环第一轮代码审计（证据 A/B）

### 38.1 本轮读取的 DBOFF 当前代码
- `src/core/dbo_save_manager.gd` SHA `912aef25a9842ecaf892c0a27ce249b82b2cca4e`
- `src/ui/lobby/character_lobby_ui.gd` SHA `dc91e58dd2d86e3a41cb4d9cf027f95cefbfd73e`
- `src/world/world_scene_driver.gd` SHA `c75b432dc16f59fd01f73d635a095b283592a237`
- `src/core/dbo_inventory_manager.gd` SHA `9204dc6adc85bd1d35a1366d45aea47673d84de3`
- `src/core/dbo_quest_manager.gd` SHA `3bf9b6719554f7bdfafef3e83c932cab7a5c5e7`
- `src/entities/player_controller_3d.gd` SHA `aafeb12ca7a774fa33ffdbbac4d6715edcd82063`
- `src/entities/character_base_3d.gd` SHA `6197c6f213d1089624b4b99dafcf9744f217d068`
- `project.godot` SHA `8adf1940305b5a72513e584453b8f4759f605221`

### 38.2 已确认的问题（限已读取代码范围）
1. 账号与角色 JSON 使用 `FileAccess.WRITE` 直接覆盖；没有观察到临时文件、原子替换、备份轮换、内容校验或损坏恢复。保存函数返回 void，没有向调用者反馈打开/写入失败。
2. SaveManager 没有从玩家实体、背包、任务等运行时系统采集数据的统一快照入口。
3. WorldSceneDriver 从存档读取角色档案和初始位置，但已读取的世界/玩家脚本范围内未发现退出位置、方向、world_id 等写回角色 JSON 的闭环。
4. CharacterBase 持有 current_health/current_energy、RP、六维属性等运行时字段；已读取的初始化路径只将 race/gender/is_adult 映射到玩家实体，未发现 stats 的完整加载/写回。
5. InventoryManager 持有 equipped_items、bags、bag_capsules、zenny，并处理新手背包、添加物品、装备交换；已读脚本没有从角色 JSON 恢复或序列化这些状态的接口。UI 事件信号不等于持久化。
6. QuestManager 持有 active_quests/completed_quests，击杀事件会更新进度；已读脚本没有角色 JSON 加载/保存逻辑。
7. 默认 JSON 预留 skills、quick_slots、quest_inventory 等字段，但技能/快捷栏运行时持有者和读写路径未定位。
8. DEFAULT_ACCOUNT_META 含 account_id=1001、username=dbo_player、gm_level=10 占位值；不能作为真实账号身份或 GM 授权依据。移除/迁移须单独设计，不能直接覆盖现有玩家文件。
9. `_active_character_cache` 与传入 Dictionary 直接共享引用；显式保存之外没有统一 dirty 标记、revision 或最近成功保存状态。

### 38.3 OpenDBO-Core 对照（证据 B）
本轮读取 `DboServer/Server/GameServer/CPlayer.cpp` 的 `CPlayer::SaveToDB`（约 901–1025 行）、`CharacterRepository.h`、`CharacterRepository.cpp` 的 `SavePcData`、`LoadCharacterCoreDataAsync`、`LoadCharacterExtendedDataAsync`。
- 原版定时路径 `SaveToDB(true)` 发送轻量运行时位置/世界/经验/游戏时间数据。
- 完整路径 `SaveToDB(false)` 保存经验、世界、位置/方向、LP/EP/RP/RP 球/AP、地图索引、标题、教程标记等，并触发物品冷却、技能、Buff、HTB 冷却、宠物数据及任务进度保存。
- Repository 将角色核心与扩展数据分组读取；扩展数据包括 items、skills、HTB skills、buffs、quest items、quests、quickslots、mascots、HoiPoi recipe、item cooldowns、portals 等。
- 原版由 GameServer 汇总运行时权威对象并向 QueryServer 提交持久化请求。DBOFF 不必复刻 QueryServer/数据库，但必须建立本地等价的“运行时状态采集 → 规范化快照 → 可靠写盘”边界。
- 原版定时运行时保存与完整退出保存不是同一数据量；DBOFF 的本地 checkpoint 与退出保存不等于云上传。云上传仅由未来启动器在游戏退出后按玩家选择执行。

### 38.4 建议实施顺序（尚未实现）
1. 定义单一角色 schema/schema_version，区分静态表数据与玩家可变状态。
2. 为玩家实体、Inventory、Quest、Skills/QuickSlots、世界位置/绑定点建立 serialize/deserialize 契约。
3. 建立统一快照入口，避免 UI 脚本各自写 JSON。
4. 实现安全写入：临时文件、检查写入/关闭结果、重新读取解析验证，再替换主文件；保留至少一份上一个有效备份。Godot 文件 API 与 Windows 替换语义须先验证。
5. 引入 dirty/revision 与最近成功保存状态；保存失败不能清除 dirty。
6. 定义主文件损坏时恢复优先级，绝不自动用默认新角色数据覆盖损坏存档。
7. 再接入本地定时保存（此前用户提出的 60 秒目标），验证正常退出、异常退出、场景切换和多角色隔离。

### 38.5 当前缺少的代码/证据
- 技能与快捷栏运行时持有者、技能学习/升级/冷却数据结构及调用入口。
- 背包/装备 UI、物品使用/拾取/丢弃等改变 Inventory 状态的全部调用方。
- 属性/经验/等级/货币的权威运行时持有者与奖励结算调用方。
- 任务 UI、任务奖励、任务物品和任务触发器的完整数据路径。
- 世界切换/传送/绑定点系统，以及玩家方向、位置和地图 ID 的最终权威来源。
- 所有调用 DBOSaveManager 的脚本/场景完整清单；当前 GitHub connector 代码搜索未返回匹配项，不能把有限读取等同于全仓库零调用。
- 正常退出、强制结束、写盘中断、损坏 JSON、磁盘空间不足、多角色切换等运行验证。
- OpenDBO 物品、技能、任务、绑定点的具体保存处理函数/Repository SQL 仍需逐项追踪；本轮只完成角色核心保存与扩展数据加载入口初步映射。

本轮只读审计并记录证据；没有修改 Godot 源码、场景、资源、Cloudflare 或部署。
### 38.6 当前源码目录结构补充核对（2026-11-02）
- 当前 `src/core/` 目录可见 `dbo_save_manager.gd`、`dbo_inventory_manager.gd`、`dbo_quest_manager.gd` 等，但没有独立的 SkillManager/QuickSlotManager。
- 当前 `src/entities/` 有 `dbo_buff_component.gd`、`dbo_character_state_machine.gd`、`character_base_3d.gd`、`player_controller_3d.gd`；尚不能据此认定 Buff/技能完整系统已实现，需继续读取具体组件与调用方。
- 当前 `src/ui/` 只有 hud、lobby 两个子目录；当前目录树中没有独立 inventory 或 quest UI 目录。角色大厅脚本是已确认的角色数据读写调用方之一。
- 当前 `scenes/` 仅列出 entities、lobby、world 子目录；本轮没有发现专门的背包/任务场景目录。
- 以上是 GitHub 当前 main 目录树证据，不排除其他目录、场景脚本或尚未推送的本地文件中存在相关逻辑。


## 39. 2026-11-02 开发重心调整：从存档审计转回核心游戏恢复

### 39.1 用户澄清（证据 D）
用户确认：技能管理、快捷栏等尚未定位到的独立系统并非遗漏上传或文件丢失，而是因为这些功能目前还没有开发。后续不得把“当前仓库没有对应模块”误报为“用户缺少文件”，也不应要求用户从旧项目或回收站恢复这些模块。

### 39.2 当前工作判断
- 第一轮本地存档审计已经识别出当前存档覆盖范围不足，但完整的技能、成长、任务等运行时数据所有权必须随着实际游戏系统恢复逐步确定。
- 在相关玩法和数据持有者尚未实现时，继续深入设计完整存档 schema 容易建立在假设上，之后还会因真实系统实现而返工。
- 因此建议暂缓“完整运行时快照 schema”和启动器工程，不放弃存档可靠性目标；将开发重心转回现有游戏的修复与核心玩法恢复。
- 优先处理当前已有代码/场景中的真实问题，按依赖恢复客户端基础、角色生命周期、角色表现与控制、世界/地形、实体、战斗等可玩主流程；每个系统仍须遵循修复、OpenDBO 对齐、方案评价、优化和验证的闭环。
- 背包、成长、技能、任务等在恢复到相应玩法阶段时再建立真实数据所有权与持久化契约。不得为了存档设计提前创建空壳管理器。
- 本地存档当前已有的角色创建/选择基础读写继续保留；在进入完整存档实现前，至少避免破坏现有数据。原子写入、备份、损坏恢复等基础可靠性工作可在合适节点单独安排。

### 39.3 本轮范围与限制
本轮只确认开发方向和缺失模块的性质；没有修改 Godot 源码、场景、资源、Worker、D1、R2 或部署。下一步应以当前 main 中实际存在的游戏功能和用户正在修复的结果为起点，不要求用户提供尚未开发的模块。


## 40. 2026-11-02 角色大厅创角/选角预览缺少初始装备（用户报告 + 当前代码证据）

### 40.1 用户报告（证据 D）
用户报告：创建角色界面与选择角色界面的人物都没有穿戴初始存档自带装备，显示为白色底裤素体。两个界面共用同一套 CharacterLobbyStage 角色预览模型与装备挂载路径。

### 40.2 已确认的代码路径（证据 A）
当前 main 分支读取：
- `src/ui/lobby/character_lobby_stage.gd` SHA `fb64f3fc104b12a081c9d05891cec8a989639a88`
- `src/ui/lobby/character_lobby_ui.gd` SHA `dc91e58dd2d86e3a41cb4d9cf027f95cefbfd73e`
- `src/entities/character_factory.gd` SHA `856841f164c5b512f46ddfcecce8e49907914345`
- `src/core/dbo_save_manager.gd` SHA `912aef25a9842ecaf892c0a27ce249b82b2cca4e`
- `data/newbie_table.json` SHA `48ef855d9945369798dca46777b7ccffe3c2a2ad`

数据与调用链：
1. `character_lobby_ui.gd::_update_avatar_preview()` 通过当前 race/class 调用 `DBOSaveManager.get_newbie_starter_items()`，并通过 `avatar_visual_changed` 信号把初始穿戴清单传给舞台。
2. 选择已有角色时，`_on_slot_character_selected()` 从角色存档 `containers.inventory_items` 中筛选 `place/byPlace == 0` 且 `pos/byPosition != 255` 的物品，再发出同一信号。
3. `character_lobby_stage.gd::_on_avatar_visual_changed()` 接收装备列表，并逐个调用 `DBOCharacterFactory.equip_item_to_character()`。
4. 舞台统一通过 `build_player_visual(race, gender, false)` 创建儿童期角色模型；因此创角和选角都会走儿童模型分支。
5. `character_factory.gd::equip_item_to_character()` 在处理武器/史考特挂载后，存在 `if not is_adult: return`，直接跳过儿童角色的上衣、裤子、鞋子、手套等蒙皮装备网格挂载。这与用户报告的“仅剩底裤素体”高度吻合，是当前最明确的代码级根因候选。
6. 同一个工厂的 `_resolve_item_glb_path()` 已经为儿童模型尝试解析 `res://assets/obj/item/<目录>/child/<模型>.glb`，但挂载函数随后又对儿童角色提前 return，说明儿童装备解析与挂载逻辑互相矛盾。
7. `newbie_table.json` 的初始穿戴数据确实包含装备栏项目，例如人类武术家配置：武器 500001（pos 0）、上衣 522001（pos 2）、裤子 522002（pos 3）、鞋子 522003（pos 4）、史考特 60000000（pos 5）；胶囊盒等 pos 255 项目不应当作为穿戴外观挂载。

### 40.3 当前结论与修复约束
- 当前已定位到预览共用路径中的儿童装备提前 return；不能只在 UI 层重复调用装备函数来解决。
- 不应简单删除 `if not is_adult: return` 后就直接加载成人装备：儿童模型必须使用与儿童骨骼/比例匹配的 child GLB；若 child GLB 不存在，应明确报告缺失并保留安全回退，不能把成人蒙皮网格强行挂到儿童骨骼上。
- 修复应让同一套装备应用逻辑同时服务创角预览和选角预览，并正确处理模型重建后的装备重应用与空装备列表时的旧槽位清理。
- 当前尚未完成 OpenDBO 对应装备模型选择、儿童/成人装备绑定与 CharacterStage 生命周期的源码对照，也未运行 Godot 验证；不能将本轮诊断标记为修复完成。

### 40.4 当前缺少的材料 / 验证
- GitHub main 当前递归树中没有任何 `.glb/.gltf/.obj/.fbx` 模型文件（0 个），包括代码引用的 `assets/obj/character/mesh_pc/` 与 `assets/obj/item/`。这是仓库当前未提供模型资产的证据，不代表用户本地没有这些文件。
- 不再要求用户重复提供历史报告中已有的装备 ID / 模型 key 映射。当前仍无法从 GitHub 验证用户本地模型文件是否存在及其 GLB Skin 结构；只有进入实际资源兼容性验证时，才针对具体缺失项提出最小材料请求。
- 首轮 `fetch_file` 对这两个大文件未返回正文；随后改用 Git blob SHA 读取成功并解析。目标装备字段与 itemproperty 映射已在第 41.7 节补齐，不再列为未解决材料。
- 需要当前本地运行时日志，确认上述初始装备项目的 item 数据命中、解析出的 GLB 路径、文件存在状态和加载结果；并在 Godot 4.7.2 下分别验证创角预览、选角预览、人类/那美克/魔人、男女及至少一个不同职业。

本轮只读诊断并记录 Markdown；未修改 Godot 源码、场景、模型资源或提交任何代码修复。



## 41. 2026-11-02 创角/选角初始装备问题：OpenDBO 装备管线对照补充

### 41.1 本轮重新核对的当前代码（证据 A）
重新读取当前 main：
- `src/entities/character_factory.gd` SHA `856841f164c5b512f46ddfcecce8e49907914345`
- `src/ui/lobby/character_lobby_stage.gd` SHA `fb64f3fc104b12a081c9d05891cec8a989639a88`
- `src/ui/lobby/character_lobby_ui.gd` SHA `dc91e58dd2d86e3a41cb4d9cf027f95cefbfd73e`
- `data/newbie_table.json` SHA `48ef855d9945369798dca46777b7ccffe3c2a2ad`

补充确认：
1. 当前舞台 `_on_avatar_visual_changed()` 对所有传入的装备项目调用 `DBOCharacterFactory.equip_item_to_character()`，当前版本没有额外的 `is_adult` 循环门控。
2. `_load_character_model()` 固定通过 `build_player_visual(race, gender, false)` 创建儿童模型。
3. 工厂的 `_resolve_item_glb_path()` 会先用 itemproperty 中的 `mesh_path/mesh_file` 解析资源，并在儿童状态先尝试 `child/` 路径；若儿童路径不存在，当前代码仍继续尝试成人路径。这是危险的静默回退：儿童资源缺失时不应把成人网格当作儿童装备使用。
4. `equip_item_to_character()` 对儿童角色仍保留 `if not is_adult: return`。因此当前上衣、裤子、鞋子和蒙皮手套不会挂载。此处与用户报告相符，是直接代码原因。
5. `newbie_table.json` 当前为对象结构，`DBOSaveManager._load_newbie_table()` 会将 Dictionary 转为 values 数组；`get_newbie_starter_items()` 过滤 `pos != 255`。例如人类格斗家初始项目包含武器 500001（pos 0）、上衣 522001（pos 2）、裤子 522002（pos 3）、鞋子 522003（pos 4）、史考特 60000000（pos 5）。新手装备数据不是本轮缺口。
6. 对照 OpenDBO `NtlItem.h` 后确认，`Equip_Slot_Type_Bit_Flag` 是装备槽 bit mask：HAND=1、SUB_WEAPON=2、JACKET=4、PANTS=8、BOOTS=16、SCOUTER=32、QUEST=64、COSTUME_SET=4096、COSTUME_HAIR_STYLE=8192 等；当前 DBOFF `_slot_flag_to_name()` 对上述常用单一 flag 的映射值一致。装备栏 `pos` 是 0-based slot index，与 bit flag 是不同字段，不能互换。仍需核对目标 item 数据实际值及是否存在多 bit 组合。

### 41.2 OpenDBO 原版源码对照（证据 B）
已读取 OpenDBO/OpenDBO-Core master：
- `DboClient/Client/Stage/CharacterStage.cpp` SHA `d4bafd3fde4124f4f2b05876c55064f0e126e631`
- `DboClient/Client/Stage/LobbyStage.cpp` SHA `d54cbddcd672f7b90f459065adf7decd6247b3f5`
- `DboClient/Lib/NtlSimulation/NtlSobCharProxyEquip.cpp` SHA `345a1eb13edd473fca3b4fd05f1dbe2d41064fd0`
- `DboClient/Lib/NtlPresentation/NtlPLCharacter.cpp` SHA `2fe5c39ebeb41d6128a96aa0ed77ba27ae020849`
- `DboShared/NtlGameTable/ItemTable.cpp` SHA `e6ab55da5e790079f4a56afac96a0054a0262211`
- `DboShared/NtlShared2/NtlItem.h` SHA `6870fc3552ef51337dcff1e77b3474b67dd3505a`

已确认的原版流程：
1. 创角 `CharacterStage.cpp::CreateDummyAvatar()` 从 NewbieTable 读取 `aitem_Tblidx[]` 与 `abyPos[]`，跳过 INVALID_TBLIDX 和 UNKNOWN 装备位置，构造装备容器数据后创建 Avatar。
2. 选角 `CharacterStage.cpp::CreateDownLoadAvatar()` 从角色摘要装备数组逐栏读取 tblidx；查找 ItemTable，跳过不存在或 `EQUIP_TYPE_UNKNOWN` 的项目，再构造装备容器。
3. `LobbyStage.cpp::CreateDummyAvatar()` 同样从 NewbieTable 读取装备；另外查找 ItemTable 并跳过 `byEquip_Type == EQUIP_SLOT_TYPE_UNKNOWN` 的不可装备项目。
4. `NtlSobCharProxyEquip.cpp::SobEquipCreateEventHandler()` 统一遍历装备槽，读取 ItemTable 的 `szModel`、`byModel_Type`，通过 `MakeItemModelName()` 加上角色种族/性别后调用 `CreatePLItem()`，再由 `CNtlPLCharacter::SetChangeEquipItem()` 纳入角色装备表现。
5. 原版 `MakeItemModelName()` 对常规装备根据种族和性别追加后缀；儿童状态仅对 Costume Mask / Hair Style 特殊追加 `_CH`，不能将旧报告中“所有儿童常规防具都必须使用独立 child 文件名”的说法当作 OpenDBO 原版规则。
6. `ItemTable.cpp` 分别读取 `Model_Type`、`Model`、`Equip_Type` 与 `Equip_Slot_Type_Bit_Flag`。这些字段语义不同，DBOFF 不能将 equip type、装备栏位置和装备槽 bit flag 混为一谈。

### 41.3 对旧报告的纠正与当前资源证据
- 历史报告 `starter_equipment_restoration_report.md` 声称 24 个儿童装备 GLB 已在 `assets/obj/item/mesh_armor_*/child/` 确认存在；`child_dual_body_and_equipment_diagnosis_report.md` 与 `starter_equipment_cause_and_solution_report.md` 则称当前儿童装备 GLB 为无 Skin 的成人静态网格。
- 上述历史文档结论互相矛盾，且均不能覆盖当前分支代码与文件树证据。
- 本轮递归读取当前 GitHub main tree：当前仓库没有提交 `.glb/.gltf/.obj/.fbx` 模型文件，也没有可供 GitHub 读取的 `assets/obj/item/` 资源树。此结论只表示 GitHub 当前分支未上传模型，不代表用户本地资源不存在。
- 因此，既有装备 ID → model key → 资源文件名映射可继续使用；但当前无法仅凭 GitHub 验证本地模型文件是否存在、是否含 Skin、骨骼名/IBM 是否兼容。不能再要求用户重复提供已经存在于历史报告中的 ID 与文件名映射。

### 41.4 当前诊断结论与后续工作
- 当前代码直接阻断点已修复：儿童角色装备挂载函数不再提前返回，儿童上衣/裤子/靴子/手套会进入与成人相同的 GLB + Skin 挂载流程。
- 重新核对 `equipment_item_mapping.json/.csv` 后，初始儿童装备的实际登记路径确实是成人命名文件名放在 `child/` 子目录中（例如 `child/a_hfi_04_01_j_h_m.glb`），与 `_resolve_item_glb_path()` 的优先查找规则一致。此前将其误判为必须使用 `a_hch_*` / `a_nch_*` / `a_mch_*` 命名，是旧报告推断错误，现予纠正。
- 儿童路径不存在时 resolver 仍会回退普通目录；后续运行若出现成人模型误挂，应进一步改为儿童资源缺失时明确告警并停止回退，而不是重新加回儿童统一跳过逻辑。
- 当前 GitHub 未提交 GLB 二进制，故无法从 GitHub 独立验证实际 Skin/骨骼结构；代码修改已提交，Godot 运行结果待用户反馈。
- 正确方向：保留创角/选角共用装备入口；明确区分刚体武器/史考特与需要 Skin 的防具/手套；儿童装备只有在资源的 Skin、骨骼映射和绑定矩阵通过检查后才允许挂载；缺失/不兼容时明确记录，不静默使用成人资源。
- 原版对照已经证明装备数据从 NewbieTable/角色装备栏进入统一装备代理，并由 ItemTable 模型字段和角色属性生成模型名；仍需继续查原版角色骨骼缩放/装备蒙皮绑定细节，以及 DBOFF 当前 GLB 的实际 Skin/骨骼结构。
- 尚未完成：核实本地模型物理文件与 GLB Skin 结构；进一步检查原版角色骨骼缩放与装备蒙皮的坐标/IBM 兼容；Godot 4.7.2 创角/选角运行验证。
- 本轮未修改 Godot 源码、场景、模型资源；仅更新本进度文档，没有执行代码修复或运行验证。


### 41.5 原版儿童骨骼缩放机制补充（证据 B）
继续读取 OpenDBO `DboClient/Lib/NtlPresentation/NtlPLCharacter.cpp` 中 `UpdatePreBoneScale()` 与 `UpdatePostBoneScale()`：
- `UpdatePreBoneScale()` 遍历角色动画层级，将动画帧的骨骼平移分量分别乘以 `BoneScale[parentIndex].fLength` 与 `fWidth`。
- `UpdatePostBoneScale()` 再将 `BoneScale[i]` 的 length/width 缩放应用到骨骼矩阵数组。
- 这确认原版儿童体型不是靠把成人装备静态模型缩小，而是角色骨骼动画/矩阵管线参与骨骼缩放。常规装备模型名按角色种族/性别生成，原版不要求常规上衣/裤子/靴子全部改用独立 `child` 文件名。
- 因此 DBOFF 后续应先明确当前儿童基础模型的骨骼比例是“已烘焙进顶点”还是“运行时骨骼缩放”，再决定装备 Skin 的导出和绑定策略。不能将成人静态网格、成人 Skin GLB、已烘焙儿童基础模型三者默认视为可直接互换。
- 本轮尚未追踪 OpenDBO 中装备主体网格与角色骨骼层级共享/绑定的全部底层实现；此项仍是 B 级对照未完成项。


### 41.6 装备槽 bit flag 映射核实（证据 B）
- 读取 OpenDBO `DboShared/NtlShared2/NtlItem.h` 的 `eEQUIP_SLOT_TYPE` 与 `eEQUIP_SLOT_FLAG`。
- 原版槽位索引依次为 HAND=0、SUB_WEAPON=1、JACKET=2、PANTS=3、BOOTS=4、SCOUTER=5、QUEST=6 等；对应 bit flag 是 `1 << slot_index`，所以 HAND=1、SUB_WEAPON=2、JACKET=4、PANTS=8、BOOTS=16、SCOUTER=32、QUEST=64、COSTUME_SET=4096、COSTUME_HAIR_STYLE=8192。
- 当前 DBOFF `_slot_flag_to_name()` 对常见单 bit 值的映射与原版定义一致；先前将其标为可能字段混淆需要修正：当前代码使用 `equip_slot_flag` 做视觉槽分类本身并非已证实错误。真正仍需确认的是每个 tblidx 的实际 flag 值、手套/武器的进一步区分，以及多 bit mask 是否会出现。
- `newbie_table.json` 中的 `pos` 是装备容器位置，不能拿它替代 `equip_slot_flag`。原版 `abyPos[]` 负责装备容器槽位置，而 ItemTable 的 `Equip_Slot_Type_Bit_Flag` 用于允许装备槽类型判断。


### 41.7 大型 JSON 映射读取成功与 child 路径不匹配（证据 A）
通过 GitHub blob SHA 读取并在工具端解析大型 JSON（不再要求用户手动导出）：
- `assets/tbl/table_item_data.json` SHA `c3037c03e7d176091588328c1931d142301b9252`，正文 6,768,810 字符。
- `assets/prop/property/itemproperty.json` SHA `5087513dd3ff28e98580c85b5e9d533d418c3154`，正文 15,774,876 字符。
- 从当前 `data/newbie_table.json` 的所有职业配置合并得到 22 个唯一初始穿戴 tblidx，全部在 `table_item_data` 中命中；对应属性 key 与 `mesh_path/mesh_file` 均已命中，唯一例外是 `W_STF_01` 没有 itemproperty 项，但它的 `model_type=0`，按原版规则不需要种族/性别后缀，仍可通过无后缀 key 查找。
- 已核实初始装备主要字段：
  - 武器/手套：500001 `W_GLV_16`（flag 1, equip_type 0, item_type 0）；505001 `W_GLV_01`（flag 1, equip_type 0, item_type 0）；506001 `W_STF_01`（flag 1, equip_type 0, item_type 1）。
  - 人类格斗家防具：522001/522002/522003 → `A_HFI_04_01_J/P/B`，flag 4/8/16，属性 key 分别追加 `_H_M` 或 `_H_F`，路径 `Mesh_Armor_HumanMale/Female`。
  - 人类气功师防具：523001/523002/523003 → `A_HMY_04_01_J/P/B`，flag 4/8/16，路径同人类男女防具目录。
  - 那美克战士防具：525001/525002/525003 → `A_NFI_04_01_J/P/B`，flag 4/8/16，属性 key 为 `_N_O_S1`，路径 `Mesh_Armor_Namek`。
  - 那美克龙族防具：526001/526002/526003 → `A_NMY_04_01_J/P/B`，flag 4/8/16，属性 key 为 `_N_O_S1`，路径 `Mesh_Armor_Namek`。
  - 魔人大魔人防具：527001/527002/527003 → `A_MMI_04_01_J/P/B`，flag 4/8/16，男女属性 key 分别为 `_M_M` / `_M_F`，路径 `Mesh_Armor_MajinMale/Female`。
  - 魔人意魔人防具：528001/528002/528003 → `A_MWO_04_01_J/P/B`，flag 4/8/16，男女属性 key 分别为 `_M_M` / `_M_F`，路径 `Mesh_Armor_MajinMale/Female`。
  - 史考特：60000000 `I_SCT_01`，flag 32、equip_type 3，按种族/性别查询属性 key。
- `_resolve_item_glb_path()` 使用 itemproperty 的 `mesh_file` 原样改扩展名，并在儿童模式下优先尝试同一文件名的 `child/` 子目录。映射 CSV/JSON 对初始装备登记的儿童路径与该规则一致，例如人类男格斗家上衣为 `mesh_armor_humanmale/child/a_hfi_04_01_j_h_m.glb`。
- 先前历史记录中“儿童装备必须改用 `a_hch_*` / `a_nch_*` / `a_mch_*` 命名”的判断与当前映射数据不符，已纠正；不能据此认定 resolver 会错过已登记的儿童 GLB。
- 本次移除儿童装备挂载提前返回后，儿童装备会按登记路径尝试加载并保留 GLB Skin；实际文件是否存在及 Skin/骨骼是否兼容仍需在本地 Godot 运行确认。若儿童资源确实缺失，当前 resolver 会回退普通目录，后续应根据运行日志决定是否禁止该回退。
- 仍缺的不是 tblidx/model 映射，而是 GitHub 当前未提交的本地模型文件本身及其 GLB 结构（Skin、骨骼名、IBM、顶点坐标/比例）。本轮没有要求用户重新提供映射。


### 2026-11-02：创角/选角儿童初始装备显示修复
- 用户明确要求不再依赖“儿童素体内嵌初始服装”的假设，统一按基础素体 + 独立装备挂载处理。
- 修改 `src/entities/character_factory.gd`：移除 `equip_item_to_character()` 中 `if not is_adult: return` 的儿童防具跳过逻辑；儿童角色现在与成人一样进入 GLB 加载、Skin 绑定、材质处理和槽位登记流程。史考特与非手套武器仍保留原有附件挂载分支。
- 更新 `get_pc_model_path()` 注释，避免继续将儿童素体描述为必然内嵌初始服装。
- 资源路径解析逻辑本来就会优先尝试儿童装备 `child/` 子目录，找不到时回退到普通装备路径；本次未改动该解析规则。
- 创角与选角共用角色装备工厂，因此该修改同时覆盖两个预览入口。
- **验证状态：代码已修改，尚未在 Godot 中运行验证。** 儿童装备 GLB 的 Skin/骨骼绑定、材质及最终显示仍需运行确认；若有错位，应针对具体资源/绑定修复。
