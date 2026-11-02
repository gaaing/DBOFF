# DBOFF 身份认证与云存档模型

> 建立日期：2026-11-02
> 文档性质：用户确认的产品规则 + 待实现架构约束
> 适用项目：DBOFF / dbo-web
> 重要：本文记录目标设计，不代表当前客户端或 Worker 已实现这些机制。

## 1. 用户确认的核心定位（证据 D）

用户明确说明：当前所称的“登录系统”并不是传统 MMO 登录系统；它的主要用途是账号识别与云存档。游戏以本地运行和本地存档为主。

用户给出的存档节奏：
- 本地存档：每 60 秒执行一次心跳/定期保存。
- 云存档：正常情况下每 30 分钟上传一次。
- 特殊动作：在执行特殊动作之前，额外上传一次云存档。

以上时间间隔和触发规则属于用户提供的目标规则；当前是否已有代码实现、心跳具体语义、特殊动作清单及失败策略均未验证。

## 2. 身份与运行模式必须分离

### 2.1 Cloudflare 账号身份
Cloudflare 账号服务的主要职责是识别云存档所有者、在需要云存档时验证账号会话、提供账号状态及 GM 等账号级权限，并为跨设备恢复、账号迁移及未来在线业务提供身份基础。
Cloudflare 登录成功不等于进入 OpenDBO GameServer，也不等于取得原版 AuthKey。

### 2.2 本地游戏运行
- 离线核心玩法必须能够在没有 Cloudflare 网络连接时启动和继续。
- 本地存档是正常游玩期间的主要进度来源。
- 普通移动、战斗、任务和地图操作不应逐项等待 Cloudflare 请求。
- 用户未登录或云服务暂时不可用时，应允许离线游玩；云存档操作进入待同步状态，而不是阻断本地进度。

是否允许首次启动完全不注册/不登录，以及游客存档以后如何绑定账号，仍需确认。

### 2.3 OpenDBO 原版服务器
OpenDBO AuthServer / CharServer / GameServer 是另一套原版 MMO 协议和权威游戏服务体系。它们不应被当作 Cloudflare 云存档服务，也不应因为用户使用 Cloudflare 账号就自动要求连接。
OpenDBO 协议继续研究；是否提供可选的在线/多人模式、哪些系统需要原版服务器权威，按具体玩法另行决定。离线单机流程不依赖 OpenDBO 服务器在线。

## 3. 目标存档生命周期
1. 游戏状态变化后，本地进度继续正常运行。
2. 每 60 秒触发本地保存心跳，将当前待保存状态安全写入本地存档。
3. 本地保存成功后更新本地保存版本/修订号；不要把本地保存心跳当作网络心跳。
4. 每 30 分钟检查是否存在尚未上传的存档变更；若已登录且网络可用，上传云端。
5. 特殊动作发生前，触发一次额外云存档上传/检查点。
6. 云端上传成功后，记录云端已确认的修订号；上传失败时保留本地进度和待上传状态，之后重试。
7. 跨设备恢复时，比较本地与云端存档版本/修订号和时间，不允许旧设备的旧快照静默覆盖更新的云端数据。

第 2、4、5 项的具体时序、并发控制、上传原子性和失败处理尚待设计与代码核查。

## 4. 必须区分的三种保存/连接机制

| 机制 | 目标频率 | 是否依赖网络 | 主要目的 |
|---|---:|---|---|
| 本地保存心跳 | 每 60 秒 | 否 | 降低崩溃/断电造成的本地进度损失 |
| 云存档定时上传 | 每 30 分钟 | 是；失败可延后 | 备份与跨设备恢复 |
| 特殊动作前上传 | 动作触发前额外执行 | 是；失败策略待定 | 为关键操作建立云端检查点 |

“60 秒心跳”目前按用户表述记录为本地存档心跳，不应擅自解释为每 60 秒向 Cloudflare 发送网络请求或 OpenDBO 保活包。

## 5. 架构约束
- 本地保存和云端上传必须是两个独立职责；本地保存不能等待云端响应。
- 云端上传只同步有变化的存档修订，避免每 30 分钟无条件重复传输整份存档（除非后续明确选择整包快照策略）。
- 使用修订号/版本号、校验值和条件写入，防止旧设备覆盖较新存档。
- 上传应具备幂等性、可重试性和中断恢复能力。
- 云存档不是反作弊证明；哈希/校验值只能检测传输或存储一致性，不能证明本地游戏状态真实。
- 影响共享经济、排行榜或其他玩家权益的结果，必须单独设计服务端权威验证，不能仅因存档已上传就信任其内容。
- 普通单机流程不应因 Cloudflare 或 OpenDBO 服务不可用而无法继续。
- 不将 Cloudflare session_token、OpenDBO accountId 和 OpenDBO AuthKey 混用。

## 6. 特殊动作前上传：待确认事项

用户已确认“特殊动作之前上传一次”，但尚未定义动作清单。需要逐项确认哪些动作属于必须建立云端检查点的操作，例如：
- 主动执行跨设备/账号存档迁移；
- 账号绑定、解绑或存档归属变更；
- 可能覆盖、替换或删除云端存档的操作；
- 其他用户指定的关键操作。

上述仅为待讨论例子，不代表用户已批准全部纳入。

还需决定：上传失败时，是阻止该特殊动作、允许动作但标记为未同步，还是提供明确的重试/取消选择。不能默认所有特殊动作都必须因网络故障而被阻断。

## 7. 当前材料缺口与核查状态

截至 2026-11-02 的 GitHub 只读检查：
- DBOFF docs/AI_DEVELOPMENT_RULES.md、docs/DBOFF_DEVELOPMENT_MAP.md、docs/AI_WORK_PROGRESS.md 已读取。
- dbo-web 根目录 ARCHITECTURE.md 已读取；其中已写明本地进度为主、云存档用于账号迁移而非实时双设备同步，但尚未包含用户本轮明确的 60 秒/30 分钟/特殊动作前上传节奏。
- 当前 main 分支实际本地存档脚本为 `src/core/dbo_save_manager.gd`（已读取）；此前记录的 `src/managers/dbo_save_manager.gd` 路径错误，已由本轮核实更正。
- `src/core/dbo_save_manager.gd` 已实现本地账号元数据与角色 JSON 的基础读写，但没有 60 秒自动保存调度、云端上传、修订号/冲突控制、原子写入或损坏恢复机制。
- `project.godot` 当前主场景仍是角色大厅；Autoload 列表没有账号网络服务或云存档服务。DBOSaveManager 以 `class_name` 静态类形式被大厅和世界场景调用。
- 当前 dbo-web `worker/worker.js` 只有账号注册、登录、登出、会话检查及 GM/ADMIN 接口；没有云存档上传、下载或元数据接口。
- 生产与 staging Worker 当前版本都只绑定 D1 `DB`，未绑定 R2。Cloudflare 账户的 R2 bucket 列表 API 返回 403 / code 10042，提示需先在 Dashboard 启用 R2。
- 生产与 staging D1 当前只有 accounts、sessions、devices、account_devices、auth_rate_limits、banned_devices、banned_ips、gm_invite_codes 等账号/认证表；没有云存档元数据表。
- 当前没有证据证明 60 秒本地保存、30 分钟云上传或特殊动作前上传已经实现。

## 8. 后续工作顺序
1. 找到并审查当前真实的本地存档脚本与所有保存调用点，确认 60 秒心跳是否已实现及其语义。
2. 读取 dbo-web 当前 Worker 路由和 Cloudflare 绑定，确认是否已有云存档上传/下载接口；不得把账号登录接口误认为云存档接口。
3. 明确存档格式、修订号、云端对象存储与元数据结构。
4. 与用户确认特殊动作清单及上传失败策略。
5. 设计本地保存、定时上传、关键动作检查点、跨设备恢复和冲突保护的完整状态机。
6. 在 staging 完成验证后，再考虑生产部署。

本轮仅新增设计记录；未修改 Godot 代码、Worker、D1、R2 或 Cloudflare 部署。

## 9. 2026-11-02 当前代码与 Cloudflare 资源审计（证据 A）

### 9.1 DBOFF 本地存档现状

已读取：
- `src/core/dbo_save_manager.gd`
- `src/ui/lobby/character_lobby_ui.gd`
- `src/world/world_scene_driver.gd`
- `src/core/dbo_inventory_manager.gd`
- `src/core/dbo_quest_manager.gd`
- `project.godot`

确认：
- 当前本地文件为 `user://saves/account_meta.json` 与 `user://saves/char_{id}.json`。
- 新建角色时会写入角色 JSON、账号角色简报和最后选择角色。
- 角色大厅会读取账号元数据/角色数据；世界场景会读取激活角色数据。
- 存档脚本目前直接使用 `FileAccess.WRITE` 覆盖 JSON 文件，没有临时文件+原子替换、备份、校验和或 schema migration。
- `DEFAULT_ACCOUNT_META` 仍包含本地占位值 account_id=1001、username=dbo_player、gm_level=10；这些不能作为真实 Cloudflare 身份或 GM 授权。
- 角色运行期间尚未发现已接入 60 秒自动保存的调度器；本轮读取的背包与任务管理器持有运行时数据，但没有直接调用 DBOSaveManager 的保存接口。
- `world_scene_driver.gd` 目前从存档读取角色与世界初始状态；没有发现对应的完整退出/定时回写闭环。
- 当前已读取范围内未发现账号登录 UI、HTTP API client、session token 持久化或云同步协调器。

### 9.2 dbo-web 账号接口现状

当前 `worker/worker.js` 已有：
- `POST /api/register`：注册并返回 account_id、username、account_type、device_id、session_token。
- `POST /api/login`：登录并返回上述身份字段及 session_token。
- `POST /api/logout`：撤销 session。
- `POST /api/session/check`：检查 session 是否有效并返回 account_type。

session 默认有效期为 30 天。注册请求要求 username、password、device_id、public_key；登录要求 username、password、device_id，public_key 可选。Worker 当前 JSON body 读取上限为 16 KiB；未来存档文件不能沿用该 JSON 小请求处理器直接接收大文件。

Godot 客户端应使用明确配置的 Worker API 基址；开发期使用 staging：
`https://dbo-account-api-staging.hoipoi.workers.dev`。
生产基址为：
`https://dbo-account-api.hoipoi.workers.dev`。
不依赖网页 Pages 的相对路径代理。

### 9.3 Cloudflare 存储现状

- 生产 Worker version 14 仅绑定 D1 `DB`（生产 D1：`edb91621-24f3-47af-8798-54d1b3914154`）。
- staging Worker version 10 仅绑定 D1 `DB`（staging D1：`0d555faf-0ae3-486e-bafd-b3100534f7de`）。
- 两个 D1 数据库的 sqlite_master 均未发现云存档元数据表。
- 通过 Cloudflare API 读取 R2 bucket 列表时，账户返回 HTTP 403、错误码 10042：需先在 Cloudflare Dashboard 启用 R2。当前不能假设已有可用 R2 bucket 或 Worker R2 binding。
- 本轮只读检查，没有创建 R2 bucket、D1 表、Worker binding 或修改任何部署。

### 9.4 当前缺口与实施顺序

1. 先补齐本地存档可靠性与完整运行时快照回写：60 秒本地保存、原子写入、schema 版本、dirty/revision 状态。
2. 在 Godot 内接入账号 UI/API：设备标识、注册/登录、session check、logout；无网络时允许离线进入游戏。
3. 在 Cloudflare 启用 R2，并建立 staging R2 bucket 与 staging Worker binding。
4. 在 staging D1 增加云存档元数据表；Worker 增加经过 session 鉴权的上传、下载、元数据/冲突检查接口。
5. Godot 云同步器按 30 分钟上传 dirty revision；特殊动作使用统一 checkpoint 入口。
6. 完成 staging 的注册/登录/离线启动/上传/下载/旧版本冲突/中断恢复验证后，再单独评估生产上线。

当前缺少或需用户操作的材料：
- **需要用户在 Cloudflare Dashboard 启用 R2**；当前 API 明确返回未启用，工具不能替用户完成 Dashboard 激活。
- 尚未取得本地运行时完整状态采集的验证结果；需要逐项确认玩家世界位置、属性、背包/装备、技能、任务等状态由哪些运行时对象持有。
- 特殊动作清单与“上传失败是否阻止该动作”的策略仍未定义；先预留通用 checkpoint 接口，不擅自阻断游戏流程。


## 10. 2026-11-02 用户确认：游客优先与 R2 零超额费用保护

### 10.1 游客/离线优先（用户明确确认，证据 D）

- 未登录玩家可以直接创建角色、正常进入游戏、游玩并保存本地进度。
- 不要求注册、登录或联网作为启动、创建角色、进入世界和保存本地进度的前置条件。
- 产品默认引导应偏向“游客/离线游玩”；云账号与云存档作为可选能力，不用弹窗、功能惩罚或反复提示诱导玩家联网。
- 玩家以后主动注册/登录时，再提供明确的本地存档与云存档关联/迁移流程；两边都有进度时不得静默覆盖，必须保留数据并让玩家选择。
- 本地存档是主存档；云端仅是玩家主动选择的备份/跨设备恢复能力。关闭云功能不得影响单机内容。

### 10.2 R2 当前状态（2026-11-02，Cloudflare API 只读证据 A）

用户报告已在 Dashboard 启用 R2。随后 API 核对：
- R2 bucket 列表请求成功，当前账户 bucket 数量为 0。
- R2 metrics 当前 Standard 与 Infrequent Access 的 uploaded/published objects、payloadSize、metadataSize 均为 0。
- 因此 R2 已启用，但尚未创建 DBOFF staging bucket，也没有 R2 Worker binding；本轮未创建资源、未产生对象存储费用。

### 10.3 免费额度与“绝不产生账单”的设计边界

按 2026-11-02 查阅的 Cloudflare 官方 R2 Pricing：
- Standard 免费额度：10 GB-month 存储、每月 1,000,000 次 Class A、每月 10,000,000 次 Class B；R2 出站流量免费。
- 超出部分按用量计费；Standard 当前公开单价为 $0.015/GB-month、$4.50/百万次 Class A、$0.36/百万次 Class B。
- 免费额度按 Cloudflare 账户及月度周期计量，不是每个 bucket 各自拥有一份额度；Infrequent Access 不享有上述免费额度，并有检索费用和 30 天最低存储期，因此 DBOFF 只使用 Standard。
- Cloudflare R2 API/当前公开计费文档未提供可配置的“达到免费额度自动拒绝请求、保证账单为零”的原生硬封顶开关。仅依赖 Cloudflare 用量指标或账单告警不足以作零费用保证。

### 10.4 DBOFF 必须采用的应用层硬停止策略（待实现）

用户要求：一旦接近免费额度，自动暂停云存档功能，不允许继续产生超额用量。设计约束：
1. 所有 R2 读写只能经过 dbo-account-api Worker；Godot 客户端不得持有 R2/S3 凭据或直接访问 bucket。
2. Worker 在执行 R2 操作前，先检查账户级/月度用量账本和当前存储字节数；检查或账本不可用时 fail-closed（暂停云功能），不能“先操作后补记”。
3. 为其他账户级使用和计量延迟保留安全余量。初始建议将 DBOFF 自身硬阈值设为官方免费额度的 70%：存储最多 7 GB 活跃对象总量、Class A 最多 700,000 次/月、Class B 最多 7,000,000 次/月。该数值是拟定的安全阈值，最终实现前还需按账户其他产品用量核对；不得把 10 GB/1M/10M 当作 DBOFF 可独占额度。
4. 到达任一阈值前，Worker 将 cloud-save 状态切换为 quota_paused，停止上传与下载等会消耗 R2 操作的请求，并向客户端返回明确的“本月云存档额度保护暂停”状态；本地保存、游客游玩和游戏进度不受影响。
5. 存储采用账户级总量上限和明确的快照保留策略，避免每次上传都永久累积快照。新快照写入、元数据指针切换成功后，才清理旧快照；不得为节省费用自动删除唯一可恢复的云存档。
6. 月度操作计数按实际 R2 操作类型分类；重试必须有限次数并计入账本。R2 读操作同样受 Class B 限制，不能只停止上传而继续无限下载。
7. 定期将 Worker 账本与 Cloudflare R2 metrics / Billing usage 对账；metrics 或账单数据有延迟，不能作为唯一的实时拦截机制。
8. 任何绕过 Worker 的 bucket 公开访问、S3 key、临时凭据或其他 Worker binding 都会破坏这层保护，必须禁止。R2 bucket 保持私有。
9. 若 Cloudflare 账户其他产品/项目也使用 R2，必须把它们的消耗计入安全余量；否则不能承诺账户级账单绝对为零。

**重要保证边界：** 应用层硬停止可以阻止 DBOFF 自身继续发起 R2 操作，但 Cloudflare 是按账户计费；在未核对账户全部 R2 用量、账单设置和其他调用方之前，不能承诺整个 Cloudflare 账户绝对不会产生任何账单。用户的零账单要求优先于云存档可用性，遇到额度状态不明时必须暂停云功能，而不是冒险继续。

### 10.5 后续顺序

1. 先保持本地游客/离线存档闭环，不等待 R2。
2. 设计并实现 Worker quota ledger、账户级存储限制、quota_paused 响应和可观测状态。
3. 先建立独立 staging bucket/binding，并且先部署额度保护，再开放任何上传/下载接口。
4. 完成阈值模拟测试（存储、Class A、Class B、账本故障、重复请求、并发上传、月度重置）后，才允许测试云存档。
5. 生产环境默认关闭云存档功能开关；只有 staging 验证完成且用户明确同意后才启用。

本节记录用户产品规则与设计约束；本轮没有创建 bucket、修改 Worker/D1、配置账单或部署代码。
