# DBO 官方繁中本地化 (zh_TW) 与 table_text_all_data 对比及私服魔改分析报告

## 1. 目标清单与完成进度 (100% DONE)

| 序号 | 目标描述 | 状态 | 完成进度 |
| :---: | :--- | :---: | :---: |
| 1 | 遍历 `E:\DBO_Offline\data\localization\zh_TW` 全量本地化 JSON 文件与结构体分类分析 | 已完成 | 100% |
| 2 | 对齐 `table_text_all_data.json` 与 `zh_TW` 各数据分类的 ID 映射与包含关系 | 已完成 | 100% |
| 3 | 全量排查官方内容覆盖度，确认是否有官方正版条目遗漏 | 已完成 | 100% |
| 4 | 深度剖析 `table_text_all_data.json` 中属于私服（DBOG）独有的魔改新增与修改内容 | 已完成 | 100% |
| 5 | 输出结构化多维度对比与分类统计报告至 `E:\DBOFF\docs` | 已完成 | 100% |

---

## 2. 覆盖度比对核心结论

经过全面比对，核心结论如下：

1. **官方文本 ID 覆盖率：100%**
   - 官方台服 1.57.51 正版数据表中的所有条目（包含 45,801 个道具、7,290 个怪物、6,889 个 NPC、6,245 个技能、3,109 个对话等），在 `table_text_all_data.json` 中 **全部包含，官方正版条目缺失数为 0**。
2. **两者的文件作用域差异**：
   - `zh_TW\gui.json`（3,806 条）：属于客户端界面 UI 文本，源自官方客户端的 `lang0.pak`（非 RDF 数据表），因此天然不包含在 `table_text_all_data.json` 中。
   - `zh_TW\quests.json`（151,218 条）：在 DBO 规范中属于任务剧情专用表 `table_quest_text_data.rdf`（即 `table_quest_text_data.json`），独立于 `table_text_all_data`。
3. **文本语言差异**：
   - `zh_TW` 下为纯正**官方台湾繁体中文**。
   - `table_text_all_data.json` 源自 DBOG（欧美私服客户端），其所有官方条目文本均被替换为**英文/英文机翻**。
4. **私服大量新增魔改内容**：
   - DBOG 在原有官方基础之上，追加了 **7,856 个魔改道具、257 个技能描述、92 个私服 NPC、61 个私服怪物、16 个赞助/奠基人称号**。

---

## 3. 各大类别数据比对统计表

| 分类名称 | 对应 RDF 标签 | 官方正版 zh_TW 条目数 | DBOG 表条目数 | 官方缺失数 | 私服新增魔改数 |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **道具全量** | `ITEM_DATA` | 45,801 | 53,657 | **0** | **+7,856** |
| **任务道具** | `QUEST_ITEM_DATA` | 3,327 | 3,328 | **0** | **+1** |
| **消耗品/载具** | `USE_ITEM_DATA` | 913 | 924 | **0** | **+11** |
| **怪物名称** | `MOB_DATA` | 7,290 | 7,351 | **0** | **+61** |
| **NPC 名称** | `NPC_DATA` | 6,889 | 6,981 | **0** | **+92** |
| **商店名称** | `MERCHANT_DATA` | 1,066 | 1,073 | **0** | **+7** |
| **角色称号** | `CHAR_TITLE_DATA` | 57 | 73 | **0** | **+16** |
| **技能描述** | `SKILL_DATA` | 6,245 | 6,502 | **0** | **+257** |
| **HTB 绝技** | `HTB_SET_DATA` | 48 | 48 | **0** | **0** |
| **地图名称** | `MAP_NAME` | 1,283 | 1,285 | **0** | **+2** |
| **路标石碑** | `MILEPOST` | 346 | 346 | **0** | **0** |
| **NPC气泡台词** | `NPC_DIALOG` | 3,109 | 3,109 | **0** | **0** |
| **系统UI界面** | *(lang0.pak GUI)* | 3,806 | N/A (UI专属) | 0 | 独立维护 |
| **任务剧情长文本** | *(Quest Text 表)* | 151,218 | 154,366 | 3 | **+3,151** |

---

## 4. `table_text_all_data.json` 私服魔改详细清单

DBOG 私服在保留官方数据的基础上，魔改并注入了大量自定义业务逻辑与商业化系统：

### 4.1 私服商城与代币体系 (Cash Shop & Token)
- **私服代币卷**：
  - `Cash shop token C-1` (ID: 199200)
  - `Cash shop token C-5` (ID: 199210)
  - `Cash shop token C-25` (ID: 199220)
  - `Cash shop token C-100` (ID: 199230)
  - `Cash shop token C-500` (ID: 199240)
  - 说明：用于在私服网页端与游戏内兑换商场点数的虚拟凭据。
- **VIP 赞助礼包**：
  - `Pet Potion VIP Package` (ID: 101401880)
  - `Pet Feature VIP Package` (ID: 101401890)

### 4.2 赞助者、奠基人与 GM 特权专属 (Founders & Donators)
- **私服专属称号 (CHAR_TITLE_DATA)**：
  - `[ID 300] Founder`（奠基人）
  - `[ID 301] Donator`（赞助者）
  - `[ID 302] Super Donator`（超级赞助者）
  - `[ID 303] Game Master`（私服 GM）
  - `[ID 100] Freedom Fighter`, `[ID 101] Eternal Flame`, `[ID 102] Eternal Dragon`
- **赞助人道具**：
  - `Krillin Founder Title` (ID: 3000), `Goku Founder Title` (ID: 3010), `Super Saiyan Founder Title` (ID: 3020)
- **GM 管理员道具**：
  - `[GM] CC Life Agent X` (ID: 181860)
  - `[GM] CC Magic Agent X` (ID: 181870)

### 4.3 幻化融合盒与自定义时装 (Cosmetic Fusion & Custom Dogi)
- **幻化系统**：
  - `Magic Weapon Fusion Box` (ID: 201000): 将武器外观幻化为饰品的魔改胶囊公司融合盒。
  - `Magic Sub-Weapon Fusion Box` (ID: 201010)
  - `Magic Armor Fusion Box` (ID: 201020)
- **私服原创道服/时装 (Dogi)**：
  - `Bardock Dogi Type A / B` (ID: 901430, 901440) - 巴达克道服
  - `Vegeta Dogi Type A / B` (ID: 901450, 901460) - 贝吉塔道服
  - `Limited Edition Dogi Ball` (ID: 4131450)

### 4.4 扩展飞行技能系统 (Extended Flight Passives)
官方原版飞行技能仅有基础逻辑，DBOG 扩展了独立的飞行控制参数与被动：
- `[ID 42] You can use the fly skill.`
- `[ID 541] Can use fly move.`（飞行移动）
- `[ID 542] Can use fly sprint.`（飞行冲刺）
- `[ID 543] Can use fly acceleration.`（飞行加速）
- `[ID 544] Can use fly move, fly sprint and acceleration.`
- `[ID 545] Increases Max AP.`, `[ID 546] Increase AP regeneration.`（飞行体力消耗与恢复被动）

### 4.5 私服新增怪物与掉落宝箱怪 (Custom Mobs & Chests)
- **宝箱怪（掉落机制魔改）**：
  - `Frieza's Army Low Priority Chest` (ID: 1753321 ~ 1753323)
  - `Frieza's Army Medium Priority Chest` (ID: 1753324 ~ 1753326)
  - `Frieza's Army High Priority Chest` (ID: 1753327 ~ 1753329)
- **活动与测试怪物**：
  - `Suspicious Planter` (ID: 1817132), `Suspicious Grower` (ID: 1817133)
  - `Suspicious Cuckoo` (ID: 3615111), `Super Suspicious Cuckoo` (ID: 3615112)

### 4.6 私服新增 NPC (Custom NPCs)
- **便利性商人与机器**：
  - `Pet Merchant` (ID: 55), `Pet Capsule Machine` (ID: 56) - 宠物商店与抽奖机
  - `Crafting Master` (ID: 57) - 打造大师
  - `Scouter Merchant` (ID: 58), `Advanced Scouter Merchant` (ID: 59) - 战斗力探测器商人
  - `CC Capsule Machine` (ID: 62) - 胶囊机
- **调试与传送桩**：
  - `Lv30.1-1`, `Lv30.1-2`, `Lv30.3`, `Lv55.1-1`（等级调试传送桩）

### 4.7 私服新增地图 (MAP_NAME)
- `[ID 100170000] Kame House`（龟仙人屋独立副本场景）
- `[ID 200270000] Kame House;`

---

## 5. 对比总结与后续建议

1. **完整性确认**：
   `table_text_all_data.json` 包含了官方繁中库（`zh_TW`）的所有业务数据表条目（包含度 100%）。若需要还原官方纯正中文体验，可直接用 `zh_TW` 中的对应字段覆盖对应的英文内容。
2. **纯净版 vs 私服版策略**：
   - 若要做**官方原汁原味单机版**：建议剔除上述 7,856 个私服新增物品及特权称号，恢复官方正版数值与繁中。
   - 若要**保留私服新增玩法**：可保留私服的扩展时装、飞行被动与宝箱怪，但需要对这些私服特有的英文文本补充中文汉化翻译。

---
*报告生成路径：`E:\DBOFF\docs\localization_vs_table_text_diff.md`*
