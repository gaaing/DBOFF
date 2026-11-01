class_name DBOCharacterBase3D
extends CharacterBody3D

## DBO Character Base 3D
## 所有玩家、NPC、怪物实体的物理与数值交互基类。
## 挂载 Jolt 3D 物理运动、重力下坠、受击冲量计算，并聚合视觉换装与帧事件系统。

signal health_changed(current_hp: int, max_hp: int)
signal energy_changed(current_ep: int, max_ep: int)
signal rp_changed(current_rp: int, max_rp: int)
signal rp_ball_changed(current_balls: int, max_balls: int)
signal target_changed(new_target: Node3D)
signal died(killer: Node)

@export_group("Identity")
@export var character_name: String = "Goku"
@export var character_property_id: String = ""
@export var level: int = 1

@export_group("Attributes")
@export var max_health: int = 1000
@export var current_health: int = 1000
@export var max_energy: int = 500
@export var current_energy: int = 500

# OpenDBO 核心六维属性 (Str, Con, Foc, Dex, Sol, Eng)
@export var str_attribute: int = 10
@export var con_attribute: int = 10
@export var foc_attribute: int = 10
@export var dex_attribute: int = 10
@export var sol_attribute: int = 10
@export var eng_attribute: int = 10

# OpenDBO 正统 RP 气珠系统: 单颗珠 100 RP，上限 3 颗 RP 珠
@export var max_rp: int = 100
@export var current_rp: int = 0
@export var max_rp_ball: int = 3
@export var current_rp_ball: int = 0
@export var rp_regen: float = 20.0 # 每秒蓄气量

@export var physical_offence: int = 50
@export var physical_defence: int = 20
@export var energy_offence: int = 50
@export var energy_defence: int = 20
@export var attack_speed: float = 1.0 # 攻击频率 (次/秒)
@export var attack_range: float = 2.5 # 近战普通攻击距离 (米)

@export_group("Movement")
@export var walk_speed: float = 4.5
@export var run_speed: float = 9.0
@export var jump_velocity: float = 8.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

var is_running: bool = false
var is_charging_ki: bool = false
var is_sitting: bool = false
var is_blocking: bool = false
var is_dead: bool = false

var current_target: Node3D = null
var visual: DBOCharacterVisual = null
var event_dispatcher: AnimEventDispatcher = null
var state_machine: DBOCharacterStateMachine = null

# 受击击飞外力冲量 (Knockback Impulse)
var _external_velocity: Vector3 = Vector3.ZERO
var _hit_stop_timer: float = 0.0


func _ready() -> void:
	_init_components()
	_load_property_speeds()


func _init_components() -> void:
	# 状态机挂载与生命周期管理
	state_machine = find_child("DBOCharacterStateMachine", true, false) as DBOCharacterStateMachine
	if state_machine == null:
		state_machine = DBOCharacterStateMachine.new()
		state_machine.name = "DBOCharacterStateMachine"
		add_child(state_machine)

	state_machine.knockdown_started.connect(_on_knockdown_started)
	state_machine.knockdown_ground_hit.connect(_on_knockdown_ground_hit)
	state_machine.knockdown_standup_started.connect(_on_knockdown_standup_started)
	state_machine.knockdown_recovered.connect(_on_knockdown_recovered)

	visual = find_child("DBOCharacterVisual", true, false) as DBOCharacterVisual
	if visual == null:
		visual = DBOCharacterVisual.new()
		visual.name = "DBOCharacterVisual"
		add_child(visual)

	event_dispatcher = visual.find_child("AnimEventDispatcher", true, false) as AnimEventDispatcher


func _load_property_speeds() -> void:
	if character_property_id.is_empty():
		return

	var prop := DBOTableManager.get_character_property(character_property_id)
	if not prop.is_empty():
		var spd: Dictionary = prop.get("speed", {})
		var w_spd: float = spd.get("walk_front", 0.0)
		var r_spd: float = spd.get("run_front", 0.0)
		if w_spd > 0.0:
			walk_speed = w_spd
		if r_spd > 0.0:
			run_speed = r_spd


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# 顿帧处理 (Hit Stop: 冻结当前帧物理与位移，提供打击钝挫手感)
	if _hit_stop_timer > 0.0:
		_hit_stop_timer -= delta
		return

	# 应用重力
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 衰减外力击退冲量
	if _external_velocity.length_squared() > 0.01:
		velocity.x += _external_velocity.x
		velocity.z += _external_velocity.z
		_external_velocity = _external_velocity.move_toward(Vector3.ZERO, 30.0 * delta)

	move_and_slide()


## 触发微顿帧 (Hit Stop / Frame Freeze)
func apply_hit_stop(duration: float = 0.05) -> void:
	_hit_stop_timer = duration


## 触发受击高亮闪白 (Hit Flash)
func trigger_hit_flash(duration: float = 0.12, flash_color: Color = Color.WHITE) -> void:
	if visual:
		visual.trigger_hit_flash(duration, flash_color)


## 触发正统击倒流程 (Knockdown)
func trigger_knockdown() -> void:
	if state_machine and not is_dead:
		state_machine.trigger_knockdown()


func _on_knockdown_started() -> void:
	if visual:
		visual.play_animation("knockdown_fall", 0.1)


func _on_knockdown_ground_hit() -> void:
	if visual:
		visual.play_animation("knockdown_idle", 0.1)
	if is_instance_valid(AudioManager):
		AudioManager.play_sfx_3d("assets/sound/character/se_hit_ground.wav", global_position, 20.0)


func _on_knockdown_standup_started() -> void:
	if visual:
		visual.play_animation("knockdown_standup", 0.15)


func _on_knockdown_recovered() -> void:
	if visual:
		visual.play_animation("idle", 0.2)


## 受击与伤害结算（参考 OpenDBO-Core 物理/能量抵扣机制）
func take_damage(damage: int, is_energy: bool = false, impulse: Vector3 = Vector3.ZERO) -> int:
	if is_dead:
		return 0

	# 无敌状态豁免
	if state_machine and state_machine.has_condition(DBOCharacterStateMachine.CharCondition.INVINCIBLE):
		return 0

	var def := energy_defence if is_energy else physical_defence
	var def_factor := DBOTableManager.get_formula_rate(3200, 1, 0.3)
	var actual_damage := maxi(1, damage - int(float(def) * def_factor))

	current_health = maxi(0, current_health - actual_damage)
	health_changed.emit(current_health, max_health)

	# 击退/击飞冲量
	if impulse.length_squared() > 0.1:
		apply_knockback(impulse)

	if current_health <= 0:
		die()

	return actual_damage


## 恢复生命 (100% 严格对应 OpenDBO-Core: CCharacter::UpdateCurLp 与 RecoverLp)
func heal(amount: int) -> int:
	if is_dead or amount <= 0:
		return 0
	var old_hp := current_health
	current_health = mini(max_health, current_health + amount)
	var recovered := current_health - old_hp
	if recovered > 0:
		health_changed.emit(current_health, max_health)
	return recovered


## 恢复气力 (100% 严格对应 OpenDBO-Core: CCharacter::UpdateCurEp 与 RecoverEp)
func restore_energy(amount: int) -> int:
	if is_dead or amount <= 0:
		return 0
	var old_ep := current_energy
	current_energy = mini(max_energy, current_energy + amount)
	var recovered := current_energy - old_ep
	if recovered > 0:
		energy_changed.emit(current_energy, max_energy)
	return recovered


## 更新 RP 气力与 RP 气珠 (100% 对应 OpenDBO-Core: CPlayer::UpdateCurRP & UpdateRpBall)
func update_cur_rp(diff: int, increase: bool = true) -> void:
	if increase:
		current_rp += diff
		while current_rp >= max_rp and current_rp_ball < max_rp_ball:
			current_rp -= max_rp
			current_rp_ball += 1
			rp_ball_changed.emit(current_rp_ball, max_rp_ball)
		if current_rp_ball >= max_rp_ball:
			current_rp = max_rp
	else:
		current_rp -= diff
		if current_rp < 0:
			if current_rp_ball > 0:
				current_rp_ball -= 1
				current_rp += max_rp
				rp_ball_changed.emit(current_rp_ball, max_rp_ball)
			else:
				current_rp = 0
	rp_changed.emit(current_rp, max_rp)


## 设置当前锁定目标 (100% 对应 OpenDBO-Core: Logic_SobTarget / OnTargetChanged)
func set_target(new_target: Node3D) -> void:
	if current_target != new_target:
		current_target = new_target
		target_changed.emit(new_target)


## 施加击飞冲量
func apply_knockback(impulse: Vector3) -> void:
	_external_velocity = impulse


## 角色阵亡处理
func die(killer: Node = null) -> void:
	if is_dead:
		return
	is_dead = true
	if state_machine:
		state_machine.change_state(DBOCharacterStateMachine.CharState.FAINTING)
	died.emit(killer)
	if visual:
		visual.play_animation("DEAD_01")
