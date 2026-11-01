class_name WorldSkybox
extends Node3D

## World Skybox (Dragon Ball Online Dome Renderer)
## 严格对标 OpenDBO-Core: DboClient/Lib/NtlPresentation/NtlPLSky.h & NtlPLSky.cpp
## 渲染官方天空穹顶模型（sky_diffuse.glb / sky_base.glb / sky_blended0t.glb / sky_blended1t.glb）
## 并在每帧精确跟踪当前活动摄像机空间位移（无视摄像机旋转），实现视差无限远的真实天空视觉。

enum SkyMode {
	NOTHING = 0,   ## eBSM_NOTHING
	RGB_MODE = 1,  ## eBSM_RGB_MODE (Vertex color 3-stop vertical gradient on diffuse sky dome)
	TEX_MODE = 2   ## eBSM_TEX_MODE (Panorama texture mapping on base sky dome)
}

const SKY_GRADIENT_SHADER: Shader = preload("res://src/shaders/sky_gradient.gdshader")
const SKY_LAYER_SHADER: Shader = preload("res://src/shaders/sky_layer.gdshader")

@export var diffuse_sky_mesh_path: String = "res://assets/obj/world/mesh/sky_diffuse.glb"
@export var base_sky_mesh_path: String = "res://assets/obj/world/mesh/sky_base.glb"
@export var cloud_mesh_0_path: String = "res://assets/obj/world/mesh/sky_blended0t.glb"
@export var cloud_mesh_1_path: String = "res://assets/obj/world/mesh/sky_blended1t.glb"
@export var sky_scale: float = 2.5
@export var enable_sun: bool = true
@export var sun_disk_path: String = "res://assets/tex/texture/ntlwe/planet/sun_001.png"
@export var sun_direction: Vector3 = Vector3(0.35, 0.75, -0.55)

var current_sky_mode: int = SkyMode.RGB_MODE
var current_top_color: Color = Color(0.302, 0.055, 0.584, 1.0)
var current_horizon_color: Color = Color(0.0, 0.635, 1.0, 1.0)
var current_bottom_color: Color = Color(0.0, 0.0, 0.0, 1.0)
var current_base_sky_tex: String = ""
var current_cloud_0_tex: String = "cloud_011"
var current_cloud_0_speed: float = 0.001
var current_cloud_1_tex: String = ""
var current_cloud_1_speed: float = 0.0

var _camera: Camera3D = null
var _diffuse_sky_instance: Node3D = null
var _base_sky_instance: Node3D = null
var _cloud_0_instance: Node3D = null
var _cloud_1_instance: Node3D = null
var _sun_instance: Sprite3D = null

var _diffuse_shader_mat: ShaderMaterial = null
var _base_sky_shader_mat: ShaderMaterial = null
var _cloud_0_shader_mat: ShaderMaterial = null
var _cloud_1_shader_mat: ShaderMaterial = null


func _ready() -> void:
	_camera = (get_viewport().get_camera_3d() as Camera3D) if get_viewport() else null
	if _camera:
		global_position = _camera.global_position
	_spawn_sky_meshes()


func _spawn_sky_meshes() -> void:
	# 1. 生成 RGB 渐变天穹 (sky_diffuse.glb - 对标 OpenDBO-Core: m_pBaseSkyLayer[0])
	if ResourceLoader.exists(diffuse_sky_mesh_path):
		var diff_scene := ResourceLoader.load(diffuse_sky_mesh_path) as PackedScene
		if diff_scene:
			_diffuse_sky_instance = diff_scene.instantiate() as Node3D
			_diffuse_sky_instance.name = "DiffuseSkyDome"
			_diffuse_sky_instance.scale = Vector3.ONE * sky_scale
			add_child(_diffuse_sky_instance)
			_disable_shadows(_diffuse_sky_instance)

	# 2. 生成贴图全景天穹 (sky_base.glb - 对标 OpenDBO-Core: m_pBaseSkyLayer[1])
	if ResourceLoader.exists(base_sky_mesh_path):
		var base_scene := ResourceLoader.load(base_sky_mesh_path) as PackedScene
		if base_scene:
			_base_sky_instance = base_scene.instantiate() as Node3D
			_base_sky_instance.name = "BaseSkyDome"
			_base_sky_instance.scale = Vector3.ONE * (sky_scale * 0.99)
			add_child(_base_sky_instance)
			_disable_shadows(_base_sky_instance)

	# 3. 生成浮空云层天穹 0 (sky_blended0t.glb - 对标 OpenDBO-Core: m_pBlendedSkyLayer[0])
	if ResourceLoader.exists(cloud_mesh_0_path):
		var c0_scene := ResourceLoader.load(cloud_mesh_0_path) as PackedScene
		if c0_scene:
			_cloud_0_instance = c0_scene.instantiate() as Node3D
			_cloud_0_instance.name = "CloudDome0"
			_cloud_0_instance.scale = Vector3.ONE * (sky_scale * 0.98)
			add_child(_cloud_0_instance)
			_disable_shadows(_cloud_0_instance)

	# 4. 生成浮空云层天穹 1 (sky_blended1t.glb - 对标 OpenDBO-Core: m_pBlendedSkyLayer[1])
	if ResourceLoader.exists(cloud_mesh_1_path):
		var c1_scene := ResourceLoader.load(cloud_mesh_1_path) as PackedScene
		if c1_scene:
			_cloud_1_instance = c1_scene.instantiate() as Node3D
			_cloud_1_instance.name = "CloudDome1"
			_cloud_1_instance.scale = Vector3.ONE * (sky_scale * 0.96)
			add_child(_cloud_1_instance)
			_disable_shadows(_cloud_1_instance)

	# 5. 生成官方行星天体 (对标 OpenDBO-Core: NtlPLPlanetHandler.cpp & NtlPLSun.cpp: PLENTITY_SUN)
	_spawn_sun_disc()

	# 6. 初始化材质管线
	_refresh_all_materials()


func _spawn_sun_disc() -> void:
	if not enable_sun or not ResourceLoader.exists(sun_disk_path):
		return
	var sun_tex := ResourceLoader.load(sun_disk_path) as Texture2D
	if sun_tex == null:
		return
	_sun_instance = Sprite3D.new()
	_sun_instance.name = "CelestialSun"
	_sun_instance.texture = sun_tex
	_sun_instance.pixel_size = 0.16
	_sun_instance.position = sun_direction.normalized() * (sky_scale * 280.0)
	_sun_instance.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sun_instance.no_depth_test = true
	_sun_instance.render_priority = -85
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = sun_tex
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.no_depth_test = true
	mat.vertex_color_use_as_albedo = true
	mat.render_priority = -85
	_sun_instance.material_override = mat
	add_child(_sun_instance)


func set_sun_direction(dir: Vector3) -> void:
	sun_direction = dir.normalized()
	if _sun_instance:
		_sun_instance.position = sun_direction * (sky_scale * 280.0)


## 从官方解包 environment.json 的 preset 字典全自动应用天空模式与流云
func apply_environment_preset(preset: Dictionary) -> void:
	if preset.is_empty():
		return

	var mode: int = int(preset.get("sky_mode", SkyMode.RGB_MODE))
	var grad: Dictionary = preset.get("sky_gradient", {})
	var top_arr: Array = grad.get("top", [0.302, 0.055, 0.584])
	var horiz_arr: Array = grad.get("horizon", [0.0, 0.635, 1.0])
	var bot_arr: Array = grad.get("bottom", [0.0, 0.0, 0.0])

	var top_c := Color(top_arr[0], top_arr[1], top_arr[2]) if top_arr.size() == 3 else Color(0.302, 0.055, 0.584)
	var horiz_c := Color(horiz_arr[0], horiz_arr[1], horiz_arr[2]) if horiz_arr.size() == 3 else Color(0.0, 0.635, 1.0)
	var bot_c := Color(bot_arr[0], bot_arr[1], bot_arr[2]) if bot_arr.size() == 3 else Color(0.0, 0.0, 0.0)

	var base_sky: String = str(preset.get("base_sky", "")).strip_edges()
	var cloud_0: String = str(preset.get("cloud_0", "")).strip_edges()
	var cloud_speed_0: float = float(preset.get("cloud_speed_0", 0.001))
	var cloud_1: String = str(preset.get("cloud_1", "")).strip_edges()
	var cloud_speed_1: float = float(preset.get("cloud_speed_1", 0.0))

	set_sky_mode(mode, top_c, horiz_c, bot_c, base_sky)
	set_clouds(cloud_0, cloud_speed_0, cloud_1, cloud_speed_1)


## 显式设置天空模式 (RGB_MODE 渐变 / TEX_MODE 贴图 / NOTHING)
func set_sky_mode(mode: int, top: Color, horizon: Color, bottom: Color, base_sky_tex: String = "") -> void:
	current_sky_mode = mode
	current_top_color = top
	current_horizon_color = horizon
	current_bottom_color = bottom
	var b_clean := base_sky_tex.to_lower().strip_edges()
	var is_dummy := (b_clean == "" or b_clean == "null" or b_clean == "sky_sp" or b_clean == "sky" or b_clean == "sky_dummy" or b_clean == "dummydummy")
	current_base_sky_tex = "" if is_dummy else base_sky_tex
	_refresh_all_materials()


## 显式设置多层流云配置 (对标 OpenDBO-Core: _BlendedTexName 与 _BlendedTexSpeed)
func set_clouds(cloud_0: String, speed_0: float = 0.001, cloud_1: String = "", speed_1: float = 0.0) -> void:
	current_cloud_0_tex = cloud_0
	current_cloud_0_speed = speed_0
	current_cloud_1_tex = cloud_1
	current_cloud_1_speed = speed_1
	_refresh_cloud_materials()


## 兼容旧接口：动态切换官方天空底图与云层动画
func set_sky_and_clouds(base_sky_name: String, cloud_name: String, cloud_speed: float = 0.001) -> void:
	var b_clean := base_sky_name.to_lower().strip_edges()
	var is_dummy := (b_clean == "" or b_clean == "null" or b_clean == "sky_sp" or b_clean == "sky" or b_clean == "sky_dummy" or b_clean == "dummydummy")
	if not is_dummy and b_clean.begins_with("sky0"):
		current_sky_mode = SkyMode.TEX_MODE
		current_base_sky_tex = base_sky_name
	else:
		# sky_sp 或空串为官方 RGB_MODE 标记
		current_sky_mode = SkyMode.RGB_MODE
		current_base_sky_tex = ""
	set_clouds(cloud_name, cloud_speed)
	_refresh_all_materials()


func _refresh_all_materials() -> void:
	# 1. 天空渐变穹顶渲染 (sky_diffuse.glb - render_priority: -30 始终作为天空最底色)
	if _diffuse_sky_instance:
		if current_sky_mode != SkyMode.NOTHING:
			_diffuse_sky_instance.visible = true
			_apply_diffuse_gradient_material(_diffuse_sky_instance)
		else:
			_diffuse_sky_instance.visible = false

	# 2. 全景地平线背景山体与天体层 (sky_base.glb - render_priority: -25 配合 _a.png Alpha 遮罩叠加在天穹之上)
	if _base_sky_instance:
		var base_clean := current_base_sky_tex.to_lower().strip_edges()
		var is_dummy := (base_clean == "" or base_clean == "null" or base_clean == "sky_sp" or base_clean == "sky" or base_clean == "sky_dummy" or base_clean == "dummydummy")
		var is_tex_mode := (current_sky_mode == SkyMode.TEX_MODE) or (not is_dummy and base_clean.begins_with("sky0"))

		if is_tex_mode and not is_dummy:
			var base_path := "res://assets/tex/texture/ntlwe/sky/" + base_clean + ".png"
			var alpha_path := "res://assets/tex/texture/ntlwe/sky/" + base_clean + "_a.png"
			var has_base := ResourceLoader.exists(base_path)
			var has_alpha := ResourceLoader.exists(alpha_path) or base_clean == "sky06"

			if has_base and has_alpha:
				_base_sky_instance.visible = true
				_apply_textured_sky_material(_base_sky_instance, base_path, alpha_path if base_clean != "sky06" else "")
			else:
				_base_sky_instance.visible = false
		else:
			_base_sky_instance.visible = false

	# 3. 刷新云层材质 (sky_blended0t / sky_blended1t - render_priority: -20 / -19)
	_refresh_cloud_materials()


func _refresh_cloud_materials() -> void:
	_apply_single_cloud_layer(_cloud_0_instance, current_cloud_0_tex, 0)
	_apply_single_cloud_layer(_cloud_1_instance, current_cloud_1_tex, 1)


func _apply_diffuse_gradient_material(node: Node) -> void:
	if _diffuse_shader_mat == null:
		_diffuse_shader_mat = ShaderMaterial.new()
		_diffuse_shader_mat.shader = SKY_GRADIENT_SHADER
		_diffuse_shader_mat.render_priority = -100

	_diffuse_shader_mat.set_shader_parameter("top_color", current_top_color)
	_diffuse_shader_mat.set_shader_parameter("horizon_color", current_horizon_color)
	_diffuse_shader_mat.set_shader_parameter("bottom_color", current_bottom_color)

	_override_mesh_materials(node, _diffuse_shader_mat)


func _get_sky_layer_shader() -> Shader:
	return SKY_LAYER_SHADER


func _apply_textured_sky_material(node: Node, tex_path: String, alpha_path: String = "") -> void:
	if _base_sky_shader_mat == null:
		_base_sky_shader_mat = ShaderMaterial.new()
		_base_sky_shader_mat.shader = _get_sky_layer_shader()
		_base_sky_shader_mat.render_priority = -95

	_base_sky_shader_mat.set_shader_parameter("albedo_tex", ResourceLoader.load(tex_path))
	if alpha_path != "":
		_base_sky_shader_mat.set_shader_parameter("alpha_tex", ResourceLoader.load(alpha_path))
		_base_sky_shader_mat.set_shader_parameter("has_alpha_tex", true)
	else:
		_base_sky_shader_mat.set_shader_parameter("has_alpha_tex", false)

	_override_mesh_materials(node, _base_sky_shader_mat)


func _apply_single_cloud_layer(node: Node3D, cloud_tex_name: String, layer_idx: int) -> void:
	if node == null:
		return
	var c_clean := cloud_tex_name.to_lower().strip_edges()
	var c_path := "res://assets/tex/texture/ntlwe/sky/" + c_clean + ".png" if (c_clean != "" and c_clean != "null") else ""
	if c_path == "" or not ResourceLoader.exists(c_path):
		node.visible = false
		return

	node.visible = true
	var mat: ShaderMaterial = _cloud_0_shader_mat if layer_idx == 0 else _cloud_1_shader_mat
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = _get_sky_layer_shader()
		mat.render_priority = -90 + layer_idx # -90 for cloud 0, -89 for cloud 1
		if layer_idx == 0:
			_cloud_0_shader_mat = mat
		else:
			_cloud_1_shader_mat = mat

	# 官方所有云层纹理 (如 cloud_011.png, cloud_022.png, cloud-p01.png) 均为 32-bit RGBA 格式
	# 其透明度已完美内置于纹理本身的 alpha 通道中，严禁加载额外 cloud_XXX_a 灰度图（避免其 r=1.0 导致整片天空被死白覆盖）
	mat.set_shader_parameter("albedo_tex", ResourceLoader.load(c_path))
	mat.set_shader_parameter("has_alpha_tex", false)

	_override_mesh_materials(node, mat)


func _override_mesh_materials(node: Node, mat: Material) -> void:
	var mesh_instances: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		mesh_instances.append(node as MeshInstance3D)
	for child in node.find_children("*", "MeshInstance3D", true, false):
		mesh_instances.append(child as MeshInstance3D)

	for mi in mesh_instances:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mi.mesh:
			for s in range(mi.mesh.get_surface_count()):
				mi.set_surface_override_material(s, mat)


func _process(delta: float) -> void:
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
		if _camera == null:
			return

	# 对标 CNtlPLSky::OnUpdate: 仅同步摄像机空间世界位置，保持世界旋转独立
	global_position = _camera.global_position

	# 云层按官方 _BlendedTexSpeed 旋转流变 (对标 NtlPLSky.cpp: m_pBlendedSkyLayer[0]->Rotate)
	# 在 Godot 中以平滑角速度驱动流云，确保天穹流云具有清晰可见的生动流动质感
	var eff_speed_0 := current_cloud_0_speed
	if eff_speed_0 == 0.0 and not current_cloud_0_tex.is_empty():
		eff_speed_0 = 0.001
	if _cloud_0_instance and _cloud_0_instance.visible:
		_cloud_0_instance.rotation.y += eff_speed_0 * 15.0 * delta

	var eff_speed_1 := current_cloud_1_speed
	if eff_speed_1 == 0.0 and not current_cloud_1_tex.is_empty():
		eff_speed_1 = 0.0006
	if _cloud_1_instance and _cloud_1_instance.visible:
		_cloud_1_instance.rotation.y += eff_speed_1 * 15.0 * delta


func _disable_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_shadows(child)
