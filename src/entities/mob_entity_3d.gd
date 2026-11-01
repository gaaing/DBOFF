class_name DBOMobEntity3D
extends DBOCharacterBase3D

## DBO Mob Entity 3D
## 野外怪物与敌对生物实体。
## 严格对标 OpenDBO-Core:
##   - DboServer/Server/GameServer/CMonster.h & CMonster.cpp
##   - DboServer/Server/GameServer/BotAiState.cpp (CBotAiState_Patrol, CBotAiState_Chase, CBotAiState_Attack)
##   - DboShared/NtlGameTable/MobTable.h (sMOB_TBLDAT)
##
## 架构特性：
## 1. 严格从 DBOTableManager (table_mob_data.json) 动态初始化各项基础数值与模型标识。
## 2. 怪物族系动画与网格由 DBOCharacterFactory 动态装配。
## 3. 完整的经典 AI 状态机（待机、巡逻游荡、仇恨追逐、近战打击、脱战回血、死亡刷新）。

enum AIState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	RETURN_SPAWN,
	DEAD
}

@export_group("Mob Configuration")
@export var mob_tblidx: int = 1211101
@export var aggro_radius: float = 12.0
@export var attack_radius: float = 2.2
@export var patrol_radius: float = 10.0
@export var return_radius_limit: float = 30.0
@export var respawn_time: float = 12.0

var ai_state: AIState = AIState.IDLE
var spawn_position: Vector3 = Vector3.ZERO
var target_enemy: Node3D = null

var _anim_player: AnimationPlayer = null
var _state_timer: float = 0.0
var _patrol_dest: Vector3 = Vector3.ZERO
var _attack_cooldown: float = 0.0


func _ready() -> void:
	add_to_group("mobs")
	add_to_group("enemies")
	spawn_position = global_position
	_load_mob_table_data()
	_assemble_visual()
	super._ready()


func _load_mob_table_data() -> void:
	var mob_data := DBOTableManager.get_mob_data(mob_tblidx)
	if mob_data.is_empty():
		return

	character_name = DBOLocalizer.get_text("MOB_DATA", mob_tblidx)
	if character_name.is_empty():
		character_name = mob_data.get("model", "Mob")

	level = mob_data.get("level", 1)
	character_property_id = mob_data.get("model", "")
	max_health = mob_data.get("basic_lp", 1000)
	current_health = max_health
	max_energy = mob_data.get("basic_ep", 500)
	current_energy = max_energy
	physical_defence = mob_data.get("basic_physical_defence", 20)
	energy_defence = mob_data.get("basic_energy_defence", 20)


func _assemble_visual() -> void:
	# 若尚未附加视觉节点，通过工厂构建
	if visual == null or visual.get_child_count() == 0:
		var mob_vis := DBOCharacterFactory.build_mob_visual(mob_tblidx)
		if mob_vis:
			if visual:
				visual.queue_free()
			visual = mob_vis
			add_child(visual)

	_anim_player = visual.find_child("AnimationPlayer", true, false) as AnimationPlayer


func _physics_process(delta: float) -> void:
	if is_dead or ai_state == AIState.DEAD:
		super._physics_process(delta)
		return

	# 硬控或击倒状态下冻结怪物 AI 自主决策与位移
	if state_machine and state_machine.is_action_blocked():
		super._physics_process(delta)
		return

	_state_timer -= delta
	_attack_cooldown -= delta

	match ai_state:
		AIState.IDLE:
			_process_idle_state(delta)
		AIState.PATROL:
			_process_patrol_state(delta)
		AIState.CHASE:
			_process_chase_state(delta)
		AIState.ATTACK:
			_process_attack_state(delta)
		AIState.RETURN_SPAWN:
			_process_return_state(delta)

	super._physics_process(delta)


func _process_idle_state(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 10.0)
	velocity.z = move_toward(velocity.z, 0.0, 10.0)
	_play_anim("idle")

	# 检查感知范围内的敌人 (寻找玩家)
	_scan_for_enemies()
	if target_enemy:
		ai_state = AIState.CHASE
		return

	# 待机计时结束，随机巡逻
	if _state_timer <= 0.0:
		_state_timer = randf_range(3.0, 6.0)
		_pick_random_patrol_point()
		ai_state = AIState.PATROL


func _process_patrol_state(delta: float) -> void:
	_scan_for_enemies()
	if target_enemy:
		ai_state = AIState.CHASE
		return

	var dist_to_dest := global_position.distance_to(_patrol_dest)
	if dist_to_dest < 1.0 or _state_timer <= 0.0:
		ai_state = AIState.IDLE
		_state_timer = randf_range(2.0, 5.0)
		return

	var dir := (_patrol_dest - global_position).normalized()
	dir.y = 0.0
	velocity.x = dir.x * walk_speed
	velocity.z = dir.z * walk_speed

	var target_angle := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 10.0 * delta)
	_play_anim("walk")


func _process_chase_state(delta: float) -> void:
	if not is_instance_valid(target_enemy) or target_enemy.is_dead:
		target_enemy = null
		ai_state = AIState.RETURN_SPAWN
		return

	# 超出追逐脱战距离
	var dist_from_spawn := global_position.distance_to(spawn_position)
	if dist_from_spawn > return_radius_limit:
		target_enemy = null
		ai_state = AIState.RETURN_SPAWN
		return

	var dist_to_target := global_position.distance_to(target_enemy.global_position)
	if dist_to_target <= attack_radius:
		ai_state = AIState.ATTACK
		_attack_cooldown = 0.0
		return

	var dir := (target_enemy.global_position - global_position).normalized()
	dir.y = 0.0
	velocity.x = dir.x * run_speed
	velocity.z = dir.z * run_speed

	var target_angle := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 12.0 * delta)
	_play_anim("run")


func _process_attack_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 15.0)
	velocity.z = move_toward(velocity.z, 0.0, 15.0)

	if not is_instance_valid(target_enemy) or target_enemy.is_dead:
		target_enemy = null
		ai_state = AIState.RETURN_SPAWN
		return

	var dist := global_position.distance_to(target_enemy.global_position)
	if dist > attack_radius + 1.0:
		ai_state = AIState.CHASE
		return

	# 面向攻击目标
	var dir := (target_enemy.global_position - global_position).normalized()
	dir.y = 0.0
	var target_angle := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 15.0 * delta)

	# 攻击冷却判定 (按攻击频率触发)
	if _attack_cooldown <= 0.0:
		_attack_cooldown = 1.0 / maxf(0.5, attack_speed)
		# OpenDBO: Mobs randomly select main or secondary attack (rand() % 2)
		var seq := 1 if randf() > 0.5 else 2
		var atk_anim := "atk_def_%d" % seq
		_play_anim(atk_anim)
		AudioManager.play_sfx_3d("assets/sound/monster/se_mob_attack.wav", global_position, 18.0)

		# 严格按 DBOFormulaEngine 公式结算打击伤害，杜绝随机数硬编码
		if target_enemy.has_method("take_damage"):
			var strike := DBOFormulaEngine.resolve_battle_strike(self, target_enemy, false)
			if strike.get("is_hit", false):
				target_enemy.take_damage(strike["final_damage"], false, dir * 4.0)


func _process_return_state(delta: float) -> void:
	var dist := global_position.distance_to(spawn_position)
	if dist < 1.0:
		ai_state = AIState.IDLE
		current_health = max_health  # 脱战生命全额恢复 (OpenDBO 原版机制)
		return

	var dir := (spawn_position - global_position).normalized()
	dir.y = 0.0
	velocity.x = dir.x * run_speed
	velocity.z = dir.z * run_speed

	var target_angle := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 10.0 * delta)
	_play_anim("run")


func _scan_for_enemies() -> void:
	if target_enemy != null:
		return

	# 检索范围内的玩家实体
	var players := get_tree().get_nodes_in_group("players")
	for p: Node3D in players:
		if is_instance_valid(p) and not p.is_dead:
			var dist := global_position.distance_to(p.global_position)
			if dist <= aggro_radius:
				target_enemy = p
				break


func _pick_random_patrol_point() -> void:
	var angle := randf() * TAU
	var radius := randf_range(2.0, patrol_radius)
	_patrol_dest = spawn_position + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)


func _play_anim(anim_name: String) -> void:
	if _anim_player and _anim_player.has_animation(anim_name):
		if _anim_player.current_animation != anim_name:
			_anim_player.play(anim_name)


## 受到攻击反击仇恨唤醒 (100% 对标 OpenDBO: CMonster::OnAttacked)
func on_attacked_by(attacker: DBOCharacterBase3D) -> void:
	if is_dead or attacker == null or attacker == self:
		return

	target_enemy = attacker
	# 若正处于闲逛、待机或归位状态，立刻转入战斗追击
	if ai_state in [AIState.IDLE, AIState.PATROL, AIState.RETURN_SPAWN]:
		ai_state = AIState.CHASE
		_state_timer = 15.0 # 追逐超时时间


## 怪物受击与受击动画
func take_damage(damage: int, is_energy: bool = false, impulse: Vector3 = Vector3.ZERO) -> int:
	var actual_dmg := super.take_damage(damage, is_energy, impulse)
	var is_knocked := (state_machine and state_machine.current_state == DBOCharacterStateMachine.CharState.KNOCKDOWN)
	if actual_dmg > 0 and not is_dead and not is_knocked:
		_play_anim("hurt")
		if is_instance_valid(AudioManager):
			AudioManager.play_sfx_3d("assets/sound/monster/se_mob_hurt.wav", global_position, 18.0)

	return actual_dmg


func die(killer: Node = null) -> void:
	super.die(killer)
	ai_state = AIState.DEAD
	_play_anim("faint")
	AudioManager.play_sfx_3d("assets/sound/monster/se_mob_die.wav", global_position, 20.0)

	# 启动重生计时
	get_tree().create_timer(respawn_time).timeout.connect(_respawn)


func _respawn() -> void:
	is_dead = false
	current_health = max_health
	current_energy = max_energy
	global_position = spawn_position
	ai_state = AIState.IDLE
	_play_anim("idle")
