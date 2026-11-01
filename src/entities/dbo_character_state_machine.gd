class_name DBOCharacterStateMachine
extends Node

## DBO Character State Machine (FSM)
## 100% 严格对标 OpenDBO-Core:
##   - DboShared/NtlShared2/NtlCharacterState.h (eCHARSTATE, eASPECTSTATE, eCHARCONDITION)
##   - DboClient/Lib/NtlSimulation/NtlFSMCharActState.cpp & NtlFSMCharActState.h
##   - DboClient/Lib/NtlSimulation/NtlFSMCharController.cpp
##   - DboServer/Server/GameServer/BotAiState.cpp & CMonster.cpp
##
## 维护角色的正统状态机、异常状态标志位 (Crowd Control) 与动作权限控制。

signal state_changed(old_state: int, new_state: int)
signal condition_applied(condition_flag: int)
signal condition_removed(condition_flag: int)
signal knockdown_started()
signal knockdown_ground_hit()
signal knockdown_standup_started()
signal knockdown_recovered()

# 严格对应 NtlCharacterState.h: enum eCHARSTATE
enum CharState {
	SPAWNING = 0,           # CHARSTATE_SPAWNING
	DESPAWNING = 1,         # CHARSTATE_DESPAWNING
	STANDING = 2,           # CHARSTATE_STANDING (Idle)
	SITTING = 3,            # CHARSTATE_SITTING (打坐休息)
	FAINTING = 4,           # CHARSTATE_FAINTING (死亡)
	CAMPING = 5,            # CHARSTATE_CAMPING
	LEAVING = 6,            # CHARSTATE_LEAVING

	MOVING = 7,             # CHARSTATE_MOVING (走/跑/平移)
	DESTMOVE = 8,           # CHARSTATE_DESTMOVE
	FOLLOWING = 9,          # CHARSTATE_FOLLOWING
	FALLING = 10,           # CHARSTATE_FALLING (下坠)
	DASH_PASSIVE = 11,      # CHARSTATE_DASH_PASSIVE
	TELEPORTING = 12,       # CHARSTATE_TELEPORTING
	SLIDING = 13,           # CHARSTATE_SLIDING
	KNOCKDOWN = 14,         # CHARSTATE_KNOCKDOWN (击倒在地)

	FOCUSING = 15,          # CHARSTATE_FOCUSING
	CASTING = 16,           # CHARSTATE_CASTING (技能吟唱中)
	SKILL_AFFECTING = 17,   # CHARSTATE_SKILL_AFFECTING (技能释放引导中)
	KEEPING_EFFECT = 18,    # CHARSTATE_KEEPING_EFFECT
	CASTING_ITEM = 19,      # CHARSTATE_CASTING_ITEM

	STUNNED = 20,           # CHARSTATE_STUNNED (眩晕)
	SLEEPING = 21,          # CHARSTATE_SLEEPING (催眠)
	PARALYZED = 22,         # CHARSTATE_PARALYZED (麻痹)

	HTB = 23,               # CHARSTATE_HTB (正在执行超绝连招)
	SANDBAG = 24,           # CHARSTATE_SANDBAG (被HTB连招强控暴打)
	CHARGING = 25,          # CHARSTATE_CHARGING (聚气聚气珠)
	GUARD = 26,             # CHARSTATE_GUARD (防御格挡)

	PRIVATESHOP = 27,       # CHARSTATE_PRIVATESHOP
	DIRECT_PLAY = 28,       # CHARSTATE_DIRECT_PLAY (剧情过场镜头)
	OPERATING = 29,         # CHARSTATE_OPERATING
	RIDEON = 30,            # CHARSTATE_RIDEON (载具)
	TURNING = 31,           # CHARSTATE_TURNING

	AIR_JUMP = 32,          # CHARSTATE_AIR_JUMP
	AIR_DASH_ACCEL = 33,    # CHARSTATE_AIR_DASH_ACCEL

	AUTO_ATTACK = 34        # 扩展：常规普攻打击链状态
}

# 严格对应 NtlCharacterState.h: enum eCHARCONDITION
enum CharCondition {
	INVISIBLE = 0,
	HIDING_KI = 1,
	INVINCIBLE = 2,
	TAUNT = 3,
	ATTACK_DISALLOW = 4,
	TRANSPARENT = 5,
	CANT_BE_TARGETTED = 6,
	DIRECT_PLAY = 7,

	BLEEDING = 8,
	POISON = 9,
	STOMACHACHE = 10,
	BURN = 11,
	CONFUSED = 12,
	TERROR = 13,
	BARRIER = 14,
	DAMAGE_REFLECTION = 15,

	AFTEREFFECT = 16,
	CHARGING_BLOCKED = 17,
	FAKE_DEATH = 18,
	NULLIFIED_DAMAGE = 19,

	CLICK_DISABLE = 20,
	CLIENT_UI_DISABLE = 21,

	TAIYOU_KEN = 22,
	BATTLE_INABILITY = 23,
	SKILL_INABILITY = 24,
	REVIVAL_AFTEREFFECT = 25
}

# 击倒子阶段跟踪 (Knockdown Phase)
enum KnockdownPhase {
	NONE,
	FLYING,      # 抛空倒飞中
	GROUND_IDLE, # 倒地瘫躺中
	STANDUP      # 起身恢复中
}

@export var current_state: int = CharState.STANDING
@export var current_condition_flags: int = 0

var knockdown_phase: int = KnockdownPhase.NONE
var _state_duration: float = 0.0
var _knockdown_timer: float = 0.0
var _owner_character: Node = null


func _ready() -> void:
	_owner_character = get_parent()


func _physics_process(delta: float) -> void:
	_state_duration += delta

	# 击倒起立恢复管线处理
	if current_state == CharState.KNOCKDOWN:
		_process_knockdown_flow(delta)


## 请求切换状态 (遵循 OpenDBO 转换守则)
func change_state(new_state: int) -> bool:
	if current_state == new_state:
		return false

	# 死亡状态不可退出（除非被复活）
	if current_state == CharState.FAINTING and new_state != CharState.SPAWNING and new_state != CharState.STANDING:
		return false

	# 硬控状态下不可主动切入行走/攻击/蓄气/打坐
	if is_action_blocked() and not _is_forced_transition(new_state):
		return false

	var old_state := current_state
	_on_exit_state(old_state)
	current_state = new_state
	_state_duration = 0.0
	_on_enter_state(new_state)

	state_changed.emit(old_state, new_state)
	return true


func _is_forced_transition(state: int) -> bool:
	return state in [
		CharState.FAINTING,
		CharState.KNOCKDOWN,
		CharState.STUNNED,
		CharState.SLEEPING,
		CharState.PARALYZED,
		CharState.SANDBAG
	]


func _on_enter_state(state: int) -> void:
	match state:
		CharState.KNOCKDOWN:
			knockdown_phase = KnockdownPhase.FLYING
			_knockdown_timer = 0.0
			knockdown_started.emit()
		CharState.STUNNED:
			add_condition(CharCondition.BATTLE_INABILITY)
			add_condition(CharCondition.SKILL_INABILITY)
		CharState.SLEEPING:
			add_condition(CharCondition.BATTLE_INABILITY)
			add_condition(CharCondition.SKILL_INABILITY)
		CharState.PARALYZED:
			add_condition(CharCondition.BATTLE_INABILITY)


func _on_exit_state(state: int) -> void:
	match state:
		CharState.KNOCKDOWN:
			knockdown_phase = KnockdownPhase.NONE
			_knockdown_timer = 0.0
			knockdown_recovered.emit()
		CharState.STUNNED:
			remove_condition(CharCondition.BATTLE_INABILITY)
			remove_condition(CharCondition.SKILL_INABILITY)
		CharState.SLEEPING:
			remove_condition(CharCondition.BATTLE_INABILITY)
			remove_condition(CharCondition.SKILL_INABILITY)
		CharState.PARALYZED:
			remove_condition(CharCondition.BATTLE_INABILITY)


## 触发正统击倒流程 (对标 OpenDBO: CCharacter::OnKnockdown)
func trigger_knockdown() -> void:
	change_state(CharState.KNOCKDOWN)


func _process_knockdown_flow(delta: float) -> void:
	_knockdown_timer += delta

	match knockdown_phase:
		KnockdownPhase.FLYING:
			# 检查是否触地
			var char_body := _owner_character as CharacterBody3D
			if (char_body and char_body.is_on_floor() and _knockdown_timer > 0.25) or _knockdown_timer > 0.8:
				knockdown_phase = KnockdownPhase.GROUND_IDLE
				_knockdown_timer = 0.0
				knockdown_ground_hit.emit()

		KnockdownPhase.GROUND_IDLE:
			# 倒地瘫躺保持约 0.9 秒 (对标 OpenDBO 倒地时长)
			if _knockdown_timer >= 0.9:
				knockdown_phase = KnockdownPhase.STANDUP
				_knockdown_timer = 0.0
				knockdown_standup_started.emit()

		KnockdownPhase.STANDUP:
			# 起身动画播放约 0.6 秒后彻底恢复站立
			if _knockdown_timer >= 0.6:
				change_state(CharState.STANDING)


## 行为判定权限接口 (严谨对齐 OpenDBO-Core)
func can_move() -> bool:
	if current_state in [
		CharState.SITTING,
		CharState.CHARGING,
		CharState.GUARD,
		CharState.CASTING,
		CharState.SKILL_AFFECTING,
		CharState.STUNNED,
		CharState.SLEEPING,
		CharState.PARALYZED,
		CharState.KNOCKDOWN,
		CharState.SANDBAG,
		CharState.HTB,
		CharState.FAINTING
	]:
		return false
	if has_condition(CharCondition.BATTLE_INABILITY):
		return false
	return true


func can_act() -> bool:
	if current_state in [
		CharState.STUNNED,
		CharState.SLEEPING,
		CharState.PARALYZED,
		CharState.KNOCKDOWN,
		CharState.SANDBAG,
		CharState.FAINTING
	]:
		return false
	return true


func can_attack() -> bool:
	if not can_act():
		return false
	if current_state in [CharState.SITTING, CharState.CHARGING, CharState.GUARD, CharState.CASTING]:
		return false
	if has_condition(CharCondition.ATTACK_DISALLOW) or has_condition(CharCondition.BATTLE_INABILITY):
		return false
	return true


func is_action_blocked() -> bool:
	return current_state in [
		CharState.STUNNED,
		CharState.SLEEPING,
		CharState.PARALYZED,
		CharState.KNOCKDOWN,
		CharState.SANDBAG,
		CharState.FAINTING
	]


## 状态异常 (Conditions) 标志位操作
func add_condition(cond: int) -> void:
	var mask := (1 << cond)
	if (current_condition_flags & mask) == 0:
		current_condition_flags |= mask
		condition_applied.emit(cond)


func remove_condition(cond: int) -> void:
	var mask := (1 << cond)
	if (current_condition_flags & mask) != 0:
		current_condition_flags &= ~mask
		condition_removed.emit(cond)


func has_condition(cond: int) -> bool:
	return (current_condition_flags & (1 << cond)) != 0
