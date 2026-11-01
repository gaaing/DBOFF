# DBO 247个 RDF 表格全量解析与 Godot JSON 导出完成报告

## 1. 目标清单与完成进度 (100% DONE)

| 序号 | 目标描述 | 状态 | 完成进度 |
| :---: | :--- | :---: | :---: |
| 1 | 扫描并校验 `E:\DBO_Offline\pipeline\raw_source\extracted\tbl\data` 下 247 个 `.rdf` 原始二进制表格文件 | 已完成 | 100% |
| 2 | 对齐 `https://github.com/OpenDBO/OpenDBO-Core` 核心规范（解析 C++ 结构体字节步长、对齐方式与序列化机制） | 已完成 | 100% |
| 3 | 开发自动化高保真转换工具，临时部署于 `E:\DBO_Offline\tools\export_all_rdf_to_godot.py` | 已完成 | 100% |
| 4 | 规避任何文本硬编码，将全局文本库 `table_text_all_data.rdf` 分解归类为 28 个分类标签，方便未来自由调整界面与多语言切换 | 已完成 | 100% |
| 5 | 全量解析 247 个 RDF 表格并完整输出为符合 Godot 引擎标准读取规范的 JSON 文件至 `E:\DBOFF\assets\tbl` | 已完成 | 100% (247/247) |
| 6 | 校验数据完整性（文件数 1:1 无遗漏、字段语义准确、坐标/数值无损映射） | 已完成 | 100% |

---

## 2. 导出成果总览

- **输入原始文件源**：`E:\DBO_Offline\pipeline\raw_source\extracted\tbl\data`（共计 247 个 `.rdf` 文件）
- **输出目标目录**：`E:\DBOFF\assets\tbl`（共计 247 个 `.json` 文件）
- **转换工具位置**：`E:\DBO_Offline\tools\export_all_rdf_to_godot.py`
- **生成总数据量**：约 121.36 MB 结构化 JSON

---

## 3. 表格分类解析架构规范

根据 OpenDBO-Core 官方规范，表格采用以下专用解析模式：

### 3.1 怪物刷新表（66 个）与 NPC 刷新表（53 个）
- **C++ 结构体原型**：`sSPAWN_TBLDAT`
- **记录步长**：84 字节（首字节 `0x01` 为边界标记 Margin Byte）
- **导出字段**：
  - `tblidx`: 刷新项唯一编号
  - `mob_tblidx`: 怪物/NPC 模板编号
  - `spawn_loc`: 三维刷新坐标 `{ x, y, z }`
  - `spawn_dir`: 三维朝向向量 `{ x, y, z }`
  - `spawn_loc_range`: 刷新散布范围
  - `spawn_quantity`: 刷新数量
  - `spawn_cool_time`: 重生/刷新冷却（秒）
  - `spawn_move_type`: 移动巡逻行为类型
  - `wander_range`: 游荡半径
  - `move_range`: 移动上限距离
  - `action_pattern_tblidx`: 行为模式索引
  - `path_table_index`: 巡逻路径表索引
  - `follow_distance`: 跟随间距向量
  - `play_script`, `play_script_scene`: 剧情脚本与场景
  - `ai_script`, `ai_script_scene`: AI 脚本与场景
  - `party_index`, `party_leader`: 怪物队伍编组与队长标志
  - `spawn_group_id`: 刷新编组 ID

### 3.2 场景交互物件/传送门/实体刷新表（49 个）
- **C++ 结构体原型**：`sOBJECT_TBLDAT`
- **记录步长**：868 字节
- **导出字段**：
  - `tblidx`, `name`, `function_flags`
  - `loc`, `dir`, `min`, `max`: 位置坐标、朝向及包围盒（AABB）
  - `model_name`: 碰撞/渲染网格模型名（如 `PORTAL_COLLISION` 等）
  - `click_sounds`: 点击与交互音效列表
  - `radius`, `sequence`, `contents_tblidx`, `object_direction_index`, `boundary_distance`
  - `min_quest_id`, `max_quest_id`, `warfog`, `zone_id`, `world_id`

### 3.3 全局多语言文本库（严格按标签分类，禁止硬编码）
- **核心文件**：`table_text_all_data.json`
- **分类标签（28 类）**：
  1. `ACTION_DATA`: 动作与动作表情文本
  2. `CHAT_COMMMAND_DATA`: 聊天指令与快捷指令
  3. `HTB_SET_DATA`: HTB 连续技名称与描述
  4. `ITEM_DATA`: 全量装备/道具名称
  5. `MERCHANT_DATA`: 商人商店与货柜标题
  6. `MOB_DATA`: 怪物全称
  7. `NPC_DATA`: NPC 名字与身份称号
  8. `SKILL_DATA`: 角色与怪兽技能描述文本
  9. `SYSTEM_EFFECT`: 状态与增益效果说明
  10. `USE_ITEM_DATA`: 消耗品与载具描述
  11. `MAP_NAME`: 场景大地图与区域地名
  12. `OBJECT_DATA`: 交互物件名称
  13. `QUEST_ITEM_DATA`: 任务专属道具说明
  14. `ETC_TEXT`: 其它系统标签与UI文本
  15. `HELP_DATA`: 游戏帮助系统与玩法说明
  16. `HELP_POPOHINT_DATA`: 波波提示教学指引
  17. `DRAGON_BALL`: 七龙珠神龙许愿台词
  18. `DB_REWARD`: 龙珠许愿奖励选项
  19. `TMQ_DATA`: 时空裂缝（TMQ）任务名与引导
  20. `CS_TEXT`: 剧情过场台词
  21. `MILEPOST`: 路标与传送石碑文本
  22. `FILTERING`: 聊天与字符过滤词库
  23. `NPC_DIALOG`: NPC 气泡对话与剧情闲聊台词
  24. `GM_TOOL`: 管理工具与系统提示文本
  25. `DBO_TIP`: 加载页游戏小贴士
  26. `DWC_DATA`: 武道会专属文本
  27. `CHAR_TITLE_DATA`: 称号与头衔文本
  28. `PARTY_DUNGEON_DATA`: 副本匹配队伍文本
- **格式**：每个标签下为 `{ "编号": "本地化文本内容" }` 映射，搭载到 Godot 中由本地化管理器统一读取。

### 3.4 动态脚本与剧情配置表
- `table_quest_text_data.json`: 任务日志、NPC 接交任务对话长文本（字典索引映射）
- `table_common_config_data.json`: 核心公共参数配置表（动态参数组与配置键值对）
- `table_tenkaichibudokai_data.json`: 天下第一武道会规则、赛季周期与奖励参数

### 3.5 核心数值与玩法表格（72 个定长表）
- 包含 `table_exp_data`（经验升级曲线）、`table_item_data`（全量道具定义表）、`table_mob_data`（怪物属性数值与模型表）、`table_npc_data`（NPC 功能与模型表）、`table_skill_data`（技能全量表）、`td_formula`（系统计算公式表）、`table_merchant_data`（商人出售配置表）、`table_world_data` / `table_world_zone_data` / `table_worldmap_data`（世界地块与地图表）等，均完成 100% 格式对齐与导出。

---

## 4. Godot 引擎读取示例 (GDScript)

在 Godot 4.x 中通过 `FileAccess` 或 `ResourceLoader` 即可直接载入：

```gdscript
# 加载技能数据表
func load_skill_table() -> Dictionary:
    var file = FileAccess.open("res://assets/tbl/table_skill_data.json", FileAccess.READ)
    if file:
        var json_str = file.get_as_text()
        return JSON.parse_string(json_str)
    return {}

# 依据标签读取本地化文本，完全杜绝硬编码
func get_localized_text(category: String, text_id: int) -> String:
    var text_db = load_json("res://assets/tbl/table_text_all_data.json")
    if text_db.has(category) and text_db[category].has(str(text_id)):
        return text_db[category][str(text_id)]
    return ""
```

---
*报告生成路径：`E:\DBOFF\docs\rdf_export_report.md`*
