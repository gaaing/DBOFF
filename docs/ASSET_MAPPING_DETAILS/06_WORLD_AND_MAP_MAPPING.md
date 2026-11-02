# DBOFF 大世界与地图地形资产全量映射表 (World & Terrain Registry)

> 统计基准：`WorldTable` 共 **106** 个大世界切片定义；`data/terrain/` 下包含 **50** 个区域与 **15,453** 个地表高度切块。

## 1. 创角与选角舞台官方场景对标 (Canon Lobby Stages)

| 舞台 ID | 舞台名称 | 官方 Field ID | 角色生成世界坐标 | 镜头聚焦目标 | 对应世界区域 | 证据状态 |
|---|---|---|---|---|---|---|
| `-1` | **Stage_Cell_Ring** | `18` | `[-296.22, 52.577, -281.39]` | `Stage_Cell_Ring` 擂台中心 | 沙鲁度假村/各族新手村 | `VERIFIED` |
| `0` | **Stage_Human** | `42` | `[-350.37, 52.0, 328.73]` | `Stage_Human` 擂台中心 | 沙鲁度假村/各族新手村 | `VERIFIED` |
| `1` | **Stage_Namek** | `45` | `[471.69, 52.0, 300.63]` | `Stage_Namek` 擂台中心 | 沙鲁度假村/各族新手村 | `VERIFIED` |
| `2` | **Stage_Majin** | `21` | `[365.617, 52.0, -365.843]` | `Stage_Majin` 擂台中心 | 沙鲁度假村/各族新手村 | `VERIFIED` |

## 2. 大世界地形切块分布表 (Top Terrain Zones)

| 区域名称 (Zone Name) | 切块数量 (Chunks) | 相对路径 | 地表高度网格结构 | 状态 |
|---|---|---|---|---|
| `battle_001_chunks` | **65** | `data/terrain/battle_001_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `battle_002_chunks` | **257** | `data/terrain/battle_002_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `battle_003_chunks` | **6** | `data/terrain/battle_003_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `bdungeon_001_chunks` | **257** | `data/terrain/bdungeon_001_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `bdungeon_002_chunks` | **257** | `data/terrain/bdungeon_002_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `bdungeon_003_chunks` | **257** | `data/terrain/bdungeon_003_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `bdungeon_004_chunks` | **65** | `data/terrain/bdungeon_004_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `budoh_001_chunks` | **257** | `data/terrain/budoh_001_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `budoh_002_chunks` | **257** | `data/terrain/budoh_002_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `budoh_003_chunks` | **257** | `data/terrain/budoh_003_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `cdungeon_001_chunks` | **1025** | `data/terrain/cdungeon_001_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `chunks` | **3337** | `data/terrain/chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `dojo_001_chunks` | **257** | `data/terrain/dojo_001_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `dungeon_000_chunks` | **257** | `data/terrain/dungeon_000_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `dungeon_001_chunks` | **257** | `data/terrain/dungeon_001_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `dungeon_002_chunks` | **114** | `data/terrain/dungeon_002_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `dungeon_003_chunks` | **112** | `data/terrain/dungeon_003_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `dungeon_004_chunks` | **257** | `data/terrain/dungeon_004_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `dungeon_005_chunks` | **257** | `data/terrain/dungeon_005_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `dungeon_006_chunks` | **257** | `data/terrain/dungeon_006_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `dungeon_007_chunks` | **257** | `data/terrain/dungeon_007_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `dungeon_etc_chunks` | **65** | `data/terrain/dungeon_etc_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `dwc_001_chunks` | **300** | `data/terrain/dwc_001_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `pdungeon_001_chunks` | **65** | `data/terrain/pdungeon_001_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `pdungeon_002_chunks` | **65** | `data/terrain/pdungeon_002_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `pdungeon_003_chunks` | **65** | `data/terrain/pdungeon_003_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `pdungeon_004_chunks` | **65** | `data/terrain/pdungeon_004_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `pdungeon_005_chunks` | **257** | `data/terrain/pdungeon_005_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `pdungeon_006_chunks` | **257** | `data/terrain/pdungeon_006_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `quest_001_chunks` | **257** | `data/terrain/quest_001_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `quest_002_chunks` | **257** | `data/terrain/quest_002_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `quest_003_chunks` | **257** | `data/terrain/quest_003_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `quest_004_chunks` | **99** | `data/terrain/quest_004_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `quest_005_chunks` | **257** | `data/terrain/quest_005_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `quest_006_chunks` | **257** | `data/terrain/quest_006_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `quest_007_chunks` | **257** | `data/terrain/quest_007_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `select_character_chunks` | **65** | `data/terrain/select_character_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `skdungeon_001_chunks` | **156** | `data/terrain/skdungeon_001_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `start_001_chunks` | **65** | `data/terrain/start_001_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `start_002_chunks` | **65** | `data/terrain/start_002_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `start_003_chunks` | **65** | `data/terrain/start_003_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `test_chunks` | **257** | `data/terrain/test_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `tlq_001_chunks` | **228** | `data/terrain/tlq_001_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `tlq_002_chunks` | **257** | `data/terrain/tlq_002_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `tlq_003_chunks` | **257** | `data/terrain/tlq_003_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `town_001_chunks` | **257** | `data/terrain/town_001_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `town_002_chunks` | **257** | `data/terrain/town_002_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `town_003_chunks` | **257** | `data/terrain/town_003_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `world_02_chunks` | **1961** | `data/terrain/world_02_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
| `wzone_001_chunks` | **204** | `data/terrain/wzone_001_chunks/` | 17×17 浮点高程网格 + 纹理层映射 | `VERIFIED` |
