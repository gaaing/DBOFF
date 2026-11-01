class_name DBOBuffComponent
extends Node

## DBO Buff & Condition Component
## 参考 OpenDBO-Core 源码 (BuffManager.cpp, Buff.cpp)
## 负责角色的增益/减益 Buff 生命周期、持续 DOT/HOT 滴答判定与硬控状态掩码。

signal buff_applied(buff_id: int, buff_name: String)
signal buff_removed(buff_id: int)
signal condition_changed(condition_flags: int)

# 对应 OpenDBO-Core 的 CHARCOND_FLAG 状态位掩码
enum CharCondition {
	NONE = 0,
	STUN = 1 << 0,         # 眩晕：完全无法移动与施法
	SLEEP = 1 << 1,        # 催眠：受击则打醒
	PARALYZE = 1 << 2,     # 麻痹：行动迟缓受限
	CONFUSED = 1 << 3,     # 混乱：颠倒移动
	TERROR = 1 << 4,       # 恐惧：四散奔逃
	TAUNTED = 1 << 5,      # 嘲讽：强制锁定目标
	CANDY = 1 << 6,        # 变糖果：模型变为巧克力/糖果，丧失战力
	BLEEDING = 1 << 7,     # 流血 DOT
	POISONED = 1 << 8,     # 中毒 DOT
	BURNING = 1 << 9       # 灼烧 DOT
}

# 活跃 Buff 列表
# buff_id -> { "name": String, "duration": float, "elapsed": float, "interval": float, "next_tick": float, "dot_damage": int, "hot_heal": int, "condition": int, "stat_modifiers": Dictionary }
var _active_buffs: Dictionary = {}
var _current_condition_flags: int = 0

var _owner_character: DBOCharacterBase3D = null


func _ready() -> void:
	_owner_character = get_parent() as DBOCharacterBase3D


func _process(delta: float) -> void:
	if _active_buffs.is_empty():
		return

	var expired_ids: Array[int] = []

	for b_id in _active_buffs.keys().duplicate():
		if not _active_buffs.has(b_id):
			continue
		var buff: Dictionary = _active_buffs[b_id]
		buff["elapsed"] += delta

		# 处理周期性 DOT 伤害或 HOT 回复 (Tick)
		if buff.get("interval", 0.0) > 0.0:
			if buff["elapsed"] >= buff["next_tick"]:
				buff["next_tick"] += buff["interval"]
				_apply_buff_tick(buff)
				if not _active_buffs.has(b_id):
					continue

		# 检查 Buff 是否到期
		if buff["duration"] > 0.0 and buff["elapsed"] >= buff["duration"]:
			expired_ids.append(b_id)

	for b_id in expired_ids:
		remove_buff(b_id)


## 注册/添加一个 Buff
func apply_buff(
	buff_id: int,
	buff_name: String,
	duration: float,
	condition: int = CharCondition.NONE,
	dot_damage: int = 0,
	hot_heal: int = 0,
	stat_modifiers: Dictionary = {}
) -> void:
	var buff_entry := {
		"id": buff_id,
		"name": buff_name,
		"duration": duration,
		"elapsed": 0.0,
		"interval": 1.0 if (dot_damage > 0 or hot_heal > 0) else 0.0,
		"next_tick": 1.0,
		"dot_damage": dot_damage,
		"hot_heal": hot_heal,
		"condition": condition,
		"stat_modifiers": stat_modifiers
	}

	_active_buffs[buff_id] = buff_entry
	_recalculate_conditions()
	buff_applied.emit(buff_id, buff_name)


## 移除指定 Buff
func remove_buff(buff_id: int) -> void:
	if _active_buffs.has(buff_id):
		_active_buffs.erase(buff_id)
		_recalculate_conditions()
		buff_removed.emit(buff_id)


## 受到伤害时打断睡眠状态 (Sleep Break)
func on_damaged_break_sleep() -> void:
	var sleep_buffs: Array[int] = []
	for b_id in _active_buffs:
		if (_active_buffs[b_id]["condition"] & CharCondition.SLEEP) != 0:
			sleep_buffs.append(b_id)

	for b_id in sleep_buffs:
		remove_buff(b_id)


## 处理周期性滴答
func _apply_buff_tick(buff: Dictionary) -> void:
	if _owner_character == null or _owner_character.is_dead:
		return

	# DOT 伤害
	var dot: int = buff.get("dot_damage", 0)
	if dot > 0:
		_owner_character.take_damage(dot, true)

	# HOT 回复
	var hot: int = buff.get("hot_heal", 0)
	if hot > 0:
		_owner_character.current_health = mini(_owner_character.max_health, _owner_character.current_health + hot)
		_owner_character.health_changed.emit(_owner_character.current_health, _owner_character.max_health)


## 重新计算综合状态位掩码
func _recalculate_conditions() -> void:
	var new_flags := 0
	for b_id in _active_buffs:
		new_flags |= _active_buffs[b_id].get("condition", 0)

	if new_flags != _current_condition_flags:
		_current_condition_flags = new_flags
		condition_changed.emit(_current_condition_flags)


# ==============================================================================
# 行动能力判定查询接口
# ==============================================================================

func can_move() -> bool:
	return (_current_condition_flags & (CharCondition.STUN | CharCondition.SLEEP | CharCondition.PARALYZE | CharCondition.CANDY)) == 0


func can_attack() -> bool:
	return (_current_condition_flags & (CharCondition.STUN | CharCondition.SLEEP | CharCondition.CANDY)) == 0


func can_cast_skills() -> bool:
	return (_current_condition_flags & (CharCondition.STUN | CharCondition.SLEEP | CharCondition.PARALYZE | CharCondition.CANDY)) == 0


func has_condition(condition: CharCondition) -> bool:
	return (_current_condition_flags & condition) != 0
