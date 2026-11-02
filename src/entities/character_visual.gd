class_name DBOCharacterVisual
extends Node3D

## DBO Character Visual Component
## 负责角色的多部件换装渲染、共享骨骼绑定与动画播放控制。
## 网格与动画彻底解耦：多个装备部件作为 MeshInstance3D 挂载到同一 Skeleton3D 下，
## 动画轨通过 AnimationPlayer 载入轻量级骨骼动画库，不占用冗余模型内存。

signal animation_started(anim_name: String)
signal animation_finished(anim_name: String)

enum Race {
	HUMAN = 0,
	NAMEK = 1,
	MAJIN = 2
}

enum Gender {
	MALE = 0,
	FEMALE = 1
}

@export var character_property_name: String = ""
@export var race: int = 0
@export var gender: int = 0
@export var is_adult: bool = false

# 装备插槽映射
var _slots: Dictionary = {
	"head": null,
	"face": null,
	"hair": null,
	"torso": null,
	"legs": null,
	"hands": null,
	"feet": null,
	"weapon_r": null,
	"weapon_l": null,
	"back": null
}

var _skeleton: Skeleton3D = null
var _anim_player: AnimationPlayer = null
var _event_dispatcher: Node = null

var is_super_saiyan: bool = false:
	set(val):
		if is_super_saiyan != val:
			is_super_saiyan = val
			if _last_customization_args.size() >= 6:
				apply_character_customization.callv(_last_customization_args)

var _last_customization_args: Array = []
var current_skin_color: Color = Color.WHITE
var equipped_glb_paths: Dictionary = {}


## 激活或取消超级赛亚人形态
func set_super_saiyan(active: bool) -> void:
	is_super_saiyan = active


func _ready() -> void:
	_init_components()


func _ensure_skeleton() -> void:
	if _skeleton != null and _skeleton.get_bone_count() > 0:
		return
	var sk := find_child("Skeleton3D", true, false) as Skeleton3D
	if sk != null and sk.get_bone_count() > 0:
		_skeleton = sk
		return
	var skels := find_children("*", "Skeleton3D", true, false)
	for s in skels:
		var s_cast := s as Skeleton3D
		if s_cast and s_cast.get_bone_count() > 0:
			_skeleton = s_cast
			return
	if _skeleton == null:
		_skeleton = Skeleton3D.new()
		_skeleton.name = "GeneralSkeleton"
		add_child(_skeleton)


func _init_components() -> void:
	_ensure_skeleton()

	# 查找或初始化 AnimationPlayer
	_anim_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim_player == null:
		_anim_player = AnimationPlayer.new()
		_anim_player.name = "AnimationPlayer"
		add_child(_anim_player)
		_anim_player.animation_started.connect(func(anim): animation_started.emit(anim))
		_anim_player.animation_finished.connect(func(anim): animation_finished.emit(anim))

	# 查找或初始化动作事件派发器
	_event_dispatcher = find_child("AnimEventDispatcher", true, false)
	if _event_dispatcher == null:
		_event_dispatcher = AnimEventDispatcher.new()
		_event_dispatcher.name = "AnimEventDispatcher"
		add_child(_event_dispatcher)


## 挂载装备或部件网格到统一 Skeleton3D
func equip_mesh_part(slot_name: String, mesh: Mesh, material: Material = null) -> MeshInstance3D:
	var slot_key := slot_name.to_lower().strip_edges()
	# 移除原有部件
	unequip_slot(slot_key)

	if mesh == null:
		return null

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Part_" + slot_key.capitalize()
	mesh_inst.mesh = mesh
	if material:
		mesh_inst.material_override = material

	# 绑定到统一骨骼
	if _skeleton:
		_skeleton.add_child(mesh_inst)
		mesh_inst.skeleton = mesh_inst.get_path_to(_skeleton)
	else:
		add_child(mesh_inst)

	_slots[slot_key] = mesh_inst
	_update_base_body_visibility()
	return mesh_inst


## 卸下指定槽位装备
func unequip_slot(slot_name: String) -> void:
	var slot_key := slot_name.to_lower().strip_edges()
	var keys_to_clear: Array[String] = [slot_key]
	if slot_key == "weapon_r" or slot_key == "hands":
		keys_to_clear = ["weapon_r", "hands"]
	for k in keys_to_clear:
		if _slots.has(k) and is_instance_valid(_slots[k]):
			var old_part: Node = _slots[k]
			old_part.queue_free()
			_slots[k] = null
		equipped_glb_paths.erase(k)
	_update_base_body_visibility()


static var _invisible_mat: StandardMaterial3D = null

static func _get_invisible_material() -> StandardMaterial3D:
	if _invisible_mat == null:
		_invisible_mat = StandardMaterial3D.new()
		_invisible_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_invisible_mat.albedo_color = Color(0, 0, 0, 0)
		_invisible_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_invisible_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return _invisible_mat


## 穿戴外装时动态隐藏素体冲突表面（彻底消除素体胸腹、裤腿与靴子穿模破皮）
func _update_base_body_visibility() -> void:
	if not _last_customization_args.is_empty():
		apply_character_customization(
			int(_last_customization_args[0]),
			int(_last_customization_args[1]),
			int(_last_customization_args[2]),
			int(_last_customization_args[3]),
			int(_last_customization_args[4]),
			int(_last_customization_args[5])
		)
	else:
		apply_character_customization(race, gender, 1, 1, 1, 1)


## 将史考特/武器 GLB 通过 GLTFDocument 加载并挂载到指定骨骼附件节点
## slot_name: "face"（史考特）| "weapon_r" | "weapon_l"
func attach_item_to_bone(slot_name: String, glb_path: String, model_name: String = "") -> void:
	_ensure_skeleton()
	if _skeleton == null:
		return
	# 按槽位确定挂载骨骼
	var bone_names: Array[String] = []
	match slot_name:
		"face":  # 史考特挂在眼部/头部骨骼
			bone_names = ["nulleye", "Bip01 Head"]
		"weapon_r":
			bone_names = ["nullRhand", "Bip01 R Hand"]
		"weapon_l":
			bone_names = ["nullLhand", "Bip01 L Hand"]
		_:
			return

	# 清理旧挂载
	var old_attach := _skeleton.find_child("ItemAttach_" + slot_name, true, false)
	if old_attach:
		old_attach.queue_free()

	if glb_path.is_empty() or not FileAccess.file_exists(glb_path):
		return

	var sc: Node = DBOMaterialHelper.load_gltf_scene_safe(glb_path, 0)
	if sc == null:
		return

	var mesh_nodes := sc.find_children("*", "MeshInstance3D", true, false)
	var mesh_inst: MeshInstance3D = null
	for c in mesh_nodes:
		if c is MeshInstance3D:
			mesh_inst = c
			break
	if mesh_inst == null or mesh_inst.mesh == null:
		sc.queue_free()
		return

	mesh_inst.get_parent().remove_child(mesh_inst)
	_clear_owner_recursive(mesh_inst)
	mesh_inst.name = "Item_" + slot_name

	DBOMaterialHelper.fix_mesh_materials(mesh_inst)

	# 找到目标骨骼
	var bone_idx := -1
	for bn in bone_names:
		bone_idx = _skeleton.find_bone(bn)
		if bone_idx != -1:
			break
	if bone_idx == -1:
		sc.queue_free()
		return

	var attachment := BoneAttachment3D.new()
	attachment.name = "ItemAttach_" + slot_name
	attachment.bone_name = _skeleton.get_bone_name(bone_idx)
	_skeleton.add_child(attachment)

	# 严格按照官方 tbl/linkitemtrasformlist.xml 与各族骨骼比例设定位置与旋转
	if slot_name == "face":
		var sct_scale := 1.30
		var sct_pos := Vector3(-0.005, -0.010, -0.010)
		var rot_x_deg := 0.0

		if race == Race.MAJIN or race == 2:
			if gender == Gender.MALE or gender == 0:
				sct_scale = 0.95
				sct_pos = Vector3(-0.005, -0.010, -0.010)
				rot_x_deg = 0.0
			else:
				sct_scale = 1.20
				sct_pos = Vector3(0.0, -0.010, 0.0)
				rot_x_deg = 0.0
		elif race == Race.NAMEK or race == 1:
			sct_scale = 1.20
			sct_pos = Vector3(-0.020, -0.030, -0.010)
			rot_x_deg = -8.0
		else: # Human
			if gender == Gender.FEMALE or gender == 1:
				sct_scale = 1.30
				sct_pos = Vector3(-0.010, -0.015, -0.020)
				rot_x_deg = 5.0
			else:
				sct_scale = 1.30
				sct_pos = Vector3(-0.005, -0.010, -0.010)
				rot_x_deg = 0.0

		if is_adult:
			sct_scale = 1.0
			sct_pos = Vector3(0.0, -0.010, -0.015)
			rot_x_deg = 0.0

		var sct_rot := Vector3(deg_to_rad(rot_x_deg), 0.0, 0.0)
		var basis := Basis.from_euler(sct_rot).scaled(Vector3(sct_scale, sct_scale, sct_scale))
		mesh_inst.transform = Transform3D(basis, sct_pos)

		# 史考特耳机材质精细分工 (Surface 0: 结实不透明耳机外壳，Surface 1: 双面晶莹半透明镜片)
		var sct_tex_name := raw_model.to_lower()
		var sct_tex_path := "res://assets/tex/texture/item/" + sct_tex_name + ".png"
		if not ResourceLoader.exists(sct_tex_path):
			sct_tex_path = "res://assets/tex/texture/item/i_sct_01.png"
		var sct_albedo: Texture2D = (ResourceLoader.load(sct_tex_path) as Texture2D) if ResourceLoader.exists(sct_tex_path) else null

		for s in range(mesh_inst.mesh.get_surface_count()):
			if s == 0:
				var body_mat := StandardMaterial3D.new()
				body_mat.roughness = 0.5
				body_mat.metallic = 0.1
				body_mat.cull_mode = BaseMaterial3D.CULL_BACK
				body_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				if sct_albedo:
					body_mat.albedo_texture = sct_albedo
				body_mat.albedo_color = Color.WHITE
				mesh_inst.set_surface_override_material(0, body_mat)
			else:
				var lens_mat := StandardMaterial3D.new()
				lens_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				lens_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
				lens_mat.roughness = 0.1
				lens_mat.metallic = 0.0
				lens_mat.albedo_color = Color(0.2, 0.95, 0.35, 0.45)
				lens_mat.emission_enabled = true
				lens_mat.emission = Color(0.1, 0.85, 0.25)
				lens_mat.emission_energy_multiplier = 0.5
				mesh_inst.set_surface_override_material(s, lens_mat)
	else:
		if not is_adult:
			mesh_inst.scale = Vector3(0.65, 0.65, 0.65)
		mesh_inst.rotation = Vector3(-PI / 2.0, 0.0, 0.0)
		mesh_inst.position = Vector3.ZERO

	_clear_owner_recursive(mesh_inst)
	mesh_inst.owner = null
	attachment.add_child(mesh_inst)
	_slots[slot_name] = mesh_inst

	sc.queue_free()


static func _clear_owner_recursive(node: Node) -> void:
	if node == null:
		return
	node.owner = null
	for child in node.get_children():
		_clear_owner_recursive(child)


## 挂接手部或背部独立物体（如单手剑、法杖、龟仙人龟壳）
func attach_object_to_bone(bone_name: String, obj_node: Node3D, offset: Vector3 = Vector3.ZERO) -> BoneAttachment3D:
	if _skeleton == null:
		push_warning("[DBOCharacterVisual] Skeleton3D 不存在，无法挂接骨骼物体")
		return null

	var bone_idx := _skeleton.find_bone(bone_name)
	if bone_idx == -1:
		push_warning("[DBOCharacterVisual] 未找到骨骼: " + bone_name)
		return null

	var attachment := BoneAttachment3D.new()
	attachment.name = "Attach_" + bone_name
	_skeleton.add_child(attachment)
	attachment.bone_idx = bone_idx
	attachment.bone_name = bone_name

	if not is_adult:
		obj_node.scale = Vector3(0.65, 0.65, 0.65)
	obj_node.position = offset
	attachment.add_child(obj_node)
	return attachment


## 载入并应用骨骼缩放矩阵（魔人肥胖/矮小、那美克星人体型调整）
func apply_bone_scaling(bone_data: Dictionary) -> void:
	if bone_data.is_empty():
		return

	if bone_data.get("apply_base_scale", false):
		var base_scale: Array = bone_data.get("base_scale", [1.0, 1.0, 1.0])
		if base_scale.size() == 3:
			scale = Vector3(base_scale[0], base_scale[1], base_scale[2])


## 播放指定动作 (支持指定融合过渡时长)
func play_animation(anim_name: String, blend_time: float = 0.2) -> void:
	if _anim_player == null:
		_anim_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim_player and _anim_player.has_animation(anim_name):
		_anim_player.play(anim_name, blend_time)
		if _event_dispatcher:
			_event_dispatcher.on_animation_played(character_property_name, anim_name)


## 检查指定动作是否正在播放
func is_playing_animation(anim_name: String) -> bool:
	if _anim_player:
		return _anim_player.is_playing() and _anim_player.current_animation == anim_name
	return false


## 获取当前正在播放的动作名
func get_current_animation() -> String:
	return _anim_player.current_animation if _anim_player else ""


## 动画分层播放支持 (严格对标 OpenDBO: CNtlAnimLayer - ANM_LAYER_BASE, ANM_LAYER_UPPER)
## 当处于移动奔跑时释放攻击/蓄气/格挡，以高优先级过渡并保持打击帧事件调度
func play_action_animation(anim_name: String, blend_time: float = 0.15) -> void:
	if _anim_player and _anim_player.has_animation(anim_name):
		_anim_player.play(anim_name, blend_time)
		if _event_dispatcher:
			_event_dispatcher.on_animation_played(character_property_name, anim_name)


## 受击高亮白光着色器闪烁 (对标 OpenDBO: NtlSobActor::OnDamageFlash)
func trigger_hit_flash(duration: float = 0.12, flash_color: Color = Color.WHITE) -> void:
	var meshes: Array[MeshInstance3D] = []
	for child in find_children("*", "MeshInstance3D", true, false):
		meshes.append(child as MeshInstance3D)

	if meshes.is_empty():
		return

	var original_materials: Dictionary = {}
	for mi in meshes:
		if mi.material_override:
			original_materials[mi] = mi.material_override
			if mi.material_override is StandardMaterial3D:
				var std_mat := (mi.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
				std_mat.emission_enabled = true
				std_mat.emission = flash_color
				std_mat.emission_energy_multiplier = 2.2
				mi.material_override = std_mat
		else:
			var flash_mat := StandardMaterial3D.new()
			flash_mat.albedo_color = flash_color
			flash_mat.emission_enabled = true
			flash_mat.emission = flash_color
			flash_mat.emission_energy_multiplier = 2.2
			mi.material_override = flash_mat

	var tween := create_tween()
	tween.tween_interval(duration)
	tween.tween_callback(func():
		for mi in meshes:
			if is_instance_valid(mi):
				if original_materials.has(mi):
					mi.material_override = original_materials[mi]
				else:
					mi.material_override = null
	)


## 注册骨骼动画库 (AnimationLibrary)
func register_animation_library(library_name: String, library: AnimationLibrary) -> void:
	if _anim_player:
		if _anim_player.has_animation_library(library_name):
			_anim_player.remove_animation_library(library_name)
		_anim_player.add_animation_library(library_name, library)


const CHARACTER_FACE_SHADER: Shader = preload("res://src/shaders/character_face.gdshader")
const CHARACTER_SKIN_SHADER: Shader = preload("res://src/shaders/character_skin.gdshader")


func _find_main_mesh_instance() -> MeshInstance3D:
	var base_body := find_child("BaseBody", true, false)
	if base_body == null:
		var meshes := find_children("*", "MeshInstance3D", true, false)
		return (meshes[0] as MeshInstance3D) if not meshes.is_empty() else null
	if base_body is MeshInstance3D:
		return base_body as MeshInstance3D
	var child_meshes := base_body.find_children("*", "MeshInstance3D", true, false)
	return (child_meshes[0] as MeshInstance3D) if not child_meshes.is_empty() else null


## 获取官方角色类型字符串标识 (严格对标 DefaultItemList.xml: CHARACTER_TYPE)
func _get_character_type_string(c_race: int, c_gender: int, c_adult: bool) -> String:
	match c_race:
		0:
			if c_adult:
				return "HUMAN_ADULT_MALE" if c_gender == 0 else "HUMAN_ADULT_FEMALE"
			else:
				return "HUMAN_CHILD_MALE" if c_gender == 0 else "HUMAN_CHILD_FEMALE"
		1:
			return "NAMEK_ADULT" if c_adult else "NAMEK_CHILD"
		2:
			if c_adult:
				return "MAJIN_ADULT_MALE" if c_gender == 0 else "MAJIN_ADULT_FEMALE"
			else:
				return "MAJIN_CHILD_MALE" if c_gender == 0 else "MAJIN_CHILD_FEMALE"
	return "HUMAN_CHILD_MALE"


## 检索五官面部贴图路径 (严格从 default_item_list.json 表检索，杜绝脚本硬编码)
func _get_face_texture_path(c_race: int, c_gender: int, face_num: int, skin_color_num: int = 1) -> String:
	var def_tbl := DBOTableManager.get_default_item_list()
	var type_str := _get_character_type_string(c_race, c_gender, is_adult)
	var type_data: Dictionary = def_tbl.get(type_str, {})
	var multi_tex: Dictionary = type_data.get("face_multi_texture", {})
	var key := "%d_%d" % [face_num, skin_color_num]
	if not multi_tex.has(key):
		key = "%d_1" % face_num
	var tex_name: String = str(multi_tex.get(key, ""))
	if not tex_name.is_empty():
		return "res://assets/tex/texture/item/" + tex_name.to_lower() + ".png"
	return ""


## 检索官方角色头部骨骼缩放与位移 (严格自 characterproperty.json 官方骨骼数据读取)
static func get_head_transform(prop_key: String) -> Dictionary:
	var prop := DBOTableManager.get_character_property(prop_key)
	if prop.is_empty():
		return { "scale": 1.0, "offset": Vector3.ZERO }

	var bdata: Dictionary = prop.get("bone_data", {})
	var bscales: Array = bdata.get("bone_scales", [])
	# Bip01 Head 在 DBO 官方骨骼中索引为 29
	var h_scale: float = 1.0
	if bscales.size() > 29:
		var head_bone: Dictionary = bscales[29]
		h_scale = float(head_bone.get("length", 1.0))

	var pos_off: Array = bdata.get("pos_offset", [0.0, 0.0, 0.0])
	var off_vec := Vector3(pos_off[0], pos_off[1], pos_off[2]) if pos_off.size() >= 3 else Vector3.ZERO
	return { "scale": h_scale, "offset": off_vec }


func _get_default_prop_key(c_race: int, c_gender: int, c_adult: bool) -> String:
	match c_race:
		0:
			return ("A_HFI_M_AD" if c_gender == 0 else "A_HFI_F_AD") if c_adult else ("A_HFI_M_CH" if c_gender == 0 else "A_HFI_F_CH")
		1:
			return "A_NFI_AD" if c_adult else "A_NFI_CH"
		2:
			return ("A_MMI_M_AD" if c_gender == 0 else "A_MMI_F_AD") if c_adult else ("A_MMI_M_CH" if c_gender == 0 else "A_MMI_F_CH")
	return "A_HFI_M_CH"



func _resolve_head_mesh_path(c_race: int, c_gender: int, c_adult: bool, hair_num: int) -> String:
	var def_tbl := DBOTableManager.get_default_item_list()
	var type_str := _get_character_type_string(c_race, c_gender, c_adult)
	var type_data: Dictionary = def_tbl.get(type_str, {})
	var head_meshes: Dictionary = type_data.get("head_mesh", {})
	var mesh_key := str(head_meshes.get(str(hair_num), ""))
	if mesh_key.is_empty():
		return ""

	var folder := ""
	match c_race:
		0:
			folder = "mesh_armor_humanmale" if c_gender == 0 else "mesh_armor_humanfemale"
		1:
			folder = "mesh_armor_namek"
		2:
			folder = "mesh_armor_majinmale" if c_gender == 0 else "mesh_armor_majinfemale"

	var full_path := "res://assets/obj/item/%s/%s.glb" % [folder, mesh_key.to_lower()]
	if ResourceLoader.exists(full_path):
		return full_path
	return ""


## 应用官方外观定制 (发型/发色/触角、五官面部贴图与肤色，严格对标 DefaultItemList.xml 与 NtlPLEquipItem.cpp)
func apply_character_customization(c_race: int, c_gender: int, hair_id: int, hair_color_id: int, face_id: int, skin_color_id: int) -> void:
	_ensure_skeleton()
	var mesh_inst := _find_main_mesh_instance()
	if mesh_inst == null or mesh_inst.mesh == null:
		return

	_last_customization_args = [c_race, c_gender, hair_id, hair_color_id, face_id, skin_color_id]

	var hair_num: int = clampi(hair_id, 1, 10)
	var hair_col_num: int = clampi(hair_color_id, 1, 13)
	var face_num: int = clampi(face_id, 1, 10)
	var skin_col_num: int = clampi(skin_color_id, 1, 5)

	# 严格从 default_item_list.json 读取官方全种族 RGB 颜色与贴图
	var def_tbl := DBOTableManager.get_default_item_list()
	var type_str := _get_character_type_string(c_race, c_gender, is_adult)
	var type_data: Dictionary = def_tbl.get(type_str, {})
	var head_cols: Dictionary = type_data.get("head_color", {})
	var skin_cols: Dictionary = type_data.get("skin_color", {})

	var default_head_key := "4" if c_race == 0 and c_gender == 0 else "1"
	var head_col_arr: Array = head_cols.get(str(hair_col_num), head_cols.get(default_head_key, [1.0, 1.0, 1.0]))
	var skin_col_arr: Array = skin_cols.get(str(skin_col_num), skin_cols.get("1", [1.0, 1.0, 1.0]))

	var hair_col := Color(head_col_arr[0], head_col_arr[1], head_col_arr[2]) if head_col_arr.size() >= 3 else Color.WHITE
	var skin_col := Color(skin_col_arr[0], skin_col_arr[1], skin_col_arr[2]) if skin_col_arr.size() >= 3 else Color.WHITE

	if c_race == 2 and (skin_col == Color.WHITE or skin_col.a < 0.01):
		skin_col = Color(0.9922, 0.7412, 0.8627)

	# 那美克星人：原版基础贴图已内嵌经典绿与肌肉红，基准色保持纯白，触角采用原生纹理
	current_skin_color = Color.WHITE if c_race == 1 else skin_col

	var face_skin_tint := Color.WHITE if c_race == 1 else skin_col
	var body_skin_tint := Color.WHITE if c_race == 1 else skin_col

	# 计算对应种族与性别的五官贴图路径 (对标 DefaultItemList.xml: FACE_MULTI_TEXTURE)
	var face_tex_path := _get_face_texture_path(c_race, c_gender, face_num, skin_col_num)
	var face_tex: Texture2D = (ResourceLoader.load(face_tex_path) as Texture2D) if (face_tex_path != "" and ResourceLoader.exists(face_tex_path)) else null

	var inv_mat := _get_invisible_material()
	var has_torso := (_slots.get("torso") != null)
	var has_legs := (_slots.get("legs") != null)
	var has_feet := (_slots.get("feet") != null)
	var has_hands := (_slots.get("hands") != null or (_slots.get("weapon_r") != null and "glv" in str(equipped_glb_paths.get("weapon_r", "")).to_lower()))

	var target_hair_slot := "mat_hair_%02d" % hair_num

	for s in range(mesh_inst.mesh.get_surface_count()):
		var base_mat := mesh_inst.mesh.surface_get_material(s)
		if base_mat == null:
			continue
		var mat_name := base_mat.resource_name.to_lower()
		var tex_name := ""
		var orig_tex: Texture2D = null
		if base_mat is BaseMaterial3D:
			orig_tex = (base_mat as BaseMaterial3D).albedo_texture
			if orig_tex:
				tex_name = orig_tex.resource_path.to_lower()

		var is_hair_slot := mat_name.begins_with("mat_hair_") or "head01" in mat_name or "hair_acc" in mat_name or "hair_accessory" in mat_name
		var is_fskin := ("fskin" in mat_name or "fskin" in tex_name)
		var is_underwear := ("pants000" in mat_name or "pants000" in tex_name or "jacket000" in mat_name or "jacket000" in tex_name)
		var is_boots := ("boots" in mat_name or "boots" in tex_name) and not is_underwear
		var is_jacket := ("jacket" in mat_name or "jacket" in tex_name) and not is_underwear
		var is_pants := ("pants" in mat_name or "pants" in tex_name) and not is_underwear
		var is_skin := ("skin" in mat_name or "skin" in tex_name) and not is_hair_slot and not is_fskin

		if is_hair_slot:
			# 发型多表面零开销切换 (Multi-surface Material Swapping)
			if is_super_saiyan:
				if mat_name == "mat_hair_ssj":
					var ssj_mat := StandardMaterial3D.new()
					ssj_mat.cull_mode = BaseMaterial3D.CULL_BACK
					ssj_mat.roughness = 0.40
					ssj_mat.albedo_color = Color(1.0, 0.88, 0.35)
					ssj_mat.emission_enabled = true
					ssj_mat.emission = Color(1.0, 0.80, 0.15)
					ssj_mat.emission_energy_multiplier = 2.0
					if orig_tex:
						ssj_mat.albedo_texture = orig_tex
					ssj_mat.uv1_scale = Vector3(1.0, -1.0, 1.0)
					ssj_mat.uv1_offset = Vector3(0.0, 1.0, 0.0)
					mesh_inst.set_surface_override_material(s, ssj_mat)
				else:
					mesh_inst.set_surface_override_material(s, inv_mat)
			else:
				if mat_name == "mat_hair_ssj":
					mesh_inst.set_surface_override_material(s, inv_mat)
				elif mat_name == target_hair_slot or mat_name == target_hair_slot + "_acc" or (hair_num == 1 and ("head01" in mat_name or "hair_accessory" in mat_name)):
					var hmat := StandardMaterial3D.new()
					hmat.cull_mode = BaseMaterial3D.CULL_BACK
					hmat.roughness = 0.65
					if orig_tex:
						hmat.albedo_texture = orig_tex

					# 基础发型(mat_hair_01)在源素体中为原生正确方向，2~10号及超赛发型需翻转V坐标以纠正贴图颠倒
					if mat_name != "mat_hair_01" and mat_name != "mat_hair_01_acc" and not ("head01" in mat_name):
						hmat.uv1_scale = Vector3(1.0, -1.0, 1.0)
						hmat.uv1_offset = Vector3(0.0, 1.0, 0.0)

					if "acc" in mat_name or "accessory" in mat_name:
						hmat.albedo_color = Color.WHITE
					elif c_race == 1:
						# 那美克触角：加载对应发型与当前肤色编号的官方全套原生精调纹理 (a_nam_head01~10_01~05.png)
						var head_tex_path := "res://assets/tex/texture/item/a_nam_head%02d_%02d.png" % [hair_num, skin_col_num]
						if ResourceLoader.exists(head_tex_path):
							hmat.albedo_texture = ResourceLoader.load(head_tex_path)
						hmat.albedo_color = Color.WHITE
					elif c_race == 2 and c_gender == 0:
						# 魔人男触角：与肤色对齐
						hmat.albedo_color = skin_col
					elif c_race == 0 and c_gender == 0 and hair_num == 2:
						# 人类男性2号光头(克林发型)染色对齐肤色
						hmat.albedo_color = skin_col
					else:
						# 其余发型与发色对齐
						hmat.albedo_color = hair_col
					mesh_inst.set_surface_override_material(s, hmat)
				else:
					mesh_inst.set_surface_override_material(s, inv_mat)
		elif is_fskin:
			# 面部五官复合渲染 (将官方眼眉五官叠合于基础肤色之上，所有脸型均与肤色统一)
			var base_face_tex: Texture2D = orig_tex
			if c_race == 1:
				var prefix := "a_nam_ad_fskin" if is_adult else "a_nam_ch_fskin"
				var fskin_path := "res://assets/tex/texture/item/%s%02d_%02d.png" % [prefix, face_num, skin_col_num]
				if not ResourceLoader.exists(fskin_path):
					fskin_path = "res://assets/tex/texture/item/%s01_%02d.png" % [prefix, skin_col_num]
				if ResourceLoader.exists(fskin_path):
					base_face_tex = ResourceLoader.load(fskin_path)
			elif base_face_tex == null:
				var def_fskin_path := ""
				match c_race:
					0:
						def_fskin_path = "res://assets/tex/texture/item/a_hum_m_ch_fskin01.png" if c_gender == 0 else "res://assets/tex/texture/item/a_hum_f_ch_fskin01.png"
					2:
						def_fskin_path = "res://assets/tex/texture/item/a_maj_m_fskin.png" if c_gender == 0 else "res://assets/tex/texture/item/a_maj_f_fskin.png"
				if def_fskin_path != "" and ResourceLoader.exists(def_fskin_path):
					base_face_tex = ResourceLoader.load(def_fskin_path)

			if face_tex == null:
				var fallback_face_path := _get_face_texture_path(c_race, c_gender, 1, skin_col_num)
				if fallback_face_path != "" and ResourceLoader.exists(fallback_face_path):
					face_tex = ResourceLoader.load(fallback_face_path)

			if face_tex and base_face_tex:
				var fmat := ShaderMaterial.new()
				fmat.shader = CHARACTER_FACE_SHADER
				fmat.set_shader_parameter("base_skin_tex", base_face_tex)
				fmat.set_shader_parameter("face_feature_tex", face_tex)
				fmat.set_shader_parameter("skin_tint", face_skin_tint)
				mesh_inst.set_surface_override_material(s, fmat)
			elif base_face_tex:
				var smat := ShaderMaterial.new()
				smat.shader = CHARACTER_SKIN_SHADER
				smat.set_shader_parameter("base_tex", base_face_tex)
				smat.set_shader_parameter("skin_tint", face_skin_tint)
				smat.set_shader_parameter("race_mode", c_race)
				mesh_inst.set_surface_override_material(s, smat)
		elif is_underwear:
			# 内衣/底裤：当角色穿着对应外装时隐藏，若无外装或外装为开胸/围巾时显式保留，保证绝不露洞
			var should_hide_underwear := false
			if "pants" in mat_name or "pants" in tex_name:
				should_hide_underwear = has_legs
			elif "jacket" in mat_name or "jacket" in tex_name:
				var torso_path := str(equipped_glb_paths.get("torso", "")).to_lower()
				var is_scarf_or_open_torso := ("mwo" in torso_path) or ("scarf" in torso_path)
				should_hide_underwear = has_torso and not is_scarf_or_open_torso

			if should_hide_underwear:
				mesh_inst.set_surface_override_material(s, inv_mat)
			else:
				var umat := StandardMaterial3D.new()
				umat.cull_mode = BaseMaterial3D.CULL_BACK
				umat.roughness = 0.65
				if orig_tex == null:
					orig_tex = _resolve_underwear_texture(c_race, c_gender, mat_name)
				if orig_tex:
					umat.albedo_texture = orig_tex
				umat.albedo_color = Color.WHITE
				mesh_inst.set_surface_override_material(s, umat)
		elif is_jacket:
			# 素体躯干与手臂表面（包含 jacket_skin 露胸/腹/臂皮肤与新手外套）
			var is_majin_hand := (c_race == 2 and ((c_gender == 1 and (s == 2 or s == 10)) or (c_gender == 0 and (s == 4 or s == 7))))
			var is_namek_hand := (c_race == 1 and (s == 2 or s == 3))
			var is_human_hand := false

			var arrays := mesh_inst.mesh.surface_get_arrays(s)
			if c_race == 0 and arrays.size() > Mesh.ARRAY_VERTEX and arrays[Mesh.ARRAY_VERTEX].size() > 0:
				var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var min_x := 999.0
				var max_x := -999.0
				for v in verts:
					if v.x < min_x: min_x = v.x
					if v.x > max_x: max_x = v.x
				if min_x > 0.35 or max_x < -0.35:
					is_human_hand = true

			var is_hand_surface := is_majin_hand or is_namek_hand or is_human_hand

			if is_hand_surface:
				# 角色手掌与小臂手腕表面 (对标 OpenDBO: surface_hands)
				# 穿戴手套时隐藏手掌，彻底消除素体手掌穿透手套的穿模破皮；脱下手套时精准恢复
				if has_hands:
					mesh_inst.set_surface_override_material(s, inv_mat)
				else:
					if c_race == 1:
						# 那美克星人手掌：直接采用原生烘焙高精纹理 (StandardMaterial3D 保真)
						var nmat := StandardMaterial3D.new()
						nmat.roughness = 0.65
						nmat.cull_mode = BaseMaterial3D.CULL_BACK
						var stex_path := "res://assets/tex/texture/item/a_nfi_ad_jacket_skin%02d.png" % skin_col_num
						if ResourceLoader.exists(stex_path):
							nmat.albedo_texture = ResourceLoader.load(stex_path)
						elif orig_tex:
							nmat.albedo_texture = orig_tex
						nmat.albedo_color = Color.WHITE
						mesh_inst.set_surface_override_material(s, nmat)
					else:
						var skin_tex: Texture2D = orig_tex
						if c_race == 2:
							var arm_path := "res://assets/tex/texture/item/a_maj_f_jacket_skin2.png" if c_gender == 1 else "res://assets/tex/texture/item/a_maj_m_jacket_skin2.png"
							skin_tex = DBOCharacterFactory.load_texture_safe(arm_path)
						var smat := ShaderMaterial.new()
						smat.shader = CHARACTER_SKIN_SHADER
						if skin_tex:
							smat.set_shader_parameter("base_tex", skin_tex)
						smat.set_shader_parameter("skin_tint", body_skin_tint)
						smat.set_shader_parameter("race_mode", c_race)
						mesh_inst.set_surface_override_material(s, smat)
			else:
				# 躯干胸腹/颈肩/大臂表面
				# 魔人族：Surface 7(女)/Surface 8(男)为双臂，Surface 8(女)/Surface 9(男)为胸腹
				var is_majin_arm := (c_race == 2 and ((c_gender == 1 and s == 7) or (c_gender == 0 and s == 8)))
				var is_majin_torso_skin := (c_race == 2 and ((c_gender == 1 and s == 8) or (c_gender == 0 and s == 9)))

				# 检查已穿戴上衣是否自带手臂模型 (若自带手臂，则隐藏素体手臂避免双重重叠导致 Z-fighting 白模)
				var torso_path := str(equipped_glb_paths.get("torso", "")).to_lower()
				var torso_has_its_own_arm := ("mmi" in torso_path)

				if is_majin_arm:
					if has_torso and torso_has_its_own_arm:
						# 上衣模型已内建手臂网格，隐藏素体手臂，彻底根除双层网格重叠引起的白模走样
						mesh_inst.set_surface_override_material(s, inv_mat)
					else:
						# 意魔人上装(围巾)或无上衣：显示素体手臂
						var arm_path := "res://assets/tex/texture/item/a_maj_f_jacket_skin2.png" if c_gender == 1 else "res://assets/tex/texture/item/a_maj_m_jacket_skin2.png"
						var arm_tex: Texture2D = DBOCharacterFactory.load_texture_safe(arm_path)
						var smat := ShaderMaterial.new()
						smat.shader = CHARACTER_SKIN_SHADER
						smat.set_shader_parameter("base_tex", arm_tex if arm_tex else orig_tex)
						smat.set_shader_parameter("skin_tint", body_skin_tint)
						smat.set_shader_parameter("race_mode", 2)
						mesh_inst.set_surface_override_material(s, smat)
				elif is_majin_torso_skin:
					# 魔人胸腹皮肤：意魔人围巾与新手背心均为开胸款，素体胸腹必须显示并正确染色
					var torso_skin_path := "res://assets/tex/texture/item/a_maj_f_jacket_skin1.png" if c_gender == 1 else "res://assets/tex/texture/item/a_maj_m_jacket_skin1.png"
					var torso_tex: Texture2D = DBOCharacterFactory.load_texture_safe(torso_skin_path)
					var smat := ShaderMaterial.new()
					smat.shader = CHARACTER_SKIN_SHADER
					smat.set_shader_parameter("base_tex", torso_tex if torso_tex else orig_tex)
					smat.set_shader_parameter("skin_tint", body_skin_tint)
					smat.set_shader_parameter("race_mode", 2)
					mesh_inst.set_surface_override_material(s, smat)
				elif c_race == 1:
					# 那美克星人：新手上装为无袖开胸小马甲，素体颈肩胸腹皮肤必须显式保留！直接使用原生烘焙贴图
					var nmat := StandardMaterial3D.new()
					nmat.roughness = 0.65
					nmat.cull_mode = BaseMaterial3D.CULL_BACK
					var stex_path := "res://assets/tex/texture/item/a_nfi_ad_jacket_skin%02d.png" % skin_col_num
					if ResourceLoader.exists(stex_path):
						nmat.albedo_texture = ResourceLoader.load(stex_path)
					elif orig_tex:
						nmat.albedo_texture = orig_tex
					nmat.albedo_color = Color.WHITE
					mesh_inst.set_surface_override_material(s, nmat)
				else:
					# 人类躯干
					var should_hide_torso := has_torso
					if should_hide_torso:
						mesh_inst.set_surface_override_material(s, inv_mat)
					else:
						if is_skin:
							var smat := ShaderMaterial.new()
							smat.shader = CHARACTER_SKIN_SHADER
							if orig_tex:
								smat.set_shader_parameter("base_tex", orig_tex)
							smat.set_shader_parameter("skin_tint", body_skin_tint)
							smat.set_shader_parameter("race_mode", c_race)
							mesh_inst.set_surface_override_material(s, smat)
						else:
							var cmat := StandardMaterial3D.new()
							cmat.cull_mode = BaseMaterial3D.CULL_BACK
							cmat.roughness = 0.65
							if orig_tex:
								cmat.albedo_texture = orig_tex
							cmat.albedo_color = Color.WHITE
							mesh_inst.set_surface_override_material(s, cmat)
		elif is_pants:
			# 素体下装表面（包含 pants_skin 腿部皮肤与新手裤子）
			if c_race == 1 and is_skin:
				# 那美克星人：裤子表面为露踝皮肤 A_NAM_pants_skin01 时，直接使用官方原生烘焙贴图
				var nmat := StandardMaterial3D.new()
				nmat.roughness = 0.65
				nmat.cull_mode = BaseMaterial3D.CULL_BACK
				var stex_path := "res://assets/tex/texture/item/a_nam_pants_skin%02d.png" % skin_col_num
				if ResourceLoader.exists(stex_path):
					nmat.albedo_texture = ResourceLoader.load(stex_path)
				elif orig_tex:
					nmat.albedo_texture = orig_tex
				nmat.albedo_color = Color.WHITE
				mesh_inst.set_surface_override_material(s, nmat)
			elif has_legs:
				mesh_inst.set_surface_override_material(s, inv_mat)
			else:
				if is_skin:
					var skin_tex: Texture2D = orig_tex
					var smat := ShaderMaterial.new()
					smat.shader = CHARACTER_SKIN_SHADER
					if skin_tex:
						smat.set_shader_parameter("base_tex", skin_tex)
					smat.set_shader_parameter("skin_tint", body_skin_tint)
					smat.set_shader_parameter("race_mode", c_race)
					mesh_inst.set_surface_override_material(s, smat)
				else:
					var cmat := StandardMaterial3D.new()
					cmat.cull_mode = BaseMaterial3D.CULL_BACK
					cmat.roughness = 0.65
					if orig_tex:
						cmat.albedo_texture = orig_tex
					cmat.albedo_color = Color.WHITE
					mesh_inst.set_surface_override_material(s, cmat)
		elif is_boots:
			if has_feet:
				mesh_inst.set_surface_override_material(s, inv_mat)
			else:
				var cmat := StandardMaterial3D.new()
				cmat.cull_mode = BaseMaterial3D.CULL_BACK
				cmat.roughness = 0.65
				if orig_tex:
					cmat.albedo_texture = orig_tex
				cmat.albedo_color = Color.WHITE
				mesh_inst.set_surface_override_material(s, cmat)
		elif is_skin:
			# 其余素体裸露皮肤调色
			var skin_tex: Texture2D = orig_tex
			var smat := ShaderMaterial.new()
			smat.shader = CHARACTER_SKIN_SHADER
			if skin_tex:
				smat.set_shader_parameter("base_tex", skin_tex)
			smat.set_shader_parameter("skin_tint", body_skin_tint)
			smat.set_shader_parameter("race_mode", c_race)
			mesh_inst.set_surface_override_material(s, smat)
		else:
			mesh_inst.set_surface_override_material(s, null)

	# 同步刷新已穿戴外装上的皮肤材质与魔人动态贴图合成
	if _slots.get("torso") != null and is_instance_valid(_slots["torso"]):
		var torso_mesh := _slots["torso"] as MeshInstance3D
		if torso_mesh and torso_mesh.mesh:
			if c_race == 2:
				var t_path: String = str(equipped_glb_paths.get("torso", ""))
				DBOCharacterFactory._apply_majin_jacket_materials(torso_mesh, t_path, c_gender == 1, current_skin_color)
			else:
				var target_skin_col := Color.WHITE if c_race == 1 else current_skin_color
				for s in range(torso_mesh.mesh.get_surface_count()):
					var smat := torso_mesh.get_surface_override_material(s)
					if smat == null:
						smat = torso_mesh.mesh.surface_get_material(s)
					if smat and "skin" in smat.resource_name.to_lower():
						var skin_mat := smat.duplicate() as StandardMaterial3D
						if skin_mat:
							skin_mat.albedo_color = target_skin_col
							torso_mesh.set_surface_override_material(s, skin_mat)

	for slot_key in ["legs", "feet", "hands", "weapon_r"]:
		if _slots.get(slot_key) != null and is_instance_valid(_slots[slot_key]):
			var part_mesh := _slots[slot_key] as MeshInstance3D
			if part_mesh and part_mesh.mesh:
				var target_skin_col := Color.WHITE if c_race == 1 else current_skin_color
				for s in range(part_mesh.mesh.get_surface_count()):
					var smat := part_mesh.get_surface_override_material(s)
					if smat == null:
						smat = part_mesh.mesh.surface_get_material(s)
					if smat and "skin" in smat.resource_name.to_lower():
						var skin_mat := smat.duplicate() as StandardMaterial3D
						if skin_mat:
							skin_mat.albedo_color = target_skin_col
							part_mesh.set_surface_override_material(s, skin_mat)


## 动态解析各族内衣/底裤贴图路径 (对标 OpenDBO: 原生底裤贴图资源)
static func _resolve_underwear_texture(c_race: int, c_gender: int, mat_name: String) -> Texture2D:
	var path := ""
	if "pants" in mat_name:
		match c_race:
			0:
				path = "res://assets/tex/texture/item/a_hum_m_pants000.png" if c_gender == 0 else "res://assets/tex/texture/item/a_hum_f_pants000.png"
			1:
				path = "res://assets/tex/texture/item/a_nam_pants000.png"
			2:
				path = "res://assets/tex/texture/item/a_maj_m_pants000.png" if c_gender == 0 else "res://assets/tex/texture/item/a_maj_f_pants000.png"
	elif "jacket" in mat_name:
		match c_race:
			0:
				path = "res://assets/tex/texture/item/a_hum_f_jacket000.png"
			2:
				path = "res://assets/tex/texture/item/a_maj_f_jacket000.png"
	if path != "" and ResourceLoader.exists(path):
		return ResourceLoader.load(path) as Texture2D
	return null


func _get_body_head_center_y() -> float:
	_ensure_skeleton()
	if _skeleton:
		var h_idx := _skeleton.find_bone("Bip01 Head")
		if h_idx != -1:
			return _skeleton.get_bone_global_rest(h_idx).origin.y + 0.25
	return 1.50


func _remove_custom_head_mesh() -> void:
	if _slots.has("hair") and is_instance_valid(_slots["hair"]):
		var node: Node = _slots["hair"]
		node.queue_free()
		_slots["hair"] = null


func get_skeleton() -> Skeleton3D:
	_ensure_skeleton()
	return _skeleton


func get_animation_player() -> AnimationPlayer:
	return _anim_player
