extends Node

## Audio Manager (Dragon Ball Online Audio Controller)
## 提供 BGM 平滑交叉淡入淡出、2D UI 界面音效池与 3D 空间发声调度服务。

signal bgm_changed(bgm_name: String)

const SOUND_BASE_DIR := "res://assets/sound/"
const SOUND_SUBDIRS: Array[String] = [
	"bgm/", "effect/", "environment/", "footsteps/", "monster/",
	"npc/", "object/", "skill/", "system/", "tlq/", "tmq/", "vehicle/", "voice/"
]

@export var default_fade_duration: float = 1.0

var _bgm_player_a: AudioStreamPlayer
var _bgm_player_b: AudioStreamPlayer
var _active_bgm_player: AudioStreamPlayer = null
var _current_bgm_track: String = ""

# 2D 音效播放器对象池 (UI等通用发声)
var _sfx_2d_pool: Array[AudioStreamPlayer] = []
const SFX_2D_POOL_SIZE := 8

# 音频资源轻量缓存
var _sound_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_bgm_players()
	_setup_sfx_pool()


func _setup_bgm_players() -> void:
	_bgm_player_a = AudioStreamPlayer.new()
	_bgm_player_a.name = "BGMPlayerA"
	_bgm_player_a.bus = "Master"
	add_child(_bgm_player_a)

	_bgm_player_b = AudioStreamPlayer.new()
	_bgm_player_b.name = "BGMPlayerB"
	_bgm_player_b.bus = "Master"
	add_child(_bgm_player_b)


func _setup_sfx_pool() -> void:
	for i in range(SFX_2D_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer2D_%d" % i
		player.bus = "Master"
		add_child(player)
		_sfx_2d_pool.append(player)


## 播放背景音乐 (支持淡入淡出平滑过渡)
func play_bgm(bgm_file_name: String, fade_duration: float = -1.0) -> void:
	if bgm_file_name == _current_bgm_track and is_bgm_playing():
		return

	var duration := fade_duration if fade_duration >= 0.0 else default_fade_duration
	var stream := load_sound(bgm_file_name)
	if stream == null:
		push_warning("[AudioManager] 无法加载 BGM: " + bgm_file_name)
		return

	var next_player: AudioStreamPlayer = _bgm_player_b if _active_bgm_player == _bgm_player_a else _bgm_player_a
	var prev_player: AudioStreamPlayer = _active_bgm_player

	next_player.stream = stream
	next_player.volume_db = -80.0
	next_player.play()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(next_player, "volume_db", 0.0, duration)

	if prev_player and prev_player.playing:
		tween.tween_property(prev_player, "volume_db", -80.0, duration)
		tween.chain().tween_callback(prev_player.stop)

	_active_bgm_player = next_player
	_current_bgm_track = bgm_file_name
	bgm_changed.emit(bgm_file_name)


## 停止背景音乐
func stop_bgm(fade_duration: float = 1.0) -> void:
	if _active_bgm_player and _active_bgm_player.playing:
		var tween := create_tween()
		tween.tween_property(_active_bgm_player, "volume_db", -80.0, fade_duration)
		tween.tween_callback(_active_bgm_player.stop)
		_current_bgm_track = ""


func is_bgm_playing() -> bool:
	return _active_bgm_player != null and _active_bgm_player.playing


## 播放 2D UI 或全局音效
func play_sfx_2d(sfx_file_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var stream := load_sound(sfx_file_name)
	if stream == null:
		return

	var player := _get_available_sfx_player()
	if player:
		player.stream = stream
		player.volume_db = volume_db
		player.pitch_scale = pitch_scale
		player.play()


## 在 3D 空间位置播放音效 (用于脚步声、受击音效、气功波爆炸)
func play_sfx_3d(sfx_file_name: String, global_position: Vector3, max_distance: float = 30.0, volume_db: float = 0.0) -> void:
	var stream := load_sound(sfx_file_name)
	if stream == null:
		return

	var player_3d := AudioStreamPlayer3D.new()
	player_3d.stream = stream
	player_3d.global_position = global_position
	player_3d.max_distance = max_distance
	player_3d.volume_db = volume_db
	player_3d.bus = "Master"
	add_child(player_3d)

	player_3d.finished.connect(player_3d.queue_free)
	player_3d.play()


## 加载音效资源（带内存缓存与自动扩展名检查）
func load_sound(sound_name: String) -> AudioStream:
	var clean_name := sound_name.strip_edges()
	if clean_name.is_empty():
		return null

	if _sound_cache.has(clean_name):
		return _sound_cache[clean_name]

	# 尝试全路径或默认搜索目录
	var candidate_paths: Array[String] = []
	if clean_name.begins_with("res://"):
		candidate_paths.append(clean_name)
	else:
		var extensions: Array[String] = []
		if clean_name.contains("."):
			extensions.append("")
		else:
			extensions.append_array(["", ".wav", ".ogg", ".mp3"])
		var prefixes: Array[String] = [SOUND_BASE_DIR]
		if not clean_name.contains("/"):
			for sub in SOUND_SUBDIRS:
				prefixes.append(SOUND_BASE_DIR + sub)

		for prefix in prefixes:
			for ext in extensions:
				candidate_paths.append(prefix + clean_name + ext)
				candidate_paths.append(prefix + clean_name.to_lower() + ext)

	for path in candidate_paths:
		if ResourceLoader.exists(path):
			var res := ResourceLoader.load(path)
			if res is AudioStream:
				_sound_cache[clean_name] = res
				return res

	# BGM 默认优雅回退
	if clean_name.to_lower().contains("bgm"):
		var default_bgm := "res://assets/sound/bgm/bgm_share_plain1.ogg"
		if ResourceLoader.exists(default_bgm):
			var default_res := ResourceLoader.load(default_bgm)
			if default_res is AudioStream:
				_sound_cache[clean_name] = default_res
				return default_res

	return null


func _get_available_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_2d_pool:
		if not p.playing:
			return p
	return _sfx_2d_pool[0]
