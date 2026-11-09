class_name CharacterLobbyStage
extends Node3D

## Character Lobby 3D Stage & Camera Controller
## 负责选角与创角舞台 3D 摄像机多机位平滑过渡、角色站台旋转、以及地形流式载入。
## 严格对标 OpenDBO-Core 官方规范 (LobbyStage.cpp & CharacterStage.cpp):
##   - 创角大厅 (Stage_Cell_Ring): Field 18 沙鲁度假村擂台
##   - 人类大厅 (Stage_Human): Field 42 柯卡拉村
##   - 那美克大厅 (Stage_Namek): Field 45 天天神殿
##   - 魔人大厅 (Stage_Majin): Field 21 孙悟饭爷爷家
## 模型组装彻底使用 DBOCharacterFactory，零硬编码。

static var _stage_configs_cache: Dictionary = {}

static func get_stage_configs() -> Dictionary:
	if not _stage_configs_cache.is_empty():
		return _stage_configs_cache

	# 1. 严格对标 OpenDBO-Core: DboClient/Client/Stage/LobbyStage.cpp:80-185 官方机位坐标与场景
	var canon_stages := {
		-1: {
			"name": "Stage_Cell_Ring",
			"field_id": 18,
			"chunk_coord": Vector2i(2, 2),
			"avatar_pos": Vector3(-296.220, 52.577, -281.390),
			"yaw_deg": 50.0,
			"cam_body_pos": Vector3(-293.450, 53.120, -279.074),
			"cam_face_pos": Vector3(-294.509, 53.188, -279.966),
			"look_target": Vector3(-296.220, 53.750, -281.390)
		},
		0: {
			"name": "Stage_Human",
			"field_id": 42,
			"chunk_coord": Vector2i(2, 5),
			"avatar_pos": Vector3(-350.370, 52.000, 328.730),
			"yaw_deg": 138.0,
			"cam_body_pos": Vector3(-347.356, 52.825, 325.413),
			"cam_face_pos": Vector3(-348.561, 52.540, 326.744),
			"look_target": Vector3(-350.370, 53.150, 328.730)
		},
		1: {
			"name": "Stage_Namek",
			"field_id": 45,
			"chunk_coord": Vector2i(5, 5),
			"avatar_pos": Vector3(471.690, 52.000, 300.630),
			"yaw_deg": 143.0,
			"cam_body_pos": Vector3(474.044, 52.802, 297.184),
			"cam_face_pos": Vector3(473.084, 52.450, 298.589),
			"look_target": Vector3(471.690, 53.150, 300.630)
		},
		2: {
			"name": "Stage_Majin",
			"field_id": 21,
			"chunk_coord": Vector2i(5, 2),
			"avatar_pos": Vector3(365.617, 52.000, -365.843),
			"yaw_deg": 135.0,
			"cam_body_pos": Vector3(368.662, 52.966, -368.846),
			"cam_face_pos": Vector3(367.596, 52.710, -367.788),
			"look_target": Vector3(365.617, 53.150, -365.843)
		}
	}

	# 2. 动态读取大世界官方环境配置 (select_character_chunks/environment.json)
	var env_data := DBOTableManager.get_zone_environment("select_character_chunks")
	var field_map: Dictionary = env_data.get("field_map", {})
	var presets: Array = env_data.get("presets", [])

	for sid in canon_stages:
		var entry: Dictionary = canon_stages[sid].duplicate(true)
		var fid: int = entry["field_id"]
		var preset_idx: int = int(field_map.get(str(fid), 0))
		var preset: Dictionary = presets[preset_idx] if preset_idx < presets.size() else {}

		# 天空模式与贴图
		entry["sky_mode"] = int(preset.get("sky_mode", 1))
		entry["base_sky_tex"] = str(preset.get("base_sky", ""))
		entry["cloud_tex_0"] = str(preset.get("cloud_0", ""))
		entry["cloud_speed_0"] = float(preset.get("cloud_speed_0", 0.0))
		entry["cloud_tex_1"] = str(preset.get("cloud_1", ""))
		entry["cloud_speed_1"] = float(preset.get("cloud_speed_1", 0.0))

		# 环境光与平行光
		var amb: Array = preset.get("ambient_color", [1.0, 1.0, 1.0])
		entry["ambient_color"] = Color(amb[0], amb[1], amb[2], 1.0) if amb.size() >= 3 else Color.WHITE

		var dir_light: Dictionary = preset.get("directional_light", {})
		var sun_c: Array = dir_light.get("color", [1.0, 1.0, 1.0])
		entry["sun_light_color"] = Color(sun_c[0], sun_c[1], sun_c[2], 1.0) if sun_c.size() >= 3 else Color.WHITE
		var sun_a: Array = dir_light.get("angle", [135.0, 45.0, 0.0])
		entry["sun_light_angle"] = Vector3(sun_a[0], sun_a[1], sun_a[2]) if sun_a.size() >= 3 else Vector3(135.0, 45.0, 0.0)

		# 行星与日晕 (太阳)
		var planets: Array = preset.get("planets", [])
		if not planets.is_empty():
			var p0: Dictionary = planets[0]
			entry["planet_tex"] = str(p0.get("texture", "sun_001.png"))
			var rpos: Array = p0.get("relative_pos", [0.0, 0.0, 0.0])
			entry["planet_pos"] = Vector3(rpos[0], rpos[1], rpos[2]) if rpos.size() >= 3 else Vector3.ZERO
			entry["planet_scale"] = float(p0.get("scale", 50.0))
			entry["has_lensflare"] = bool(p0.get("lensflare", false))
		else:
			entry["planet_tex"] = "sun_001.png"
			entry["planet_pos"] = Vector3.ZERO
			entry["planet_scale"] = 50.0
			entry["has_lensflare"] = false

		# 天空盒色彩渐变
		var grad: Dictionary = preset.get("sky_gradient", {})
		if not grad.is_empty():
			var t_arr: Array = grad.get("top", [0.3, 0.1, 0.5])
			var h_arr: Array = grad.get("horizon", [0.0, 0.6, 1.0])
			var b_arr: Array = grad.get("bottom", [0.0, 0.0, 0.0])
			entry["sky_gradient"] = {
				"top": Color(t_arr[0], t_arr[1], t_arr[2], 1.0) if t_arr.size() >= 3 else Color.BLACK,
				"horizon": Color(h_arr[0], h_arr[1], h_arr[2], 1.0) if h_arr.size() >= 3 else Color.BLACK,
				"bottom": Color(b_arr[0], b_arr[1], b_arr[2], 1.0) if b_arr.size() >= 3 else Color.BLACK
			}
		_stage_configs_cache[sid] = entry

	return _stage_configs_cache

var STAGE_CONFIGS: Dictionary:
	get: return get_stage_configs()

const CAM_FOV := 68.0
const ROT_SPEED_DEG := 90.0

@onready var lobby_camera: Camera3D = $LobbyCamera
@onready var sun_light: DirectionalLight3D = $DirectionalLight3D
@onready var stage_background_mount: Node3D = $StageBackground
@onready var avatar_pivot: Node3D = $AvatarPivot
@onready var model_mount: Node3D = $AvatarPivot/ModelMount
@onready var lobby_ui: CharacterLobbyUI = $CharacterLobbyUI

var chunk_manager: WorldChunkManager = null
var current_stage_id: int = -999
var current_yaw_deg: float = 50.0
var rot_direction: int = 0 # -1: 左旋, 0: 停止, 1: 右旋

var current_cam_pos: Vector3 = Vector3.ZERO
var current_cam_target: Vector3 = Vector3.ZERO
var cam_tween: Tween = null

var current_visual_instance: DBOCharacterVisual = null
var current_race: int = 0
var current_gender: int = 0
var current_class_id: int = 0
var is_in_create_mode: bool = false

var _skybox_instance: WorldSkybox = null
var _sun_flare_node: Node3D = null
var _current_sun_world_pos: Vector3 = Vector3.ZERO
var _lens_flare_overlay: Control = null
var _flare_spots: Array = []


func _ready() -> void:
	lobby_camera.fov = CAM_FOV

	# 清理旧残留
	for child in model_mount.get_children():
		model_mount.remove_child(child)
		child.queue_free()

	# 初始化天空穹顶、耀眼太阳与大气环境
	_setup_environment_and_sun()

	# 初始化 select_character 世界区块流加载器 (九宫格流式加载周围地表)
	chunk_manager = WorldChunkManager.new()
	chunk_manager.name = "WorldChunkManager"
	chunk_manager.zone_name = "select_character"
	chunk_manager.view_distance_chunks = 1
	stage_background_mount.add_child(chunk_manager)

	# 绑定 UI 事件信号
	if lobby_ui:
		lobby_ui.avatar_rot_input.connect(_on_avatar_rot_input)
		lobby_ui.camera_zoom_requested.connect(_on_camera_zoom_requested)
		lobby_ui.avatar_visual_changed.connect(_on_avatar_visual_changed)
		lobby_ui.mode_changed.connect(_on_ui_mode_changed)
		lobby_ui.trigger_initial_avatar_sync()

	if current_stage_id == -999:
		switch_to_stage(0)
	
	if current_visual_instance == null:
		_load_character_model(0, 0, 1, 4, 1, 2)
	
	# 播放大厅背景音乐
	if AudioManager:
		AudioManager.play_bgm("BGM_Field_01", 1.0)


func _process(delta: float) -> void:
	if rot_direction != 0:
		current_yaw_deg += rot_direction * ROT_SPEED_DEG * delta
		avatar_pivot.rotation_degrees.y = current_yaw_deg

	if _lens_flare_overlay:
		_lens_flare_overlay.queue_redraw()


## 切换到指定种族的选角/创角舞台机位与地貌
func switch_to_stage(stage_id: int) -> void:
	if not STAGE_CONFIGS.has(stage_id):
		stage_id = -1
	if current_stage_id == stage_id:
		return
	current_stage_id = stage_id
	var cfg: Dictionary = STAGE_CONFIGS[stage_id]

	# 1. 刷新对应舞台地貌 (大厅设定 3x3 九宫格视距，加载中心周围地表，杜绝超大视距越界加载其他独立大厅地貌)
	if chunk_manager:
		chunk_manager.view_distance_chunks = 1
		var center_chunk: Vector2i = cfg.get("chunk_coord", Vector2i.ZERO)
		chunk_manager.force_load_zone("select_character", center_chunk)

	# 2. 移动角色站台锚点
	var target_pos: Vector3 = cfg.avatar_pos
	avatar_pivot.global_position = target_pos
	current_yaw_deg = cfg.yaw_deg
	avatar_pivot.rotation_degrees.y = current_yaw_deg

	# 3. 摄影机对齐
	current_cam_pos = cfg.get("cam_body_pos", lobby_camera.global_position)
	current_cam_target = cfg.get("look_target", avatar_pivot.global_position)

	if cam_tween and cam_tween.is_valid():
		cam_tween.kill()

	_apply_camera_lookat(current_cam_pos, current_cam_target)

	# 4. 从数据层 environment.json 读取官方解包环境配置 (对标 wfp 属性表)
	var env_data: Dictionary = DBOTableManager.get_zone_environment("select_character_chunks")
	var field_id_str: String = str(cfg.get("field_id", 18))
	var preset: Dictionary = {}
	if not env_data.is_empty():
		var field_map: Dictionary = env_data.get("field_map", {})
		var presets: Array = env_data.get("presets", [])
		if field_map.has(field_id_str):
			var p_idx: int = field_map[field_id_str]
			if p_idx >= 0 and p_idx < presets.size():
				preset = presets[p_idx]

	var _amb_color_arr: Array = preset.get("ambient_color", [])
	var _amb_color: Color = Color(_amb_color_arr[0], _amb_color_arr[1], _amb_color_arr[2]) if _amb_color_arr.size() == 3 else cfg.get("ambient_color", Color(0.32, 0.40, 0.83))
	var planets_arr: Array = preset.get("planets", [])
	var p_tex_name: String = ""
	var has_flare: bool = true
	if not planets_arr.is_empty():
		p_tex_name = str(planets_arr[0].get("texture", "sun_001.png"))
		has_flare = bool(planets_arr[0].get("lensflare", true))
	else:
		p_tex_name = str(cfg.get("planet_tex", "sun_001.png"))
		has_flare = bool(cfg.get("has_lensflare", true))

	if _skybox_instance:
		if not preset.is_empty():
			_skybox_instance.apply_environment_preset(preset)
			# 若预设缺少全景山体贴图或为 sky_sp/空串，且 stage 配置包含 sky00~06 真实贴图时补齐
			var cur_b := _skybox_instance.current_base_sky_tex.to_lower().strip_edges()
			if (cur_b.is_empty() or cur_b == "sky_sp" or cur_b == "sky") and cfg.has("base_sky_tex"):
				var cfg_b := str(cfg["base_sky_tex"]).to_lower().strip_edges()
				if cfg_b.begins_with("sky0"):
					_skybox_instance.current_base_sky_tex = cfg_b
			if _skybox_instance.current_cloud_0_tex.is_empty() and cfg.has("cloud_tex_0"):
				_skybox_instance.current_cloud_0_tex = str(cfg["cloud_tex_0"])
				_skybox_instance.current_cloud_0_speed = float(cfg.get("cloud_speed_0", 0.001))
			_skybox_instance._refresh_all_materials()
		else:
			var s_mode: int = int(cfg.get("sky_mode", 1))
			var s_grad: Dictionary = cfg.get("sky_gradient", {})
			var base_sky: String = str(cfg.get("base_sky_tex", "sky_sp"))
			var cloud_0: String = str(cfg.get("cloud_tex_0", "cloud_011"))
			var cloud_speed_0: float = float(cfg.get("cloud_speed_0", 0.001))
			var cloud_1: String = str(cfg.get("cloud_tex_1", ""))
			var cloud_speed_1: float = float(cfg.get("cloud_speed_1", 0.0))
			var top_c: Color = s_grad.get("top", Color(0.302, 0.055, 0.584))
			var horiz_c: Color = s_grad.get("horizon", Color(0.0, 0.635, 1.0))
			var bot_c: Color = s_grad.get("bottom", Color(0.0, 0.0, 0.0))
			_skybox_instance.set_sky_mode(s_mode, top_c, horiz_c, bot_c, base_sky)
			_skybox_instance.set_clouds(cloud_0, cloud_speed_0, cloud_1, cloud_speed_1)

	# 5. 动态注入官方环境光照与主日光 (严格对标 OpenDBO-Core: CharacterStage.cpp:100-118)
	var world_env: WorldEnvironment = find_child("WorldEnvironment", true, false) as WorldEnvironment
	if world_env and world_env.environment:
		var env := world_env.environment
		# 对标 CharacterStage.cpp: color = {0.9f, 0.9f, 0.9f, 1.0f}
		# 采用温暖明朗的白昼漫反射，彻底消除冷蓝死黑阴森阴影
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.86, 0.89, 0.94, 1.0)
		env.ambient_light_energy = 0.90

	# 6. 定位官方天体与光晕系统 (对标 sNTL_PLANET: _TexName, _RelativePos, _Scale, _LensFlareExistence)
	var cam_dir := (current_cam_target - current_cam_pos).normalized()
	var cam_right := cam_dir.cross(Vector3.UP).normalized()
	var sun_pos := current_cam_pos + cam_dir * 38.0 + Vector3.UP * 24.0 - cam_right * 5.0
	_current_sun_world_pos = sun_pos
	if _sun_flare_node:
		_sun_flare_node.global_position = sun_pos
		var p_tex_path := "res://assets/tex/texture/ntlwe/planet/" + p_tex_name
		if ResourceLoader.exists(p_tex_path):
			var sun_core_sprite := _sun_flare_node.find_child("SunCore", true, false) as Sprite3D
			if sun_core_sprite:
				var tex = ResourceLoader.load(p_tex_path) as Texture2D
				sun_core_sprite.texture = tex
				if sun_core_sprite.material_override is StandardMaterial3D:
					(sun_core_sprite.material_override as StandardMaterial3D).albedo_texture = tex

	if _lens_flare_overlay:
		_lens_flare_overlay.visible = has_flare

	if sun_light:
		# 严格对标 OpenDBO-Core CharacterStage.cpp:114-115
		# RwFrameRotate(X, 135.0f); RwFrameRotate(Y, -45.0f);
		# 主日光从摄像机斜上方照向角色正面，赋予面部与身躯明朗阳光，阴影自然投射于身后
		var light_pos := current_cam_pos + Vector3.UP * 22.0 + cam_right * 10.0 - cam_dir * 8.0
		sun_light.global_position = light_pos
		var dl_dict: Dictionary = preset.get("directional_light", {})
		var dl_col_arr: Array = dl_dict.get("color", [])
		if dl_col_arr.size() == 3:
			sun_light.light_color = Color(dl_col_arr[0], dl_col_arr[1], dl_col_arr[2])
		else:
			sun_light.light_color = cfg.get("sun_light_color", Color(1.0, 0.98, 0.90))
		sun_light.light_energy = 1.25
		sun_light.look_at(target_pos, Vector3.UP)


## 初始化天空穹顶、太阳光晕与大气光照 (对标 OpenDBO-Core: NtlPLSky.cpp & NtlPLLensFlare.cpp)
func _setup_environment_and_sun() -> void:
	# 1. 注入官方天空穹顶 (sky_base 渐变底 + sky_blended0t 浮云)
	if _skybox_instance == null:
		_skybox_instance = WorldSkybox.new()
		_skybox_instance.name = "WorldSkybox"
		_skybox_instance.sky_scale = 3.0
		_skybox_instance.enable_sun = false # 选角大厅太阳由本舞台机位联动系统专门驱动
		add_child(_skybox_instance)

	# 2. 动态构建官方耀眼太阳与多阶光晕系统 (对标 NtlPLLensFlare.cpp: AddSpots)
	if _sun_flare_node == null:
		_sun_flare_node = Node3D.new()
		_sun_flare_node.name = "SunLensFlareGroup"
		add_child(_sun_flare_node)

		var sun_disk_path := "res://assets/tex/texture/ntlwe/planet/sun_001.png"
		var flare_tex1_path := "res://assets/tex/texture/effect/lensflare_01.png"
		var flare_tex2_path := "res://assets/tex/texture/effect/lensflare_02.png"
		var flare_tex3_path := "res://assets/tex/texture/effect/lensflare_03.png"
		var flare_tex4_path := "res://assets/tex/texture/effect/lensflare_04.png"

		var tex_sun: Texture2D = (ResourceLoader.load(sun_disk_path) as Texture2D) if ResourceLoader.exists(sun_disk_path) else null
		var tex1: Texture2D = (ResourceLoader.load(flare_tex1_path) as Texture2D) if ResourceLoader.exists(flare_tex1_path) else null
		var tex2: Texture2D = (ResourceLoader.load(flare_tex2_path) as Texture2D) if ResourceLoader.exists(flare_tex2_path) else null
		var tex3: Texture2D = (ResourceLoader.load(flare_tex3_path) as Texture2D) if ResourceLoader.exists(flare_tex3_path) else null
		var tex4: Texture2D = (ResourceLoader.load(flare_tex4_path) as Texture2D) if ResourceLoader.exists(flare_tex4_path) else null

		# 实体太阳光盘：采用 DBO 原版 planet/sun_001.png 核心日轮 (对标 NtlPLPlanet.cpp & NtlPLSun.cpp)
		var sun_core_tex: Texture2D = tex_sun if tex_sun else tex1
		if sun_core_tex:
			var sprite1 := Sprite3D.new()
			sprite1.name = "SunCore"
			sprite1.texture = sun_core_tex
			sprite1.pixel_size = 0.035
			sprite1.modulate = Color(1.0, 0.96, 0.88, 1.0)
			sprite1.no_depth_test = true
			sprite1.render_priority = 10
			var mat1 := StandardMaterial3D.new()
			mat1.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat1.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			mat1.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat1.albedo_texture = sun_core_tex
			mat1.cull_mode = BaseMaterial3D.CULL_DISABLED
			mat1.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			mat1.no_depth_test = true
			mat1.vertex_color_use_as_albedo = true
			mat1.render_priority = 10
			sprite1.material_override = mat1
			_sun_flare_node.add_child(sprite1)

		# 大气光晕射线：采用 DBO 原版 effect/lensflare_02.png 柔和辐射
		if tex2:
			var sprite2 := Sprite3D.new()
			sprite2.name = "SunRays"
			sprite2.texture = tex2
			sprite2.pixel_size = 0.080
			sprite2.modulate = Color(1.0, 0.95, 0.85, 0.60)
			sprite2.no_depth_test = true
			sprite2.render_priority = 9
			var mat2 := StandardMaterial3D.new()
			mat2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat2.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			mat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat2.albedo_texture = tex2
			mat2.cull_mode = BaseMaterial3D.CULL_DISABLED
			mat2.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			mat2.no_depth_test = true
			mat2.vertex_color_use_as_albedo = true
			mat2.render_priority = 9
			sprite2.material_override = mat2
			_sun_flare_node.add_child(sprite2)

		# 3. 动态构建官方 10 阶透镜折射光斑连线系统 (对标 OpenDBO-Core: NtlPLLensFlare.cpp: AddSpots)
		# 沿太阳投射至屏幕中心的光晕折射线上生成细腻光斑群，杜绝过曝模糊
		_flare_spots.clear()
		_flare_spots.append({"tex": tex2, "size": 0.15, "line_pos":  0.70, "color": Color(1.0, 1.0, 1.0, 0.18)})
		_flare_spots.append({"tex": tex1, "size": 0.10, "line_pos":  0.50, "color": Color(1.0, 1.0, 1.0, 0.14)})
		_flare_spots.append({"tex": tex4, "size": 0.04, "line_pos":  0.40, "color": Color(0.6, 1.0, 0.9, 0.12)})
		_flare_spots.append({"tex": tex3, "size": 0.03, "line_pos":  0.30, "color": Color(1.0, 0.6, 0.5, 0.20)})
		_flare_spots.append({"tex": tex4, "size": 0.025, "line_pos": 0.15, "color": Color(0.4, 0.6, 1.0, 0.12)})
		_flare_spots.append({"tex": tex4, "size": 0.04, "line_pos": -0.10, "color": Color(0.6, 1.0, 0.9, 0.12)})
		_flare_spots.append({"tex": tex3, "size": 0.10, "line_pos": -0.30, "color": Color(1.0, 0.7, 0.0, 0.15)})
		_flare_spots.append({"tex": tex3, "size": 0.18, "line_pos": -0.70, "color": Color(1.0, 0.35, 0.0, 0.16)})
		_flare_spots.append({"tex": tex4, "size": 0.12, "line_pos": -1.00, "color": Color(1.0, 0.7, 0.5, 0.12)})
		_flare_spots.append({"tex": tex4, "size": 0.25, "line_pos": -2.50, "color": Color(1.0, 0.8, 0.2, 0.06)})

		var canvas_layer := CanvasLayer.new()
		canvas_layer.name = "LensFlareCanvasLayer"
		canvas_layer.layer = 5
		add_child(canvas_layer)

		_lens_flare_overlay = Control.new()
		_lens_flare_overlay.name = "LensFlareOverlay"
		_lens_flare_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		_lens_flare_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cmat := CanvasItemMaterial.new()
		cmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_lens_flare_overlay.material = cmat
		_lens_flare_overlay.draw.connect(_on_lens_flare_draw)
		canvas_layer.add_child(_lens_flare_overlay)

	# 3. 增强世界环境光照参数 (清晰通透的大气视觉，抑制过度泛光导致太阳失真模糊)
	var world_env: WorldEnvironment = find_child("WorldEnvironment", true, false) as WorldEnvironment
	if world_env and world_env.environment:
		var env := world_env.environment
		# 清空背景放行 3D Skybox 真实几何与云层渲染
		env.background_mode = Environment.BG_CLEAR_COLOR
		RenderingServer.set_default_clear_color(Color(0.38, 0.68, 0.98, 1.0))

		# 注入正统环境光照参数 (对标 OpenDBO-Core: CharacterStage.cpp: m_pLtAmbient)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.86, 0.89, 0.94, 1.0)
		env.ambient_light_energy = 0.90

		env.glow_enabled = true
		env.glow_intensity = 0.15
		env.glow_bloom = 0.04
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.tonemap_exposure = 1.08

	if sun_light:
		sun_light.light_color = Color(1.0, 0.97, 0.91)
		sun_light.light_energy = 1.35
		sun_light.shadow_enabled = true


func _apply_camera_lookat(pos: Vector3, target: Vector3) -> void:
	lobby_camera.global_position = pos
	lobby_camera.look_at(target, Vector3.UP)


## 动态绘制正统透镜折射光斑连线 (严格对标 OpenDBO-Core: NtlPLLensFlare.cpp: UpdateVertices)
func _on_lens_flare_draw() -> void:
	if not is_inside_tree() or lobby_camera == null or not lobby_camera.is_inside_tree() or _lens_flare_overlay == null or _current_sun_world_pos == Vector3.ZERO:
		return
	if lobby_camera.is_position_behind(_current_sun_world_pos):
		return

	var pos_light: Vector2 = lobby_camera.unproject_position(_current_sun_world_pos)
	var screen_size: Vector2 = _lens_flare_overlay.get_viewport_rect().size
	var center := screen_size * 0.5
	var diff := center - pos_light

	# 边缘渐隐强度计算 (对标 NtlPLLensFlare.cpp)
	var away_x: float = 0.0
	if pos_light.x < 0.0:
		away_x = -pos_light.x
	elif pos_light.x > screen_size.x:
		away_x = pos_light.x - screen_size.x
	var away_y: float = 0.0
	if pos_light.y < 0.0:
		away_y = -pos_light.y
	elif pos_light.y > screen_size.y:
		away_y = pos_light.y - screen_size.y
	var f_away: float = max(away_x, away_y)
	var border := 450.0
	if f_away > border:
		return
	var intensity: float = clamp(1.0 - f_away / border, 0.0, 1.0)

	for spot in _flare_spots:
		var tex: Texture2D = spot.get("tex")
		if tex == null:
			continue
		var line_pos: float = float(spot.get("line_pos", 0.0))
		var size_ratio: float = float(spot.get("size", 0.1))
		var col: Color = spot.get("color", Color.WHITE)

		var spot_x: float = center.x - diff.x * line_pos
		var spot_y: float = center.y - diff.y * line_pos
		var spot_size: float = screen_size.x * size_ratio
		var rect := Rect2(spot_x - spot_size * 0.5, spot_y - spot_size * 0.5, spot_size, spot_size)
		col.a *= intensity
		_lens_flare_overlay.draw_texture_rect(tex, rect, false, col)


func _on_avatar_rot_input(direction: int) -> void:
	rot_direction = direction


func _on_camera_zoom_requested(is_zoom_in: bool) -> void:
	var cfg: Dictionary = STAGE_CONFIGS.get(current_stage_id, STAGE_CONFIGS.get(-1, {}))
	if cfg.is_empty():
		return
	if cam_tween and cam_tween.is_valid():
		cam_tween.kill()

	var face_pos: Vector3 = cfg.get("cam_face_pos", lobby_camera.global_position)
	var body_pos: Vector3 = cfg.get("cam_body_pos", lobby_camera.global_position)
	var target_pos: Vector3 = face_pos if is_zoom_in else body_pos
	var look_tgt: Vector3 = cfg.get("look_target", avatar_pivot.global_position)

	cam_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	cam_tween.tween_method(_tween_cam_pos, lobby_camera.global_position, target_pos, 0.45)
	cam_tween.tween_method(_tween_cam_target, current_cam_target, look_tgt, 0.45)


func _tween_cam_pos(pos: Vector3) -> void:
	current_cam_pos = pos
	lobby_camera.global_position = pos
	lobby_camera.look_at(current_cam_target, Vector3.UP)


func _tween_cam_target(target: Vector3) -> void:
	current_cam_target = target
	lobby_camera.look_at(current_cam_target, Vector3.UP)


func _on_ui_mode_changed(is_create: bool) -> void:
	is_in_create_mode = is_create
	if is_in_create_mode:
		switch_to_stage(-1)
	else:
		switch_to_stage(current_race)


func _on_avatar_visual_changed(race: int, gender: int, class_id: int, hair: int, hair_color: int, face: int, skin_color: int, equipped_items: Array = []) -> void:
	var race_changed := (current_race != race or current_gender != gender)
	current_race = race
	current_gender = gender
	current_class_id = class_id

	if is_in_create_mode:
		switch_to_stage(-1)
	else:
		switch_to_stage(race)

	if race_changed or current_visual_instance == null:
		_load_character_model(race, gender, hair, hair_color, face, skin_color)
	else:
		if current_visual_instance:
			current_visual_instance.character_class_id = current_class_id
			current_visual_instance.apply_character_customization(race, gender, hair, hair_color, face, skin_color)
	if current_visual_instance:
		current_visual_instance.character_class_id = current_class_id

	# 装备初始新手部件或已穿戴装备 (适配成人素体与儿童烘焙素体)
	if current_visual_instance:
		if not equipped_items.is_empty():
			for itm in equipped_items:
				var itm_tblidx: int = int(itm.get("item_tblidx", itm.get("tblidx", 0)))
				if itm_tblidx > 0:
					DBOCharacterFactory.equip_item_to_character(current_visual_instance, itm_tblidx)
		else:
			# 创角模式或裸身预览状态：卸下所有防具与武器，完美恢复纯净素体
			for slot_k in ["torso", "legs", "feet", "hands", "weapon_r", "weapon_l", "face", "head"]:
				current_visual_instance.unequip_slot(slot_k)


func _load_character_model(race: int, gender: int, hair: int = 1, hair_color: int = 4, face: int = 1, skin_color: int = 2) -> void:
	# 销毁旧视觉模型
	for child in model_mount.get_children():
		model_mount.remove_child(child)
		child.queue_free()
	current_visual_instance = null

	# 使用 DBOCharacterFactory 构建标准童年期素体模型 (选角与创角统一使用童年阶段)
	var visual := DBOCharacterFactory.build_player_visual(race, gender, false)
	if visual:
		model_mount.add_child(visual)
		current_visual_instance = visual
		visual.character_class_id = current_class_id
		visual.apply_character_customization(race, gender, hair, hair_color, face, skin_color)
		visual.play_animation("idle")
