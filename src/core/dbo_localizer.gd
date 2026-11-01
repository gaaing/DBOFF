extends Node

## DBO Localizer (Dragon Ball Online Localization Service)
## 遵循 GEMINI.md 规范：零硬编码文本，全量通过映射导向对应语言文本，
## 搭载标签分类系统，以便未来自由修改富文本显示效果、字体与颜色。

signal language_changed(new_language: String)

const LOCALIZATION_FILE_PATH := "res://assets/tbl/table_text_all_data.json"

# 支持的所有官方分类标签
const CATEGORIES := {
	"ACTION": "ACTION_DATA",
	"CHAT": "CHAT_COMMMAND_DATA",
	"HTB": "HTB_SET_DATA",
	"ITEM": "ITEM_DATA",
	"MERCHANT": "MERCHANT_DATA",
	"MOB": "MOB_DATA",
	"NPC": "NPC_DATA",
	"SKILL": "SKILL_DATA",
	"SYS_EFFECT": "SYSTEM_EFFECT",
	"USE_ITEM": "USE_ITEM_DATA",
	"MAP": "MAP_NAME",
	"OBJECT": "OBJECT_DATA",
	"QUEST_ITEM": "QUEST_ITEM_DATA",
	"ETC": "ETC_TEXT",
	"HELP": "HELP_DATA",
	"POPO": "HELP_POPOHINT_DATA",
	"DRAGON_BALL": "DRAGON_BALL",
	"DB_REWARD": "DB_REWARD",
	"TMQ": "TMQ_DATA",
	"CS": "CS_TEXT",
	"MILEPOST": "MILEPOST",
	"FILTERING": "FILTERING",
	"NPC_DIALOG": "NPC_DIALOG",
	"GM": "GM_TOOL",
	"TIP": "DBO_TIP",
	"DWC": "DWC_DATA",
	"TITLE": "CHAR_TITLE_DATA",
	"PARTY_DUNGEON": "PARTY_DUNGEON_DATA",
	"GUI": "GUI_TEXT",
	"COMBAT": "COMBAT_TEXT"
}

# 官方标准 GUI 界面文本映射字典 (台湾官方 1.57.51 对齐)
const GUI_FALLBACK_TEXT: Dictionary = {
	"COMBAT_CRITICAL": "CRITICAL!",
	"COMBAT_GUARD": "GUARD",
	"COMBAT_MISS": "MISS",
	"COMBAT_DODGE": "DODGE",
	"DST_LOBBY_CARACTER_INFO": "角色信息",
	"DST_STATUS_NAME": "姓名",
	"DST_LOBBY_CHAR_LEVEL": "等级",
	"DST_LOBBY_CHAR_CLASS": "职业",
	"DST_LOBBY_ZENNY": "索尼",
	"DST_LOBBY_POSITION": "所在区域",
	"DST_LOBBY_CHARACTER_LIST": "角色列表",
	"DST_LOBBY_DEL_CHAR": "删除",
	"DST_LOBBY_GAME_START": "开始游戏",
	"DST_LOBBY_MAKE": "创建",
	"DST_LOBBY_RETURN": "返回",
	"DST_LOBBY_CHARACTER_ATTRIBUTE": "角色属性",
	"DST_LOBBY_RACE": "种族",
	"DST_LOBBY_CLASS": "职业",
	"DST_LOBBY_GENDER": "性别",
	"DST_LOBBY_HAIR": "发型",
	"DST_LOBBY_HAIRCOLOR": "发色",
	"DST_LOBBY_FACE": "脸型",
	"DST_LOBBY_SKIN": "肤色",
	"DST_LOBBY_RANDOM_CHOICE": "随机",
	"DST_LOBBY_CHARACTER_MAKE": "新建角色",
	"DST_LOBBY_NO_HAVE_ZENNY": "0 索尼",
	"DST_ZENNY": "索尼",
	"DST_LOBBY_DEFAULT_POSITION_HUMAN": "柯卡拉村",
	"DST_LOBBY_DEFAULT_POSITION_NAMEK": "天天神殿",
	"DST_LOBBY_DEFAULT_POSITION_MAJIN": "悟饭老爷爷家",
	"DST_RACE_HUMAN": "人类",
	"DST_RACE_NAMEK": "那美克星人",
	"DST_RACE_MAJIN": "魔人",
	"DST_CLASS_HUMAN_FIGHTER": "武道家",
	"DST_CLASS_HUMAN_MYSTIC": "气功师",
	"DST_CLASS_NAMEK_FIGHTER": "战士",
	"DST_CLASS_NAMEK_MYSTIC": "龙族",
	"DST_CLASS_MIGHTY_MAJIN": "大魔人",
	"DST_CLASS_WONDER_MAJIN": "意魔人"
}

# 样式标签预设（支持 BBCode 自定义包装）
const STYLE_TAGS := {
	"item_common": "[color=#FFFFFF]%s[/color]",
	"item_magic": "[color=#4E95FF]%s[/color]",
	"item_rare": "[color=#FFCC00]%s[/color]",
	"item_legend": "[color=#FF6600]%s[/color]",
	"npc_name": "[color=#70DBFF][b]%s[/b][/color]",
	"mob_name": "[color=#FF4444]%s[/color]",
	"skill_name": "[color=#A0FFA0][b]%s[/b][/color]",
	"quest_title": "[color=#FFE680][b]%s[/b][/color]",
	"system_tip": "[color=#E0E0E0]%s[/color]",
	"warning": "[color=#FF3333]%s[/color]"
}

var _current_language: String = "zh_TW"
var _text_database: Dictionary = {}
var _is_loaded: bool = false


func _ready() -> void:
	load_localization_data()


## 加载官方全并集文本库
func load_localization_data() -> bool:
	if _is_loaded:
		return true

	if not FileAccess.file_exists(LOCALIZATION_FILE_PATH):
		push_error("[DBOLocalizer] 找不到语言数据文件: " + LOCALIZATION_FILE_PATH)
		return false

	var file := FileAccess.open(LOCALIZATION_FILE_PATH, FileAccess.READ)
	if file == null:
		push_error("[DBOLocalizer] 无法打开语言文件: " + str(FileAccess.get_open_error()))
		return false

	var json_str := file.get_as_text()
	file.close()

	var json_parsed = JSON.parse_string(json_str)
	if json_parsed == null or not (json_parsed is Dictionary):
		push_error("[DBOLocalizer] 语言文件 JSON 解析失败")
		return false

	_text_database = json_parsed
	_is_loaded = true
	return true


## 获取纯文本映射（按分类和键名获取）
func get_text(category: String, key: Variant, default_text: String = "") -> String:
	if not _is_loaded:
		load_localization_data()

	var cat_key := _normalize_category(category)
	var str_key := str(key)

	if _text_database.has(cat_key):
		var cat_dict: Dictionary = _text_database[cat_key]
		if cat_dict.has(str_key):
			return cat_dict[str_key]

	if cat_key == "GUI_TEXT" and GUI_FALLBACK_TEXT.has(str_key):
		return GUI_FALLBACK_TEXT[str_key]

	if default_text != "":
		return default_text

	return "[%s:%s]" % [cat_key, str_key]


## 获取带样式标签的富文本（自动应用 BBCode，用于 UI 渲染）
func get_styled_text(category: String, key: Variant, style_tag: String = "", default_text: String = "") -> String:
	var raw_text := get_text(category, key, default_text)
	if style_tag != "" and STYLE_TAGS.has(style_tag):
		return STYLE_TAGS[style_tag] % raw_text
	return raw_text


## 检查是否存在某个词条
func has_text(category: String, key: Variant) -> bool:
	if not _is_loaded:
		load_localization_data()

	var cat_key := _normalize_category(category)
	var str_key := str(key)

	return _text_database.has(cat_key) and _text_database[cat_key].has(str_key)


## 获取当前分类下的所有词条条目数
func get_category_count(category: String) -> int:
	var cat_key := _normalize_category(category)
	if _text_database.has(cat_key):
		return _text_database[cat_key].size()
	return 0


## 获取当前语言
func get_current_language() -> String:
	return _current_language


## 设置当前语言并广播变更信号
func set_language(new_language: String) -> void:
	if _current_language != new_language:
		_current_language = new_language
		language_changed.emit(new_language)


## 格式化占位符文本（如 "获得了 %s 个 %s"）
func format_text(category: String, key: Variant, args: Array, default_text: String = "") -> String:
	var raw_template := get_text(category, key, default_text)
	var formatted := raw_template
	for i in range(args.size()):
		var pos := formatted.find("%s")
		if pos != -1:
			formatted = formatted.erase(pos, 2)
			formatted = formatted.insert(pos, str(args[i]))
	return formatted


## 规格化分类名称
func _normalize_category(category: String) -> String:
	var upper := category.to_upper().strip_edges()
	if CATEGORIES.has(upper):
		return CATEGORIES[upper]
	return upper
