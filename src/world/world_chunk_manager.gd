class_name WorldChunkManager
extends Node3D

## World Chunk Manager (Dragon Ball Online Dynamic Streaming)
## 对标 OpenDBO-Core: DboClient/Lib/NtlPresentation/NtlWorldSectorPVS.cpp & DboServer/Server/GameServer/WorldManager.cpp
## 负责大世界九宫格流式区块管理与性能调度。
## 动态载入 data/terrain/ 高程数据，编译地表物理网格，并自动实例化大世界 4,504 个独立建筑/树木物件。

signal chunk_loaded(chunk_coord: Vector2i)
signal chunk_unloaded(chunk_coord: Vector2i)

@export var zone_name: String = "start_001"
@export var chunk_size: float = 256.0  # DBO 单个 Field 默认网格跨度为 64 * 4.0 = 256 米
@export var view_distance_chunks: int = 1  # 1 = 3x3 九宫格, 2 = 5x5
@export var target_follow_node: Node3D = null

# 当前活跃的区块: Vector2i -> Node3D
var _active_chunks: Dictionary = {}
var _current_center_chunk: Vector2i = Vector2i(-9999, -9999)
var _prop_manager: WorldPropManager = null


func _ready() -> void:
	_prop_manager = find_child("WorldPropManager", true, false) as WorldPropManager
	if _prop_manager == null:
		_prop_manager = WorldPropManager.new()
		_prop_manager.name = "WorldPropManager"
		add_child(_prop_manager)


func _process(_delta: float) -> void:
	if target_follow_node == null:
		return

	var current_pos := target_follow_node.global_position
	var current_chunk := world_pos_to_chunk_coord(current_pos)

	if current_chunk != _current_center_chunk:
		_current_center_chunk = current_chunk
		_update_chunks(current_chunk)


## 世界三维空间坐标转换为区块网格索引 (严格对标 OpenDBO: 地图世界坐标原点为中心, 边界起始为 -1024m)
func world_pos_to_chunk_coord(pos: Vector3) -> Vector2i:
	return Vector2i(
		clampi(int(floor((pos.x + 1024.0) / chunk_size)), 0, 7),
		clampi(int(floor((pos.z + 1024.0) / chunk_size)), 0, 7)
	)


## 强制刷新加载指定中心坐标区块
func force_load_zone(new_zone: String, center_coord: Vector2i = Vector2i.ZERO) -> void:
	zone_name = new_zone
	_clear_all_chunks()
	_current_center_chunk = center_coord
	_update_chunks(center_coord)


## 刷新活跃区块
func _update_chunks(center: Vector2i) -> void:
	var required_coords: Dictionary = {}

	for x in range(center.x - view_distance_chunks, center.x + view_distance_chunks + 1):
		for y in range(center.y - view_distance_chunks, center.y + view_distance_chunks + 1):
			if x < 0 or x > 7 or y < 0 or y > 7:
				continue
			var coord := Vector2i(x, y)
			required_coords[coord] = true
			if not _active_chunks.has(coord):
				_load_chunk(coord)

	# 卸载离开视距的区块
	var to_remove: Array[Vector2i] = []
	for coord in _active_chunks.keys():
		if not required_coords.has(coord):
			to_remove.append(coord)

	for coord in to_remove:
		_unload_chunk(coord)


func _load_chunk(coord: Vector2i) -> void:
	var json_path := "res://data/terrain/%s_chunks/chunk_%d_%d.json" % [zone_name, coord.x, coord.y]
	if not FileAccess.file_exists(json_path):
		return

	var file := FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		return

	var json_str := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_str) != OK:
		return

	var chunk_data: Dictionary = json.data

	var chunk_root := Node3D.new()
	chunk_root.name = "Chunk_%s_%d_%d" % [zone_name, coord.x, coord.y]
	add_child(chunk_root)

	# 1. 生成 3D 地形高度网格与物理碰撞体
	var terrain_mesh := WorldTerrainMeshBuilder.build_terrain_chunk_mesh(chunk_data)
	if terrain_mesh:
		chunk_root.add_child(terrain_mesh)

	# 2. 批量实例化大世界场景物件 (房屋、树木、城堡、障碍物)
	var props: Array = chunk_data.get("props", [])
	for p in props:
		if p is Dictionary:
			var model_name: String = p.get("model", "")
			if model_name.is_empty() or model_name.to_upper().begins_with("COLLISION"):
				continue
			 #创角/选角大厅 (select_character) 仅过滤新手教程大地图独立巨型地面网格 (D0_TUTORIAL_001)，保留远景山体山峦看板 (D0_TUTORIAL_002)
			if zone_name == "select_character" and model_name.to_upper() == "D0_TUTORIAL_001":
				continue

			var pos_arr: Array = p.get("pos", [0.0, 0.0, 0.0])
			var rot_arr: Array = p.get("rot", [0.0, 0.0, 0.0])
			var scl_arr: Array = p.get("scale", [1.0, 1.0, 1.0])

			var t := Transform3D()
			if scl_arr.size() == 3:
				t = t.scaled(Vector3(float(scl_arr[0]), float(scl_arr[1]), float(scl_arr[2])))
			if rot_arr.size() == 3:
				var rx := deg_to_rad(float(rot_arr[0]))
				var ry := deg_to_rad(float(rot_arr[1]))
				var rz := deg_to_rad(float(rot_arr[2]))
				var rot_basis := Basis.from_euler(Vector3(rx, ry, rz))
				t.basis = rot_basis * t.basis
			if pos_arr.size() == 3:
				t.origin = Vector3(float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]))

			_prop_manager.spawn_world_prop(model_name, t, chunk_root)

	_active_chunks[coord] = chunk_root
	chunk_loaded.emit(coord)


func _unload_chunk(coord: Vector2i) -> void:
	if _active_chunks.has(coord):
		var chunk_node: Node3D = _active_chunks[coord]
		chunk_node.queue_free()
		_active_chunks.erase(coord)
		chunk_unloaded.emit(coord)


func _clear_all_chunks() -> void:
	for coord in _active_chunks.keys():
		var chunk_node: Node3D = _active_chunks[coord]
		chunk_node.queue_free()
	_active_chunks.clear()


func get_active_chunk_count() -> int:
	return _active_chunks.size()
