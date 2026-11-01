class_name DBOSaveManager
extends RefCounted

## DBO Save Manager
## 负责单机离线模式下账号元数据 (account_meta.json) 与角色全量数据 (char_{id}.json) 的持久化。
## 严格对标 OpenDBO-Core 数据结构:
##   - DboServer/Server/GameServer/CPlayer.cpp
##   - DboShared/NtlGameTable/NewbieTable.h
## 纯静态无状态/全局缓存驱动，杜绝 Autoload 命名冲突与实例调用异常。

const SAVE_DIR := "user://saves/"
const ACCOUNT_META_PATH := "user://saves/account_meta.json"
const CHAR_DATA_FORMAT := "user://saves/char_%d.json"

const DEFAULT_ACCOUNT_META: Dictionary = {
	"save_schema_version": 100,
	"last_save_timestamp": 0,
	"account_id": 1001,
	"username": "dbo_player",
	"gm_level": 10,
	"character_max_slots": 8,
	"last_played_char_id": 0,
	"character_brief_list": []
}

const DEFAULT_CHARACTER_DATA: Dictionary = {
	"character_profile": {
		"char_id": 100001,
		"char_name": "NewHero",
		"race": 0,
		"class_id": 0,
		"gender": 0,
		"face_style": 1,
		"hair_style": 1,
		"hair_color": 1,
		"skin_color": 1,
		"is_adult": false,
		"is_class_changed": false,
		"character_grade": 0
	},
	"world_transform": {
		"world_id": 1,
		"world_tblidx": 1,
		"position": [4448.0, 39.0, 3968.0],
		"direction": [0.0, 0.0, 1.0],
		"bind_point": {
			"bind_type": 0,
			"bind_world_id": 1,
			"bind_object_tblidx": 0,
			"bind_position": [4448.0, 39.0, 3968.0],
			"bind_direction": [0.0, 0.0, 1.0]
		}
	},
	"stats": {
		"level": 1,
		"exp": 0,
		"zenny": 0,
		"cur_lp": 100,
		"cur_ep": 100,
		"cur_rp": 0,
		"cur_rp_balls": 0,
		"cur_ap": 100,
		"sp_points": 0,
		"reputation": 0,
		"mudosa_points": 0,
		"netpy_points": 0,
		"wagu_points": 0,
		"str": 10,
		"con": 10,
		"foc": 10,
		"dex": 10,
		"sol": 10,
		"eng": 10
	},
	"containers": {
		"inventory_items": []
	},
	"skills": [],
	"quick_slots": [],
	"quests": {
		"quests_completed_bitfield": "",
		"in_progress_quests": [],
		"quest_inventory": []
	}
}

static var selected_char_id: int = 0
static var _active_character_cache: Dictionary = {}


static func _ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


## 加载账号级元数据
static func load_account_meta() -> Dictionary:
	_ensure_save_directory()
	if not FileAccess.file_exists(ACCOUNT_META_PATH):
		save_account_meta(DEFAULT_ACCOUNT_META.duplicate(true))
		return DEFAULT_ACCOUNT_META.duplicate(true)

	var file := FileAccess.open(ACCOUNT_META_PATH, FileAccess.READ)
	if file == null:
		return DEFAULT_ACCOUNT_META.duplicate(true)

	var content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if parsed is Dictionary:
		return parsed
	return DEFAULT_ACCOUNT_META.duplicate(true)


## 保存账号级元数据
static func save_account_meta(meta: Dictionary) -> void:
	_ensure_save_directory()
	meta["last_save_timestamp"] = int(Time.get_unix_time_from_system())
	var file := FileAccess.open(ACCOUNT_META_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(meta, "\t"))
		file.close()


## 加载指定角色的全量数据
static func load_character_data(char_id: int) -> Dictionary:
	_ensure_save_directory()
	var char_file_path := CHAR_DATA_FORMAT % char_id
	if not FileAccess.file_exists(char_file_path):
		return {}

	var file := FileAccess.open(char_file_path, FileAccess.READ)
	if file == null:
		return {}

	var content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if parsed is Dictionary:
		if char_id == selected_char_id:
			_active_character_cache = parsed
		return parsed
	return {}


## 保存指定角色的全量数据
static func save_character_data(char_id: int, data: Dictionary) -> void:
	_ensure_save_directory()
	var char_file_path := CHAR_DATA_FORMAT % char_id
	var file := FileAccess.open(char_file_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		if char_id == selected_char_id:
			_active_character_cache = data


## 删除角色存档与简报条目
static func delete_character(char_id: int) -> void:
	var meta := load_account_meta()
	var brief_list: Array = meta.get("character_brief_list", [])
	var filtered: Array = []
	for brief in brief_list:
		if int(brief.get("char_id", 0)) != char_id:
			filtered.append(brief)
	meta["character_brief_list"] = filtered
	if meta.get("last_played_char_id", 0) == char_id:
		meta["last_played_char_id"] = filtered[0].get("char_id", 0) if not filtered.is_empty() else 0
	save_account_meta(meta)

	var char_file_path := CHAR_DATA_FORMAT % char_id
	if FileAccess.file_exists(char_file_path):
		DirAccess.remove_absolute(char_file_path)

	if selected_char_id == char_id:
		selected_char_id = meta.get("last_played_char_id", 0)
		_active_character_cache.clear()


## 设置当前激活的角色 ID
static func set_active_character_id(char_id: int) -> void:
	selected_char_id = char_id
	if char_id > 0:
		_active_character_cache = load_character_data(char_id)
		var meta := load_account_meta()
		meta["last_played_char_id"] = char_id
		save_account_meta(meta)
	else:
		_active_character_cache.clear()


## 获取当前激活的角色 ID
static func get_active_character_id() -> int:
	if selected_char_id <= 0:
		var meta := load_account_meta()
		selected_char_id = int(meta.get("last_played_char_id", 0))
	return selected_char_id


## 获取当前激活的角色完整数据 (若为空则自动使用默认新手兜底)
static func get_active_character_data() -> Dictionary:
	if not _active_character_cache.is_empty():
		return _active_character_cache

	var cid := get_active_character_id()
	if cid > 0:
		var data := load_character_data(cid)
		if not data.is_empty():
			_active_character_cache = data
			return data

	return DEFAULT_CHARACTER_DATA.duplicate(true)


## 依据 OpenDBO newbie_table.json 新建角色全量数据
static func create_character_from_newbie(
	char_id: int,
	char_name: String,
	race: int,
	class_id: int,
	gender: int,
	hair: int,
	hair_color: int,
	face: int,
	skin_color: int
) -> Dictionary:
	var newbie_table := _load_newbie_table()
	var newbie_entry := _find_newbie_entry(newbie_table, race, class_id)

	var spawn_pos: Array = [4448.0, 39.0, 3968.0]
	var spawn_dir: Array = [0.0, 0.0, 1.0]
	var world_id: int = 1

	if not newbie_entry.is_empty():
		var pos_dict: Dictionary = newbie_entry.get("spawn_loc", {})
		spawn_pos = [float(pos_dict.get("x", 4448.0)), float(pos_dict.get("y", 39.0)) + 0.63, float(pos_dict.get("z", 3968.0))]
		var dir_dict: Dictionary = newbie_entry.get("spawn_dir", {})
		spawn_dir = [float(dir_dict.get("x", 0.0)), float(dir_dict.get("y", 0.0)), float(dir_dict.get("z", 1.0))]
		world_id = int(newbie_entry.get("world_tblidx", 1))

	var char_data: Dictionary = DEFAULT_CHARACTER_DATA.duplicate(true)
	char_data["character_profile"] = {
		"char_id": char_id,
		"char_name": char_name,
		"race": race,
		"class_id": class_id,
		"gender": gender,
		"face_style": face,
		"hair_style": hair,
		"hair_color": hair_color,
		"skin_color": skin_color,
		"is_adult": false,
		"is_class_changed": false,
		"character_grade": 0
	}

	char_data["world_transform"] = {
		"world_id": world_id,
		"world_tblidx": world_id,
		"position": spawn_pos,
		"direction": spawn_dir,
		"bind_point": {
			"bind_type": 1,
			"bind_world_id": world_id,
			"bind_object_tblidx": 0,
			"bind_position": spawn_pos,
			"bind_direction": spawn_dir
		}
	}

	# 官方初始道具与技能
	if not newbie_entry.is_empty():
		var starter_items: Array = newbie_entry.get("starter_items", newbie_entry.get("items", []))
		char_data["containers"]["inventory_items"] = starter_items
		char_data["skills"] = newbie_entry.get("skills", newbie_entry.get("starter_skills", []))
		char_data["quick_slots"] = newbie_entry.get("quick_slots", newbie_entry.get("starter_quick_slots", []))

	save_character_data(char_id, char_data)

	# 同步加入账号 brief 列表
	var meta := load_account_meta()
	var brief_list: Array = meta.get("character_brief_list", [])
	var new_brief := {
		"char_id": char_id,
		"char_name": char_name,
		"race": race,
		"class_id": class_id,
		"gender": gender,
		"level": 1,
		"face_style": face,
		"hair_style": hair,
		"hair_color": hair_color,
		"skin_color": skin_color
	}
	brief_list.append(new_brief)
	meta["character_brief_list"] = brief_list
	meta["last_played_char_id"] = char_id
	save_account_meta(meta)

	set_active_character_id(char_id)
	return char_data


## 获取指定种族与职业的官方新手装备清单 (过滤掉背包非装备物)
static func get_newbie_starter_items(race: int, class_id: int) -> Array:
	var newbie_table := _load_newbie_table()
	var entry := _find_newbie_entry(newbie_table, race, class_id)
	if entry.is_empty():
		return []

	var all_items: Array = entry.get("starter_items", entry.get("items", []))
	var equipped: Array = []
	for it in all_items:
		if int(it.get("pos", 255)) != 255:
			equipped.append(it)
	return equipped


static func _load_newbie_table() -> Array:
	const PATH := "res://data/newbie_table.json"
	if FileAccess.file_exists(PATH):
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Array:
				return parsed
			elif parsed is Dictionary:
				return parsed.values()
	return []


static func _find_newbie_entry(newbie_table: Array, race: int, class_id: int) -> Dictionary:
	for entry in newbie_table:
		if int(entry.get("race", -1)) == race and int(entry.get("class", -1)) == class_id:
			return entry
	return {}
