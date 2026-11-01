class_name WorldSpawnManager
extends Node3D

## World Spawn Manager
## 负责大世界流式怪物与 NPC 实体按需生成与动态剔除。
## 严格对标 OpenDBO-Core:
##   - DboShared/NtlGameTable/SpawnTable.h (sSPAWN_TBLDAT)
##   - DboServer/Server/GameServer/BotState_Spawning.cpp & BotState_Despawning.cpp
##
## 采用二维空间网格 (Spatial Hash Cell) 分区，仅在玩家视野九宫格半径内实例化实体，
## 超出视距自动销毁或回收，绝不让上万只野怪同时常驻场景，保证 Godot 极致流畅与 0 内存泄漏。

const CELL_SIZE: float = 120.0
const SPAWN_RADIUS: float = 120.0
const DESPAWN_RADIUS: float = 180.0
const CHECK_INTERVAL: float = 0.5

@export var follow_target: Node3D = null
@export var world_id_name: String = "main_world"

# 空间网格缓存 { Vector2i: Array[Dictionary] }
var _mob_cells: Dictionary = {}
var _npc_cells: Dictionary = {}

# 活跃实例追踪 { spawn_idx: Node3D }
var _active_mobs: Dictionary = {}
var _active_npcs: Dictionary = {}

# 怪物击杀重生冷却追踪 { spawn_idx: float(重生时间戳) }
var _respawn_cooldowns: Dictionary = {}

var _check_timer: float = 0.0
var _is_initialized: bool = false


func _ready() -> void:
	if follow_target == null:
		follow_target = find_parent("MainWorld")
	load_world_spawns(world_id_name)


## 载入指定世界的生成数据并构建空间网格索引 (严格读取 assets/tbl/ 官方刷新总表)
func load_world_spawns(world_name: String) -> void:
	world_id_name = world_name
	_clear_all_instances()
	_mob_cells.clear()
	_npc_cells.clear()

	# 1. 从 assets/tbl 载入怪物刷新表 (如 spawn_mob_main_world.json)
	var mob_path := "res://assets/tbl/spawn_mob_%s.json" % world_name
	if FileAccess.file_exists(mob_path):
		var file := FileAccess.open(mob_path, FileAccess.READ)
		if file:
			var mob_list = JSON.parse_string(file.get_as_text())
			if mob_list is Array:
				for entry in mob_list:
					var loc: Dictionary = entry.get("spawn_loc", {})
					var sx: float = float(loc.get("x", 0.0))
					var sz: float = float(loc.get("z", 0.0))
					var cell := _get_cell_coord(sx, sz)
					if not _mob_cells.has(cell):
						_mob_cells[cell] = []
					_mob_cells[cell].append(entry)

	# 2. 从 assets/tbl 载入 NPC 刷新表 (如 spawn_npc_main_world.json)
	var npc_path := "res://assets/tbl/spawn_npc_%s.json" % world_name
	if FileAccess.file_exists(npc_path):
		var file := FileAccess.open(npc_path, FileAccess.READ)
		if file:
			var npc_list = JSON.parse_string(file.get_as_text())
			if npc_list is Array:
				for entry in npc_list:
					var loc: Dictionary = entry.get("spawn_loc", {})
					var sx: float = float(loc.get("x", 0.0))
					var sz: float = float(loc.get("z", 0.0))
					var cell := _get_cell_coord(sx, sz)
					if not _npc_cells.has(cell):
						_npc_cells[cell] = []
					_npc_cells[cell].append(entry)

	_is_initialized = true


func _process(delta: float) -> void:
	if not _is_initialized:
		return

	if follow_target == null or not is_instance_valid(follow_target):
		var player = get_tree().get_first_node_in_group("players")
		if player and is_instance_valid(player):
			follow_target = player
		else:
			return

	_check_timer += delta
	if _check_timer >= CHECK_INTERVAL:
		_check_timer = 0.0
		_update_streaming()


func _update_streaming() -> void:
	var p_pos: Vector3 = follow_target.global_position
	var p_cell := _get_cell_coord(p_pos.x, p_pos.z)
	var now := Time.get_ticks_msec() / 1000.0

	# 遍历以玩家为中心的 3x3 空间网格
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var cell := Vector2i(p_cell.x + dx, p_cell.y + dz)
			_stream_mobs_in_cell(cell, p_pos, now)
			_stream_npcs_in_cell(cell, p_pos)

	# 剔除离开视距的远距离实体
	_cull_distant_entities(_active_mobs, DESPAWN_RADIUS, p_pos)
	_cull_distant_entities(_active_npcs, DESPAWN_RADIUS, p_pos)


func _stream_mobs_in_cell(cell: Vector2i, p_pos: Vector3, now: float) -> void:
	if not _mob_cells.has(cell):
		return

	for entry in _mob_cells[cell]:
		var spawn_idx: int = int(entry.get("tblidx", 0))
		if _active_mobs.has(spawn_idx):
			continue

		# 检查是否处于击杀冷却状态 (OpenDBO spawn_cool_time)
		if _respawn_cooldowns.has(spawn_idx):
			if now < _respawn_cooldowns[spawn_idx]:
				continue
			else:
				_respawn_cooldowns.erase(spawn_idx)

		var loc: Dictionary = entry.get("spawn_loc", {})
		var pos := Vector3(float(loc.get("x", 0.0)), float(loc.get("y", 0.0)), float(loc.get("z", 0.0)))
		var dist_sq := p_pos.distance_squared_to(pos)
		if dist_sq <= SPAWN_RADIUS * SPAWN_RADIUS:
			_spawn_mob_instance(entry, pos, spawn_idx)


func _stream_npcs_in_cell(cell: Vector2i, p_pos: Vector3) -> void:
	if not _npc_cells.has(cell):
		return

	for entry in _npc_cells[cell]:
		var spawn_idx: int = int(entry.get("tblidx", 0))
		if _active_npcs.has(spawn_idx):
			continue

		var loc: Dictionary = entry.get("spawn_loc", {})
		var pos := Vector3(float(loc.get("x", 0.0)), float(loc.get("y", 0.0)), float(loc.get("z", 0.0)))
		var dist_sq := p_pos.distance_squared_to(pos)
		if dist_sq <= SPAWN_RADIUS * SPAWN_RADIUS:
			_spawn_npc_instance(entry, pos, spawn_idx)


func _spawn_mob_instance(entry: Dictionary, pos: Vector3, spawn_idx: int) -> void:
	var mob_tblidx: int = int(entry.get("mob_tblidx", 0))
	var mob_node := DBOMobEntity3D.new()
	mob_node.name = "Mob_%d_%d" % [mob_tblidx, spawn_idx]
	mob_node.mob_tblidx = mob_tblidx
	mob_node.patrol_radius = float(entry.get("wander_range", 10.0))

	add_child(mob_node)
	mob_node.global_position = pos

	var dir: Dictionary = entry.get("spawn_dir", {})
	var dir_x: float = float(dir.get("x", 0.0))
	var dir_z: float = float(dir.get("z", 0.0))
	if abs(dir_x) > 0.001 or abs(dir_z) > 0.001:
		mob_node.rotation.y = atan2(dir_x, dir_z)

	mob_node.died.connect(func(_killer):
		var cool_time: float = float(entry.get("spawn_cool_time", 15.0))
		var now := Time.get_ticks_msec() / 1000.0
		_respawn_cooldowns[spawn_idx] = now + maxf(5.0, cool_time)
		_active_mobs.erase(spawn_idx)
	)

	_active_mobs[spawn_idx] = mob_node


func _spawn_npc_instance(entry: Dictionary, pos: Vector3, spawn_idx: int) -> void:
	var npc_tblidx: int = int(entry.get("mob_tblidx", 0))
	var npc_node := DBONpcEntity3D.new()
	npc_node.name = "NPC_%d_%d" % [npc_tblidx, spawn_idx]
	npc_node.npc_tblidx = npc_tblidx

	add_child(npc_node)
	npc_node.global_position = pos

	var dir: Dictionary = entry.get("spawn_dir", {})
	var dir_x: float = float(dir.get("x", 0.0))
	var dir_z: float = float(dir.get("z", 0.0))
	if abs(dir_x) > 0.001 or abs(dir_z) > 0.001:
		npc_node.rotation.y = atan2(dir_x, dir_z)

	_active_npcs[spawn_idx] = npc_node


func _cull_distant_entities(dict: Dictionary, max_dist: float, p_pos: Vector3) -> void:
	var max_sq := max_dist * max_dist
	var to_remove: Array = []
	for spawn_idx in dict:
		var node: Node3D = dict[spawn_idx]
		if not is_instance_valid(node):
			to_remove.append(spawn_idx)
		elif node.global_position.distance_squared_to(p_pos) > max_sq:
			node.queue_free()
			to_remove.append(spawn_idx)

	for spawn_idx in to_remove:
		dict.erase(spawn_idx)


func _clear_all_instances() -> void:
	for k in _active_mobs:
		if is_instance_valid(_active_mobs[k]):
			_active_mobs[k].queue_free()
	_active_mobs.clear()

	for k in _active_npcs:
		if is_instance_valid(_active_npcs[k]):
			_active_npcs[k].queue_free()
	_active_npcs.clear()


func _get_cell_coord(x: float, z: float) -> Vector2i:
	return Vector2i(int(floor(x / CELL_SIZE)), int(floor(z / CELL_SIZE)))
