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


## 检索素体模型路径 (儿童期使用官方绑定骨骼与新手服饰模型，成人期使用对应族群成人素体)
static func get_pc_model_path(race: int, gender: int, is_adult: bool, _prop_name: String = "") -> String:
	# 选角与创角及童年期角色：必须使用内嵌标准骨骼架构与初始新手服饰的儿童模型
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
										var b_idx := skel.find_bone("Bip01")
										var rest_origin := skel.get_bone_rest(b_idx).origin
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
	var slot_name := _slot_flag_to_name(slot_flag)

	var glb_path := _resolve_item_glb_path(raw_model, race, gender, is_adult)
	if glb_path.is_empty() or not FileAccess.file_exists(glb_path):
		return

	# 史考特（Scouter）挂载到头部骨骼附件节点
	if slot_flag == 32:
		visual.attach_item_to_bone(slot_name, glb_path, raw_model)
		return

	# 非手套类武器（杖、剑、斧等）挂到手部骨骼附件节点；手套是蒙皮网格走主管线
	if (slot_flag == 1 or slot_flag == 2) and "glv" not in raw_model.to_lower():
		visual.attach_item_to_bone(slot_name, glb_path, raw_model)
		return

	# 上装/下装/靴子/手套：蒙皮网格，必须用 GLTFDocument 动态加载保留 Skin
	var skeleton := visual._skeleton
	if skeleton == null:
		return

	var sc: Node = DBOMaterialHelper.load_gltf_scene_safe(glb_path, GLTFDocument.IMPORT_FLAG_USE_NAMED_SKIN_BINDS)
	if sc == null:
		push_warning("[equip_item_to_character] load_gltf_scene_safe failed: %s" % glb_path)
		return

	# 找到蒙皮 MeshInstance3D
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
	mesh_inst.get_parent().remove_child(mesh_inst)
	mesh_inst.name = "Part_" + slot_name.capitalize()
	_clear_owner_recursive(mesh_inst)

	# 先移除旧槽位部件
	visual.unequip_slot(slot_name)

	# 应用 Skin：优先自身 Skin，其次素体 Skin
	if own_skin != null:
		mesh_inst.skin = own_skin
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

	# 绑定到素体同一 Skeleton3D
	skeleton.add_child(mesh_inst)
	mesh_inst.skeleton = mesh_inst.get_path_to(skeleton)
	mesh_inst.material_override = null

	# 修复材质（透明度/双面等）
	DBOMaterialHelper.fix_mesh_materials(mesh_inst)

	# 皮肤与布料材质派发及肤色同步染色（对标 OpenDBO-Core 逆向与旧工程魔人修复标准）
	var c_skin_col := visual.current_skin_color
	if c_skin_col == Color.WHITE and visual._last_customization_args.size() >= 6:
		var c_skin_col_num: int = clampi(int(visual._last_customization_args[5]), 1, 5)
		var def_tbl := DBOTableManager.get_default_item_list()
		var type_str := visual._get_character_type_string(race, gender, is_adult)
		var type_data: Dictionary = def_tbl.get(type_str, {})
		var skin_cols: Dictionary = type_data.get("skin_color", {})
		var sc_arr: Array = skin_cols.get(str(c_skin_col_num), [1.0, 1.0, 1.0])
		if sc_arr.size() >= 3 and race != 1:
			c_skin_col = Color(sc_arr[0], sc_arr[1], sc_arr[2])

	# 魔人默认粉红保底，严禁退回纯白导致白模
	if race == 2 and (c_skin_col == Color.WHITE or c_skin_col.a < 0.01):
		c_skin_col = Color(0.9922, 0.7412, 0.8627)
	visual.current_skin_color = c_skin_col

	var is_majin_jacket := (race == 2 and slot_name == "torso")
	var is_majin_female := (gender == 1)

	if is_majin_jacket:
		_apply_majin_jacket_materials(mesh_inst, glb_path, is_majin_female, c_skin_col)
	else:
		for s in range(mesh_inst.mesh.get_surface_count()):
			var smat := mesh_inst.get_surface_override_material(s)
			if smat == null:
				smat = mesh_inst.mesh.surface_get_material(s)
			if smat:
				var m_name := smat.resource_name.to_lower()
				if "skin" in m_name:
					var skin_mat := smat.duplicate() as StandardMaterial3D
					if skin_mat:
						skin_mat.albedo_color = c_skin_col
						mesh_inst.set_surface_override_material(s, skin_mat)

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
		"res://assets/tex/texture/item/%s%sjacket04_01_2.png" % [pfx, gender_str]
	]

	for tc in candidates:
		var t := load_texture_safe(tc)
		if t:
			return t
	return null


## 针对魔人两种职业男女上衣执行精准多图元材质派发与动态肤色合成（彻底消除肩臂白模与服装显示错误）
static func _apply_majin_jacket_materials(mesh_inst: MeshInstance3D, glb_path: String, is_female: bool, skin_color: Color) -> void:
	if mesh_inst == null or mesh_inst.mesh == null:
		return

	# 保底肤色：魔人族默认粉红 (0.9922, 0.7412, 0.8627)，绝不允许纯白 (WHITE) 造成肩臂白模
	if skin_color == Color.WHITE or skin_color.a < 0.01:
		skin_color = Color(0.9922, 0.7412, 0.8627)

	var glb_lower := glb_path.to_lower()
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
			var mat := StandardMaterial3D.new()
			mat.roughness = 0.8
			mat.cull_mode = BaseMaterial3D.CULL_BACK
			var tex: Texture2D = null
			if base_mat is BaseMaterial3D and (base_mat as BaseMaterial3D).albedo_texture:
				tex = (base_mat as BaseMaterial3D).albedo_texture
			if not tex:
				if "jacket" in mat_name and not ("01_2" in mat_name or "04_01_2" in mat_name or "04_02_2" in mat_name):
					tex = cloth_shirt_tex
				else:
					tex = scarf_tex
			mat.albedo_texture = tex
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


## 动态推断装备 GLB 路径 (严格依据 OpenDBO itemproperty.json 官方模型映射)
## 支持成人素体与儿童素体 (儿童素体优先路由到 child/ 子目录烘焙模型)
static func _resolve_item_glb_path(raw_model: String, race: int = 0, gender: int = 0, is_adult: bool = true) -> String:
	var u := raw_model.to_upper().strip_edges()
	if u.is_empty():
		return ""

	var prefixes: Array[String] = [u]
	var suffixes: Array[String] = []

	if race == Race.NAMEK:
		if u.begins_with("A_HFI_") or u.begins_with("A_HCH_"):
			prefixes.insert(0, u.replace("A_HFI_", "A_NFI_").replace("A_HCH_", "A_NCH_"))
		elif u.begins_with("A_HMY_"):
			prefixes.insert(0, u.replace("A_HMY_", "A_NMY_"))
		suffixes = ["_N_O_S1", "_N_S1", "_N_O", ""]
	elif race == Race.MAJIN:
		if u.begins_with("A_HFI_") or u.begins_with("A_HCH_"):
			prefixes.insert(0, u.replace("A_HFI_", "A_MMI_").replace("A_HCH_", "A_MCH_"))
		elif u.begins_with("A_HMY_"):
			prefixes.insert(0, u.replace("A_HMY_", "A_MWO_"))
		suffixes = ["_M_F" if gender == Gender.FEMALE else "_M_M", ""]
	else: # Human
		suffixes = ["_H_F" if gender == Gender.FEMALE else "_H_M", ""]

	# 1. 优先通过 itemproperty.json 查询官方模型路径
	for p in prefixes:
		for s in suffixes:
			var cand := p + s
			var prop := DBOTableManager.get_item_property(cand)
			if not prop.is_empty():
				var m_path: String = prop.get("mesh_path", "")
				var m_file: String = prop.get("mesh_file", "")
				if not m_file.is_empty():
					var clean_dir := m_path.trim_prefix(".\\Item\\").trim_prefix(".\\item\\").replace("\\", "/").to_lower()
					var clean_file := m_file.to_lower().replace(".dff", ".glb")
					if not is_adult:
						var dbo_child_armor := "E:/DBO_Offline/assets/models/items/armors/child/" + clean_file
						if FileAccess.file_exists(dbo_child_armor):
							return dbo_child_armor
						var dbo_child_weapon := "E:/DBO_Offline/assets/models/items/weapons/child/" + clean_file
						if FileAccess.file_exists(dbo_child_weapon):
							return dbo_child_weapon
						var child_url := "res://assets/obj/item/%schild/%s" % [clean_dir, clean_file]
						if FileAccess.file_exists(child_url):
							return child_url
					var glb_url := "res://assets/obj/item/%s%s" % [clean_dir, clean_file]
					if FileAccess.file_exists(glb_url):
						return glb_url

	# 2. 回退机制：装备子目录穷举检索
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

	for p in prefixes:
		for s in suffixes:
			var target_file: String = (p + s).to_lower() + ".glb"
			if not is_adult:
				var dbo_child_armor := "E:/DBO_Offline/assets/models/items/armors/child/" + target_file
				if FileAccess.file_exists(dbo_child_armor):
					return dbo_child_armor
				var dbo_child_weapon := "E:/DBO_Offline/assets/models/items/weapons/child/" + target_file
				if FileAccess.file_exists(dbo_child_weapon):
					return dbo_child_weapon
			for sdir: String in search_dirs:
				if not is_adult:
					var child_path: String = sdir + "child/" + target_file
					if FileAccess.file_exists(child_path):
						return child_path
				var test_path: String = sdir + target_file
				if FileAccess.file_exists(test_path):
					return test_path

	return ""


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
