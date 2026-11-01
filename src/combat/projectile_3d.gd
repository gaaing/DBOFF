class_name DBOProjectile3D
extends Area3D

## DBO Projectile 3D (Energy Blast / Ki Wave / Hissidan / Beam)
## 100% 严格对标 OpenDBO-Core 投射物系统：
##   - DboClient/Lib/NtlSimulation/NtlSobProjectile.cpp & NtlSobProjectile.h
##   - characterproperty.json 中的 uiProjectileEffectType：
##     2000: BEID_PROJ_BALL (普通气功弹)
##     2001: BEID_PROJ_BEAM (龟派气功/魔贯光杀炮持续光束)
##     2002: BEID_PROJ_HISSIDAN (操气弹/曲线跟踪弹)
##     2003: BEID_PROJ_HELLZONE (魔空包围弹)
##     2004: BEID_PROJ_MULTI_HISSIDAN (多重连环气功弹)

signal hit_target(target: Node3D, hit_pos: Vector3)

@export var speed: float = 32.0
@export var max_lifetime: float = 5.0
@export var projectile_type: int = 2000

var target_node: Node3D = null
var attacker_node: DBOCharacterBase3D = null
var hit_event_data: Dictionary = {}

var _current_lifetime: float = 0.0
var _direction: Vector3 = Vector3.FORWARD
var _core_mesh_inst: MeshInstance3D = null
var _flight_light: OmniLight3D = null


func _ready() -> void:
	# 配置碰撞检测层 (层 1: 地形, 层 2: 玩家, 层 3: 怪物)
	collision_layer = 0
	collision_mask = 1 | 2 | 4
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_build_projectile_visuals()


func _build_projectile_visuals() -> void:
	# 1. 物理碰撞体胶囊/球体
	var col_shape := find_child("CollisionShape3D", true, false) as CollisionShape3D
	if col_shape == null:
		col_shape = CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 0.35
		col_shape.shape = sphere
		add_child(col_shape)

	# 2. 核心高能光球网格 (Glowing Energy Core)
	_core_mesh_inst = MeshInstance3D.new()
	_core_mesh_inst.name = "EnergySphereCore"
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.32
	sphere_mesh.height = 0.64
	_core_mesh_inst.mesh = sphere_mesh

	var mat := StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = StandardMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = StandardMaterial3D.CULL_DISABLED
	var ki_color := Color(1.0, 0.92, 0.35, 1.0)
	if projectile_type == 2001:
		ki_color = Color(0.25, 0.75, 1.0, 1.0) # 龟派气功水蓝
	elif projectile_type == 2002:
		ki_color = Color(1.0, 0.45, 0.15, 1.0) # 操气弹金橙
	mat.albedo_color = ki_color
	_core_mesh_inst.material_override = mat
	add_child(_core_mesh_inst)

	# 3. 飞行伴随动态点光源 (Dynamic Flight Light)
	_flight_light = OmniLight3D.new()
	_flight_light.light_color = ki_color
	_flight_light.light_energy = 2.0
	_flight_light.omni_range = 5.0
	add_child(_flight_light)


func init_projectile(attacker: DBOCharacterBase3D, target: Node3D, event_data: Dictionary) -> void:
	attacker_node = attacker
	target_node = target
	hit_event_data = event_data

	projectile_type = event_data.get("projectile_effect_type", 2000)
	var cfg_speed: float = event_data.get("projectile_speed", 0.0)
	if cfg_speed > 0.0:
		speed = cfg_speed

	if target_node:
		var target_center := target_node.global_position + Vector3.UP * 1.0
		_direction = (target_center - global_position).normalized()
	else:
		_direction = -global_transform.basis.z

	# 播放气功出膛音效
	if is_instance_valid(AudioManager):
		AudioManager.play_sfx_3d("assets/sound/skill/se_ki_blast_fire.wav", global_position, 25.0)


func _physics_process(delta: float) -> void:
	_current_lifetime += delta
	if _current_lifetime >= max_lifetime:
		_destroy_with_fade()
		return

	# 操气弹 / 曲线跟踪弹道 (BEID_PROJ_HISSIDAN: 8.0 弧度/秒平滑跟踪)
	if projectile_type == 2002 and is_instance_valid(target_node):
		var target_center := target_node.global_position + Vector3.UP * 1.0
		var to_target := (target_center - global_position).normalized()
		_direction = _direction.slerp(to_target, 9.0 * delta)

	global_position += _direction * speed * delta

	# 朝向飞行矢量
	if _direction.length_squared() > 0.001:
		look_at(global_position + _direction, Vector3.UP)


func _on_body_entered(body: Node3D) -> void:
	if body == attacker_node or body == self:
		return

	_handle_collision(body)


func _on_area_entered(area: Area3D) -> void:
	if area == self or area.get_parent() == attacker_node:
		return
	# 碰撞判定
	var parent_char := area.get_parent() as DBOCharacterBase3D
	if parent_char and parent_char != attacker_node:
		_handle_collision(parent_char)


func _handle_collision(hit_collider: Node3D) -> void:
	var hit_pos := global_position

	# 触发爆裂特效
	if is_instance_valid(DBOEffectManager):
		DBOEffectManager.spawn_projectile_impact(hit_pos, true)

	if is_instance_valid(AudioManager):
		AudioManager.play_sfx_3d("assets/sound/skill/se_ki_blast_hit.wav", hit_pos, 25.0)

	# 若命中角色实体，执行伤害打击结算
	if hit_collider is DBOCharacterBase3D:
		var defender := hit_collider as DBOCharacterBase3D
		DBOCombatEngine.calculate_attack(attacker_node, defender, hit_event_data)
		hit_target.emit(defender, hit_pos)
	else:
		hit_target.emit(hit_collider, hit_pos)

	queue_free()


func _destroy_with_fade() -> void:
	if is_instance_valid(DBOEffectManager):
		DBOEffectManager.spawn_projectile_impact(global_position, false)
	queue_free()
