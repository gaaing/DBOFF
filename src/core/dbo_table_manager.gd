extends Node

## DBO Table Manager (Dragon Ball Online Core Data Services)
## 参考 OpenDBO-Core 数据容器 (CNtlTableContainer & CNtlPLPropertyContainer)
## 提供全套数值表格与属性配置的高性能惰性按需加载与索引服务，
## 避免在游戏启动时一次性加载几百兆数据造成内存膨胀与主线程卡死。

signal table_loaded(table_name: String)

const TABLE_DIR := "res://assets/tbl/"
const PROPERTY_DIR := "res://assets/prop/property/"

# 内存缓存字典: table_name -> Dictionary
var _table_cache: Dictionary = {}

# 属性缓存字典: property_name -> Dictionary
var _property_cache: Dictionary = {}


## 获取通用表格全量数据（惰性加载）
func get_table(table_name: String) -> Dictionary:
	var clean_name := table_name.strip_edges()
	if not clean_name.ends_with(".json"):
		clean_name += ".json"

	if _table_cache.has(clean_name):
		return _table_cache[clean_name]

	var file_path := TABLE_DIR + clean_name
	var data := _load_json_file(file_path)
	if data.is_empty():
		push_warning("[DBOTableManager] 未能读取表格或内容为空: " + file_path)
		return {}

	_table_cache[clean_name] = data
	table_loaded.emit(clean_name)
	return data


## 获取通用单条记录（根据 tblidx）
func get_table_record(table_name: String, tblidx: Variant) -> Dictionary:
	var tbl := get_table(table_name)
	var key := str(tblidx)
	if tbl.has(key):
		return tbl[key]
	return {}


# ==============================================================================
# 核心业务表格专用查询接口 (完全对应 OpenDBO-Core 核心表)
# ==============================================================================

## 获取道具基础数据 (CItemTable)
func get_item_data(tblidx: int) -> Dictionary:
	return get_table_record("table_item_data.json", tblidx)


## 获取技能数据 (CSkillTable)
func get_skill_data(tblidx: int) -> Dictionary:
	return get_table_record("table_skill_data.json", tblidx)


## 获取怪物数值与规则数据 (CMobTable)
func get_mob_data(tblidx: int) -> Dictionary:
	return get_table_record("table_mob_data.json", tblidx)


## 获取 NPC 基础数据 (CNpcTable)
func get_npc_data(tblidx: int) -> Dictionary:
	return get_table_record("table_npc_data.json", tblidx)


## 获取玩家角色等级经验与成长数据 (CExpTable)
func get_exp_data(level: int) -> Dictionary:
	return get_table_record("table_exp_data.json", level)


## 获取大世界场景数据 (CWorldTable)
func get_world_data(tblidx: int) -> Dictionary:
	return get_table_record("table_world_data.json", tblidx)


## 获取世界地图索引数据 (CWorldMapTable)
func get_worldmap_data(tblidx: int) -> Dictionary:
	return get_table_record("table_worldmap_data.json", tblidx)


## 获取 HTB 合体必杀技设定数据 (CHTBSetTable)
func get_htb_set_data(tblidx: int) -> Dictionary:
	return get_table_record("table_htb_set_data.json", tblidx)


## 获取任务道具数据 (CQuestItemTable)
func get_quest_item_data(tblidx: int) -> Dictionary:
	return get_table_record("table_quest_item_data.json", tblidx)


## 获取公式规则参数数据
func get_formula_data() -> Dictionary:
	return get_table("td_formula.json")


## 从 td_formula.json 检索指定索引与栏位的公式比率 (1-based 或 0-based 兼容索引)
func get_formula_rate(formula_index: int, rate_idx: int = 1, default_fallback: float = 0.0) -> float:
	var tbl := get_formula_data()
	var key := str(formula_index)
	if tbl.has(key):
		var rates: Array = tbl[key].get("rates", [])
		var zero_idx := rate_idx - 1 if rate_idx >= 1 else 0
		if zero_idx >= 0 and zero_idx < rates.size():
			return float(rates[zero_idx])
	return default_fallback


## 获取官方全种族/全性别捏脸定制数据表 (default_item_list.json, 严格对标 DefaultItemList.xml)
func get_default_item_list() -> Dictionary:
	return _get_property_file("default_item_list.json")


## 获取全局游戏机制常数表 (game_constants.json)
func get_game_constants() -> Dictionary:
	return _load_json_file("res://data/game_constants.json")


# ==============================================================================
# 核心属性与导演样条查询接口 (对应 CNtlPLPropertyContainer)
# ==============================================================================

## 获取角色骨骼、动作帧事件、受击判定属性 (CNtlPLCharacterProperty)
func get_character_property(char_name: String) -> Dictionary:
	var prop := _get_property_file("characterproperty.json")
	if prop.has("characters"):
		var chars: Dictionary = prop["characters"]
		if chars.has(char_name):
			return chars[char_name]
	return {}


## 获取道具装备挂点、刀光残影与强化光效属性 (CNtlPLItemProperty)
func get_item_property(item_name: String) -> Dictionary:
	var prop := _get_property_file("itemproperty.json")
	if prop.has("items"):
		var items: Dictionary = prop["items"]
		if items.has(item_name):
			return items[item_name]
	return {}


## 获取大世界场景物件物理、AABB包围盒与剔除属性 (CNtlPLObjectProperty)
func get_object_property(object_name: String) -> Dictionary:
	var prop := _get_property_file("objectproperty.json")
	if prop.has("objects"):
		var objs: Dictionary = prop["objects"]
		if objs.has(object_name):
			return objs[object_name]
	return {}


## 获取剧情与必杀技 3D 摄像机样条轨迹数据 (CNtlDTContainer / CNtlDTSpline)
func get_spline(spline_name: String) -> Dictionary:
	var prop := _get_property_file("direct_splines.json")
	if prop.has("splines"):
		var splines: Dictionary = prop["splines"]
		if splines.has(spline_name):
			return splines[spline_name]
	return {}


## 获取导演演出工程树状分类与层级 (CDTEditorDoc)
func get_project_hierarchy() -> Dictionary:
	return _get_property_file("direct_project.json")


## 获取天下第一武道会赛场导演与气氛控制器 (CNtlSLTBCrowdManager)
func get_tenkaichi_direction(step_name: String) -> Dictionary:
	var prop := _get_property_file("tenkaichi_direction.json")
	if prop.has("controllers"):
		var ctrls: Dictionary = prop["controllers"]
		if ctrls.has(step_name):
			return ctrls[step_name]
	return {}


## 获取指定世界区域环境配置 (对应 50 个世界的 environment.json)
func get_zone_environment(folder_name: String) -> Dictionary:
	var clean_folder := folder_name.strip_edges()
	if not clean_folder.ends_with("_chunks") and clean_folder != "chunks":
		clean_folder += "_chunks"
	var file_path := "res://data/terrain/" + clean_folder + "/environment.json"
	return _load_json_file(file_path)


# ==============================================================================
# 缓存与内部工具函数
# ==============================================================================

func _get_property_file(file_name: String) -> Dictionary:
	if _property_cache.has(file_name):
		return _property_cache[file_name]

	var file_path := PROPERTY_DIR + file_name
	var data := _load_json_file(file_path)
	if not data.is_empty():
		_property_cache[file_name] = data
	return data


func _load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("[DBOTableManager] 找不到文件: " + path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[DBOTableManager] 无法打开文件: " + path)
		return {}

	var content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if parsed is Dictionary:
		return parsed
	return {}


## 预加载高频核心表（如经验表、公式表）
func preload_essential_tables() -> void:
	get_table("table_exp_data.json")
	get_table("td_formula.json")


## 清除特定或全部内存缓存
func clear_cache(table_name: String = "") -> void:
	if table_name != "":
		_table_cache.erase(table_name)
	else:
		_table_cache.clear()
		_property_cache.clear()
