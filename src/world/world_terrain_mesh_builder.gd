class_name WorldTerrainMeshBuilder
extends RefCounted

## World Terrain Mesh Builder (Dragon Ball Online Heightfield Generator)
## 对标 OpenDBO-Core: DboClient/Lib/NtlPresentation/NtlPLWorldEntity.cpp & NtlWorldField.cpp
## 高性能网格生成机：将 data/terrain/ 导出的 65x65 高程图与步长参数实时编译为
## 带精确 Jolt 物理碰撞与 NTLWE 地表贴图的轻量级 3D 网格实体。

const DEFAULT_TERRAIN_TEX := "res://assets/tex/texture/ntlwe/tex_karin_grass_001.png"
const NTLWE_TEX_DIR := "res://assets/tex/texture/ntlwe/"

# 材质缓存，避免重复创建相同的地表材质
static var _material_cache: Dictionary = {}


## 从区块 JSON 数据构建 3D 地形网格实体
static func build_terrain_chunk_mesh(chunk_data: Dictionary) -> MeshInstance3D:
	var heights: Array = chunk_data.get("heights", [])
	if heights.is_empty():
		return null

	var grid_size: int = int(chunk_data.get("grid_size", 65))
	var step: float = float(chunk_data.get("step", 4.0))
	var origin_x: float = float(chunk_data.get("origin_x", 0.0))
	var origin_z: float = float(chunk_data.get("origin_z", 0.0))
	var tex_name: String = chunk_data.get("tex_name", "NTL")

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 1. 遍历栅格点添加顶点与 UV
	# 65x65 点集构筑 64x64 方格单元
	for gz in range(grid_size):
		for gx in range(grid_size):
			var idx := gz * grid_size + gx
			var h: float = float(heights[idx]) if idx < heights.size() else 0.0
			if h > 2000.0 or h < -500.0:
				h = 52.0
			var world_x := origin_x + float(gx) * step
			var world_z := origin_z + float(gz) * step

			var u := float(gx) / float(grid_size - 1)
			var v := float(gz) / float(grid_size - 1)

			st.set_uv(Vector2(u, v))
			st.add_vertex(Vector3(world_x, h, world_z))

	# 2. 生成三角形面索引 (两两三角形拼成四边形 Quad)
	var quads := grid_size - 1
	for gz in range(quads):
		for gx in range(quads):
			var v00 := gz * grid_size + gx
			var v10 := gz * grid_size + (gx + 1)
			var v01 := (gz + 1) * grid_size + gx
			var v11 := (gz + 1) * grid_size + (gx + 1)

			# 对应 RenderWare 地表顺时针/逆时针法线绕序
			st.add_index(v00)
			st.add_index(v10)
			st.add_index(v01)

			st.add_index(v10)
			st.add_index(v11)
			st.add_index(v01)

	# 3. 自动生成法线与切线
	st.generate_normals()
	st.generate_tangents()

	var array_mesh := st.commit()
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "TerrainMesh_%d_%d" % [int(chunk_data.get("col", 0)), int(chunk_data.get("row", 0))]
	mesh_inst.mesh = array_mesh

	# 4. 绑定地表贴图材质
	var mat := _get_terrain_material(tex_name)
	mesh_inst.material_override = mat

	# 5. 生成 Jolt 3D 静态地表碰撞体
	mesh_inst.create_trimesh_collision()

	return mesh_inst


## 获取或生成地表材质
static func _get_terrain_material(tex_hint: String) -> StandardMaterial3D:
	var key := tex_hint.to_lower().strip_edges()
	if _material_cache.has(key):
		return _material_cache[key]

	var mat := StandardMaterial3D.new()
	mat.roughness = 0.9
	mat.metallic_specular = 0.1
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.uv1_scale = Vector3(8.0, 8.0, 1.0) # 8x8 平铺保证地表高清晰度

	var tex_path := DEFAULT_TERRAIN_TEX
	# 智能探查匹配贴图
	var candidates: Array[String] = [
		NTLWE_TEX_DIR + "tex_" + key + "_grass_001.png",
		NTLWE_TEX_DIR + "tex_" + key + "_ground_001.png",
		NTLWE_TEX_DIR + key + ".png"
	]
	for c in candidates:
		if ResourceLoader.exists(c):
			tex_path = c
			break

	if ResourceLoader.exists(tex_path):
		var tex := ResourceLoader.load(tex_path) as Texture2D
		if tex:
			mat.albedo_texture = tex

	_material_cache[key] = mat
	return mat
