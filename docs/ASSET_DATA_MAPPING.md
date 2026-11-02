# DBOFF 全项目资产与数据总索引映射工程 (Master Asset & Data Mapping Registry)

> 本文档是 DBOFF 项目的长期有效、可查询、字节级证据支撑的资产与数据总导航基线。
> 构建日期：2026-11-02 | 依据标准：`docs/AI_DEVELOPMENT_RULES.md` 与 OpenDBO-Core 官方规范。

## 一、 映射工程规模与宏观统计 (Macro Statistics)

- 📁 **已扫描核心资源目录**: `assets/` (12 个子系统目录) + `data/` (5 个核心数据目录) + `src/` (82 个 GDScript 脚本)
- 📦 **全项目实际文件总数**: **114,941** 个资产文件
  - 3D 模型与动画 (`.glb`): **30,894** 个
  - 纹理贴图与 UI 图集 (`.png`): **28,577** 张
  - 音频音效与配乐 (`.wav`, `.ogg`): **3,475** 个
- 📊 **数据表覆盖总量**: **280** 个表格（`assets/tbl/` 275 张 + `data/` 5 张）
- ⚔️ **装备与物品条目**: **14,273** 条物品数据；已深度核验全部 **25** 条初始新手装备链路
- 🏃 **骨骼动画库总量**: **5,302** 个独立动作 GLB
- 🗺️ **大世界切片与地形**: **106** 个世界切片定义，**50** 个区域共 **15,453** 个高程切块
- 👾 **生物与技能实体**: **3,169** 个 NPC，**7,125** 只怪物，**2,663** 个技能

## 二、 证据等级与状态标记规范 (Evidence Standards)

| 状态标记 | 含义与判定准则 |
|---|---|
| `VERIFIED` | **完全核实**：数据表条目存在、目标资源文件真实落盘、且代码加载链路已对齐验证。 |
| `PARTIAL` | **部分核实**：数据表或模型文件已确认存在，但贴图路径、骨骼绑定或代码调用仍有待补充。 |
| `INFERRED` | **推断推导**：基于官方表命名规则（如加 `_H_M` 尾缀）计算出的理论路径，尚未逐字节核实。 |
| `MISSING` | **明确缺失**：数据表有定义，但在当前工程资产目录中明确不存在对应文件。 |
| `UNKNOWN` | **待调查**：尚未进行反序列化或二进制抽样验证。 |

## 三、 系统子映射导航表 (Sub-Registry Index)

| 序号 | 业务领域 | 核心覆盖范围 | 详细文档路径 | 机器可读数据文件 |
|---|---|---|---|---|
| **01** | **数据表映射** | 全量 280 张表结构、主键、字段、OpenDBO 头文件对应 | [`01_DATA_TABLE_MAPPING.md`](ASSET_MAPPING_DETAILS/01_DATA_TABLE_MAPPING.md) | [`table_registry.json`](ASSET_MAPPING_DETAILS/table_registry.json) |
| **02** | **角色与职业** | 3 种族、6 基础职业、12 大师职业、成幼素体骨骼 | [`02_CHARACTER_AND_CLASS_MAPPING.md`](ASSET_MAPPING_DETAILS/02_CHARACTER_AND_CLASS_MAPPING.md) | [`character_class_mapping.json`](ASSET_MAPPING_DETAILS/character_class_mapping.json) |
| **03** | **装备与物品 (P0)** | 25 件新手装全链路核验、防具槽位、模型贴图、骨骼蒙皮 | [`03_EQUIPMENT_AND_ITEM_MAPPING.md`](ASSET_MAPPING_DETAILS/03_EQUIPMENT_AND_ITEM_MAPPING.md) | [`equipment_item_mapping.csv`](ASSET_MAPPING_DETAILS/equipment_item_mapping.csv)<br/>[`equipment_item_mapping.json`](ASSET_MAPPING_DETAILS/equipment_item_mapping.json) |
| **04** | **动作与动画** | 5,300+ 独立 GLB 动作切片、状态机绑定、防拉伸重定向 | [`04_ANIMATION_MAPPING.md`](ASSET_MAPPING_DETAILS/04_ANIMATION_MAPPING.md) | [`animation_mapping.json`](ASSET_MAPPING_DETAILS/animation_mapping.json) |
| **05** | **模型与贴图** | 30,894 GLB 与 28,577 PNG 贴图分布、材质与 Shader | [`05_MODEL_MATERIAL_TEXTURE_MAPPING.md`](ASSET_MAPPING_DETAILS/05_MODEL_MATERIAL_TEXTURE_MAPPING.md) | [`model_texture_mapping.json`](ASSET_MAPPING_DETAILS/model_texture_mapping.json) |
| **06** | **大世界与地图** | 106 个世界定义、50 个地形区域、4 大选角官方机位舞台 | [`06_WORLD_AND_MAP_MAPPING.md`](ASSET_MAPPING_DETAILS/06_WORLD_AND_MAP_MAPPING.md) | [`world_map_mapping.json`](ASSET_MAPPING_DETAILS/world_map_mapping.json) |
| **07** | **NPC、怪物与技能** | 3,169 NPC，7,125 怪物，2,663 技能模型与数据调用入口 | [`07_NPC_MOB_SKILL_EFFECT_MAPPING.md`](ASSET_MAPPING_DETAILS/07_NPC_MOB_SKILL_EFFECT_MAPPING.md) | [`npc_mob_skill_mapping.json`](ASSET_MAPPING_DETAILS/npc_mob_skill_mapping.json) |

## 四、 快速检索指南 (How to Query by ID)

### 1. 查询任意装备 ID 对应的 3D 资源
1. 打开 [`equipment_item_mapping.json`](ASSET_MAPPING_DETAILS/equipment_item_mapping.json) 或搜索 [`equipment_item_mapping.csv`](ASSET_MAPPING_DETAILS/equipment_item_mapping.csv) 的 `item_id` 列；
2. 获取对应 `model_raw` 字段（例如 `A_HFI_04_01_J`）；
3. 根据种族与性别拼接后缀（人男 `_H_M`、人女 `_H_F`、那美克 `_N_O_S1`、魔男 `_M_M`、魔女 `_M_F`）；
4. 在 `assets/obj/item/` 下匹配对应子目录（如 `mesh_armor_humanmale/a_hfi_04_01_j_h_m.glb`）；
5. 判断角色状态：若为幼童（`is_adult=false`），**禁止外挂独立防具网格**，由素体自带网格渲染。

### 2. 查询怪物与 NPC 实体模型
1. 在 [`table_mob_data.json`](../assets/tbl/table_mob_data.json) 中按 `mob_id` 获取 `model` 字段（如 `m_akm_a1`）；
2. 模型物理文件统一存储于 `assets/obj/character/mesh_mob/{model}.glb`；
3. 对应动画池位于 `assets/obj/character/animation_npc/`（NPC 与 Mob 共享核心骨骼采样库）。

## 五、 明确已确认与未完全确认领域 (Current Gaps & Status)

1. **已完全确认并建立基线的领域**：
   - 全部 280 张表格的字段与记录数结构；
   - 选角/创角全族群男女童年与成年素体模型及材质 Shader 链路；
   - 全部 25 件初始装备的槽位映射与挂载规则；
   - 4 大官方选角大厅场景（Field 18, 42, 45, 21）的坐标、环境光、天空盒参数；
   - 全局 5,300+ 骨骼动画库的加载与重定向逻辑。
2. **尚待逐条抽样与运行时确认的领域**：
   - 14,000+ 进阶装备中非新手装备的模型存在率（当前仅抽样验证了前沿热门套装）；
   - 7,125 怪物中部分特殊 Boss 的专属特效粒子（`.tscn` 特效驱动）；
   - 50 个野外地图的动态物件（Dynamic Object）在大世界流式加载中的精确摆放坐标。
