class_name DBOMaterialHelper
extends RefCounted

## DBO Material Helper
## 负责自动校正 RenderWare DFF 衍生模型的颠倒贴图 (UV 垂直翻转纠偏)。
## 由于 DFF 转 glTF 历史工具中对 V 坐标执行了多余的 (1.0 - v) 变换，
## 本助手在材质管线层统一注入 uv1_scale.y = -1.0, uv1_offset.y = 1.0，
## 实现 100% 贴图方向正向对齐，零磁盘文件修改、零引擎重新导入卡死。


## 遍历节点树下所有 MeshInstance3D 并纠正材质 UV
static func fix_node_materials(root: Node) -> void:
	if root == null or not is_instance_valid(root):
		return

	if root is MeshInstance3D:
		fix_mesh_materials(root as MeshInstance3D)

	for child in root.get_children():
		fix_node_materials(child)


## 针对单个 MeshInstance3D 执行材质校正与 Alpha 剪裁
static func fix_mesh_materials(mesh_inst: MeshInstance3D) -> void:
	if mesh_inst == null or not is_instance_valid(mesh_inst):
		return

	# 地表网格使用程序化数学 UV，无需翻转
	if mesh_inst.name.begins_with("TerrainMesh_"):
		return

	# 判断是否为角色网格（角色素体与装备网格原生 UV 已完全对齐，严禁执行二次翻转导致五官与身体倒立）
	var is_character_mesh := false
	if mesh_inst.name.begins_with("Part_") or mesh_inst.name.begins_with("Item_") or mesh_inst.name.begins_with("Equip") or mesh_inst.name.begins_with("Base"):
		is_character_mesh = true
	var parent_check: Node = mesh_inst
	while parent_check and not is_character_mesh:
		if parent_check is DBOCharacterVisual or parent_check.name == "DBOCharacterVisual" or parent_check.name == "AvatarPivot" or parent_check.name == "ModelMount":
			is_character_mesh = true
			break
		parent_check = parent_check.get_parent()

	# 仅对场景物件、建筑与道具执行 RenderWare DirectX V 坐标纠偏 (uv1_scale.y = -1.0)
	# 唯独排除：角色网格（is_character_mesh）与 程序化数学地表网格（TerrainMesh_）
	var should_flip_uv := (not is_character_mesh) and (not mesh_inst.name.begins_with("TerrainMesh_"))

	# 1. 材质重写 (material_override)
	if mesh_inst.material_override:
		_process_material(mesh_inst.material_override, should_flip_uv)

	# 2. 网格分表面材质 (surface materials)
	if mesh_inst.mesh:
		for s in range(mesh_inst.mesh.get_surface_count()):
			var surf_mat := mesh_inst.get_surface_override_material(s)
			if surf_mat:
				_process_material(surf_mat, should_flip_uv)
			else:
				var base_mat := mesh_inst.mesh.surface_get_material(s)
				if base_mat:
					_process_material(base_mat, should_flip_uv)
					# 植被树冠/棕榈叶片微风摆动材质动态替换 (对标 OpenDBO-Core: 00_N_TREE_PALM_001.ANM 叶片骨骼运动)
					var leaf_shader_mat := _create_foliage_leaf_material_if_needed(base_mat, should_flip_uv)
					if leaf_shader_mat:
						mesh_inst.set_surface_override_material(s, leaf_shader_mat)


const FOLIAGE_SWAY_SHADER: Shader = preload("res://src/shaders/foliage_sway.gdshader")

static func _get_foliage_shader() -> Shader:
	return FOLIAGE_SWAY_SHADER


static func _create_foliage_leaf_material_if_needed(bmat: Material, should_flip_uv: bool) -> ShaderMaterial:
	if not (bmat is BaseMaterial3D):
		return null
	var base := bmat as BaseMaterial3D
	var mat_name := base.resource_name.to_lower()
	var tex_path: String = base.albedo_texture.resource_path.to_lower() if base.albedo_texture else ""

	# 仅针对叶片/棕榈材质，严禁影响树干(wood/trunk)与建筑石头
	var is_leaf := ("leaf" in mat_name or "leaf" in tex_path or "palm_leaf" in mat_name or "palm_leaf" in tex_path)
	var is_trunk := ("trunk" in mat_name or "trunk" in tex_path or "wood" in mat_name or "wood" in tex_path)
	if not is_leaf or is_trunk:
		return null

	var smat := ShaderMaterial.new()
	smat.shader = _get_foliage_shader()
	if base.albedo_texture:
		smat.set_shader_parameter("albedo_tex", base.albedo_texture)
	smat.set_shader_parameter("uv_scale", Vector2(1.0, -1.0) if should_flip_uv else Vector2(1.0, 1.0))
	smat.set_shader_parameter("uv_offset", Vector2(0.0, 1.0) if should_flip_uv else Vector2(0.0, 0.0))
	smat.set_shader_parameter("alpha_scissor_threshold", 0.5)
	smat.set_shader_parameter("wind_speed", 1.8)
	smat.set_shader_parameter("wind_strength", 0.15)
	smat.set_shader_parameter("height_threshold", 3.0)
	return smat


static func _process_material(mat: Material, should_flip_uv: bool) -> void:
	if mat == null or not is_instance_valid(mat):
		return

	if mat is BaseMaterial3D:
		var bmat := mat as BaseMaterial3D
		var mat_name := bmat.resource_name.to_lower()
		var tex_path: String = bmat.albedo_texture.resource_path.to_lower() if bmat.albedo_texture else ""

		# 1. UV 垂直翻转纠偏：修复场景建筑、龙首、石阶、雕塑与成人物件倒立贴图
		var is_tutorial_bg := ("tutorialmap_005" in tex_path or "tutorialmap_005" in mat_name or
			"tutorialmap_006" in tex_path or "tutorialmap_006" in mat_name or
			"tutorialmap_011" in tex_path or "tutorialmap_011" in mat_name)

		if should_flip_uv:
			if is_tutorial_bg:
				# 远景山峦看板原生 V 跨越 [1.0, 1.97]，映射至 [1.0, 0.03] 实现绝对正立与透明天空剔除
				bmat.uv1_scale.y = -1.0
				bmat.uv1_offset.y = 2.0
			elif bmat.uv1_scale.y > 0.0:
				bmat.uv1_scale.y = -abs(bmat.uv1_scale.y)
				bmat.uv1_offset.y = 1.0

		# 2. 自动检测植被与透明看板，强制开启 Alpha Scissor (消除白边方块并开启双面)
		var needs_scissor := false

		const ALPHA_KEYWORDS := [
			"leaf", "tree", "palm", "grass", "plant", "flower", "bush", "reed",
			"branch", "flora", "board", "fence", "alpha", "cut", "effect", "billboard",
			"shadow", "sign", "glass", "lamp", "parasol", "tutorial", "tutorialmap", "bg"
		]
		for kw in ALPHA_KEYWORDS:
			if kw in tex_path or kw in mat_name:
				needs_scissor = true
				break

		# 命中植被/广告牌关键字，或具有透明通道的材质
		if needs_scissor:
			bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			bmat.alpha_scissor_threshold = 0.5
			bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
			bmat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS


## 安全载入 GLB 场景，防止 GLB 中包含的损坏贴图 URI (如 ".../texture/item/") 触发引擎底层红字错误
static func load_gltf_scene_safe(glb_path: String, flags: int = 0) -> Node:
	if glb_path.is_empty() or not FileAccess.file_exists(glb_path):
		return null

	var file := FileAccess.open(glb_path, FileAccess.READ)
	if file == null:
		return null
	var bytes := file.get_buffer(file.get_length())
	file.close()

	if bytes.size() < 20:
		return null

	# 检查是否为有效 GLB (magic: 0x46546C67 "glTF")
	var magic := bytes.decode_u32(0)
	if magic == 0x46546C67:
		var json_chunk_len := bytes.decode_u32(12)
		var json_chunk_type := bytes.decode_u32(16)
		if json_chunk_type == 0x4E4F534A and bytes.size() >= 20 + json_chunk_len:
			var json_bytes := bytes.slice(20, 20 + json_chunk_len)
			var json_text := json_bytes.get_string_from_utf8()
			var parsed = JSON.parse_string(json_text)
			if parsed is Dictionary and parsed.has("images"):
				var modified := false
				for img in parsed["images"]:
					if img is Dictionary:
						var u: String = str(img.get("uri", "")).strip_edges()
						# 修正无效路径：指向目录以 / 结尾、为空、或者指向不存在的损坏文件名 (如 69.png, e.png, ad.png 等)
						if u.is_empty() or u.ends_with("/") or u.ends_with("texture/item") or not u.ends_with(".png"):
							img["uri"] = "../../../tex/texture/item/i_sct_01.png"
							modified = true
						elif u.contains("texture/item/"):
							var fname := u.get_file()
							var check_path := "res://assets/tex/texture/item/" + fname
							if not FileAccess.file_exists(check_path):
								img["uri"] = "../../../tex/texture/item/i_sct_01.png"
								modified = true
				if modified:
					var new_json_text := JSON.stringify(parsed)
					while new_json_text.length() % 4 != 0:
						new_json_text += " "
					var new_json_bytes := new_json_text.to_utf8_buffer()
					var new_json_len := new_json_bytes.size()
					var bin_chunk := bytes.slice(20 + json_chunk_len)
					var new_total_len := 12 + 8 + new_json_len + bin_chunk.size()

					var new_bytes := PackedByteArray()
					new_bytes.resize(new_total_len)
					new_bytes.encode_u32(0, 0x46546C67)
					new_bytes.encode_u32(4, 2)
					new_bytes.encode_u32(8, new_total_len)
					new_bytes.encode_u32(12, new_json_len)
					new_bytes.encode_u32(16, 0x4E4F534A)
					for i in range(new_json_len):
						new_bytes[20 + i] = new_json_bytes[i]
					var bin_offset := 20 + new_json_len
					for i in range(bin_chunk.size()):
						new_bytes[bin_offset + i] = bin_chunk[i]
					bytes = new_bytes

	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var base_dir := glb_path.get_base_dir() + "/"
	var err := doc.append_from_buffer(bytes, base_dir, state, flags)
	if err != OK:
		return null
	return doc.generate_scene(state)
