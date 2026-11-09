extends Node

## DBO Inventory Manager
## 全局背包、穿戴装备与胶囊盒数据管理器。
## 严格对标 OpenDBO-Core:
##   - DboShared/NtlGameTable/ItemTable.h (sITEM_TBLDAT)
##   - DboShared/NtlGameTable/NewbieTable.h (sNEWBIE_TBLDAT)
##   - DboShared/NtlShared2/NtlItem.h (eEQUIP_SLOT_TYPE)
## 杜绝硬编码：初始装备与技能均由 newbie_table.json 驱动，装备属性由 table_item_data.json 动态下发。

const MAX_BAG_SLOTS: int = 6
const MAX_EQUIP_SLOTS: int = 17

# 对应 OpenDBO NtlItem.h: eEQUIP_SLOT_TYPE
enum EquipSlot {
	HAND = 0,               # 主手武器
	SUB_WEAPON = 1,         # 副手武器
	JACKET = 2,             # 上衣
	PANTS = 3,              # 裤子
	BOOTS = 4,              # 鞋子
	SCOUTER = 5,            # 侦察镜 (史考特)
	QUEST = 6,              # 任务饰品
	NECKLACE = 7,           # 项链
	EARRING_1 = 8,          # 耳环1
	EARRING_2 = 9,          # 耳环2
	RING_1 = 10,            # 戒指1
	RING_2 = 11,            # 戒指2
	COSTUME_SET = 12,       # 时装套装
	COSTUME_HAIR = 13,      # 时装发型
	COSTUME_MASK = 14,      # 时装面具
	COSTUME_HAIR_ACC = 15,  # 时装发饰
	COSTUME_BACK = 16       # 时装背饰
}

# 背包容器与装备栏
var equipped_items: Array[Dictionary] = []
var bags: Array[Array] = []
var bag_capsules: Array[Dictionary] = []
var zenny: int = 0

var _newbie_data_cache: Dictionary = {}
var _item_table_cache: Dictionary = {}


func _ready() -> void:
	_init_containers()


func _init_containers() -> void:
	equipped_items.clear()
	for i in range(MAX_EQUIP_SLOTS):
		equipped_items.append({})

	bags.clear()
	bag_capsules.clear()
	for i in range(MAX_BAG_SLOTS):
		bags.append([])
		bag_capsules.append({})


## 依据玩家种族与职业，从 newbie_table.json 载入官方标准初始背包与初始装备
func init_newbie_inventory(race: int, class_id: int) -> void:
	_init_containers()
	_load_newbie_data()

	# 查找匹配的种族与职业预设
	var matched_entry: Dictionary = {}
	for k in _newbie_data_cache:
		var entry: Dictionary = _newbie_data_cache[k]
		if entry.get("race") == race and entry.get("class") == class_id:
			matched_entry = entry
			break

	if matched_entry.is_empty():
		push_warning("[DBOInventoryManager] 未找到 race=%d, class=%d 的新手创生配置" % [race, class_id])
		return

	# 1. 初始背包装填基础胶囊盒 (16格)
	var starter_items: Array = matched_entry.get("starter_items", [])
	# 遍历 starter_items 查找胶囊盒 (pos == 255)
	for item_info in starter_items:
		var kit_tblidx: int = int(item_info.get("item_tblidx", 0))
		var kit_pos: int = int(item_info.get("pos", 255))
		if kit_pos == 255 and is_capsule_kit(kit_tblidx):
			equip_capsule_kit(0, kit_tblidx)
			break

	# 若未配置胶囊盒，默认加载 16 格基本胶囊盒 19901
	if bag_capsules[0].is_empty():
		equip_capsule_kit(0, 19901)

	# 2. 装备穿戴与背包装入
	for item_info in starter_items:
		var tblidx: int = int(item_info.get("item_tblidx", 0))
		var pos: int = int(item_info.get("pos", 255))
		var stack: int = int(item_info.get("stack", 1))

		if tblidx == 0 or tblidx == 4294967295:
			continue

		var item_data := get_item_data(tblidx)
		if item_data.is_empty():
			continue

		if pos >= 0 and pos < MAX_EQUIP_SLOTS:
			# 官方初始自动穿戴栏位
			equipped_items[pos] = {
				"tblidx": tblidx,
				"data": item_data,
				"stack": stack
			}
		else:
			# 放入背包
			add_item_to_bag(0, tblidx, stack)

	DBOEventBus.inventory_updated.emit()
	DBOEventBus.equipment_updated.emit()


## 获取物品静态数据
func get_item_data(tblidx: int) -> Dictionary:
	if _item_table_cache.is_empty():
		_item_table_cache = DBOTableManager.get_table("table_item_data.json")

	var key := str(tblidx)
	if _item_table_cache.has(key):
		return _item_table_cache[key]
	return {}


## 判断是否为胶囊盒背包拓展道具
func is_capsule_kit(tblidx: int) -> bool:
	var d := get_item_data(tblidx)
	var item_type: int = int(d.get("item_type", 0))
	# OpenDBO: ITEM_TYPE_BAG = 8
	return item_type == 8 or (tblidx >= 19900 and tblidx <= 19999)


## 装备胶囊盒 (扩展背包容量)
func equip_capsule_kit(bag_index: int, tblidx: int) -> void:
	if bag_index < 0 or bag_index >= MAX_BAG_SLOTS:
		return

	var d := get_item_data(tblidx)
	var bag_capacity: int = 16 # 默认标准 16 格
	# 检查容量字段
	var bag_size_val = d.get("bag_size", d.get("param1", 16))
	if int(bag_size_val) > 0:
		bag_capacity = int(bag_size_val)

	bag_capsules[bag_index] = {
		"tblidx": tblidx,
		"data": d,
		"capacity": bag_capacity
	}

	# 扩充或保留现有槽位
	while bags[bag_index].size() < bag_capacity:
		bags[bag_index].append({})


## 向指定背包中添加物品
func add_item_to_bag(bag_index: int, tblidx: int, count: int = 1) -> bool:
	if bag_index < 0 or bag_index >= MAX_BAG_SLOTS:
		return false

	var d := get_item_data(tblidx)
	if d.is_empty():
		return false

	# 优先堆叠到同类物品槽位
	var max_stack: int = int(d.get("max_stack", 1))
	if max_stack > 1:
		for slot in bags[bag_index]:
			if slot.get("tblidx") == tblidx and slot.get("stack", 0) < max_stack:
				var space: int = max_stack - int(slot.get("stack", 0))
				var add_count := mini(space, count)
				slot["stack"] = int(slot["stack"]) + add_count
				count -= add_count
				if count <= 0:
					DBOEventBus.inventory_updated.emit()
					return true

	# 填入首个空槽位
	for i in range(bags[bag_index].size()):
		if bags[bag_index][i].is_empty():
			bags[bag_index][i] = {
				"tblidx": tblidx,
				"data": d,
				"stack": count
			}
			DBOEventBus.inventory_updated.emit()
			return true

	return false


## 穿戴/卸下装备
func equip_item(bag_idx: int, slot_idx: int, target_equip_slot: int) -> bool:
	if bag_idx < 0 or bag_idx >= MAX_BAG_SLOTS:
		return false
	if slot_idx < 0 or slot_idx >= bags[bag_idx].size():
		return false
	if target_equip_slot < 0 or target_equip_slot >= MAX_EQUIP_SLOTS:
		return false

	var item_to_equip: Dictionary = bags[bag_idx][slot_idx]
	if item_to_equip.is_empty():
		return false

	var old_equipped: Dictionary = equipped_items[target_equip_slot]
	equipped_items[target_equip_slot] = item_to_equip
	bags[bag_idx][slot_idx] = old_equipped

	DBOEventBus.inventory_updated.emit()
	DBOEventBus.equipment_updated.emit()
	return true


func _load_newbie_data() -> void:
	if _newbie_data_cache.is_empty():
		var path := "res://data/newbie_table.json"
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				var json_res = JSON.parse_string(file.get_as_text())
				if json_res is Dictionary:
					_newbie_data_cache = json_res
