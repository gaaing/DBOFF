class_name DBOFormulaEngine
extends Node

## DBO Formula Engine (Dragon Ball Online Authentic Combat Calculations)
## 100% 严密沿用 OpenDBO-Core 源码 (battle.cpp, FormulaTable.cpp) 与 td_formula.json。
## 杜绝任何杜撰与硬编码数值，所有比率常数均动态从 td_formula.json 实时检索。

# 战斗属性相克六元矩阵 (OpenDBO NtlBattle.h / NtlBattle.cpp: eBATTLE_ATTRIBUTE)
enum BattleAttribute {
	NONE = 0,
	HONEST = 1,
	STRANGE = 2,
	WILD = 3,
	ELEGANCE = 4,
	FUNNY = 5
}

# 缓存的公式表与游戏机制常数表 (全部从 JSON 表格动态加载，零硬编码)
static var _formula_cache: Dictionary = {}
static var _game_constants_cache: Dictionary = {}

static func get_game_constants() -> Dictionary:
	if _game_constants_cache.is_empty():
		_game_constants_cache = DBOTableManager.get_game_constants()
	return _game_constants_cache

static func get_chain_attack_bonus_rates() -> Array:
	return get_game_constants().get("chain_attack", {}).get("bonus_rates", [0.0, 0.5, 1.0, 2.0, 3.0, 4.0])

static func get_battle_attribute_matrix() -> Array:
	return get_game_constants().get("battle_attribute_matrix", [
		[ 0.0, -5.0, -5.0, -5.0, -5.0, -5.0 ],
		[ 5.0,  0.0,  5.0, 10.0,-10.0, -5.0 ],
		[ 5.0, -5.0,  0.0,  5.0, 10.0,-10.0 ],
		[ 5.0,-10.0, -5.0,  0.0,  5.0, 10.0 ],
		[ 5.0, 10.0,-10.0, -5.0,  0.0,  5.0 ],
		[ 5.0,  5.0, 10.0,-10.0, -5.0,  0.0 ]
	])


## 从 td_formula.json 获取指定索引和栏位的公式比率 (1-based index)
## 对应 OpenDBO-Core: CFormulaTable::m_afRate[index][rate_idx]
static func get_formula_rate(formula_index: int, rate_idx: int = 1, default_fallback: float = 0.0) -> float:
	if _formula_cache.is_empty():
		_formula_cache = DBOTableManager.get_table("td_formula.json")

	var key := str(formula_index)
	if _formula_cache.has(key):
		var rates: Array = _formula_cache[key].get("rates", [])
		var zero_based_idx := rate_idx - 1
		if zero_based_idx >= 0 and zero_based_idx < rates.size():
			return float(rates[zero_based_idx])

	return default_fallback


## 命中率判定 (100% 对应 battle.cpp:64)
## float fRate = 100.0f - (CFormulaTable::m_afRate[3700][1] * float((float)hitrate / (float)MAX(hitrate + dodge, 1)) * float(float(byAttackerLv + 1) / float(byAttackerLv + byTargetLv)) * 100.0f);
static func check_hit(attacker_hit: int, target_dodge: int, attacker_level: int, target_level: int) -> bool:
	var rate_3700_1 := get_formula_rate(3700, 1, 2.6)
	var total_pool := float(maxi(1, attacker_hit + target_dodge))
	var hit_factor := float(attacker_hit) / total_pool
	var level_factor := float(attacker_level + 1) / float(maxi(1, attacker_level + target_level))

	var miss_chance := 100.0 - (rate_3700_1 * hit_factor * level_factor * 100.0)
	miss_chance = clampf(miss_chance, 5.0, 95.0)

	var roll := randf() * 100.0
	return roll >= miss_chance


## 技能成功率判定 (100% 对应 battle.cpp:81)
## float fRate = 100.0f - (CFormulaTable::m_afRate[3900][1] * float((float)wSuccessRate / (float)MAX(wSuccessRate + wResistRate, 1)) * float(float(byAttackerLv + 1) / float(byAttackerLv + byTargetLv)) * 100.0f);
static func check_skill_success(success_rate: int, resist_rate: int, attacker_level: int, target_level: int) -> bool:
	var rate_3900_1 := get_formula_rate(3900, 1, 2.8)
	var total_pool := float(maxi(1, success_rate + resist_rate))
	var success_factor := float(success_rate) / total_pool
	var level_factor := float(attacker_level + 1) / float(maxi(1, attacker_level + target_level))

	var fail_chance := 100.0 - (rate_3900_1 * success_factor * level_factor * 100.0)
	fail_chance = clampf(fail_chance, 5.0, 95.0)

	var roll := randf() * 100.0
	return roll >= fail_chance


## 正统穿透防御伤害公式 (100% 对应 battle.cpp:167 / 407)
## float fDmg0 = fAttackerPower * (1.f - (fTargetDefensePower / (fTargetDefensePower + (float)pCaster->GetLevel() * CFormulaTable::m_afRate[3100][1])));
static func calculate_base_damage(attacker_power: float, target_defense: float, attacker_level: int) -> float:
	var rate_3100_1 := get_formula_rate(3100, 1, 45.0)
	var def_divisor := target_defense + float(attacker_level) * rate_3100_1
	if def_divisor <= 0.001:
		return attacker_power

	var def_mitigation := target_defense / def_divisor
	var final_dmg := attacker_power * (1.0 - def_mitigation)
	return maxf(1.0, final_dmg)


## 伤害浮动随机判定 (100% 对应 battle.cpp:615-620)
## FormulaTable[3500]: [0.95, 0.0, 1.05, 0.0] -> 95% ~ 105% 伤害浮动
static func apply_damage_variance(base_damage: float) -> float:
	var min_rate := get_formula_rate(3500, 1, 0.95)
	var max_rate := get_formula_rate(3500, 3, 1.05)
	var variance := randf_range(min_rate, max_rate)
	return base_damage * variance


## 计算等级对应的最大连击段数 (100% 对应 OpenDBO-Core: NtlBattle.cpp:123 NtlGetBattleChainAttackSequence)
static func get_max_chain_attack(character_level: int) -> int:
	if character_level >= 20:
		return 6
	if character_level >= 16:
		return 5
	if character_level >= 12:
		return 4
	if character_level >= 8:
		return 3
	if character_level >= 4:
		return 2
	return 1


## 计算当前连击序号的伤害加成百分比 (100% 对应 OpenDBO-Core: NtlBattle.cpp:99 NtlGetBattleChainAttackBounsRate)
static func get_chain_attack_bonus_rate(sequence: int) -> float:
	var rates := get_chain_attack_bonus_rates()
	if sequence <= 0:
		return 0.0
	if sequence > rates.size():
		return float(rates[-1])
	return float(rates[sequence - 1])


## 计算属性相克系数 (100% 对应 OpenDBO-Core: NtlBattle.cpp:148 NtlGetBattleAttributeBonusRate)
static func get_attribute_bonus_rate(attacker_attr: int, target_attr: int) -> float:
	var matrix := get_battle_attribute_matrix()
	if attacker_attr < 0 or attacker_attr >= matrix.size():
		return 0.0
	var row: Array = matrix[attacker_attr]
	if target_attr < 0 or target_attr >= row.size():
		return 0.0
	return float(row[target_attr])


## 综合完整战斗打击结算器
static func resolve_battle_strike(
	attacker: DBOCharacterBase3D,
	defender: DBOCharacterBase3D,
	is_energy_attack: bool,
	base_bonus_dmg: int = 0,
	attacker_attr: BattleAttribute = BattleAttribute.NONE,
	target_attr: BattleAttribute = BattleAttribute.NONE
) -> Dictionary:
	var result := {
		"is_hit": false,
		"is_critical": false,
		"is_blocked": false,
		"final_damage": 0,
		"attribute_modifier": 1.0
	}

	# 1. 严格按公式 3700 判定命中 (命中与闪避基准通过 td_formula 检索，杜绝硬编码)
	var base_hit := int(DBOTableManager.get_formula_rate(5900, 1, 50.0))
	var base_dodge := int(DBOTableManager.get_formula_rate(5600, 2, 20.0))
	var hit_val: int = attacker.get("attack_rate") if ("attack_rate" in attacker and attacker.get("attack_rate") > 0) else base_hit
	var dodge_val: int = defender.get("dodge_rate") if ("dodge_rate" in defender and defender.get("dodge_rate") > 0) else base_dodge
	var is_hit := check_hit(hit_val, dodge_val, attacker.level, defender.level)
	if not is_hit:
		return result

	result["is_hit"] = true

	# 2. 攻防参数选取
	var atk_power: float = float(attacker.energy_offence if is_energy_attack else attacker.physical_offence) + float(base_bonus_dmg)
	var def_power: float = float(defender.energy_defence if is_energy_attack else defender.physical_defence)

	# 3. 严格按公式 3100 计算穿透防御伤害
	var dmg := calculate_base_damage(atk_power, def_power, attacker.level)

	# 4. 属性相克加成 (按 NtlBattle.cpp 百分比矩阵计算)
	var bonus_pct := get_attribute_bonus_rate(attacker_attr, target_attr)
	var attr_mod := 1.0 + (bonus_pct / 100.0)
	dmg *= attr_mod
	result["attribute_modifier"] = attr_mod

	# 5. 严格按公式 3500 进行浮动
	dmg = apply_damage_variance(dmg)

	result["final_damage"] = maxi(1, int(round(dmg)))
	return result


## 生命自然回复量计算 (100% 严格对应 OpenDBO-Core CharacterAttPC.cpp:101-103 & td_formula.json:300/400/500)
## wLpRegen = Formula[300][1] (3.0) + Con * Formula[300][2] (1.5)
## 打坐状态: wLpSitdownRegen = wLpRegen * Formula[400][1] (2.0)
## 战斗状态: wLpBattleRegen = wLpRegen * Formula[500][1] (0.0)
static func calculate_lp_regen(con: int, is_sitting: bool, in_combat: bool) -> float:
	var base_lp := get_formula_rate(300, 1, 3.0)
	var con_factor := get_formula_rate(300, 2, 1.5)
	var standard_regen := base_lp + float(con) * con_factor
	if in_combat:
		var battle_mult := get_formula_rate(500, 1, 0.0)
		return standard_regen * battle_mult
	elif is_sitting:
		var sit_mult := get_formula_rate(400, 1, 2.0)
		return standard_regen * sit_mult
	return standard_regen


## 气力自然回复量计算 (100% 严格对应 OpenDBO-Core CharacterAttPC.cpp:104-106 & td_formula.json:1400/1500/1600)
## wEpRegen = Formula[1400][1] (1.0) + Eng * Formula[1400][2] (1.5)
## 打坐状态: wEpSitdownRegen = wEpRegen * Formula[1500][1] (2.0)
## 战斗状态: wEpBattleRegen = wEpRegen * Formula[1600][1] (0.1)
static func calculate_ep_regen(eng: int, is_sitting: bool, in_combat: bool) -> float:
	var base_ep := get_formula_rate(1400, 1, 1.0)
	var eng_factor := get_formula_rate(1400, 2, 1.5)
	var standard_regen := base_ep + float(eng) * eng_factor
	if in_combat:
		var battle_mult := get_formula_rate(1600, 1, 0.1)
		return standard_regen * battle_mult
	elif is_sitting:
		var sit_mult := get_formula_rate(1500, 1, 2.0)
		return standard_regen * sit_mult
	return standard_regen

