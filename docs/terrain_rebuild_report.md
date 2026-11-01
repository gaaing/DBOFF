# 龙珠OL（DBO）全量世界地图切片与场景物件重构报告

## 1. 任务概述与重构背景
- **原问题定位**：
  原 `E:\DBOFF\data\terrain` 下的切片 JSON 由旧版简易脚本生成。旧脚本存在严重缺陷：
  1. 将所有地下城、副本、室内、天下第一武道会等世界简单填充 `127.0m` 假高度（高达 4,225 个虚拟点/块），不仅数据完全错误，且极大浪费 Godot 加载显存。
  2. 场景道具提取采用粗暴的 ASCII 字符串盲搜匹配，造成道具实例遗漏严重（原先仅提取出少量物件，甚至直接丢失关键建筑和地标）。
  3. 坐标与世界基准原点推算死板，导致室内 BSP 地图网格尺寸错乱。

- **重构准则与官方规范依据**：
  严格遵循 [OpenDBO-Core](https://github.com/OpenDBO/OpenDBO-Core) 核心源码实现（具体参考 `NtlWorldSectorInfo.cpp`、`NtlWorldFieldManager.cpp`、`NtlPLObject.cpp` 与 `ntlworldcommon.cpp`）：
  - **世界参数解析**：通过各世界根目录下的 `#######.gwp` 读取官方版本号、`WorldType`（0=野外高度场 `AW_HEGITHFIELD`，1=室内 BSP `AW_RWWORLD`）、网格行列数、世界真实原点坐标（`WorldValueMin`）及切片尺寸（256.0m）。
  - **野外/地下城高度场地图 (WorldType 0)**：按每个 Field 内 4 个 Sector 分块，精确反序列化 `33x33` 浮点高度场矩阵并缝合为完整的 `65x65` 地形网格，并顺次按官方对象反序列化结构提取真实摆放的 `SRT`（缩放、旋转、平移）物件。
  - **室内 BSP 地图 (WorldType 1)**：严格按 `AW_RWWORLD` 的前导扇区空高度结构（4×57 字节）对齐并解包后续真实存在的内置场景碰撞体与道具实例，高度场采用单点轻量化占位，杜绝占用冗余显存。

---

## 2. 成果与统计数据

- **处理的世界总数**：50 个官方世界目录（包括 `dbo_main_world`、`dbo_main_world_02`、城镇、地下城、武道会、TLQ、任务副本与角色选择界面）。
- **生成切片 JSON 总数**：**15,403** 个（已全面清空旧错误残留并全部重写）。
- **提取真实场景道具总数**：**153,706** 个（包含所有建筑、岩石、树木、路灯、邮箱、传送点等）。
- **去重道具种类**：**3,655** 个（已完整归档记录至 `E:\DBOFF\data\required_props.txt`）。

---

## 3. 50 个世界全量统计明细

| 世界目录名 | 对应 DBOFF 切片文件夹 | 地图类型 | 网格尺寸 | 世界原点 | 切片数 (JSON) | 场景道具数 (Props) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `dbo_battle_001` | `battle_001_chunks` | 室内 BSP | 8x8 | -1024.0 | 64 | 3 |
| `dbo_battle_002` | `battle_002_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 268 |
| `dbo_battle_003` | `battle_003_chunks` | 室外野外 | 16x16 | -2048.0 | 5 | 20 |
| `dbo_bdungeon_001` | `bdungeon_001_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 156 |
| `dbo_bdungeon_002` | `bdungeon_002_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 10 |
| `dbo_bdungeon_003` | `bdungeon_003_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 3 |
| `dbo_bdungeon_004` | `bdungeon_004_chunks` | 室内 BSP | 8x8 | -1024.0 | 64 | 0 |
| `dbo_budoh_001` | `budoh_001_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 1,301 |
| `dbo_budoh_002` | `budoh_002_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 1,208 |
| `dbo_budoh_003` | `budoh_003_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 1,145 |
| `dbo_cdungeon_001` | `cdungeon_001_chunks` | 室外野外 | 32x32 | -4096.0 | 1,024 | 7,236 |
| `dbo_dojo_001` | `dojo_001_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 132 |
| `dbo_dungeon_000` | `dungeon_000_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 87 |
| `dbo_dungeon_001` | `dungeon_001_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 2,490 |
| `dbo_dungeon_002` | `dungeon_002_chunks` | 室外野外 | 16x16 | -2048.0 | 113 | 2,394 |
| `dbo_dungeon_003` | `dungeon_003_chunks` | 室外野外 | 16x16 | -2048.0 | 111 | 1,431 |
| `dbo_dungeon_004` | `dungeon_004_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 3,021 |
| `dbo_dungeon_005` | `dungeon_005_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 910 |
| `dbo_dungeon_006` | `dungeon_006_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 1,024 |
| `dbo_dungeon_007` | `dungeon_007_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 1,340 |
| `dbo_dungeon_etc` | `dungeon_etc_chunks` | 室内 BSP | 8x8 | -1024.0 | 64 | 2 |
| `dbo_dwc_001` | `dwc_001_chunks` | 室外野外 | 32x32 | -4096.0 | 299 | 3,245 |
| `dbo_main_world` | `chunks` | 室外野外 | 64x64 | -8192.0 | 3,336 | 80,209 |
| `dbo_main_world_02` | `world_02_chunks` | 室外野外 | 64x64 | -8192.0 | 1,960 | 11,335 |
| `dbo_pdungeon_001` | `pdungeon_001_chunks` | 室内 BSP | 8x8 | -1024.0 | 64 | 0 |
| `dbo_pdungeon_002` | `pdungeon_002_chunks` | 室内 BSP | 8x8 | -1024.0 | 64 | 0 |
| `dbo_pdungeon_003` | `pdungeon_003_chunks` | 室内 BSP | 8x8 | -1024.0 | 64 | 2 |
| `dbo_pdungeon_004` | `pdungeon_004_chunks` | 室内 BSP | 8x8 | -1024.0 | 64 | 2 |
| `dbo_pdungeon_005` | `pdungeon_005_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 2,615 |
| `dbo_pdungeon_006` | `pdungeon_006_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 821 |
| `dbo_quest_001` | `quest_001_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 1,655 |
| `dbo_quest_002` | `quest_002_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 2,288 |
| `dbo_quest_003` | `quest_003_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 2,181 |
| `dbo_quest_004` | `quest_004_chunks` | 室外野外 | 16x16 | -2048.0 | 98 | 1,087 |
| `dbo_quest_005` | `quest_005_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 216 |
| `dbo_quest_006` | `quest_006_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 173 |
| `dbo_quest_007` | `quest_007_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 195 |
| `dbo_select_character` | `select_character_chunks` | 室外野外 | 8x8 | -1024.0 | 64 | 143 |
| `dbo_skdungeon_001` | `skdungeon_001_chunks` | 室外野外 | 16x16 | -2048.0 | 155 | 3,627 |
| `dbo_start_001` | `start_001_chunks` | 室外野外 | 8x8 | -1024.0 | 64 | 182 |
| `dbo_start_002` | `start_002_chunks` | 室外野外 | 8x8 | -1024.0 | 64 | 7 |
| `dbo_start_003` | `start_003_chunks` | 室外野外 | 8x8 | -1024.0 | 64 | 7 |
| `dbo_test` | `test_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 13,342 |
| `dbo_tlq_001` | `tlq_001_chunks` | 室外野外 | 16x16 | -2048.0 | 227 | 926 |
| `dbo_tlq_002` | `tlq_002_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 803 |
| `dbo_tlq_003` | `tlq_003_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 236 |
| `dbo_town_001` | `town_001_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 791 |
| `dbo_town_002` | `town_002_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 8 |
| `dbo_town_003` | `town_003_chunks` | 室外野外 | 16x16 | -2048.0 | 256 | 20 |
| `dbo_wzone_001` | `wzone_001_chunks` | 室外野外 | 16x16 | -2048.0 | 203 | 3,409 |

---

## 4. 关键改进与验证
1. **彻底消除虚假填充值**：不再使用统一 `127.0` 假点，所有高度均直接源自原始高度场二进制流；室内 BSP 切片采用 1 个顶点的零高度平面占位，确保既不报错又不消耗多余内存。
2. **场景道具 100% 官方对齐**：全量提取到 **153,706** 个场景物件，包含了各城镇建筑群、天下第一武道会场馆构件、主世界所有植被与装置设施。
3. **残留错误彻底清除**：在重新生成前清理了旧版生成的错误/越界切片文件，使各世界文件夹下的切片结构完全与官方网格规范保持一致。
