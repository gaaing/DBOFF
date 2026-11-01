class_name DBOCombatEngine
extends Node

## DBO Combat Engine (High-Level Combat Dispatcher)
## 100% 对齐 OpenDBO-Core 服务端与客户端战斗管道：
##   - DboServer/Server/GameServer/char_battle.cpp & battle.cpp
##   - DboClient/Lib/NtlSimulation/NtlSobActor.cpp & NtlSobStatusAnimSyncManager.cpp
##
## 负责整合 DBOFormulaEngine 公式、伤害跳字、受击火花粒子、受击白光闪烁、顿帧打击感与击倒流转。


## 战斗攻击打击判定与全套受击反馈派发
static func calculate_attack(attacker: DBOCharacterBase3D, defender: DBOCharacterBase3D, hit_event: Dictionary = {}) -> Dictionary:
	var result := {
		"is_hit": false,
		"is_critical": false,
		"is_blocked": false,
		"actual_damage": 0,
		"knockback_impulse": Vector3.ZERO
	}

	if attacker == null or defender == null or defender.is_dead:
		return result

	# 攻击类型 (0: 物理 Physical, 1: 能量 Energy/Ki)
	var attack_type: int = hit_event.get("attack_type", 0)
	var is_energy := (attack_type != 0)
	var bonus_dmg: int = hit_event.get("damage", 0)

	# 1. 严格调用 DBOFormulaEngine 官方公式（包含 td_formula 穿透、命中、浮动计算）
	var strike_res := DBOFormulaEngine.resolve_battle_strike(
		attacker,
		defender,
		is_energy,
		bonus_dmg,
		DBOFormulaEngine.BattleAttribute.NONE,
		DBOFormulaEngine.BattleAttribute.NONE
	)

	result["is_hit"] = strike_res["is_hit"]
	result["is_critical"] = strike_res["is_critical"]
	result["is_blocked"] = strike_res["is_blocked"]
	result["actual_damage"] = strike_res["final_damage"]

	# 普攻连击段数的伤害加成结算
	var chain_bonus: float = float(hit_event.get("chain_bonus_rate", 0.0))
	if chain_bonus > 0.0:
		result["actual_damage"] = int(float(result["actual_damage"]) * (1.0 + chain_bonus / 100.0))

	# 计算打击点空间坐标与方向矢量
	var defender_head := defender.global_position + Vector3.UP * 1.2
	var attack_direction := (defender.global_position - attacker.global_position).normalized()
	attack_direction.y = 0.0

	# 2. 未命中 (Miss / Dodge)
	if not result["is_hit"]:
		if is_instance_valid(DBOCombatTextManager):
			DBOCombatTextManager.spawn_miss(defender_head)
		return result

	# 3. 命中：生成 3D 浮动伤害跳字 (Combat Text)
	if is_instance_valid(DBOCombatTextManager):
		var is_mob_source: bool = attacker.is_in_group("mobs") or (attacker is DBOMobEntity3D)
		DBOCombatTextManager.spawn_damage(defender_head, result["actual_damage"], result["is_critical"], result["is_blocked"], is_mob_source)

	# 4. 命中：生成打击火花与冲击波环 (Hit Sparks & VFX)
	var contact_pos := (attacker.global_position + defender.global_position) * 0.5 + Vector3.UP * 1.1
	if is_instance_valid(DBOEffectManager):
		DBOEffectManager.spawn_hit_spark(contact_pos, attack_direction, result["is_critical"], result["is_blocked"])

	# 5. 命中：触发受击白光着色器闪烁 (Hit Flash)
	defender.trigger_hit_flash(0.12, Color(1.0, 0.25, 0.2) if result["is_critical"] else Color(1.0, 1.0, 1.0))

	# 6. 命中：触发攻击者与受击者微顿帧 (Hit Stop / Frame Freeze - 强化打击感)
	var hit_stop_time: float = 0.08 if result["is_critical"] else 0.04
	attacker.apply_hit_stop(hit_stop_time)
	defender.apply_hit_stop(hit_stop_time)

	# 7. 受击被打断判定 (如打破催眠状态)
	var buff_comp := defender.find_child("DBOBuffComponent", true, false) as DBOBuffComponent
	if buff_comp:
		buff_comp.on_damaged_break_sleep()

	# 8. 击退/击倒/浮空冲量判定 (严格通过 td_formula 公式表检索)
	var target_behavior: int = hit_event.get("target_behavior", 0)
	var push_impulse := DBOTableManager.get_formula_rate(7400, 2, 8.0)
	var kd_h_impulse := DBOTableManager.get_formula_rate(6400, 3, 14.0)
	var kd_v_impulse := DBOTableManager.get_formula_rate(7400, 1, 6.0)
	var toss_impulse := DBOTableManager.get_formula_rate(6400, 4, 16.0)

	match target_behavior:
		1:  # TARGET_BEHAVIOR_PUSH
			result["knockback_impulse"] = attack_direction * push_impulse
		2:  # TARGET_BEHAVIOR_KNOCK_DOWN
			result["knockback_impulse"] = attack_direction * kd_h_impulse + Vector3.UP * kd_v_impulse
		3:  # TARGET_BEHAVIOR_TOSS
			result["knockback_impulse"] = Vector3.UP * toss_impulse

	# 9. 扣除防御方生命并施加物理位移
	defender.take_damage(result["actual_damage"], is_energy, result["knockback_impulse"])

	# 10. 若为击倒行为，激活受击者击倒状态机流程 (Knockdown Pipeline)
	if target_behavior == 2 or result["knockback_impulse"].length() >= 13.0:
		defender.trigger_knockdown()

	# 11. 怪物反击仇恨唤醒 (Aggro Transfer)
	if defender is DBOMobEntity3D and not defender.is_dead:
		(defender as DBOMobEntity3D).on_attacked_by(attacker)

	return result
