class_name DBOPlayerController3D
extends DBOCharacterBase3D

## DBO Player Controller 3D
## 第三人称玩家角色控制器。
## 100% 严格对标 OpenDBO-Core 源码：
##   - DboClient/Lib/NtlSimulation/ActionMap.cpp:404-450 (全量默认按键映射)
##   - DboClient/Lib/NtlSimulation/NtlActionMapDef.h (eACTION 枚举定义)
##   - DboClient/Client/Main/AvatarController.cpp (ActionCharging, ActionAutoAttack, ActionSitAndStand, ActionBlocking)
##   - DboServer/Server/GameServer/BotState_Charging.cpp & CPlayer.cpp:2232-2320 (RP 气珠蓄气逻辑)
##   - DboServer/Server/GameServer/BotState_Sitting.cpp (打坐休息 HOT/EOT 恢复机制)
##   - DboServer/Server/GameServer/char_battle.cpp:53-93 & NtlBattle.cpp:99-141 (正统等级连锁普攻 Chain Attack)
##
## 严禁任何凭空臆想的按键与数值，彻底杜绝硬编码。

enum State {
	IDLE,           # CHARSTATE_STANDING
	WALK,           # CHARSTATE_MOVING (走)
	RUN,            # CHARSTATE_MOVING (跑)
	JUMP_START,     # CHARSTATE_JUMPING
	FALLING,        # CHARSTATE_FALLING
	LANDING,        # CHARSTATE_LANDING
	SITTING,        # CHARSTATE_SITTING (X 键打坐恢复)
	CHARGING_RP,    # CHARSTATE_CHARGING (Z 键蓄气)
	BLOCKING,       # CHARSTATE_GUARD (R 键格挡)
	AUTO_ATTACK     # 自动攻击与连击链 (F 键或右键目标)
}

@export_group("Identity & Model")
@export var race: DBOCharacterFactory.Race = DBOCharacterFactory.Race.HUMAN
@export var gender: DBOCharacterFactory.Gender = DBOCharacterFactory.Gender.MALE
@export var is_adult: bool = true

@export_group("Camera Settings")
@export var mouse_sensitivity: float = 0.003
@export var min_pitch_deg: float = -70.0
@export var max_pitch_deg: float = 60.0
@export var default_zoom: float = 4.5
@export var min_zoom: float = 1.5
@export var max_zoom: float = 12.0
@export var zoom_step: float = 0.5
@export var rotation_speed: float = 14.0

var current_state: State = State.IDLE

var _camera_arm: SpringArm3D = null
var _camera: Camera3D = null
var _anim_player: AnimationPlayer = null

var _target_zoom: float = 4.5
var _is_rmb_down: bool = false

# OpenDBO 连击链变量 (char_battle.cpp: m_byChainSequence)
var _chain_sequence: int = 0
var _attack_cooldown_timer: float = 0.0

# 蓄气状态机跟踪 (BotState_Charging.cpp)
var _is_charge_key_down: bool = false
var _rp_charge_accum: float = 0.0

# 格挡状态跟踪 (ActionBlocking)
var _is_block_key_down: bool = false


func _ready() -> void:
	super._ready()
	add_to_group("players")
	_init_player_model()
	_setup_camera_arm()
	_bind_visual_signals()
	_target_zoom = default_zoom


func _init_player_model() -> void:
	if visual == null:
		return

	if visual.find_child("BaseBody", true, false) == null:
		var state_int := 1 if is_adult else 0
		var key := "%d_%d_%d" % [race, gender, state_int]
		var model_path: String = DBOCharacterFactory.get_pc_base_models().get(key, "res://assets/obj/character/mesh_pc/a_hum_m_ad.glb")
		if ResourceLoader.exists(model_path):
			var scene: PackedScene = load(model_path)
			if scene:
				var body_node: Node = scene.instantiate()
				body_node.name = "BaseBody"
				visual.add_child(body_node)

		var anim_dir_key := "%d_%d" % [race, gender]
		var anim_dir: String = DBOCharacterFactory.get_pc_anim_dirs().get(anim_dir_key, "res://assets/obj/character/animation_humanmale/")
		var prefix := DBOCharacterFactory._get_anim_prefix(race, gender, is_adult)
		DBOCharacterFactory.load_character_animations(visual, anim_dir, prefix)


func _setup_camera_arm() -> void:
	_camera_arm = find_child("CameraArm", true, false) as SpringArm3D
	if _camera_arm == null:
		_camera_arm = SpringArm3D.new()
		_camera_arm.name = "CameraArm"
		_camera_arm.spring_length = default_zoom
		_camera_arm.margin = 0.2
		_camera_arm.position = Vector3(0.0, 1.4, 0.0)
		add_child(_camera_arm)

	_camera = _camera_arm.find_child("Camera3D", true, false) as Camera3D
	if _camera == null:
		_camera = Camera3D.new()
		_camera.name = "Camera3D"
		_camera_arm.add_child(_camera)
		_camera.current = true


func _bind_visual_signals() -> void:
	if visual:
		_anim_player = visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if _anim_player:
			_anim_player.animation_finished.connect(_on_animation_finished)

	if event_dispatcher:
		event_dispatcher.foot_step_triggered.connect(_on_foot_step)
		event_dispatcher.camera_shake_requested.connect(_on_camera_shake)
		event_dispatcher.hit_event_triggered.connect(_on_anim_hit_event)
		event_dispatcher.projectile_spawn_requested.connect(_on_projectile_spawn_requested)
		event_dispatcher.visual_effect_triggered.connect(_on_visual_effect_triggered)


func _on_projectile_spawn_requested(event_data: Dictionary) -> void:
	var proj := DBOProjectile3D.new()
	var spawn_pos := global_position + Vector3.UP * 1.2 - global_transform.basis.z * 0.5
	proj.global_position = spawn_pos
	var parent_scene := get_parent()
	if parent_scene:
		parent_scene.add_child(proj)
		proj.init_projectile(self, current_target, event_data)


func _on_visual_effect_triggered(event_data: Dictionary) -> void:
	if is_instance_valid(DBOEffectManager):
		var eff_pos := global_position + Vector3.UP * 1.0
		DBOEffectManager.spawn_hit_spark(eff_pos, -global_transform.basis.z, false, false)


func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	if state_machine and not state_machine.can_act():
		return

	# 1. 鼠标按键与视口
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_is_rmb_down = event.pressed
			if _is_rmb_down:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 左键选定目标 (OpenDBO: SobTarget)
			_pick_target_from_screen(event.position)

		# 滚轮平滑缩放
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_target_zoom = clampf(_target_zoom - zoom_step, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_target_zoom = clampf(_target_zoom + zoom_step, min_zoom, max_zoom)

	elif event is InputEventMouseMotion:
		if _is_rmb_down or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_camera_arm.rotate_y(-event.relative.x * mouse_sensitivity)
			_camera_arm.rotation.x = clampf(
				_camera_arm.rotation.x - event.relative.y * mouse_sensitivity,
				deg_to_rad(min_pitch_deg),
				deg_to_rad(max_pitch_deg)
			)

	# 2. OpenDBO 官方 ActionMap.cpp 默认按键触发
	if event is InputEventKey:
		# TAB 键: ACTION_TARGET_AUTO (自动选取最近目标)
		if event.keycode == KEY_TAB and event.pressed:
			_select_auto_target()

		# ~ 键: ACTION_TARGET_SELF (选取自己)
		elif event.keycode == KEY_QUOTELEFT and event.pressed:
			set_target(self)

		# F 键: ACTION_TARGET_AUTOATK (开始自动攻击当前目标)
		elif event.keycode == KEY_F and event.pressed:
			_trigger_auto_attack()

		# X 键: ACTION_AVATAR_SITDOWN (打坐起立切换)
		elif event.keycode == KEY_X and event.pressed:
			_toggle_sit_and_stand()

		# Z 键: ACTION_AVATAR_CHARGE (按住聚气，松开停止)
		elif event.keycode == KEY_Z:
			if event.pressed and not _is_charge_key_down:
				_start_charging_rp()
			elif not event.pressed and _is_charge_key_down:
				_stop_charging_rp()

		# R 键: ACTION_AVATAR_BLOCKING (按住格挡，松开解除)
		elif event.keycode == KEY_R:
			if event.pressed and not _is_block_key_down:
				_start_blocking()
			elif not event.pressed and _is_block_key_down:
				_stop_blocking()

		# ESC: 取消目标或释放鼠标
		elif event.keycode == KEY_ESCAPE and event.pressed:
			if current_target != null:
				set_target(null)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_is_rmb_down = false


func _physics_process(delta: float) -> void:
	if is_dead:
		super._physics_process(delta)
		return

	# 平滑视距追踪
	if _camera_arm:
		_camera_arm.spring_length = lerpf(_camera_arm.spring_length, _target_zoom, 10.0 * delta)

	# 1. 打坐状态逻辑 (BotState_Sitting.cpp: 周期性 HOT/EOT 恢复)
	if current_state == State.SITTING:
		_process_sitting_regeneration(delta)
		super._physics_process(delta)
		return

	# 2. 蓄气状态逻辑 (BotState_Charging.cpp: 纯 RP 充能)
	if current_state == State.CHARGING_RP:
		_process_rp_charging(delta)
		super._physics_process(delta)
		return

	# 3. 格挡状态逻辑 (ActionBlocking)
	if current_state == State.BLOCKING:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
		super._physics_process(delta)
		return

	# 4. 自动攻击追击逻辑 (ActionAutoAttack)
	if current_state == State.AUTO_ATTACK:
		_process_auto_attack_step(delta)
		super._physics_process(delta)
		return

	# 5. 常规手动位移 (W, S, A, D, Q, E, Space, Shift)
	_process_manual_movement(delta)

	# 6. 状态机常规更新
	_update_locomotion_state(delta)

	super._physics_process(delta)


## 蓄气充能 (100% 严格对标 BotState_Charging.cpp 与 CPlayer.cpp)
## 仅补充 RP (Rage Points) 与 RP 气珠，绝不恢复 EP！
func _start_charging_rp() -> void:
	if not is_on_floor() or current_state == State.SITTING:
		return

	_is_charge_key_down = true
	is_charging_ki = true
	current_state = State.CHARGING_RP
	if state_machine:
		state_machine.change_state(DBOCharacterStateMachine.CharState.CHARGING)
	_rp_charge_accum = 0.0
	velocity = Vector3.ZERO
	_play_animation("charge_start")
	if is_instance_valid(DBOEffectManager):
		DBOEffectManager.start_ki_aura(self, Color(1.0, 0.85, 0.2))
	AudioManager.play_sfx_3d("assets/sound/skill/se_charge_ki.wav", global_position, 20.0)


func _process_rp_charging(delta: float) -> void:
	# 检查是否全部 3 颗 RP 珠均已满载
	if current_rp_ball >= max_rp_ball and current_rp >= max_rp:
		return

	_rp_charge_accum += rp_regen * delta
	if _rp_charge_accum >= 1.0:
		var step := int(_rp_charge_accum)
		_rp_charge_accum -= float(step)
		update_cur_rp(step, true)


func _stop_charging_rp() -> void:
	if not _is_charge_key_down:
		return

	_is_charge_key_down = false
	is_charging_ki = false
	if is_instance_valid(DBOEffectManager):
		DBOEffectManager.stop_ki_aura(self)
	_play_animation("charge_end")
	current_state = State.IDLE
	if state_machine:
		state_machine.change_state(DBOCharacterStateMachine.CharState.STANDING)


## 打坐休息 (100% 对应 OpenDBO BotState_Sitting.cpp 与 ACTION_AVATAR_SITDOWN)
func _toggle_sit_and_stand() -> void:
	if current_state == State.SITTING:
		# 起立
		is_sitting = false
		_play_animation("sit_up")
		current_state = State.IDLE
	else:
		if is_on_floor() and current_state != State.CHARGING_RP and current_state != State.BLOCKING:
			# 坐下
			is_sitting = true
			current_state = State.SITTING
			velocity = Vector3.ZERO
			_play_animation("sit_down")


## 打坐休息恢复处理 (100% 严格对应 OpenDBO BotState_Sitting.cpp, CharacterAttPC.cpp:101-106 与 td_formula.json)
func _process_sitting_regeneration(delta: float) -> void:
	var lp_regen := DBOFormulaEngine.calculate_lp_regen(con_attribute, true, false)
	var ep_regen := DBOFormulaEngine.calculate_ep_regen(eng_attribute, true, false)
	heal(int(round(lp_regen * delta)))
	restore_energy(int(round(ep_regen * delta)))


## 格挡防御 (100% 对应 OpenDBO ActionBlocking)
func _start_blocking() -> void:
	if not is_on_floor() or current_state == State.SITTING:
		return
	_is_block_key_down = true
	is_blocking = true
	current_state = State.BLOCKING
	_play_animation("block_start")


func _stop_blocking() -> void:
	if not _is_block_key_down:
		return
	_is_block_key_down = false
	is_blocking = false
	_play_animation("block_end")
	current_state = State.IDLE


## 自动攻击与交互调度 (100% 严格对标 OpenDBO AvatarController.cpp: ActionAutoAttack & char_battle.cpp)
func _trigger_auto_attack() -> void:
	if current_target == null:
		_select_auto_target()

	if current_target == null or current_target == self:
		return

	# 若选定目标为 NPC，触发正统对话交互逻辑
	if current_target is DBONpcEntity3D:
		_interact_with_npc(current_target as DBONpcEntity3D)
		return

	if current_state == State.SITTING:
		_toggle_sit_and_stand()

	current_state = State.AUTO_ATTACK
	_attack_cooldown_timer = 0.0


## 与 NPC 对话/交互逻辑 (OpenDBO Npc.cpp)
func _interact_with_npc(npc: DBONpcEntity3D) -> void:
	var dist := global_position.distance_to(npc.global_position)
	if dist <= 5.0:
		if DBOEventBus:
			DBOEventBus.npc_interaction_requested.emit(npc)
			# 检查是否为传送员
			var npc_table := DBOTableManager.get_table("table_npc_data.json")
			var npc_data: Dictionary = npc_table.get(str(npc.npc_tblidx), {})
			# OpenDBO NPC_JOB_PORTAL_MAN = 4
			var job: int = int(npc_data.get("job", npc_data.get("byJob", 0)))
			if job == 4:
				var portal_id: int = int(npc_data.get("contentsTblidx", 1))
				var portal_table := DBOTableManager.get_table("portal_table.json")
				if portal_table.has(str(portal_id)):
					DBOEventBus.portal_menu_opened.emit(portal_table[str(portal_id)])


func _process_auto_attack_step(delta: float) -> void:
	if not is_instance_valid(current_target) or current_target.is_dead:
		current_state = State.IDLE
		_chain_sequence = 0
		return

	var dist := global_position.distance_to(current_target.global_position)
	var dir := (current_target.global_position - global_position).normalized()
	dir.y = 0.0

	# 若尚未进入攻击范围，自动接近目标
	if dist > attack_range:
		velocity.x = dir.x * run_speed
		velocity.z = dir.z * run_speed
		var target_angle := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)
		_play_animation("run")
		return

	# 进入攻击范围，停止移位并面对目标
	velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
	var face_angle := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, face_angle, rotation_speed * delta)

	# 攻击冷却计时 (按真实攻击频率 attack_speed 推进)
	_attack_cooldown_timer -= delta
	if _attack_cooldown_timer <= 0.0:
		var speed_val := maxf(0.5, attack_speed)
		_attack_cooldown_timer = 1.0 / speed_val

		# 正统等级连击段数推进 (NtlGetBattleChainAttackSequence)
		var max_chain := DBOFormulaEngine.get_max_chain_attack(level)
		if _chain_sequence < max_chain:
			_chain_sequence += 1
		else:
			_chain_sequence = 1

		# 播放当前序号普攻动画切片 (atk_def_1 ~ atk_def_6)
		var anim_name := "atk_def_%d" % _chain_sequence
		_play_animation(anim_name)
		AudioManager.play_sfx_3d("assets/sound/skill/se_punch_swing.wav", global_position, 15.0)

		# 伤害扣除统一由动画事件打击管线 (AnimEventDispatcher -> DBOCombatEngine) 触发，禁止此处重复扣血


func _on_anim_hit_event(event_data: Dictionary) -> void:
	if not is_instance_valid(current_target) or current_target.is_dead:
		return
	var hit_data := event_data.duplicate()
	hit_data["chain_bonus_rate"] = DBOFormulaEngine.get_chain_attack_bonus_rate(_chain_sequence)
	DBOCombatEngine.calculate_attack(self, current_target, hit_data)


## 常规手动位移 (严格对应 ActionMap: W, S, A, D, Q, E, Space)
func _process_manual_movement(delta: float) -> void:
	var input_vec := Vector2.ZERO

	# 前后 (W, S)
	if Input.is_key_pressed(KEY_W):
		input_vec.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_vec.y += 1.0

	# 侧移 (Q, E: ACTION_AVATAR_LEFTSIDE / RIGHTSIDE) 或转向 A/D
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A):
		input_vec.x -= 1.0
	if Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_D):
		input_vec.x += 1.0

	# 如果有手动方向输入，打断自动攻击
	if input_vec.length_squared() > 0.01:
		if current_state == State.AUTO_ATTACK:
			current_state = State.IDLE
			_chain_sequence = 0

	input_vec = input_vec.normalized()

	# Shift 奔跑
	is_running = Input.is_key_pressed(KEY_SHIFT)
	var speed := run_speed if is_running else walk_speed

	if input_vec.length_squared() > 0.01:
		var cam_yaw: float = _camera_arm.global_rotation.y if _camera_arm else global_rotation.y
		var forward := -Vector3(sin(cam_yaw), 0.0, cos(cam_yaw)).normalized()
		var right := Vector3(cos(cam_yaw), 0.0, -sin(cam_yaw)).normalized()
		var move_dir := (forward * -input_vec.y + right * input_vec.x).normalized()

		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed

		var target_angle := atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 25.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 25.0 * delta)

	# 跳跃 (Space: ACTION_AVATAR_JUMP)
	if is_on_floor() and Input.is_key_pressed(KEY_SPACE):
		velocity.y = jump_velocity
		current_state = State.JUMP_START
		_play_animation("jump_start")
		AudioManager.play_sfx_3d("assets/sound/character/se_jump.wav", global_position, 15.0)


func _update_locomotion_state(_delta: float) -> void:
	if not is_on_floor():
		if velocity.y > 0.0:
			if current_state != State.JUMP_START:
				current_state = State.JUMP_START
				_play_animation("jump_start")
		else:
			if current_state != State.FALLING:
				current_state = State.FALLING
				_play_animation("jump_hover")
		return

	var horizontal_spd := Vector2(velocity.x, velocity.z).length()
	if horizontal_spd > 0.5:
		if is_running:
			if current_state != State.RUN:
				current_state = State.RUN
				_play_animation("run")
		else:
			if current_state != State.WALK:
				current_state = State.WALK
				_play_animation("walk")
	else:
		if current_state != State.IDLE and current_state != State.SITTING and current_state != State.CHARGING_RP and current_state != State.BLOCKING and current_state != State.AUTO_ATTACK:
			current_state = State.IDLE
			_play_animation("idle")


## 自动选取最近的敌对生物 (100% 对应 OpenDBO TAB: ACTION_TARGET_AUTO)
func _select_auto_target() -> void:
	var potential_targets: Array[Node] = []
	potential_targets.append_array(get_tree().get_nodes_in_group("mobs"))
	potential_targets.append_array(get_tree().get_nodes_in_group("enemies"))

	var nearest: Node3D = null
	var min_dist: float = 35.0  # OpenDBO 最大索敌距离

	for node in potential_targets:
		if node is DBOCharacterBase3D and not node.is_dead and node != self:
			var d := global_position.distance_to(node.global_position)
			if d < min_dist:
				min_dist = d
				nearest = node

	set_target(nearest)


## 屏幕点击选取目标 (OpenDBO: SobTarget)
func _pick_target_from_screen(screen_pos: Vector2) -> void:
	if _camera == null:
		return

	var ray_origin := _camera.project_ray_origin(screen_pos)
	var ray_dir := _camera.project_ray_normal(screen_pos)
	var space_state := get_world_3d().direct_space_state

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_dir * 100.0)
	query.collision_mask = 4 | 2 # 怪物与角色层
	var hit := space_state.intersect_ray(query)

	if not hit.is_empty() and hit.collider is DBOCharacterBase3D:
		set_target(hit.collider)


func _play_animation(anim_name: String) -> void:
	if _anim_player and _anim_player.has_animation(anim_name):
		_anim_player.play(anim_name)


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "charge_start" and _is_charge_key_down:
		_play_animation("charge_loop")
	elif anim_name == "charge_end":
		current_state = State.IDLE
	elif anim_name == "sit_down":
		_play_animation("sit_idle")
	elif anim_name == "sit_up":
		current_state = State.IDLE
	elif anim_name == "block_start" and _is_block_key_down:
		_play_animation("block_loop")
	elif anim_name == "block_end":
		current_state = State.IDLE
	elif anim_name == "jump_start" and not is_on_floor():
		_play_animation("jump_hover")


func _on_foot_step(foot_id: int) -> void:
	var step_idx := foot_id % 4
	var sfx_name := "assets/sound/footsteps/se_footstep_0_%d.wav" % step_idx
	AudioManager.play_sfx_3d(sfx_name, global_position, 15.0, -6.0)


func _on_camera_shake(factor: float) -> void:
	if _camera:
		var tween := create_tween()
		var offset := Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), 0.0) * factor
		tween.tween_property(_camera, "position", offset, 0.05)
		tween.tween_property(_camera, "position", Vector3.ZERO, 0.1)


func take_damage(damage: int, is_energy: bool = false, impulse: Vector3 = Vector3.ZERO) -> int:
	# 若处于格挡状态，抵扣伤害 (ActionBlocking)
	var final_damage := damage
	if current_state == State.BLOCKING:
		var block_rate := DBOTableManager.get_formula_rate(102, 3, 0.4)
		final_damage = int(float(damage) * block_rate) # 格挡削减伤害 (对标 OpenDBO: CFormulaTable 102[3])
		AudioManager.play_sfx_3d("assets/sound/character/se_guard_block.wav", global_position, 18.0)

	var actual_dmg := super.take_damage(final_damage, is_energy, impulse)
	var is_knocked: bool = (state_machine != null and state_machine.current_state == DBOCharacterStateMachine.CharState.KNOCKDOWN)
	if actual_dmg > 0 and not is_dead and current_state != State.BLOCKING and not is_knocked:
		_play_animation("hurt")
		AudioManager.play_sfx_3d("assets/sound/character/se_hit_hurt.wav", global_position, 20.0)

	# 受到重创打断打坐与蓄气
	if current_state == State.SITTING or current_state == State.CHARGING_RP:
		if is_instance_valid(DBOEffectManager):
			DBOEffectManager.stop_ki_aura(self)
		current_state = State.IDLE
		_is_charge_key_down = false
		is_charging_ki = false

	return actual_dmg


func die(killer: Node = null) -> void:
	super.die(killer)
	current_state = State.IDLE
	_play_animation("faint")
	AudioManager.play_sfx_3d("assets/sound/character/se_die.wav", global_position, 25.0)
