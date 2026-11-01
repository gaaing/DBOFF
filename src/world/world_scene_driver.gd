class_name WorldSceneDriver
extends Node3D

## World Scene Driver (Dragon Ball Online Master Environment Controller)
## 对标 OpenDBO-Core: DboClient/Lib/NtlPresentation/NtlPLWorldEntity.cpp & DboClient/Client/Main/DboApplication.cpp
## 大世界全景中枢：调度大世界天空盒、九宫格区块流式加载、动漫高动态光照环境与区域背景音乐（BGM）。

@export var default_zone_name: String = "start_001"
@export var initial_player_spawn_pos: Vector3 = Vector3(0.0, 60.0, 0.0)
@export var spawn_player: bool = true
@export var player_character_scene: PackedScene = preload("res://scenes/entities/player_character.tscn")

var _skybox: WorldSkybox = null
var _chunk_manager: WorldChunkManager = null
var _prop_manager: WorldPropManager = null
var _camera: Camera3D = null
var player_instance: DBOPlayerController3D = null


func _ready() -> void:
	_setup_lighting_and_environment()
	_setup_skybox()
	_setup_chunk_manager()
	_setup_player()
	_setup_default_bgm()


## 全局动态接入官方切片 environment.json 光照与环境配置 (严格对标 OpenDBO-Core: NtlPLLight.cpp)
func _setup_lighting_and_environment() -> void:
	var env_data: Dictionary = DBOTableManager.get_zone_environment(default_zone_name)
	var preset: Dictionary = {}
	if not env_data.is_empty():
		var presets: Array = env_data.get("presets", [])
		if not presets.is_empty():
			preset = presets[0]

	# 1. 阳光定向光源 (来自切片二进制解包 directional_light)
	var sun := find_child("DirectionalLight3D", true, false) as DirectionalLight3D
	if sun == null:
		sun = DirectionalLight3D.new()
		sun.name = "AnimeSunlight"
		add_child(sun)

	var dl_dict: Dictionary = preset.get("directional_light", {})
	var dl_col_arr: Array = dl_dict.get("color", [1.0, 0.98, 0.90])
	var dl_col := Color(dl_col_arr[0], dl_col_arr[1], dl_col_arr[2]) if dl_col_arr.size() == 3 else Color(1.0, 0.98, 0.90)
	var dl_ang_arr: Array = dl_dict.get("angle", [135.0, 45.0, 0.0])

	sun.light_color = dl_col
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.shadow_bias = 0.04
	sun.directional_shadow_max_distance = 250.0

	# 角度映射: 官方 wfp 中 _AngLightDirectional 欧拉角 (X=135°, Y=45°)
	# 在 Godot 中 pitch 旋转为 -(180 - X) = -45°, yaw 为 Y = 45°
	var pitch_deg: float = -(180.0 - float(dl_ang_arr[0])) if dl_ang_arr.size() > 0 else -45.0
	var yaw_deg: float = float(dl_ang_arr[1]) if dl_ang_arr.size() > 1 else 45.0
	sun.rotation_degrees = Vector3(pitch_deg, yaw_deg, 0.0)

	# 2. 世界环境渲染配置 (来自切片二进制解包 ambient_color)
	var env_node := find_child("WorldEnvironment", true, false) as WorldEnvironment
	if env_node == null:
		env_node = WorldEnvironment.new()
		env_node.name = "WorldEnvironment"
		var env := Environment.new()
		env.background_mode = Environment.BG_CLEAR_COLOR
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR

		var amb_col_arr: Array = preset.get("ambient_color", [0.75, 0.82, 0.90])
		var amb_col := Color(amb_col_arr[0], amb_col_arr[1], amb_col_arr[2]) if amb_col_arr.size() == 3 else Color(0.75, 0.82, 0.90)
		env.ambient_light_color = amb_col
		env.ambient_light_energy = 0.85
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.tonemap_exposure = 1.05
		env.ssr_enabled = false
		env.ssao_enabled = true
		env.ssao_radius = 1.5
		env.glow_enabled = true
		env.glow_intensity = 0.35
		env_node.environment = env
		add_child(env_node)


func _setup_skybox() -> void:
	_skybox = find_child("WorldSkybox", true, false) as WorldSkybox
	if _skybox == null:
		_skybox = WorldSkybox.new()
		_skybox.name = "WorldSkybox"
		add_child(_skybox)

	var env_data: Dictionary = DBOTableManager.get_zone_environment(default_zone_name)
	if not env_data.is_empty():
		var presets: Array = env_data.get("presets", [])
		if not presets.is_empty():
			_skybox.apply_environment_preset(presets[0])


func _setup_chunk_manager() -> void:
	_prop_manager = find_child("WorldPropManager", true, false) as WorldPropManager
	if _prop_manager == null:
		_prop_manager = WorldPropManager.new()
		_prop_manager.name = "WorldPropManager"
		add_child(_prop_manager)

	_chunk_manager = find_child("WorldChunkManager", true, false) as WorldChunkManager
	if _chunk_manager == null:
		_chunk_manager = WorldChunkManager.new()
		_chunk_manager.name = "WorldChunkManager"
		_chunk_manager.zone_name = default_zone_name
		add_child(_chunk_manager)

	_camera = get_viewport().get_camera_3d()
	if _camera:
		_chunk_manager.target_follow_node = _camera
		_camera.global_position = initial_player_spawn_pos


func _setup_player() -> void:
	if not spawn_player:
		return

	# 若场景中已存在 FreeLookCamera3D，关闭它让位于玩家视角
	var free_cam := find_child("FreeLookCamera3D", true, false) as Camera3D
	if free_cam:
		free_cam.current = false
		free_cam.process_mode = Node.PROCESS_MODE_DISABLED

	if player_character_scene:
		player_instance = player_character_scene.instantiate() as DBOPlayerController3D
		player_instance.name = "PlayerCharacter"

		# 读取当前选中的角色存档数据 (来自 DBOSaveManager)
		var char_data: Dictionary = DBOSaveManager.get_active_character_data()
		var prof: Dictionary = char_data.get("character_profile", {})
		player_instance.race = int(prof.get("race", 0)) as DBOCharacterFactory.Race
		player_instance.gender = int(prof.get("gender", 0)) as DBOCharacterFactory.Gender
		player_instance.is_adult = bool(prof.get("is_adult", false))

		var spawn_pos: Vector3 = initial_player_spawn_pos
		var world_tx: Dictionary = char_data.get("world_transform", {})
		var pos_arr: Array = world_tx.get("position", [])
		if pos_arr.size() == 3:
			spawn_pos = Vector3(float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]))

		add_child(player_instance)
		player_instance.global_position = spawn_pos

		# 绑定大世界九宫格追踪
		if _chunk_manager:
			_chunk_manager.target_follow_node = player_instance

		# 挂载大世界流式实体刷怪调度器 (加载 assets/tbl/spawn_mob_main_world.json)
		var spawn_mgr := find_child("WorldSpawnManager", true, false) as WorldSpawnManager
		if spawn_mgr == null:
			spawn_mgr = WorldSpawnManager.new()
			spawn_mgr.name = "WorldSpawnManager"
			spawn_mgr.follow_target = player_instance
			spawn_mgr.world_id_name = "main_world"
			add_child(spawn_mgr)

		# 初始化玩家官方新手初始装备与背包道具
		if DBOInventoryManager:
			var class_id: int = int(prof.get("class_id", 0))
			DBOInventoryManager.init_newbie_inventory(player_instance.race, class_id)


func _setup_default_bgm() -> void:
	# 播放龙珠大世界原版野外或新手村背景音乐
	if AudioManager:
		AudioManager.play_bgm("BGM_Field_01", 1.5)
