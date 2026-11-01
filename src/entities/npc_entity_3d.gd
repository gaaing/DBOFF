class_name DBONpcEntity3D
extends DBOCharacterBase3D

## DBO NPC Entity 3D
## 大世界城镇与野外 NPC 实体。
## 严格对标 OpenDBO-Core:
##   - DboServer/Server/GameServer/CNpc.h & CNpc.cpp
##   - DboShared/NtlGameTable/NpcTable.h (sNPC_TBLDAT)
##   - DboClient/Client/Stage/WorldStage.cpp
##
## 架构特性：
## 1. 严格从 DBOTableManager (table_npc_data.json) 动态初始化各项基础数值与模型标识。
## 2. 文本名由 DBOLocalizer (NPC_DATA) 驱动，杜绝硬编码。
## 3. 玩家靠近自动注视打招呼（Soc Courtesy / Hi），支持交互触发信号。

signal interaction_requested(npc_tblidx: int, player: Node3D)

@export_group("NPC Configuration")
@export var npc_tblidx: int = 1111101
@export var interaction_distance: float = 3.5
@export var turn_speed: float = 8.0

var _anim_player: AnimationPlayer = null
var _original_rotation_y: float = 0.0
var _current_target_player: Node3D = null


func _ready() -> void:
	_original_rotation_y = rotation.y
	_load_npc_table_data()
	_assemble_visual()
	super._ready()


func _load_npc_table_data() -> void:
	var npc_data := DBOTableManager.get_npc_data(npc_tblidx)
	if npc_data.is_empty():
		return

	character_name = DBOLocalizer.get_text("NPC_DATA", npc_tblidx)
	if character_name.is_empty():
		character_name = npc_data.get("model", "NPC")

	level = npc_data.get("level", 1)
	max_health = npc_data.get("basic_lp", 2000)
	current_health = max_health
	max_energy = npc_data.get("basic_ep", 1000)
	current_energy = max_energy


func _assemble_visual() -> void:
	if visual == null or visual.get_child_count() == 0:
		var npc_vis := DBOCharacterFactory.build_npc_visual(npc_tblidx)
		if npc_vis:
			if visual:
				visual.queue_free()
			visual = npc_vis
			add_child(visual)

	_anim_player = visual.find_child("AnimationPlayer", true, false) as AnimationPlayer


func _physics_process(delta: float) -> void:
	if is_dead:
		super._physics_process(delta)
		return

	_check_player_proximity(delta)
	super._physics_process(delta)


func _check_player_proximity(delta: float) -> void:
	# 检查附近是否有玩家进入交互范围
	var players := get_tree().get_nodes_in_group("players")
	var nearest_player: Node3D = null
	var min_dist: float = interaction_distance

	for p: Node3D in players:
		if is_instance_valid(p) and not p.is_dead:
			var d := global_position.distance_to(p.global_position)
			if d <= min_dist:
				min_dist = d
				nearest_player = p

	if nearest_player:
		# 首次进入范围，播放问候动作与声音
		if _current_target_player == null:
			_play_greeting()
		_current_target_player = nearest_player

		# 转向玩家
		var dir := (nearest_player.global_position - global_position).normalized()
		dir.y = 0.0
		var target_angle := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, turn_speed * delta)
	else:
		if _current_target_player != null:
			_current_target_player = null
			_play_anim("idle")

		# 慢慢回正至原始角度
		rotation.y = lerp_angle(rotation.y, _original_rotation_y, 4.0 * delta)


func _play_greeting() -> void:
	if _anim_player:
		if _anim_player.has_animation("soc_hi"):
			_anim_player.play("soc_hi")
		elif _anim_player.has_animation("soc_courtesy"):
			_anim_player.play("soc_courtesy")

	AudioManager.play_sfx_3d("assets/sound/npc/se_npc_greet.wav", global_position, 15.0)


func interact(player: Node3D) -> void:
	interaction_requested.emit(npc_tblidx, player)


func _play_anim(anim_name: String) -> void:
	if _anim_player and _anim_player.has_animation(anim_name):
		_anim_player.play(anim_name)
