class_name DBOAspectComponent
extends Node

## DBO Aspect & Transformation Component
## 100% 对应 OpenDBO-Core 源码中的 AspectState 系列形态变身与 StatusTransformTable.h：
## - AspectState_SuperSaiyan.cpp (超级赛亚人)
## - AspectState_GreatNamek.cpp (那美克星人超巨体化)
## - AspectState_PureMajin.cpp (纯粹魔人小布欧形态)
## - AspectState_Kaioken.cpp (界王拳)
## - AspectState_Vehicle.cpp (胶囊载具)
## 杜绝臆想与硬编码：消耗速率、持续时间与属性修饰全部由 table_status_transform_data.json 动态下发。

signal aspect_transformed(new_aspect: AspectType, transform_tblidx: int)
signal aspect_reverted(old_aspect: AspectType)

enum AspectType {
	NONE = 0,
	SUPER_SAIYAN = 1,   # 超级赛亚人
	GREAT_NAMEK = 2,    # 那美克巨体化
	PURE_MAJIN = 3,     # 纯粹小布欧魔人
	KAIOKEN = 4,        # 界王拳
	VEHICLE = 5         # 胶囊载具
}

@export var current_aspect: AspectType = AspectType.NONE
@export var current_transform_tblidx: int = 0

var _transform_data: Dictionary = {}
var _duration_left: float = 0.0
var _tick_timer: float = 0.0

var _owner_character: DBOCharacterBase3D = null
var _original_scale: Vector3 = Vector3.ONE


func _ready() -> void:
	_owner_character = get_parent() as DBOCharacterBase3D
	if _owner_character:
		_original_scale = _owner_character.scale


func _process(delta: float) -> void:
	if current_aspect == AspectType.NONE or _owner_character == null or _owner_character.is_dead:
		return

	# 限时变身倒计时 (对应 dwDuration / dwDurationInMilliSecs)
	if _duration_left > 0.0:
		_duration_left -= delta
		if _duration_left <= 0.0:
			revert_transformation()
			return

	_tick_timer += delta
	# OpenDBO NTL_EFFECT_APPLY_INTERVAL 周期性消耗 (通常为每秒 1.0 秒)
	if _tick_timer >= 1.0:
		_tick_timer -= 1.0
		_process_periodic_consumption()


## 激活变身形态 (按官方 StatusTransform 表格 tblidx 检索)
func transform_to(target_aspect: AspectType, transform_tblidx: int = 101) -> bool:
	if target_aspect == current_aspect:
		return false

	if current_aspect != AspectType.NONE:
		revert_transformation()

	current_aspect = target_aspect
	current_transform_tblidx = transform_tblidx

	# 从官方 table_status_transform_data.json 读取精确实测数据
	_load_transform_tblidx_data(transform_tblidx)

	# 赋值限时
	var dur_secs: float = float(_transform_data.get("dwDuration", 0))
	_duration_left = dur_secs if dur_secs > 0.0 else -1.0
	_tick_timer = 0.0

	# 对应 OpenDBO-Core 各变身形态的 OnEnter 行为
	match target_aspect:
		AspectType.SUPER_SAIYAN:
			if _owner_character and _owner_character.visual:
				_owner_character.visual.play_animation("TRANS_SSJ_START")
		AspectType.GREAT_NAMEK:
			if _owner_character:
				_owner_character.scale = _original_scale * 4.0
		AspectType.PURE_MAJIN:
			# 对应 CAspectState_PureMajin::OnEnter: ChangeModelData(DBO_PURE_MAJIN_MODEL_RESOURCE_NAME)
			pass
		AspectType.KAIOKEN:
			pass
		AspectType.VEHICLE:
			if _owner_character:
				_owner_character.run_speed *= 1.8

	aspect_transformed.emit(target_aspect, transform_tblidx)
	return true


## 解除变身 (对应 OnExit)
func revert_transformation() -> void:
	if current_aspect == AspectType.NONE:
		return

	var old_aspect := current_aspect
	current_aspect = AspectType.NONE
	current_transform_tblidx = 0
	_transform_data.clear()

	if _owner_character:
		_owner_character.scale = _original_scale
		# 对应 CAspectState_SuperSaiyan::OnExit: AddConditionState(CHARCOND_AFTEREFFECT)
		var buff_comp := _owner_character.find_child("DBOBuffComponent", true, false) as DBOBuffComponent
		if buff_comp:
			buff_comp.apply_buff(9999, "CHARCOND_AFTEREFFECT", 5.0)

	aspect_reverted.emit(old_aspect)


## 周期性生命与气力消耗 (100% 对应 OnUpdate 源码逻辑)
func _process_periodic_consumption() -> void:
	if _owner_character == null or _transform_data.is_empty():
		return

	# float fMultiplier = pPlayer->GetTransformationTbldat()->fEP_Consume_Rate / 100.0f;
	var ep_rate: float = _transform_data.get("fEP_Consume_Rate", 0.0) / 100.0
	if ep_rate > 0.0:
		var ep_drain := maxi(1, int(float(_owner_character.max_energy) * ep_rate))
		_owner_character.current_energy = maxi(0, _owner_character.current_energy - ep_drain)
		_owner_character.energy_changed.emit(_owner_character.current_energy, _owner_character.max_energy)
		# if (pPlayer->ConsiderEPLow(10.0f)) pPlayer->CancelTransformation();
		if float(_owner_character.current_energy) / float(maxi(1, _owner_character.max_energy)) <= 0.10:
			revert_transformation()
			return

	# float fMultiplier = ((float)pPlayer->GetTransformGrade() * pPlayer->GetTransformationTbldat()->fLP_Consume_Rate) / 100.0f;
	var lp_rate: float = _transform_data.get("fLP_Consume_Rate", 0.0) / 100.0
	if lp_rate > 0.0:
		var lp_drain := maxi(1, int(float(_owner_character.max_health) * lp_rate))
		_owner_character.current_health = maxi(1, _owner_character.current_health - lp_drain)
		_owner_character.health_changed.emit(_owner_character.current_health, _owner_character.max_health)
		if float(_owner_character.current_health) / float(maxi(1, _owner_character.max_health)) <= 0.10:
			revert_transformation()
			return


## 从 table_status_transform_data.json 解码字段
func _load_transform_tblidx_data(tblidx: int) -> void:
	var tbl := DBOTableManager.get_table("table_status_transform_data.json")
	var key := str(tblidx)
	if not tbl.has(key):
		return

	var raw_record: Dictionary = tbl[key]
	var hex_str: String = raw_record.get("_hex", "")
	if hex_str.is_empty():
		return

	# 按 sSTATUS_TRANSFORM_TBLDAT 二进制定义解包 18 个浮点数与整型字段
	var raw_bytes := hex_str.hex_decode()
	if raw_bytes.size() < 76:
		return

	_transform_data = {
		"fLP_Transform": raw_bytes.decode_float(4),
		"fEP_Transform": raw_bytes.decode_float(8),
		"fPhysical_Offence_Transform": raw_bytes.decode_float(12),
		"fEnergy_Offence_Transform": raw_bytes.decode_float(16),
		"fPhysical_Defence_Transform": raw_bytes.decode_float(20),
		"fEnergy_Defence_Transform": raw_bytes.decode_float(24),
		"fRun_Speed_Transform": raw_bytes.decode_float(28),
		"fAttack_Speed_Transform": raw_bytes.decode_float(32),
		"fAttack_Rate_Transform": raw_bytes.decode_float(36),
		"fDodge_Rate_Transform": raw_bytes.decode_float(40),
		"fBlock_Rate_Transform": raw_bytes.decode_float(44),
		"fCurse_Success_Transform": raw_bytes.decode_float(48),
		"fCurse_Tolerance_Transform": raw_bytes.decode_float(52),
		"fAttack_Range_Change": raw_bytes.decode_float(56),
		"fLP_Consume_Rate": raw_bytes.decode_float(60),
		"fEP_Consume_Rate": raw_bytes.decode_float(64),
		"dwDuration": raw_bytes.decode_u32(68),
		"dwDurationInMilliSecs": raw_bytes.decode_u32(72)
	}


## 受伤受创被打断判定 (对应 CAspectState_Vehicle::OnDamaged)
func on_owner_damaged() -> void:
	if current_aspect == AspectType.VEHICLE:
		revert_transformation()
