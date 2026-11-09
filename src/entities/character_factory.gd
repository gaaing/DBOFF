class_name DBOCharacterFactory
extends RefCounted

## DBO Character Factory
## 负责大世界角色（玩家、NPC、怪物）的模块化解耦组装与轻量资源装配。
## 对标 OpenDBO-Core:
##   - DboClient/Lib/NtlPresentation/NtlPLCharacter.cpp (CNtlPLCharacter)
##   - DboClient/Lib/NtlPresentation/NtlPLItem.cpp (CNtlPLItem)
##   - DboServer/Server/GameServer/CPlayer.cpp & CMonster.cpp
##
## 架构特性：
## 1. 彻底解耦：网格部件、骨骼层级与独立动画切片分离，零冗余内存开销。
## 2. 纯动态解析：模型与动画路径从 DBOTableManager (table_item_data, table_mob_data, table_npc_data) 动态寻址。
## 3. 骨骼动画池：按需加载纯骨骼采样 GLB，动态注入 AnimationLibrary，杜绝一次性导入卡死。

enum Race {
	HUMAN = 0,
	NAMEK = 1,
	MAJIN = 2
}

enum Gender {
	MALE = 0,
	FEMALE = 1
}

enum BodyState {
	CHILD = 0,
	ADULT = 1
}

# 动画资源缓存池 (避免重复解析磁盘 GLB)
static var _anim_cache: Dictionary = {}

const CORE_ANIM_KEYS: Dictionary = {
	"idle": ["idle", "nml_idle_loop", "nml_idle_01", "idle1", "stand"],
	"walk": ["walk", "move_front"],
	"run": ["run", "run_front"],
	"walk_back": ["walk_back", "move_back"],
	"run_back": ["run_back"],
	"walk_left": ["move_left"],
	"walk_right": ["move_right"],
	"jump_start": ["jump_start"],
	"jump_hover": ["jump_hover", "jump_high_loop"],
	"jump_landing": ["jump_land", "jump_landing_short", "jump_landing_long"],
	"charge_start": ["basic_charge_start"],
	"charge_loop": ["basic_charge_loop"],
	"charge_end": ["basic_charge_end"],
	"sit_down": ["sit_down"],
	"sit_idle": ["sit_idle"],
	"sit_up": ["sit_standup"],
	"block_start": ["guard_start"],
	"block_loop": ["guard_loop"],
	"block_end": ["guard_end"],
	"attack_01": ["attack_1", "atk_01", "attack01", "combo_01", "atk_def_1"],
	"attack_02": ["attack_2", "atk_02", "attack02", "combo_02", "atk_def_2"],
	"attack_03": ["atk_03", "attack03", "combo_03", "atk_def_3"],
	"attack_04": ["atk_04", "attack04", "combo_04", "atk_def_4"],
	"attack_05": ["atk_05", "attack05", "combo_05", "atk_def_5"],
	"attack_06": ["atk_06", "attack06", "combo_06", "atk_def_6"],
	"hurt": ["hurt", "dmg_front", "hit_01"],
	"faint": ["faint", "die_front", "DEAD_01"],
	"knockdown_fall": ["knockdown", "knockdown_fall", "kd_fall"],
	"knockdown_idle": ["knockdown_idle", "kd_idle"],
	"knockdown_standup": ["stand_up", "knockdown_standup", "kd_standup"]
}

static func get_core_anim_keys() -> Dictionary:
	return CORE_ANIM_KEYS

static func get_pc_base_models() -> Dictionary:
	return {
		"0_0_1": "res://assets/obj/character/mesh_pc/a_hum_m_ad.glb",
		"0_1_1": "res://assets/obj/character/mesh_pc/a_hum_f_ad.glb",
		"1_0_1": "res://assets/obj/character/mesh_pc/a_nam_ad.glb",
		"2_0_1": "res://assets/obj/character/mesh_pc/a_maj_m_m.glb",
		"2_1_1": "res://assets/obj/character/mesh_pc/a_maj_m_f_ad.glb",
		"0_0_0": "res://assets/obj/character/mesh_pc/human_m_child.glb",
		"0_1_0": "res://assets/obj/character/mesh_pc/human_f_child.glb",
		"1_0_0": "res://assets/obj/character/mesh_pc/namek_m_child.glb",
		"2_0_0": "res://assets/obj/character/mesh_pc/majin_m_child.glb",
		"2_1_0": "res://assets/obj/character/mesh_pc/majin_f_child.glb"
	}

static func get_pc_anim_dirs() -> Dictionary:
	return {
		"0_0": "res://assets/obj/character/animation_humanmale/",
		"0_1": "res://assets/obj/character/animation_humanfemale/",
		"1_0": "res://assets/obj/character/animation_namek/",
		"2_0": "res://assets/obj/character/animation_majinmale/",
		"2_1": "res://assets/obj/character/animation_majinfemale/"
	}


## 检索素体模型路径（儿童与成人均使用基础素体，装备由独立装备系统挂载）
static func get_pc_model_path(race: int, gender: int, is_adult: bool, _prop_name: String = "") -> String:
	# 创角与选角使用儿童基础素体；初始服装由独立装备网格挂载。
	if not is_adult:
		match race:
			Race.HUMAN:
				return "res://assets/obj/character/mesh_pc/human_m_child.glb" if gender == Gender.MALE else "res://assets/obj/character/mesh_pc/human_f_child.glb"
			Race.NAMEK:
				return "res://assets/obj/character/mesh_pc/namek_m_child.glb"
			Race.MAJIN:
				return "res://assets/obj/character/mesh_pc/majin_m_child.glb" if gender == Gender.MALE else "res://assets/obj/character/mesh_pc/majin_f_child.glb"

	# 成人期素体模型寻址
	match race:
		Race.HUMAN:
			return "res://assets/obj/character/mesh_pc/a_hum_m_ad.glb" if gender == Gender.MALE else "res://assets/obj/character/mesh_pc/a_hum_f_ad.glb"
		Race.NAMEK:
			return "res://assets/obj/character/mesh_pc/a_nam_ad.glb"
		Race.MAJIN:
			return "res://assets/obj/character/mesh_pc/a_maj_m_m.glb" if gender == Gender.MALE else "res://assets/obj/character/mesh_pc/a_maj_m_f_ad.glb"

	return "res://assets/obj/character/mesh_pc/human_m_child.glb"


## 检索素体脚底地面高度校准值 (严格从 characterproperty.json 的 bone_data.pos_offset 提取)
static func get_pc_ground_offset(prop_name: String) -> float:
	var prop := DBOTableManager.get_character_property(prop_name)
	var bdata: Dictionary = prop.get("bone_data", {})
	var pos_off: Array = bdata.get("pos_offset", [0.0, 0.0, 0.0])
	return float(pos_off[1]) if pos_off.size() >= 2 else 0.0


## 检索官方素体脚底地面高程微调补偿 (保证各族儿童素体最低顶点 100% 严密贴合地面)
static func get_pc_foot_offset(race: int, gender: int, is_adult: bool) -> float:
	if is_adult:
		return 0.0
	match race:
		Race.HUMAN:
			return 0.038 if gender == Gender.MALE else 0.093
		Race.NAMEK:
			return -0.066
		Race.MAJIN:
			return 0.026 if gender == Gender.MALE else 0.005
	return 0.0


## 构建完整的玩家视觉节点 (DBOCharacterVisual)
static func build_player_visual(race: int = Race.HUMAN, gender: int = Gender.MALE, is_adult: bool = true) -> DBOCharacterVisual:
	var visual := DBOCharacterVisual.new()
	visual.name = "DBOCharacterVisual"
	visual.race = race
	visual.gender = gender
	visual.is_adult = is_adult

	# 查找官方角色属性并记录
	var prop_name := _get_pc_property_name(race, gender, is_adult)
	visual.character_property_name = prop_name

	var model_path: String = get_pc_model_path(race, gender, is_adult, prop_name)

	# 加载基础素体网格
	var base_scene: PackedScene = load(model_path)
	if base_scene:
		var base_inst: Node = base_scene.instantiate()
		base_inst.name = "BaseBody"
		# 统一脚底地面高度对齐
		if base_inst is Node3D:
			var foot_off := get_pc_foot_offset(race, gender, is_adult)
			(base_inst as Node3D).position.y = foot_off if not is_adult else get_pc_ground_offset(prop_name)
		# 剔除素体内部可能携带的动画播放器与动画树，保证素体之间零差异
		for ap in base_inst.find_children("*", "AnimationPlayer", true, false):
			ap.queue_free()
		for at in base_inst.find_children("*", "AnimationTree", true, false):
			at.queue_free()
		visual.add_child(base_inst)

	# 读取官方骨骼缩放配置 (characterproperty.json: bone_data.base_scale)
	var prop := DBOTableManager.get_character_property(prop_name)
	var bdata: Dictionary = prop.get("bone_data", {})
	var base_s: Array = bdata.get("base_scale", [0.65, 0.65, 0.65] if not is_adult else [1.0, 1.0, 1.0])
	if base_s.size() >= 3:
		visual.scale = Vector3(float(base_s[0]), float(base_s[1]), float(base_s[2]))
	else:
		visual.scale = Vector3(0.65, 0.65, 0.65) if not is_adult else Vector3.ONE

	# 加载角色官方骨骼动画库
	var anim_dir_key := "%d_%d" % [race, gender]
	var anim_dir: String = get_pc_anim_dirs().get(anim_dir_key, "res://assets/obj/character/animation_humanmale/")
	var prefix := _get_anim_prefix(race, gender, is_adult)
	load_character_animations(visual, anim_dir, prefix)

	# 材质 UV 与 Alpha 自动修正
	DBOMaterialHelper.fix_node_materials(visual)

	return visual


## 构建怪物视觉节点 (DBOCharacterVisual)
static func build_mob_visual(mob_tblidx: int) -> DBOCharacterVisual:
	var mob_data := DBOTableManager.get_mob_data(mob_tblidx)
	if mob_data.is_empty():
		push_warning("[DBOCharacterFactory] 找不到怪物数据: %d" % mob_tblidx)
		return null

	var visual := DBOCharacterVisual.new()
	visual.name = "DBOCharacterVisual_Mob_%d" % mob_tblidx

	var model_name: String = mob_data.get("model", "").to_lower().strip_edges()
	if not model_name.is_empty():
		var mesh_path := "res://assets/obj/character/mesh_mob/%s.glb" % model_name
		if ResourceLoader.exists(mesh_path):
			var mesh_scene: PackedScene = load(mesh_path)
			if mesh_scene:
				var mesh_inst: Node = mesh_scene.instantiate()
				mesh_inst.name = "MobBody"
				visual.add_child(mesh_inst)

		# 怪物动画目录匹配 (如 m_akm_a1 -> family 'm_akm')
		var family := _extract_mob_family(model_name)
		var anim_dir := "res://assets/obj/character/animation_mob/%s/" % family
		if DirAccess.dir_exists_absolute(anim_dir):
			load_mob_animations(visual, anim_dir, family)

	DBOMaterialHelper.fix_node_materials(visual)
	return visual


## 构建 NPC 视觉节点 (DBOCharacterVisual)
static func build_npc_visual(npc_tblidx: int) -> DBOCharacterVisual:
	var npc_data := DBOTableManager.get_npc_data(npc_tblidx)
	if npc_data.is_empty():
		push_warning("[DBOCharacterFactory] 找不到 NPC 数据: %d" % npc_tblidx)
		return null

	var visual := DBOCharacterVisual.new()
	visual.name = "DBOCharacterVisual_NPC_%d" % npc_tblidx

	var model_name: String = npc_data.get("model", "").to_lower().strip_edges()
	if not model_name.is_empty():
		var mesh_path := "res://assets/obj/character/mesh_npc/%s.glb" % model_name
		if ResourceLoader.exists(mesh_path):
			var mesh_scene: PackedScene = load(mesh_path)
			if mesh_scene:
				var mesh_inst: Node = mesh_scene.instantiate()
				mesh_inst.name = "NPCBody"
				visual.add_child(mesh_inst)

		# NPC 动画池直接挂接
		var anim_dir := "res://assets/obj/character/animation_npc/"
		load_character_animations(visual, anim_dir, model_name)

	DBOMaterialHelper.fix_node_materials(visual)
	return visual


const HANIM_MAP_HUMAN_MALE: Array[String] = [
	"nullroot", "Bip01", "Bip01 Pelvis", "Bip01 Spine", "B_SK_BL1", "B_SK_BR1",
	"B_SK_FL1", "B_SK_FR1", "B_SK_SL1", "B_SK_SR1", "B_belt1", "B_belt2",
	"Bip01 L Thigh", "Bip01 L Calf", "B_SK_BL2", "B_SK_FL2", "Bip01 L Foot", "Bip01 L Toe0",
	"Bip01 R Thigh", "Bip01 R Calf", "B_SK_BR2", "B_SK_FR2", "Bip01 R Foot", "Bip01 R Toe0",
	"Bip01 Spine1", "Bip01 Spine2", "Bip01 Spine3", "B_bust", "Bip01 Neck", "Bip01 Head",
	"Bip01 PT1", "Bip01 PT2", "nulleye", "Bip01 L Clavicle", "Bip01 L UpperArm",
	"Bip01 L Forearm", "Bip01 L Hand", "Bip01 L Finger0", "Bip01 L Finger1", "Bip01 L Finger2",
	"nullLhand", "Bip01 R Clavicle", "Bip01 R UpperArm", "Bip01 R Forearm", "Bip01 R Hand",
	"Bip01 R Finger0", "Bip01 R Finger1", "Bip01 R Finger2", "nullRhand", "nullback"
]

const HANIM_MAP_HUMAN_FEMALE: Array[String] = [
	"nullroot", "Bip01", "Bip01 Pelvis", "Bip01 Spine", "B_SK_BL1", "B_SK_BR1",
	"B_SK_FL1", "B_SK_FR1", "B_SK_SL1", "B_SK_SR1", "B_belt1", "B_belt2",
	"Bip01 L Thigh", "Bip01 L Calf", "B_SK_BL2", "B_SK_FL2", "Bip01 L Foot", "Bip01 L Toe0",
	"Bip01 R Thigh", "Bip01 R Calf", "B_SK_BR2", "B_SK_FR2", "Bip01 R Foot", "Bip01 R Toe0",
	"Bip01 Spine1", "Bip01 Spine2", "B_bust", "Bip01 Neck", "Bip01 Head", "B_HB1",
	"B_HB2", "B_HL", "Bip01 PT1", "Bip01 PT2", "nulleye", "Bip01 L Clavicle",
	"Bip01 L UpperArm", "Bip01 L Forearm", "Bip01 L Hand", "Bip01 L Finger0", "Bip01 L Finger1",
	"Bip01 L Finger2", "nullLhand", "Bip01 R Clavicle", "Bip01 R UpperArm", "Bip01 R Forearm",
	"Bip01 R Hand", "Bip01 R Finger0", "Bip01 R Finger1", "Bip01 R Finger2", "nullRhand",
	"nullback"
]

const HANIM_MAP_NAMEK: Array[String] = [
	"nullroot", "Bip01", "Bip01 Pelvis", "Bip01 Spine", "B_SK_BL1", "B_SK_BR1",
	"B_SK_FL1", "B_SK_FR1", "B_SK_SL1", "B_SK_SR1", "B_belt1", "B_belt2",
	"Bip01 L Thigh", "Bip01 L Calf", "B_SK_BL2", "B_SK_FL2", "Bip01 L Foot", "Bip01 L Toe0",
	"Bip01 R Thigh", "Bip01 R Calf", "B_SK_BR2", "B_SK_FR2", "Bip01 R Foot", "Bip01 R Toe0",
	"Bip01 Spine1", "Bip01 Spine2", "B_M1", "B_M2", "B_M3", "B_M4", "B_M5", "B_M6", "B_M7",
	"B_bust", "Bip01 Neck", "Bip01 Head", "nulleye", "Bip01 L Clavicle", "Bip01 L UpperArm",
	"Bip01 L Forearm", "Bip01 L Hand", "Bip01 L Finger0", "Bip01 L Finger1", "Bip01 L Finger2",
	"nullLhand", "Bip01 R Clavicle", "Bip01 R UpperArm", "Bip01 R Forearm", "Bip01 R Hand",
	"Bip01 R Finger0", "Bip01 R Finger1", "Bip01 R Finger2", "nullRhand", "nullback"
]

const HANIM_MAP_MAJIN_MALE: Array[String] = [
	"nullroot", "Bip01", "Bip01 Pelvis", "Bip01 Spine", "Bip01 L Thigh", "Bip01 L Calf",
	"Bip01 L Foot", "Bip01 L Toe0", "Bip01 R Thigh", "Bip01 R Calf", "Bip01 R Foot",
	"Bip01 R Toe0", "Bip01 Spine1", "B_SK_BL", "B_SK_BR", "B_SK_FL", "B_SK_FR",
	"B_SK_SL", "B_SK_SR", "Bip01 Spine2", "B_bust", "Bip01 Spine3", "B_M", "B_M2",
	"B_M3", "B_M4", "B_M5", "B_M6", "B_M7", "Bip01 Head", "Bip01 PT1", "Bip01 PT2",
	"nulleye", "Bip01 L Clavicle", "Bip01 L UpperArm", "Bip01 L Forearm", "Bip01 L Hand",
	"Bip01 L Finger0", "Bip01 L Finger1", "Bip01 L Finger2", "nullLhand", "Bip01 R Clavicle",
	"Bip01 R UpperArm", "Bip01 R Forearm", "Bip01 R Hand", "Bip01 R Finger0", "Bip01 R Finger1",
	"Bip01 R Finger2", "nullRhand", "nullback"
]

const HANIM_MAP_MAJIN_FEMALE: Array[String] = [
	"nullroot", "Bip01", "Bip01 Pelvis", "Bip01 Spine", "B_SK_BL", "B_SK_BR",
	"B_SK_FC1", "B_SK_FC2", "B_SK_FL", "B_SK_FR1", "B_SK_FR2", "B_SK_SL1", "B_SK_SL2",
	"B_SK_SR1", "B_SK_SR2", "Bip01 L Thigh", "Bip01 L Calf", "Bip01 L Foot", "Bip01 L Toe0",
	"Bip01 R Thigh", "Bip01 R Calf", "Bip01 R Foot", "Bip01 R Toe0", "Bip01 Spine1",
	"Bip01 Spine2", "B_M1", "B_M2", "BM_3", "B_M4", "BM_5", "B_M6", "BM_7", "B_bust",
	"Bip01 Neck", "Bip01 Head", "B_HB1", "B_HB2", "Bip01 PT 1", "Bip01 PT 2", "nulleye",
	"Bip01 L Clavicle", "Bip01 L UpperArm", "Bip01 L Forearm", "Bip01 L Hand", "Bip01 L Finger0",
	"Bip01 L Finger1", "Bip01 L Finger2", "nullLhand", "Bip01 R Clavicle", "Bip01 R UpperArm",
	"Bip01 R Forearm", "Bip01 R Hand", "Bip01 R Finger0", "Bip01 R Finger1", "Bip01 R Finger2",
	"nullRhand", "nullback"
]


## 检索 RenderWare RpHAnimHierarchy 对应骨骼名称 (严格按照各族骨架定义序列)
static func get_hanim_bone_name(race: int, gender: int, h_idx: int) -> String:
	var map: Array[String]
	match race:
		Race.HUMAN:
			map = HANIM_MAP_HUMAN_MALE if gender == Gender.MALE else HANIM_MAP_HUMAN_FEMALE
		Race.NAMEK:
			map = HANIM_MAP_NAMEK
		Race.MAJIN:
			map = HANIM_MAP_MAJIN_MALE if gender == Gender.MALE else HANIM_MAP_MAJIN_FEMALE
		_:
			map = HANIM_MAP_HUMAN_MALE
	if h_idx >= 0 and h_idx < map.size():
		return map[h_idx]
	return ""


## 动态加载角色的骨骼动画并绑定到 AnimationPlayer 的 AnimationLibrary
static func load_character_animations(visual: DBOCharacterVisual, anim_dir: String, prefix: String) -> void:
	var anim_player: AnimationPlayer = visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player == null:
		anim_player = AnimationPlayer.new()
		anim_player.name = "AnimationPlayer"
		visual.add_child(anim_player)

	visual._ensure_skeleton()
	var skel: Skeleton3D = visual.get_skeleton()
	var anim_root: Node = anim_player.get_node_or_null(anim_player.root_node)
	if anim_root == null:
		anim_root = visual
		anim_player.root_node = anim_player.get_path_to(visual)
	var skel_rel_path: String = ""
	if skel and is_instance_valid(skel):
		skel_rel_path = str(anim_root.get_path_to(skel))

	# 获取默认全局动画库
	var lib: AnimationLibrary = null
	if anim_player.has_animation_library(""):
		lib = anim_player.get_animation_library("")
	else:
		lib = AnimationLibrary.new()
		anim_player.add_animation_library("", lib)

	# 遍历核心动画切片
	var core_anims := get_core_anim_keys()
	for action_name: String in core_anims.keys():
		var file_candidates: Array = core_anims[action_name]
		var found := false
		for candidate: String in file_candidates:
			# 组装前缀候选 (处理童年期回退到该种族通用前缀或无前缀)
			var test_prefixes: Array[String] = [prefix]
			if prefix.begins_with("a_hch_m_"): test_prefixes.append("a_hum_m_")
			elif prefix.begins_with("a_hch_f_"): test_prefixes.append("a_hum_f_")
			elif prefix.begins_with("a_nch_"): test_prefixes.append("a_nam_")
			elif prefix.begins_with("a_mch_m_"): test_prefixes.append("a_maj_m_")
			elif prefix.begins_with("a_mch_f_"): test_prefixes.append("a_maj_f_")
			test_prefixes.append("")

			for pfx in test_prefixes:
				var filename := "%s%s.glb" % [pfx, candidate]
				var full_path := anim_dir + filename
				if ResourceLoader.exists(full_path):
					var anim := _load_animation_from_glb(full_path)
					if anim:
						# 精准重定向骨骼轨道路径，消除未决轨道，保证驱动真实 Skeleton3D 骨骼
						if skel and not skel_rel_path.is_empty():
							var tracks_to_remove: Array[int] = []
							for t in range(anim.get_track_count()):
								var tpath := anim.track_get_path(t)
								var raw_bone := ""
								if tpath.get_subname_count() > 0:
									raw_bone = tpath.get_subname(0)
								elif tpath.get_name_count() > 0:
									raw_bone = tpath.get_name(tpath.get_name_count() - 1)

								var target_bone := ""
								if not raw_bone.is_empty():
									if skel.find_bone(raw_bone) != -1:
										target_bone = raw_bone
									elif raw_bone.begins_with("Bone_"):
										var b_idx := raw_bone.trim_prefix("Bone_").to_int()
										target_bone = get_hanim_bone_name(visual.race, visual.gender, b_idx)

								if not target_bone.is_empty() and skel.find_bone(target_bone) != -1:
									var track_type := anim.track_get_type(t)
									# 仅允许根骨骼 Bip01 携带位移轨迹，其余子骨骼位移一律丢弃，杜绝成人肢体长度强行拉伸儿童骨架
									if track_type == Animation.TYPE_POSITION_3D and target_bone != "Bip01":
										tracks_to_remove.append(t)
										continue

									# 针对 Bip01 根骨骼位移，执行骨架重定向高程补偿，使儿童骨架脚底完美贴合地面，彻底消除浮空
									if track_type == Animation.TYPE_POSITION_3D and target_bone == "Bip01":
										var bip_bone_idx := skel.find_bone("Bip01")
										var rest_origin := skel.get_bone_rest(bip_bone_idx).origin
										var key_cnt := anim.track_get_key_count(t)
										if key_cnt > 0:
											var first_val: Vector3 = anim.track_get_key_value(t, 0)
											var delta_y: float = rest_origin.y - first_val.y
											if abs(delta_y) > 0.05:
												for k in range(key_cnt):
													var val: Vector3 = anim.track_get_key_value(t, k)
													val.y += delta_y
													anim.track_set_key_value(t, k, val)

									anim.track_set_path(t, NodePath(skel_rel_path + ":" + target_bone))
								else:
									tracks_to_remove.append(t)

							for i in range(tracks_to_remove.size() - 1, -1, -1):
								anim.remove_track(tracks_to_remove[i])

						if action_name in ["idle", "run", "walk", "jump_hover", "charge_loop", "sit_idle", "block_loop"]:
							anim.loop_mode = Animation.LOOP_LINEAR
						lib.add_animation(action_name, anim)
						found = true
						break
			if found:
				break


## 加载怪物族系专属动画切片
static func load_mob_animations(visual: DBOCharacterVisual, anim_dir: String, family: String) -> void:
	var anim_player: AnimationPlayer = visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player == null:
		anim_player = AnimationPlayer.new()
		anim_player.name = "AnimationPlayer"
		visual.add_child(anim_player)

	visual._ensure_skeleton()
	var skel: Skeleton3D = visual.get_skeleton()
	var anim_root: Node = anim_player.get_node_or_null(anim_player.root_node)
	if anim_root == null:
		anim_root = visual
		anim_player.root_node = anim_player.get_path_to(visual)
	var skel_rel_path: String = ""
	if skel and is_instance_valid(skel):
		skel_rel_path = str(anim_root.get_path_to(skel))

	var lib: AnimationLibrary = null
	if anim_player.has_animation_library(""):
		lib = anim_player.get_animation_library("")
	else:
		lib = AnimationLibrary.new()
		anim_player.add_animation_library("", lib)

	var prefix := "%s_" % family
	var core_anims := get_core_anim_keys()
	for action_name: String in core_anims.keys():
		var file_candidates: Array = core_anims[action_name]
		for candidate: String in file_candidates:
			var filename := "%s%s.glb" % [prefix, candidate]
			var full_path := anim_dir + filename
			if ResourceLoader.exists(full_path):
				var anim := _load_animation_from_glb(full_path)
				if anim:
					if skel and not skel_rel_path.is_empty():
						var tracks_to_remove: Array[int] = []
						for t in range(anim.get_track_count()):
							var tpath := anim.track_get_path(t)
							var raw_bone := ""
							if tpath.get_subname_count() > 0:
								raw_bone = tpath.get_subname(0)
							elif tpath.get_name_count() > 0:
								raw_bone = tpath.get_name(tpath.get_name_count() - 1)

							var target_bone := ""
							if not raw_bone.is_empty():
								if skel.find_bone(raw_bone) != -1:
									target_bone = raw_bone
								elif raw_bone.begins_with("Bone_"):
									var b_idx := raw_bone.trim_prefix("Bone_").to_int()
									if b_idx >= 0 and b_idx < skel.get_bone_count():
										target_bone = skel.get_bone_name(b_idx)

							if not target_bone.is_empty() and skel.find_bone(target_bone) != -1:
								anim.track_set_path(t, NodePath(skel_rel_path + ":" + target_bone))
							else:
								tracks_to_remove.append(t)

						for i in range(tracks_to_remove.size() - 1, -1, -1):
							anim.remove_track(tracks_to_remove[i])

					if action_name in ["idle", "run", "walk", "jump_hover", "charge_loop", "sit_idle", "block_loop"]:
						anim.loop_mode = Animation.LOOP_LINEAR
					lib.add_animation(action_name, anim)
					break


## 从轻量骨骼采样 GLB 场景中提取 Animation 资源
static func _load_animation_from_glb(glb_path: String) -> Animation:
	if _anim_cache.has(glb_path):
		return _anim_cache[glb_path].duplicate()

	var scene: PackedScene = load(glb_path)
	if scene == null:
		return null

	var inst: Node = scene.instantiate()
	var temp_player: AnimationPlayer = inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var target_anim: Animation = null

	if temp_player:
		for lib_name in temp_player.get_animation_library_list():
			var lib: AnimationLibrary = temp_player.get_animation_library(lib_name)
			for anim_name in lib.get_animation_list():
				target_anim = lib.get_animation(anim_name).duplicate()
				break
			if target_anim:
				break

	inst.queue_free()

	if target_anim:
		_anim_cache[glb_path] = target_anim
		return target_anim.duplicate()

	return null


static var _glb_joint_names_cache: Dictionary = {}

## 从 GLB 场景文件的 JSON Chunk 直接解析骨骼关节名称列表，杜绝无 Skeleton 场景丢失蒙皮绑定的底层问题
static func get_glb_joint_names(glb_path: String) -> Array[String]:
	if _glb_joint_names_cache.has(glb_path):
		var cached: Array = _glb_joint_names_cache[glb_path]
		var ret: Array[String] = []
		for item in cached:
			ret.append(str(item))
		return ret

	var names: Array[String] = []
	if glb_path.is_empty() or not FileAccess.file_exists(glb_path):
		_glb_joint_names_cache[glb_path] = names
		return names

	var file := FileAccess.open(glb_path, FileAccess.READ)
	if file == null:
		_glb_joint_names_cache[glb_path] = names
		return names

	if file.get_length() < 20:
		file.close()
		_glb_joint_names_cache[glb_path] = names
		return names

	var magic := file.get_32()
	var _version := file.get_32()
	var _total_len := file.get_32()
	var json_chunk_len := file.get_32()
	var json_chunk_type := file.get_32()

	if magic == 0x46546C67 and json_chunk_type == 0x4E4F534A:
		var json_bytes := file.get_buffer(json_chunk_len)
		var json_str := json_bytes.get_string_from_utf8()
		var parsed = JSON.parse_string(json_str)
		if parsed is Dictionary and parsed.has("skins") and parsed.has("nodes"):
			var skins: Array = parsed.get("skins", [])
			var nodes: Array = parsed.get("nodes", [])
			if not skins.is_empty():
				var skin0: Dictionary = skins[0]
				var joints: Array = skin0.get("joints", [])
				for j_idx in joints:
					var n_idx := int(j_idx)
					if n_idx >= 0 and n_idx < nodes.size():
						var n_dict: Dictionary = nodes[n_idx]
						names.append(str(n_dict.get("name", "")))
					else:
						names.append("")
	file.close()
	_glb_joint_names_cache[glb_path] = names
	return names


## 穿戴装备/更换部件
static func equip_item_to_character(visual: DBOCharacterVisual, item_tblidx: int) -> void:
	if visual == null:
		return

	visual._ensure_skeleton()
	var item_data := DBOTableManager.get_item_data(item_tblidx)
	if item_data.is_empty():
		return

	var raw_model: String = item_data.get("model", "").strip_edges()
	if raw_model.is_empty():
		return

	var race: int = visual.race if "race" in visual else 0
	var gender: int = visual.gender if "gender" in visual else 0
	var is_adult: bool = visual.is_adult

	var slot_flag: int = item_data.get("equip_slot_flag", 0)
	var is_glove := (slot_flag == 1 or slot_flag == 2) and "glv" in raw_model.to_lower()
	var slot_name := _slot_flag_to_name(slot_flag)
	if is_glove:
		slot_name = "weapon_r"

	var glb_path := _resolve_item_glb_path(raw_model, race, gender, is_adult, 1)
	if glb_path.is_empty() or not FileAccess.file_exists(glb_path):
		push_warning("[equip_item_to_character] No GLB resolved for item %d model %s" % [item_tblidx, raw_model])
		return

	# 若该槽位当前已穿戴完全相同的装备模型，无需重复销毁与重新解析，杜绝闪烁与卡顿
	if visual.equipped_glb_paths.get(slot_name, "") == glb_path and is_instance_valid(visual._slots.get(slot_name, null)):
		return

	# 互斥清理：若穿戴武器或手套，清理同侧旧武器挂载
	if slot_flag == 1 or slot_flag == 2:
		for old_k in ["weapon_r", "weapon_l", "hands"]:
			if old_k == slot_name and visual._slots.has(old_k) and is_instance_valid(visual._slots[old_k]):
				visual._slots[old_k].queue_free()
				visual._slots[old_k] = null
				visual.equipped_glb_paths.erase(old_k)

	# 史考特（Scouter）挂载到头部骨骼附件节点
	if slot_flag == 32:
		visual.attach_item_to_bone(slot_name, glb_path, raw_model)
		return

	# 武器类装备（主手拳套、剑、杖、副手等）：严格遵循 OpenDBO 规范，作为手部节点挂载物，杜绝全身蒙皮拉伸飞天黑线
	if slot_flag == 1 or slot_flag == 2:
		visual.attach_item_to_bone(slot_name, glb_path, raw_model)
		return

	# 鞋靴装备（feet）：严格遵循防具挂载规范，加载独立 3D 装备鞋靴模型并精准双侧骨骼绑定
	if slot_name == "feet":
		_equip_feet_mesh(visual, glb_path, is_adult)
		return

	# 上装/下装/靴子/手套：严格遵循防具挂载规范，通过 GLTFDocument 动态加载为蒙皮网格并对齐骨架与 Skin
	var skeleton := visual._skeleton
	if skeleton == null:
		return

	var sc: Node = DBOMaterialHelper.load_gltf_scene_safe(glb_path, GLTFDocument.IMPORT_FLAG_USE_NAMED_SKIN_BINDS)
	if sc == null:
		push_warning("[equip_item_to_character] load_gltf_scene_safe failed: %s" % glb_path)
		return

	# 找到源场景中的 Skeleton3D 与 MeshInstance3D
	var src_skel: Skeleton3D = sc.find_child("Skeleton3D", true, false) as Skeleton3D
	var mesh_nodes := sc.find_children("*", "MeshInstance3D", true, false)
	var mesh_inst: MeshInstance3D = null
	for c in mesh_nodes:
		if c is MeshInstance3D:
			mesh_inst = c
			break

	if mesh_inst == null or mesh_inst.mesh == null:
		push_warning("[equip_item_to_character] no MeshInstance3D in GLB: %s" % glb_path)
		sc.queue_free()
		return

	# 保留装备自身的 Skin（逆绑定矩阵）；若没有则回退到素体 Skin
	var own_skin: Skin = mesh_inst.skin
	# Exported parts can carry a transform on the mesh or its GLB parent nodes.
	# Accumulate it while the mesh is still in the generated scene.
	var source_mesh_transform: Transform3D = mesh_inst.transform
	var transform_parent := mesh_inst.get_parent()
	while transform_parent != null and transform_parent != sc:
		if transform_parent is Node3D:
			source_mesh_transform = (transform_parent as Node3D).transform * source_mesh_transform
		transform_parent = transform_parent.get_parent()
	mesh_inst.get_parent().remove_child(mesh_inst)
	mesh_inst.name = "Part_" + slot_name.capitalize()
	_clear_owner_recursive(mesh_inst)

	# 先移除旧槽位部件
	visual.unequip_slot(slot_name)
	var glb_joint_names: Array[String] = get_glb_joint_names(glb_path)

	# 精准重构 Skin：逐骨骼对齐骨骼名称、索引与绑定姿态，彻底消除拉伸畸变
	if own_skin != null and own_skin.get_bind_count() > 0:
		var new_skin := Skin.new()
		var bind_cnt := own_skin.get_bind_count()
		new_skin.set_bind_count(bind_cnt)

		# 查找主要回退骨骼 (杜绝 bone_idx = -1 导致顶点着色器丢失骨骼矩阵坍塌)
		var fallback_b_idx := skeleton.find_bone("Bip01 Pelvis")
		if fallback_b_idx == -1:
			fallback_b_idx = skeleton.find_bone("Bip01")
		if fallback_b_idx == -1 and skeleton.get_bone_count() > 0:
			fallback_b_idx = 0

		for i in range(bind_cnt):
			var b_name := ""
			if i < glb_joint_names.size():
				b_name = glb_joint_names[i]
			if b_name.is_empty():
				b_name = str(own_skin.get_bind_name(i))
			if b_name.is_empty() and src_skel:
				var src_b_idx := own_skin.get_bind_bone(i)
				if src_b_idx >= 0 and src_b_idx < src_skel.get_bone_count():
					b_name = src_skel.get_bone_name(src_b_idx)
			if b_name.is_empty():
				b_name = get_hanim_bone_name(visual.race, visual.gender, i)

			var target_b_idx := skeleton.find_bone(b_name)
			if target_b_idx == -1 and b_name.begins_with("Bone_"):
				var h_idx := b_name.trim_prefix("Bone_").to_int()
				var mapped_name := get_hanim_bone_name(visual.race, visual.gender, h_idx)
				if not mapped_name.is_empty():
					target_b_idx = skeleton.find_bone(mapped_name)
					if target_b_idx != -1:
						b_name = mapped_name

			# 智能骨骼映射回退（针对不同种族骨骼差异、幼年骨骼高程补偿或裙摆/配件骨骼）
			if (not is_adult and b_name.begins_with("B_bust")) or target_b_idx == -1:
				if b_name.begins_with("B_bust"):
					target_b_idx = skeleton.find_bone("Bip01 Spine2")
					if target_b_idx == -1:
						target_b_idx = skeleton.find_bone("Bip01 Spine1")
				elif not b_name.is_empty():
					var alt_name := ""
					if b_name.begins_with("B_SK_") or b_name.begins_with("B_belt"):
						alt_name = "Bip01 Pelvis"
					elif b_name.begins_with("B_M"):
						alt_name = "Bip01 Spine2"
					elif b_name.begins_with("B_HB") or b_name.begins_with("B_HL"):
						alt_name = "Bip01 Head"
					elif b_name.begins_with("nullL") or b_name == "nullLhand":
						alt_name = "Bip01 L Hand"
					elif b_name.begins_with("nullR") or b_name == "nullRhand":
						alt_name = "Bip01 R Hand"
					elif b_name == "nulleye":
						alt_name = "Bip01 Head"
					elif b_name == "nullroot":
						alt_name = "Bip01"
					elif b_name == "nullback":
						alt_name = "Bip01 Spine2"
					if not alt_name.is_empty():
						target_b_idx = skeleton.find_bone(alt_name)

			# Some costume rigs add secondary bones such as Box01 or Bip02 ponytail
			# bones. If the avatar rig lacks that joint, bind it to the nearest
			# source-rig ancestor that exists on the avatar, preserving its region.
			if target_b_idx == -1 and src_skel:
				var source_b_idx := own_skin.get_bind_bone(i)
				while source_b_idx >= 0 and source_b_idx < src_skel.get_bone_count():
					var source_bone_name := src_skel.get_bone_name(source_b_idx)
					target_b_idx = skeleton.find_bone(source_bone_name)
					if target_b_idx != -1:
						break
					source_b_idx = src_skel.get_bone_parent(source_b_idx)

			if target_b_idx == -1:
				target_b_idx = fallback_b_idx

			new_skin.set_bind_name(i, StringName(b_name))
			new_skin.set_bind_bone(i, target_b_idx)
			var bp: Transform3D = own_skin.get_bind_pose(i)
			if bp == Transform3D.IDENTITY and target_b_idx != -1:
				new_skin.set_bind_pose(i, skeleton.get_bone_global_pose(target_b_idx).affine_inverse())
			else:
				new_skin.set_bind_pose(i, bp)

		# 针对单侧建模的鞋靴部件，检测并补充对侧骨骼绑定到 Skin，并在内存中进行双侧对称镜像生成
		if slot_name == "feet":
			var sym_map: Dictionary = {}
			var extra_binds: Array[Dictionary] = []
			for i in range(bind_cnt):
				var b_name := String(new_skin.get_bind_name(i))
				var opp_name := ""
				if " R " in b_name or b_name.begins_with("R_") or b_name.ends_with("_R") or "Right" in b_name:
					opp_name = b_name.replace(" R ", " L ").replace("R_", "L_").replace("_R", "_L").replace("Right", "Left")
				elif " L " in b_name or b_name.begins_with("L_") or b_name.ends_with("_L") or "Left" in b_name:
					opp_name = b_name.replace(" L ", " R ").replace("L_", "R_").replace("_L", "_R").replace("Left", "Right")

				if not opp_name.is_empty():
					var existing_opp_idx := -1
					for j in range(bind_cnt):
						if String(new_skin.get_bind_name(j)) == opp_name:
							existing_opp_idx = j
							break
					if existing_opp_idx != -1:
						sym_map[i] = existing_opp_idx
					else:
						var opp_b_idx := skeleton.find_bone(opp_name)
						if opp_b_idx != -1:
							var new_joint_idx := bind_cnt + extra_binds.size()
							sym_map[i] = new_joint_idx
							extra_binds.append({
								"name": opp_name,
								"bone_idx": opp_b_idx,
								"pose": skeleton.get_bone_global_pose(opp_b_idx).affine_inverse()
							})

			if not extra_binds.is_empty():
				new_skin.set_bind_count(bind_cnt + extra_binds.size())
				for k in range(extra_binds.size()):
					var eb: Dictionary = extra_binds[k]
					var dest_idx := bind_cnt + k
					new_skin.set_bind_name(dest_idx, StringName(eb["name"]))
					new_skin.set_bind_bone(dest_idx, eb["bone_idx"])
					new_skin.set_bind_pose(dest_idx, eb["pose"])

			mesh_inst.skin = new_skin
			if not sym_map.is_empty():
				_mirror_equipment_mesh(mesh_inst, sym_map)
		else:
			mesh_inst.skin = new_skin
	else:
		# 查找素体主 MeshInstance3D 的 Skin 作为回退
		var base_body := visual.find_child("BaseBody", true, false)
		var base_mi: MeshInstance3D = null
		if base_body is MeshInstance3D:
			base_mi = base_body
		elif base_body != null:
			var meshes := base_body.find_children("*", "MeshInstance3D", true, false)
			if not meshes.is_empty():
				base_mi = meshes[0] as MeshInstance3D
		if base_mi and base_mi.skin:
			mesh_inst.skin = base_mi.skin

	# 针对上装装备网格，若已是离线提纯好的纯净衣服本体网格，无需再进行计算过滤
	if slot_name == "torso":
		_filter_torso_equipment_mesh(mesh_inst, glb_joint_names, not is_adult)

	# 挂载到素体 Skeleton3D 内部并保留导出部件自身的节点变换
	skeleton.add_child(mesh_inst)
	mesh_inst.transform = source_mesh_transform
	mesh_inst.skeleton = NodePath("..")
	mesh_inst.material_override = null

	# 修复材质（透明度/双面等）
	DBOMaterialHelper.fix_mesh_materials(mesh_inst)

	# 皮肤与布料材质派发及肤色同步染色（对标 OpenDBO-Core 逆向与旧工程魔人修复标准）
	var c_skin_col := visual.current_skin_color
	if race == 1:
		c_skin_col = Color.WHITE
	else:
		if c_skin_col == Color.WHITE and visual._last_customization_args.size() >= 6:
			var c_skin_col_num: int = clampi(int(visual._last_customization_args[5]), 1, 5)
			var def_tbl := DBOTableManager.get_default_item_list()
			var type_str := visual._get_character_type_string(race, gender, is_adult)
			var type_data: Dictionary = def_tbl.get(type_str, {})
			var skin_cols: Dictionary = type_data.get("skin_color", {})
			var sc_arr: Array = skin_cols.get(str(c_skin_col_num), [1.0, 1.0, 1.0])
			if sc_arr.size() >= 3:
				c_skin_col = Color(sc_arr[0], sc_arr[1], sc_arr[2])

		# 魔人默认粉红保底，严禁退回纯白导致白模
		if race == 2 and (c_skin_col == Color.WHITE or c_skin_col.a < 0.01):
			c_skin_col = Color(0.9922, 0.7412, 0.8627)
	visual.current_skin_color = c_skin_col

	var is_majin_jacket := (race == 2 and slot_name == "torso")
	var is_majin_female := (gender == 1)
	var smat: Material = null

	if is_majin_jacket:
		_apply_majin_jacket_materials(mesh_inst, glb_path, is_majin_female, c_skin_col)
	elif slot_name == "torso":
		for s in range(mesh_inst.mesh.get_surface_count()):
			smat = mesh_inst.get_surface_override_material(s)
			if smat == null:
				smat = mesh_inst.mesh.surface_get_material(s)
			var mat_name := smat.resource_name.to_lower() if smat else ""
			if "skin" in mat_name:
				if not is_adult:
					# ??????????????????? DFF ???????????????????
					mesh_inst.set_surface_override_material(s, DBOCharacterVisual._get_invisible_material())
				else:
					var skin_mat := StandardMaterial3D.new()
					skin_mat.albedo_color = c_skin_col
					skin_mat.roughness = 0.8
					mesh_inst.set_surface_override_material(s, skin_mat)
			else:
				# ???????????????????????????????????/????
				var cloth_tex: Texture2D = null
				if not mat_name.is_empty():
					cloth_tex = load_texture_safe("res://assets/tex/texture/item/" + mat_name + ".png")
				if cloth_tex == null:
					cloth_tex = _resolve_general_jacket_texture(glb_path, race, gender)
				if cloth_tex:
					var cloth_mat := StandardMaterial3D.new()
					cloth_mat.albedo_texture = cloth_tex
					cloth_mat.albedo_color = Color.WHITE
					cloth_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
					cloth_mat.roughness = 0.8
					cloth_mat.metallic = 0.0
					cloth_mat.render_priority = 1
					mesh_inst.set_surface_override_material(s, cloth_mat)
	else:
		for s in range(mesh_inst.mesh.get_surface_count()):
			smat = mesh_inst.get_surface_override_material(s)
			if smat == null:
				smat = mesh_inst.mesh.surface_get_material(s)
			var m_name: String = smat.resource_name.to_lower() if smat else ""
			if "skin" in m_name:
				if not is_adult:
					mesh_inst.set_surface_override_material(s, DBOCharacterVisual._get_invisible_material())
				else:
					var other_skin_mat := StandardMaterial3D.new()
					other_skin_mat.albedo_color = c_skin_col
					other_skin_mat.roughness = 0.8
					mesh_inst.set_surface_override_material(s, other_skin_mat)
			else:
				var tex: Texture2D = null
				if not m_name.is_empty():
					tex = load_texture_safe("res://assets/tex/texture/item/" + m_name + ".png")
				if tex == null:
					if slot_name == "legs":
						tex = _resolve_child_pants_texture(race, gender, visual.character_class_id, glb_path)
					elif slot_name == "feet":
						tex = _resolve_child_boots_texture(race, gender, visual.character_class_id, glb_path)
				if tex:
					var mat := StandardMaterial3D.new()
					mat.albedo_texture = tex
					mat.albedo_color = Color.WHITE
					mat.cull_mode = BaseMaterial3D.CULL_DISABLED
					mat.roughness = 0.8
					mat.metallic = 0.0
					mat.render_priority = 1
					mesh_inst.set_surface_override_material(s, mat)
				elif smat is StandardMaterial3D:
					(smat as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED

	# 更新视觉槽位记录与模型路径
	visual._slots[slot_name] = mesh_inst
	visual.equipped_glb_paths[slot_name] = glb_path
	visual._update_base_body_visibility()

	sc.queue_free()


## 穿戴装备/更换部件 (方法别名兼容)
static func equip_item_by_tblidx(visual: DBOCharacterVisual, item_tblidx: int) -> void:
	equip_item_to_character(visual, item_tblidx)


const CHARACTER_SKIN_SHADER: Shader = preload("res://src/shaders/character_skin.gdshader")

static var _composite_cache: Dictionary = {}

## 安全载入贴图文件（优先直读磁盘 Image 避免 ResourceLoader 未导入或缓存缺失导致返回 null）
static func load_texture_safe(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if FileAccess.file_exists(path):
		var g_path := ProjectSettings.globalize_path(path)
		var img := Image.load_from_file(g_path)
		if img:
			return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path) as Texture2D
	return null


## 检索魔人男女上装短袖/马甲布料贴图
static func _find_majin_jacket_cloth_texture(glb_path: String, is_female: bool) -> Texture2D:
	var glb_file := glb_path.to_lower().get_file().get_basename()
	var num_str := "04_01"
	var reg := RegEx.new()
	reg.compile("(\\d{2}_\\d{2})")
	var match_res := reg.search(glb_file)
	if match_res:
		num_str = match_res.get_string(1)

	var pfx := "a_mwo_" if ("mwo" in glb_file) else "a_mmi_"
	var gender_str := "f_" if is_female else "m_"
	var candidates: Array[String] = [
		"res://assets/tex/texture/item/%s%sjacket%s_1.png" % [pfx, gender_str, num_str],
		"res://assets/tex/texture/item/%s%sjacket%s.png" % [pfx, gender_str, num_str],
		"res://assets/tex/texture/item/%s%sjacket04_01_1.png" % [pfx, gender_str],
		"res://assets/tex/texture/item/%s%sjacket04_01.png" % [pfx, gender_str]
	]

	for tc in candidates:
		var t := load_texture_safe(tc)
		if t:
			return t
	return null


## 智能检索全种族男女通用上装布料贴图（对齐 OpenDBO 资源命名规则与官方 DFF 材质）
static func _resolve_general_jacket_texture(glb_path: String, race: int, gender: int) -> Texture2D:
	var glb_file := glb_path.to_lower().get_file().get_basename()
	var num_str := "04_01"
	var reg := RegEx.new()
	reg.compile("(\\d{2}_\\d{2})")
	var match_res := reg.search(glb_file)
	if match_res:
		num_str = match_res.get_string(1)

	# ????????????????????????/????
	var pfx := ""
	var pfx_reg := RegEx.new()
	pfx_reg.compile("^(a_[a-z0-9]{3}|ccbd_[a-z0-9]+|a_com)")
	var pfx_match := pfx_reg.search(glb_file)
	if pfx_match:
		pfx = pfx_match.get_string(1)
	else:
		var parts := glb_file.split("_")
		if parts.size() >= 2:
			pfx = parts[0] + "_" + parts[1]

	var g_str := ""
	if "_h_m" in glb_file or "_m_m" in glb_file:
		g_str = "m_"
	elif "_h_f" in glb_file or "_m_f" in glb_file:
		g_str = "f_"
	elif race == 0 or race == 2:
		g_str = "m_" if gender == 0 else "f_"

	var candidates: Array[String] = [
		"res://assets/tex/texture/item/%s_%sjacket%s.png" % [pfx, g_str, num_str],
		"res://assets/tex/texture/item/%s_%sjacket%s_1.png" % [pfx, g_str, num_str],
		"res://assets/tex/texture/item/%s%sjacket%s.png" % [pfx, g_str, num_str],
		"res://assets/tex/texture/item/%s%sjacket%s_1.png" % [pfx, g_str, num_str],
		"res://assets/tex/texture/item/%s.png" % glb_file
	]

	# ????????
	if pfx == "a_hfi":
		candidates.append("res://assets/tex/texture/item/a_hfi_m_jacket04_01.png")
		candidates.append("res://assets/tex/texture/item/a_hfi_f_jacket04_01_1.png")
	elif pfx == "a_hmy":
		candidates.append("res://assets/tex/texture/item/a_hmy_m_jacket04_01_1.png")
		candidates.append("res://assets/tex/texture/item/a_hmy_f_jacket04_01_1.png")
	elif pfx == "a_nfi":
		candidates.append("res://assets/tex/texture/item/a_nfi_jacket04_01.png")
	elif pfx == "a_nmy":
		candidates.append("res://assets/tex/texture/item/a_nmy_jacket04_01_1.png")
	elif pfx == "a_mmi":
		candidates.append("res://assets/tex/texture/item/a_mmi_m_jacket04_01.png")
	elif pfx == "a_mwo":
		candidates.append("res://assets/tex/texture/item/a_mwo_m_jacket04_01_1.png")

	for tc in candidates:
		var tex := load_texture_safe(tc)
		if tex:
			return tex
	return null



## 检索意魔人男女上装围巾颈圈贴图
static func _find_majin_jacket_scarf_texture(glb_path: String, is_female: bool) -> Texture2D:
	var glb_file := glb_path.to_lower().get_file().get_basename()
	var num_str := "04_01"
	var reg := RegEx.new()
	reg.compile("(\\d{2}_\\d{2})")
	var match_res := reg.search(glb_file)
	if match_res:
		num_str = match_res.get_string(1)

	var pfx := "a_mwo_" if ("mwo" in glb_file) else "a_mmi_"
	var gender_str := "f_" if is_female else "m_"
	var candidates: Array[String] = [
		"res://assets/tex/texture/item/%s%sjacket%s_2.png" % [pfx, gender_str, num_str],
		"res://assets/tex/texture/item/%s%sjacket04_01_2.png" % [pfx, gender_str],
		"res://assets/tex/texture/item/a_mwo_%sjacket%s_2.png" % [gender_str, num_str],
		"res://assets/tex/texture/item/a_mwo_%sjacket04_01_2.png" % gender_str
	]

	for tc in candidates:
		var t := load_texture_safe(tc)
		if t:
			return t
	return null


## 智能检索全种族男女通用上装布料贴图（对齐 OpenDBO 资源命名规则与官方 DFF 材质）
## 针对魔人两种职业男女上衣执行精准多图元材质派发与动态肤色合成（彻底消除肩臂白模与服装显示错误）
static func _apply_majin_jacket_materials(mesh_inst: MeshInstance3D, glb_path: String, is_female: bool, skin_color: Color) -> void:
	if mesh_inst == null or mesh_inst.mesh == null:
		return

	# 保底肤色：魔人族默认粉红 (0.9922, 0.7412, 0.8627)，绝不允许纯白 (WHITE) 造成肩臂白模
	if skin_color == Color.WHITE or skin_color.a < 0.01:
		skin_color = Color(0.9922, 0.7412, 0.8627)

	var surf_count := mesh_inst.mesh.get_surface_count()

	var cloth_shirt_tex := _find_majin_jacket_cloth_texture(glb_path, is_female)
	var scarf_tex := _find_majin_jacket_scarf_texture(glb_path, is_female)
	var base_skin_path := "res://assets/tex/texture/item/a_maj_f_jacket_skin1.png" if is_female else "res://assets/tex/texture/item/a_maj_m_jacket_skin1.png"
	var arm_skin_path := "res://assets/tex/texture/item/a_maj_f_jacket_skin2.png" if is_female else "res://assets/tex/texture/item/a_maj_m_jacket_skin2.png"

	var comp_shirt_tex := _composite_skin_with_armor(base_skin_path, cloth_shirt_tex, skin_color)
	var arm_tex := load_texture_safe(arm_skin_path)

	for s in range(surf_count):
		var base_mat := mesh_inst.mesh.surface_get_material(s)
		var mat_name := base_mat.resource_name.to_lower() if base_mat else ""

		if "skin" in mat_name or "fskin" in mat_name or "arm" in mat_name:
			if "skin2" in mat_name or "arm" in mat_name:
				# 肩部与手臂裸露皮肤表面：采用统一角色皮肤着色器 CHARACTER_SKIN_SHADER 染色，彻底杜绝白模！
				var smat := ShaderMaterial.new()
				smat.shader = CHARACTER_SKIN_SHADER
				var use_arm_tex := arm_tex
				if use_arm_tex == null and base_mat is BaseMaterial3D and (base_mat as BaseMaterial3D).albedo_texture:
					use_arm_tex = (base_mat as BaseMaterial3D).albedo_texture
				if use_arm_tex:
					smat.set_shader_parameter("base_tex", use_arm_tex)
				smat.set_shader_parameter("skin_tint", skin_color)
				smat.set_shader_parameter("race_mode", 2)
				mesh_inst.set_surface_override_material(s, smat)
			else:
				# skin1: 躯干衣服+皮肤合成表面 (女魔人短袖/吊带，男魔人背心马甲/衬衫)
				var cmat := StandardMaterial3D.new()
				cmat.roughness = 0.8
				cmat.cull_mode = BaseMaterial3D.CULL_BACK
				var tex := comp_shirt_tex if comp_shirt_tex else cloth_shirt_tex
				if not tex and base_mat is BaseMaterial3D and (base_mat as BaseMaterial3D).albedo_texture:
					tex = (base_mat as BaseMaterial3D).albedo_texture
				cmat.albedo_texture = tex
				cmat.albedo_color = Color.WHITE
				mesh_inst.set_surface_override_material(s, cmat)
		else:
			# 非皮肤表面（围巾、领圈、灯笼袖衣物部件等）
			var item_tex: Texture2D = null
			if base_mat is BaseMaterial3D and (base_mat as BaseMaterial3D).albedo_texture:
				item_tex = (base_mat as BaseMaterial3D).albedo_texture
			if not item_tex and not mat_name.is_empty():
				var direct_tex_path := "res://assets/tex/texture/item/" + mat_name + ".png"
				item_tex = load_texture_safe(direct_tex_path)
			if not item_tex:
				if "jacket" in mat_name and not ("01_2" in mat_name or "04_01_2" in mat_name or "04_02_2" in mat_name):
					item_tex = cloth_shirt_tex
				else:
					item_tex = scarf_tex

			if item_tex:
				var mat := StandardMaterial3D.new()
				mat.roughness = 0.8
				mat.cull_mode = BaseMaterial3D.CULL_BACK
				mat.albedo_texture = item_tex
				mat.albedo_color = Color.WHITE
				mesh_inst.set_surface_override_material(s, mat)


## 将魔人上装镂空布料动态合成至肤色底层（消除露胸/腹黑块与色差）
static func _composite_skin_with_armor(skin_path: String, cloth_tex: Texture2D, skin_color: Color) -> Texture2D:
	if not cloth_tex:
		return null
	if skin_color == Color.WHITE or skin_color.a < 0.01:
		skin_color = Color(0.9922, 0.7412, 0.8627)
	var cache_key := "%s|%d|%s" % [skin_path, cloth_tex.get_instance_id(), skin_color.to_html()]
	if _composite_cache.has(cache_key):
		return _composite_cache[cache_key]

	var skin_tex: Texture2D = load_texture_safe(skin_path)
	if not skin_tex:
		return cloth_tex

	var skin_img: Image = skin_tex.get_image()
	var cloth_img: Image = cloth_tex.get_image()
	if not skin_img or not cloth_img:
		return cloth_tex

	skin_img = skin_img.duplicate()
	if skin_img.is_compressed():
		skin_img.decompress()
	if skin_img.get_format() != Image.FORMAT_RGBA8:
		skin_img.convert(Image.FORMAT_RGBA8)

	var w := skin_img.get_width()
	var h := skin_img.get_height()

	cloth_img = cloth_img.duplicate()
	if cloth_img.is_compressed():
		cloth_img.decompress()
	if cloth_img.get_format() != Image.FORMAT_RGBA8:
		cloth_img.convert(Image.FORMAT_RGBA8)
	if cloth_img.get_width() != w or cloth_img.get_height() != h:
		cloth_img.resize(w, h)

	for y in range(h):
		for x in range(w):
			var c := skin_img.get_pixel(x, y)
			skin_img.set_pixel(x, y, Color(c.r * skin_color.r, c.g * skin_color.g, c.b * skin_color.b, c.a))

	skin_img.blend_rect(cloth_img, Rect2i(0, 0, w, h), Vector2i(0, 0))

	var res_tex := ImageTexture.create_from_image(skin_img)
	_composite_cache[cache_key] = res_tex
	return res_tex


## 动态推断装备 GLB 路径 (严格依据 OpenDBO itemproperty.json 与 DefaultItemList.xml 官方模型规范)
## 适配儿童与成人体型：儿童专属装备优先，通用/成人装备自动平滑降级回退
static func _resolve_item_glb_path(raw_model: String, race: int = 0, gender: int = 0, is_adult: bool = true, namek_skin: int = 1) -> String:
	var u := raw_model.to_upper().strip_edges()
	if u.is_empty():
		return ""

	# 装备子目录穷举检索
	var search_dirs: Array[String] = [
		"res://assets/obj/item/mesh_armor_humanmale/",
		"res://assets/obj/item/mesh_armor_humanfemale/",
		"res://assets/obj/item/mesh_armor_namek/",
		"res://assets/obj/item/mesh_armor_majinmale/",
		"res://assets/obj/item/mesh_armor_majinfemale/",
		"res://assets/obj/item/mesh_weapon/",
		"res://assets/obj/item/mesh_scouter/",
		"res://assets/obj/item/mesh_costume/",
		"res://assets/obj/item/mesh_common_armor/",
		"res://assets/obj/item/mesh_battlesuit/",
		"res://assets/obj/item/mesh_ccbd_armor/",
		"res://assets/obj/item/mesh_costume_engineer/",
		"res://assets/obj/item/drop item/"
	]

	var prefixes: Array[String] = []
	var suffixes: Array[String] = []

	if race == Race.NAMEK:
		if u.begins_with("A_HFI_"):
			prefixes.append(u.replace("A_HFI_", "A_NFI_"))
		elif u.begins_with("A_HMY_"):
			prefixes.append(u.replace("A_HMY_", "A_NMY_"))
		prefixes.append(u)
		suffixes = ["_N_O_S%d" % namek_skin, "_N_O_S1", "_N_S1", "_N_O", ""]
	elif race == Race.MAJIN:
		if u.begins_with("A_HFI_"):
			prefixes.append(u.replace("A_HFI_", "A_MMI_"))
		elif u.begins_with("A_HMY_"):
			prefixes.append(u.replace("A_HMY_", "A_MWO_"))
		prefixes.append(u)
		suffixes = ["_M_F" if gender == Gender.FEMALE else "_M_M", ""]
	else: # Human
		prefixes.append(u)
		suffixes = ["_H_F" if gender == Gender.FEMALE else "_H_M", ""]

	# 优先通过 itemproperty.json 查询官方模型路径
	for p in prefixes:
		for s in suffixes:
			var cand := p + s
			var prop_path := _get_item_property_glb_path(cand)
			if not prop_path.is_empty():
				return prop_path

	# 遍历装备目录检索对应 GLB 文件
	for p in prefixes:
		for s in suffixes:
			var target_file: String = (p + s).to_lower() + ".glb"
			for sdir: String in search_dirs:
				var test_path: String = sdir + target_file
				if FileAccess.file_exists(test_path):
					return test_path

	return ""


## 装备鞋靴专用加载与精准双侧骨骼绑定
static func _equip_feet_mesh(visual: DBOCharacterVisual, glb_path: String, _is_adult: bool) -> void:
	if visual == null:
		return
	visual.unequip_slot("feet")

	var skeleton := visual._skeleton
	if skeleton == null:
		return

	var sc: Node = DBOMaterialHelper.load_gltf_scene_safe(glb_path, GLTFDocument.IMPORT_FLAG_USE_NAMED_SKIN_BINDS)
	if sc == null:
		return

	var mesh_nodes := sc.find_children("*", "MeshInstance3D", true, false)
	var src_mi: MeshInstance3D = null
	for c in mesh_nodes:
		if c is MeshInstance3D and c.mesh != null and c.mesh.get_surface_count() > 0:
			src_mi = c
			break
	if src_mi == null:
		sc.queue_free()
		return

	# 提取外部装备靴子的原始材质与贴图
	var orig_mat: Material = src_mi.get_surface_override_material(0)
	if orig_mat == null:
		orig_mat = src_mi.mesh.surface_get_material(0)

	var boot_tex: Texture2D = null
	if orig_mat is BaseMaterial3D:
		boot_tex = (orig_mat as BaseMaterial3D).albedo_texture
	if boot_tex == null:
		boot_tex = _resolve_child_boots_texture(visual.race, visual.gender, visual.character_class_id, glb_path)

	var boot_mat := StandardMaterial3D.new()
	boot_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	boot_mat.roughness = 0.8
	boot_mat.metallic = 0.0
	if boot_tex:
		boot_mat.albedo_texture = boot_tex
	boot_mat.albedo_color = Color.WHITE

	# 获取素体主网格及其 Skin，并计算素体左右脚真实的包围盒
	var base_body := visual.find_child("BaseBody", true, false)
	var base_mi: MeshInstance3D = null
	if base_body is MeshInstance3D:
		base_mi = base_body
	elif base_body != null:
		var b_meshes := base_body.find_children("*", "MeshInstance3D", true, false)
		if not b_meshes.is_empty():
			base_mi = b_meshes[0] as MeshInstance3D

	var pos_min := Vector3(0.09, -0.04, -0.09)
	var pos_max := Vector3(0.25, 0.07, 0.22)
	var neg_min := Vector3(-0.25, -0.04, -0.09)
	var neg_max := Vector3(-0.09, 0.07, 0.22)

	if base_mi and base_mi.mesh:
		var b_mesh := base_mi.mesh
		for s in range(b_mesh.get_surface_count()):
			var smat := base_mi.get_surface_override_material(s)
			if smat == null:
				smat = b_mesh.surface_get_material(s)
			var m_name := smat.resource_name.to_lower() if smat else ""
			if "boot" in m_name:
				var arrs := b_mesh.surface_get_arrays(s)
				if arrs.size() > Mesh.ARRAY_VERTEX and arrs[Mesh.ARRAY_VERTEX] != null:
					var bverts: PackedVector3Array = arrs[Mesh.ARRAY_VERTEX]
					if not bverts.is_empty():
						var s_min := bverts[0]
						var s_max := bverts[0]
						for bv in bverts:
							s_min.x = min(s_min.x, bv.x)
							s_min.y = min(s_min.y, bv.y)
							s_min.z = min(s_min.z, bv.z)
							s_max.x = max(s_max.x, bv.x)
							s_max.y = max(s_max.y, bv.y)
							s_max.z = max(s_max.z, bv.z)
						var center_x := (s_min.x + s_max.x) * 0.5
						if center_x > 0:
							pos_min = s_min
							pos_max = s_max
						else:
							neg_min = s_min
							neg_max = s_max

	var r_bone_idx := skeleton.find_bone("Bip01 R Foot")
	var l_bone_idx := skeleton.find_bone("Bip01 L Foot")
	if r_bone_idx == -1: r_bone_idx = skeleton.find_bone("Bip01 R Calf")
	if l_bone_idx == -1: l_bone_idx = skeleton.find_bone("Bip01 L Calf")
	if r_bone_idx == -1: r_bone_idx = 0
	if l_bone_idx == -1: l_bone_idx = 0

	var base_skin: Skin = base_mi.skin if base_mi else null
	var r_joint_idx := 0
	var l_joint_idx := 0
	if base_skin:
		for j in range(base_skin.get_bind_count()):
			var b_name := str(base_skin.get_bind_name(j))
			if b_name == "Bip01 R Foot":
				r_joint_idx = j
			elif b_name == "Bip01 L Foot":
				l_joint_idx = j
			elif base_skin.get_bind_bone(j) == r_bone_idx and r_joint_idx == 0:
				r_joint_idx = j
			elif base_skin.get_bind_bone(j) == l_bone_idx and l_joint_idx == 0:
				l_joint_idx = j

	# 读取外部靴子 Surface 0 几何
	var src_arrays := src_mi.mesh.surface_get_arrays(0)
	var src_verts: PackedVector3Array = src_arrays[Mesh.ARRAY_VERTEX]
	var src_normals: PackedVector3Array = src_arrays[Mesh.ARRAY_NORMAL] if src_arrays.size() > Mesh.ARRAY_NORMAL and src_arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
	var src_uvs: PackedVector2Array = src_arrays[Mesh.ARRAY_TEX_UV] if src_arrays.size() > Mesh.ARRAY_TEX_UV and src_arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var src_indices_raw = src_arrays[Mesh.ARRAY_INDEX] if src_arrays.size() > Mesh.ARRAY_INDEX else null
	var src_indices: PackedInt32Array = PackedInt32Array(src_indices_raw) if src_indices_raw != null else PackedInt32Array()

	var v_count := src_verts.size()
	if v_count == 0:
		sc.queue_free()
		return

	# 计算外部靴子包围盒
	var s_min := src_verts[0]
	var s_max := src_verts[0]
	for v in src_verts:
		s_min.x = min(s_min.x, v.x)
		s_min.y = min(s_min.y, v.y)
		s_min.z = min(s_min.z, v.z)
		s_max.x = max(s_max.x, v.x)
		s_max.y = max(s_max.y, v.y)
		s_max.z = max(s_max.z, v.z)
	var s_size := s_max - s_min
	if s_size.x < 0.001: s_size.x = 0.1
	if s_size.y < 0.001: s_size.y = 0.1
	if s_size.z < 0.001: s_size.z = 0.1

	var pos_size := pos_max - pos_min
	var neg_size := neg_max - neg_min

	var final_verts := PackedVector3Array()
	var final_normals := PackedVector3Array()
	var final_uvs := PackedVector2Array()
	var final_bones := PackedInt32Array()
	var final_weights := PackedFloat32Array()
	var final_indices := PackedInt32Array()

	# 1. 构建正侧（Right Foot）战靴
	for i in range(v_count):
		var orig_v := src_verts[i]
		var nx := (orig_v.x - s_min.x) / s_size.x
		var ny := (orig_v.y - s_min.y) / s_size.y
		var nz := (orig_v.z - s_min.z) / s_size.z
		var mapped_v := Vector3(pos_min.x + nx * pos_size.x, pos_min.y + ny * pos_size.y, pos_min.z + nz * pos_size.z)
		final_verts.append(mapped_v)
		if not src_normals.is_empty():
			final_normals.append(src_normals[i])
		if not src_uvs.is_empty():
			final_uvs.append(src_uvs[i])
		final_bones.append(r_joint_idx)
		final_bones.append(0)
		final_bones.append(0)
		final_bones.append(0)
		final_weights.append(1.0)
		final_weights.append(0.0)
		final_weights.append(0.0)
		final_weights.append(0.0)

	if not src_indices.is_empty():
		for idx in src_indices:
			final_indices.append(idx)
	else:
		for i in range(v_count):
			final_indices.append(i)

	# 2. 构建负侧（Left Foot）战靴（沿左右对称 X 轴镜像映射）
	var offset := v_count
	for i in range(v_count):
		var orig_v := src_verts[i]
		var nx := (orig_v.x - s_min.x) / s_size.x
		var ny := (orig_v.y - s_min.y) / s_size.y
		var nz := (orig_v.z - s_min.z) / s_size.z
		# 负侧 X 坐标从右向左镜像
		var mapped_v := Vector3(neg_max.x - nx * neg_size.x, neg_min.y + ny * neg_size.y, neg_min.z + nz * neg_size.z)
		final_verts.append(mapped_v)
		if not src_normals.is_empty():
			var orig_n := src_normals[i]
			final_normals.append(Vector3(-orig_n.x, orig_n.y, orig_n.z))
		if not src_uvs.is_empty():
			final_uvs.append(src_uvs[i])
		final_bones.append(l_joint_idx)
		final_bones.append(0)
		final_bones.append(0)
		final_bones.append(0)
		final_weights.append(1.0)
		final_weights.append(0.0)
		final_weights.append(0.0)
		final_weights.append(0.0)

	if not src_indices.is_empty():
		var idx_cnt := src_indices.size()
		for tri in range(0, idx_cnt, 3):
			var i0 := src_indices[tri] + offset
			var i1 := src_indices[tri + 1] + offset
			var i2 := src_indices[tri + 2] + offset
			final_indices.append(i0)
			final_indices.append(i2)
			final_indices.append(i1)
	else:
		for i in range(0, v_count, 3):
			final_indices.append(offset + i)
			final_indices.append(offset + i + 2)
			final_indices.append(offset + i + 1)

	var new_arrays: Array = []
	new_arrays.resize(Mesh.ARRAY_MAX)
	new_arrays[Mesh.ARRAY_VERTEX] = final_verts
	if not final_normals.is_empty():
		new_arrays[Mesh.ARRAY_NORMAL] = final_normals
	if not final_uvs.is_empty():
		new_arrays[Mesh.ARRAY_TEX_UV] = final_uvs
	new_arrays[Mesh.ARRAY_BONES] = final_bones
	new_arrays[Mesh.ARRAY_WEIGHTS] = final_weights
	new_arrays[Mesh.ARRAY_INDEX] = final_indices

	var new_mesh := ArrayMesh.new()
	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, new_arrays)
	new_mesh.surface_set_material(0, boot_mat)

	var new_mi := MeshInstance3D.new()
	new_mi.name = "Part_Feet"
	new_mi.mesh = new_mesh
	if base_skin:
		new_mi.skin = base_skin
	skeleton.add_child(new_mi)
	new_mi.transform = Transform3D.IDENTITY
	new_mi.skeleton = NodePath("..")

	visual._slots["feet"] = new_mi
	visual.equipped_glb_paths["feet"] = glb_path
	visual._update_base_body_visibility()

	sc.queue_free()


## 检测装备是否为单侧网格 (原版主手武器保持单侧真实规范，杜绝顶点矩阵拉伸飞天)
static func _mirror_single_sided_mesh_if_needed(_mesh_inst: MeshInstance3D, _joint_names: Array[String]) -> void:
	# 原版 DBO 武器如拳套为 SlotFlag=1 主手佩戴武器，保持原版正规渲染，杜绝拉飞顶点
	return


## 针对单侧鞋靴部件在内存中沿左右对称轴 Y 进行镜像，生成完整合法的双侧蒙皮网格
static func _mirror_equipment_mesh(mesh_inst: MeshInstance3D, sym_map: Dictionary) -> void:
	if mesh_inst == null or mesh_inst.mesh == null or sym_map.is_empty():
		return
	var orig_mesh := mesh_inst.mesh
	var surface_cnt := orig_mesh.get_surface_count()
	if surface_cnt == 0:
		return

	var new_mesh := ArrayMesh.new()
	var modified := false

	for s in range(surface_cnt):
		var arrays := orig_mesh.surface_get_arrays(s)
		if arrays.size() <= Mesh.ARRAY_BONES or arrays[Mesh.ARRAY_VERTEX] == null:
			new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			continue

		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones_raw = arrays[Mesh.ARRAY_BONES]
		var weights_raw = arrays[Mesh.ARRAY_WEIGHTS]

		if verts.is_empty() or bones_raw == null:
			new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			continue

		var v_cnt := verts.size()
		var bones: PackedInt32Array = PackedInt32Array(bones_raw)
		var weights: PackedFloat32Array = PackedFloat32Array(weights_raw) if weights_raw != null else PackedFloat32Array()

		var new_verts := verts.duplicate()
		var new_normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL].duplicate() if arrays.size() > Mesh.ARRAY_NORMAL and arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		var new_uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV].duplicate() if arrays.size() > Mesh.ARRAY_TEX_UV and arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var new_bones := bones.duplicate()
		var new_weights := weights.duplicate()
		var indices_raw = arrays[Mesh.ARRAY_INDEX] if arrays.size() > Mesh.ARRAY_INDEX else null
		var new_indices: PackedInt32Array = PackedInt32Array(indices_raw) if indices_raw != null else PackedInt32Array()

		for vi in range(v_cnt):
			var orig_v := verts[vi]
			# 严格遵循人体左右对称（YZ平面镜像）：X 轴反转，Y 高度与 Z 前后严格保留，杜绝垂直翻转倒立到脖子上
			new_verts.append(Vector3(-orig_v.x, orig_v.y, orig_v.z))
			if not new_normals.is_empty():
				var orig_n := new_normals[vi]
				new_normals.append(Vector3(-orig_n.x, orig_n.y, orig_n.z))
			if not new_uvs.is_empty():
				new_uvs.append(new_uvs[vi])
			for k in range(4):
				var b := bones[vi * 4 + k]
				new_bones.append(sym_map.get(b, b))
				if not new_weights.is_empty():
					new_weights.append(weights[vi * 4 + k])

		if not new_indices.is_empty():
			var idx_cnt := new_indices.size()
			for tri in range(0, idx_cnt, 3):
				var i0 := new_indices[tri] + v_cnt
				var i1 := new_indices[tri + 1] + v_cnt
				var i2 := new_indices[tri + 2] + v_cnt
				new_indices.append(i0)
				new_indices.append(i2)
				new_indices.append(i1)
			arrays[Mesh.ARRAY_INDEX] = new_indices

		arrays[Mesh.ARRAY_VERTEX] = new_verts
		if not new_normals.is_empty():
			arrays[Mesh.ARRAY_NORMAL] = new_normals
		if not new_uvs.is_empty():
			arrays[Mesh.ARRAY_TEX_UV] = new_uvs
		arrays[Mesh.ARRAY_BONES] = new_bones
		if not new_weights.is_empty():
			arrays[Mesh.ARRAY_WEIGHTS] = new_weights
		if arrays.size() > Mesh.ARRAY_TANGENT:
			arrays[Mesh.ARRAY_TANGENT] = null

		new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		if new_mesh.get_surface_count() > s:
			var mat := orig_mesh.surface_get_material(s)
			if mat:
				new_mesh.surface_set_material(s, mat)
		modified = true

	if modified:
		mesh_inst.mesh = new_mesh


## 针对上装装备网格，在内存中提纯过滤掉从母版 DFF 错误合并进来的成人皮肤废面及残损袖管/腕环
## 彻底杜绝双臂浮空袖管与服装贴图污染手臂与胸口
static func _filter_torso_equipment_mesh(_mesh_inst: MeshInstance3D, _joint_names: Array[String], _is_child: bool) -> void:
	return


## 动态解析下装贴图（覆盖全 10 种种族与职业）
static func _resolve_child_pants_texture(race: int, gender: int, class_id: int, glb_path: String) -> Texture2D:
	var base_fn := glb_path.get_file().get_basename().to_lower()
	var g_code := "m" if gender == 0 else "f"
	var cand_paths: Array[String] = []

	# 1. 优先尝试提取装备本身编号 (如 a_hfi_04_01_p_h_m -> a_hfi_m_pants04_01.png)
	if "04_01" in base_fn:
		match race:
			Race.HUMAN:
				if class_id == 1:
					cand_paths.append("res://assets/tex/texture/item/a_hmy_%s_pants04_01.png" % g_code)
				elif class_id == 2:
					cand_paths.append("res://assets/tex/texture/item/a_hen_%s_pants04_01.png" % g_code)
				else:
					cand_paths.append("res://assets/tex/texture/item/a_hfi_%s_pants04_01.png" % g_code)
			Race.NAMEK:
				if class_id == 4:
					cand_paths.append("res://assets/tex/texture/item/a_nmy_pants04_01.png")
				else:
					cand_paths.append("res://assets/tex/texture/item/a_nfi_pants04_01.png")
			Race.MAJIN:
				if class_id == 6:
					cand_paths.append("res://assets/tex/texture/item/a_mwo_%s_pants04_01.png" % g_code)
				else:
					cand_paths.append("res://assets/tex/texture/item/a_mmi_%s_pants04_01.png" % g_code)

	# 2. 尝试从 item 目录中查找 base_fn 相关的贴图
	cand_paths.append("res://assets/tex/texture/item/%s.png" % base_fn)
	cand_paths.append("res://assets/tex/texture/item/%s.png" % base_fn.trim_suffix("_h_m").trim_suffix("_h_f"))

	for cp in cand_paths:
		if FileAccess.file_exists(cp):
			var t := load_texture_safe(cp)
			if t:
				return t
	return null


## 动态解析鞋靴贴图（覆盖全 10 种种族与职业）
static func _resolve_child_boots_texture(race: int, gender: int, class_id: int, glb_path: String) -> Texture2D:
	var base_fn := glb_path.get_file().get_basename().to_lower()
	var g_code := "m" if gender == 0 else "f"
	var cand_paths: Array[String] = []

	# 1. 尝试原生鞋靴编号 (如 a_hfi_m_boots001 / boots002)
	match race:
		Race.HUMAN:
			if class_id == 1:
				cand_paths.append("res://assets/tex/texture/item/a_hmy_%s_boots001.png" % g_code)
				cand_paths.append("res://assets/tex/texture/item/a_hmy_%s_boots002.png" % g_code)
				cand_paths.append("res://assets/tex/texture/item/a_hmy_f_boots001.png")
				cand_paths.append("res://assets/tex/texture/item/a_hfi_m_boots001.png")
			else:
				cand_paths.append("res://assets/tex/texture/item/a_hfi_%s_boots002.png" % g_code)
				cand_paths.append("res://assets/tex/texture/item/a_hfi_%s_boots001.png" % g_code)
		Race.NAMEK:
			cand_paths.append("res://assets/tex/texture/item/a_nfi_boots001.png")
			cand_paths.append("res://assets/tex/texture/item/a_nmy_boots001.png")
		Race.MAJIN:
			cand_paths.append("res://assets/tex/texture/item/a_mmi_%s_boots001.png" % g_code)
			cand_paths.append("res://assets/tex/texture/item/a_mwo_%s_boots001.png" % g_code)
			cand_paths.append("res://assets/tex/texture/item/a_mmi_m_boots001.png")

	cand_paths.append("res://assets/tex/texture/item/%s.png" % base_fn)
	for cp in cand_paths:
		if FileAccess.file_exists(cp):
			var t := load_texture_safe(cp)
			if t:
				return t
	return null


static func _get_item_property_glb_path(model_key: String) -> String:
	var prop := DBOTableManager.get_item_property(model_key)
	# Namek child skin variants share the S1 property record; the other exported
	# meshes exist beside it under the same mesh directory.
	var is_namek_child_skin_variant := model_key.begins_with("A_NCH_") and model_key.right(2) in ["_S2", "_S3", "_S4", "_S5"]
	if prop.is_empty() and is_namek_child_skin_variant:
		var base_key := model_key.left(model_key.length() - 2) + "S1"
		prop = DBOTableManager.get_item_property(base_key)
	if prop.is_empty():
		return ""
	var m_path: String = prop.get("mesh_path", "")
	var m_file: String = prop.get("mesh_file", "")
	if m_file.is_empty():
		return ""
	var clean_dir := m_path.trim_prefix(".\\Item\\").trim_prefix(".\\item\\").replace("\\", "/").to_lower()
	var clean_file := m_file.to_lower().replace(".dff", ".glb")
	if model_key.begins_with("A_NCH_") and model_key.length() >= 2:
		var skin_suffix := model_key.right(2).to_lower()
		if skin_suffix in ["_s2", "_s3", "_s4", "_s5"]:
			clean_file = clean_file.trim_suffix("_s1.glb") + skin_suffix + ".glb"
	var glb_url := "res://assets/obj/item/%s%s" % [clean_dir, clean_file]
	return glb_url if FileAccess.file_exists(glb_url) else ""


static func _get_pc_property_name(race: int, gender: int, is_adult: bool) -> String:
	match race:
		Race.HUMAN:
			if gender == Gender.MALE:
				return "A_HFI_M_AD" if is_adult else "A_HFI_M_CH"
			else:
				return "A_HFI_F_AD" if is_adult else "A_HFI_F_CH"
		Race.NAMEK:
			return "A_NFI_AD" if is_adult else "A_NFI_CH"
		Race.MAJIN:
			if gender == Gender.MALE:
				return "A_MMI_M_AD" if is_adult else "A_MMI_M_CH"
			else:
				return "A_MMI_F_AD" if is_adult else "A_MMI_F_CH"
	return "A_HFI_M_AD" if is_adult else "A_HFI_M_CH"


static func _get_anim_prefix(race: int, gender: int, is_adult: bool) -> String:
	match race:
		Race.HUMAN:
			if gender == Gender.MALE:
				return "a_hum_m_" if is_adult else "a_hch_m_"
			else:
				return "a_hum_f_" if is_adult else "a_hch_f_"
		Race.NAMEK:
			return "a_nam_" if is_adult else "a_nch_"
		Race.MAJIN:
			if gender == Gender.MALE:
				return "a_maj_m_" if is_adult else "a_mch_m_"
			else:
				return "a_maj_f_" if is_adult else "a_mch_f_"
	return "a_hum_m_"


static func _extract_mob_family(model_name: String) -> String:
	# 如 m_akm_a1 -> family 提取前两段 m_akm
	var parts := model_name.split("_")
	if parts.size() >= 2:
		return "%s_%s" % [parts[0], parts[1]]
	return model_name


static func _slot_flag_to_name(slot_flag: int) -> String:
	match slot_flag:
		1: return "weapon_r"
		2: return "weapon_l"
		4: return "torso"
		8: return "legs"
		16: return "feet"
		32: return "face" # Scouter
		64: return "head"
		4096: return "torso" # Costume / Dogi
		8192: return "head" # Cap
		_: return "torso"


static func _clear_owner_recursive(node: Node) -> void:
	if node == null:
		return
	node.owner = null
	for child in node.get_children():
		_clear_owner_recursive(child)
