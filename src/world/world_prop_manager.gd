class_name WorldPropManager
extends Node3D

## World Prop Manager (Dragon Ball Online Scene Object Manager)
## 负责大世界场景物件（建筑、树木、废墟、机关）的实例化与性能调度。
## 复用已转换的 4,504 个独立 GLB 资产，结合 objectproperty.json 动态配置 AABB 碰撞体与视距剔除。

const MESH_DIR := "res://assets/obj/object/mesh/"
const ANIM_DIR := "res://assets/obj/object/animation/"

# 网格资产内存缓存: clean_name -> PackedScene
var _mesh_cache: Dictionary = {}


## 在世界中生成单个场景物件
func spawn_world_prop(prop_name: String, transform_3d: Transform3D, parent_node: Node3D = null) -> Node3D:
	var clean_name := prop_name.to_lower().strip_edges()
	if clean_name.ends_with(".dff") or clean_name.ends_with(".glb"):
		clean_name = clean_name.get_basename()

	var scene := _load_prop_scene(clean_name)
	if scene == null:
		return null

	var prop_inst := scene.instantiate() as Node3D
	if prop_inst == null:
		return null

	prop_inst.name = "Prop_" + clean_name
	prop_inst.transform = transform_3d

	# 读取物体属性（碰撞、包围盒、剔除距离）
	var prop_cfg := DBOTableManager.get_object_property(clean_name.to_upper())
	if not prop_cfg.is_empty():
		_apply_prop_properties(prop_inst, prop_cfg)

	# 修正 RenderWare 贴图颠倒 UV
	DBOMaterialHelper.fix_node_materials(prop_inst)

	# 必须先将节点挂接进场景树，AnimationPlayer 才能正确激活并播放
	var target_parent := parent_node if parent_node else self
	target_parent.add_child(prop_inst)

	# 自动激活并循环播放场景物件动画（如机关运转、风车旋转、动态道具）
	# 对标 OpenDBO-Core: NtlPLObject.cpp: SetAnimation
	var anim_player := prop_inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player:
		var anim_list := anim_player.get_animation_list()
		if not anim_list.is_empty():
			var first_anim := anim_list[0]
			var anim := anim_player.get_animation(first_anim)
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
			anim_player.autoplay = first_anim
			anim_player.play(first_anim)
	else:
		# 若自身无内置动画播放器，检查 objectproperty.json 中官方指定的 anim_file 动画轨道
		var anim_file: String = prop_cfg.get("anim_file", "")
		if anim_file != "":
			var anim_clean := anim_file.get_file().get_basename().to_lower().strip_edges()
			var anim_glb_path := ANIM_DIR + anim_clean + ".glb"
			if ResourceLoader.exists(anim_glb_path):
				var anim_scene := ResourceLoader.load(anim_glb_path) as PackedScene
				if anim_scene:
					var anim_inst := anim_scene.instantiate() as Node3D
					if anim_inst:
						anim_inst.name = "AnimTrack_" + anim_clean
						prop_inst.add_child(anim_inst)
						var ext_player := anim_inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
						if ext_player:
							var ext_anim_list := ext_player.get_animation_list()
							if not ext_anim_list.is_empty():
								var ext_first_anim := ext_anim_list[0]
								var ext_anim := ext_player.get_animation(ext_first_anim)
								if ext_anim:
									ext_anim.loop_mode = Animation.LOOP_LINEAR
								ext_player.play(ext_first_anim)

	return prop_inst


## 根据 objectproperty.json 动态配置碰撞与剔除
func _apply_prop_properties(node: Node3D, prop_cfg: Dictionary) -> void:
	var cull_dist: float = prop_cfg.get("culling_distance", 0.0)
	var has_collision: bool = prop_cfg.get("collision", false)
	var bbox: Dictionary = prop_cfg.get("bbox", {})

	# 遍历 MeshInstance3D 设置视距裁切 (LOD / Visibility Range)
	if cull_dist > 0.0:
		for child in node.find_children("*", "MeshInstance3D", true, false):
			var mesh_inst := child as MeshInstance3D
			mesh_inst.visibility_range_end = cull_dist
			mesh_inst.visibility_range_end_margin = 10.0
			mesh_inst.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF

	# 如果原版定义有碰撞，则基于 BBox 动态添加 StaticBody3D 与 Jolt BoxShape3D
	if has_collision and not bbox.is_empty():
		var b_min: Array = bbox.get("min", [0, 0, 0])
		var b_max: Array = bbox.get("max", [0, 0, 0])
		if b_min.size() == 3 and b_max.size() == 3:
			var size := Vector3(absf(b_max[0] - b_min[0]), absf(b_max[1] - b_min[1]), absf(b_max[2] - b_min[2]))
			var center := Vector3((b_max[0] + b_min[0]) * 0.5, (b_max[1] + b_min[1]) * 0.5, (b_max[2] + b_min[2]) * 0.5)

			if size.x > 0.01 and size.y > 0.01 and size.z > 0.01:
				var static_body := StaticBody3D.new()
				static_body.name = "CollisionBody"
				var shape_node := CollisionShape3D.new()
				var box_shape := BoxShape3D.new()
				box_shape.size = size
				shape_node.shape = box_shape
				shape_node.position = center
				static_body.add_child(shape_node)
				node.add_child(static_body)


func _load_prop_scene(clean_name: String) -> PackedScene:
	if _mesh_cache.has(clean_name):
		return _mesh_cache[clean_name]

	# 必须优先加载实体网格模型库 (MESH_DIR) 确保 100% 具备 3D 几何与材质
	var mesh_path := MESH_DIR + clean_name + ".glb"
	if ResourceLoader.exists(mesh_path):
		var scene = ResourceLoader.load(mesh_path) as PackedScene
		if scene:
			_mesh_cache[clean_name] = scene
			return scene

	# 若 MESH_DIR 无该模型，尝试从 ANIM_DIR 加载
	var anim_path := ANIM_DIR + clean_name + ".glb"
	if ResourceLoader.exists(anim_path):
		var a_scene = ResourceLoader.load(anim_path) as PackedScene
		if a_scene:
			_mesh_cache[clean_name] = a_scene
			return a_scene

	return null
