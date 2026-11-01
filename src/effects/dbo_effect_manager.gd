extends Node3D

## DBO Effect Manager (Particle & VFX Pipeline)
## 100% 严格对标 OpenDBO-Core 特效与粒子管线：
##   - DboClient/Lib/NtlPresentation/NtlResourceEffect.h & NtlResourceParticleSystem.h
##   - DboClient/Lib/NtlPresentation/NtlEffectAPI.h & NtlInstanceParticleSystem.cpp
##   - DboClient/Lib/NtlPresentation/NtlPLLinkEffect.cpp
##
## 管理全局打击火花、聚气气焰 (Ki Aura)、冲击波光环、投射物撞击爆炸与受击光照。

const TEX_HIT_SPARK: String = "res://assets/tex/texture/effect/hit03.png"
const TEX_HIT_RING: String = "res://assets/tex/texture/effect/ik_hit_ring_02.png"
const TEX_AURA_FIRE: String = "res://assets/tex/texture/effect/ik_fire_01_01_y.png"
const TEX_SMOKE: String = "res://assets/tex/texture/effect/smoke_01.png"
const TEX_FLASH: String = "res://assets/tex/texture/effect/flash_01.png"

var _active_auras: Dictionary = {} # character_instance_id -> aura_node


## 1. 生成物理/近战/能量受击火花与冲击波 (对标 NtlEffectAPI: PlayHitEffect)
func spawn_hit_spark(pos: Vector3, _normal: Vector3 = Vector3.UP, is_critical: bool = false, is_blocked: bool = false) -> void:
	var effect_root := Node3D.new()
	effect_root.name = "HitSparkEffect"
	effect_root.global_position = pos
	add_child(effect_root)

	# 1. 冲击波光环看板 (Expanding Shockwave Ring)
	var ring_sprite := Sprite3D.new()
	ring_sprite.name = "ShockwaveRing"
	ring_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ring_sprite.no_depth_test = true
	ring_sprite.render_priority = 25

	var ring_mat := StandardMaterial3D.new()
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if ResourceLoader.exists(TEX_HIT_RING):
		ring_mat.albedo_texture = ResourceLoader.load(TEX_HIT_RING) as Texture2D
	ring_sprite.material_override = ring_mat

	var spark_color := Color(1.0, 0.85, 0.3, 1.0) # 默认暖金黄
	if is_critical:
		spark_color = Color(1.0, 0.25, 0.15, 1.0) # 暴击猩红
	elif is_blocked:
		spark_color = Color(0.3, 0.8, 1.0, 1.0)  # 格挡冰蓝

	ring_sprite.modulate = spark_color
	ring_sprite.scale = Vector3.ONE * (0.3 if not is_critical else 0.5)
	effect_root.add_child(ring_sprite)

	# 2. 核心闪光精灵 (Flash Core)
	var flash_sprite := Sprite3D.new()
	flash_sprite.name = "FlashCore"
	flash_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	flash_sprite.no_depth_test = true
	flash_sprite.render_priority = 26

	var flash_mat := StandardMaterial3D.new()
	flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if ResourceLoader.exists(TEX_HIT_SPARK):
		flash_mat.albedo_texture = ResourceLoader.load(TEX_HIT_SPARK) as Texture2D
	flash_sprite.material_override = flash_mat
	flash_sprite.modulate = spark_color * 1.5
	flash_sprite.scale = Vector3.ONE * (0.8 if not is_critical else 1.4)
	effect_root.add_child(flash_sprite)

	# 3. 极速动态微光照亮角色网格
	var light := OmniLight3D.new()
	light.light_color = spark_color
	light.light_energy = 2.5 if not is_critical else 5.0
	light.omni_range = 4.0
	effect_root.add_child(light)

	# 4. 动效 Tween 调度 (0.2 秒极速爆发消散)
	var tween := create_tween().set_parallel(true)
	var target_ring_scale := Vector3.ONE * (1.8 if not is_critical else 2.8)
	tween.tween_property(ring_sprite, "scale", target_ring_scale, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring_sprite, "modulate:a", 0.0, 0.18)

	tween.tween_property(flash_sprite, "scale", Vector3.ZERO, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(flash_sprite, "modulate:a", 0.0, 0.14)
	tween.tween_property(light, "light_energy", 0.0, 0.15)

	tween.chain().tween_callback(effect_root.queue_free)


## 2. 启动角色聚气气焰 (Ki Aura)
func start_ki_aura(character: Node3D, aura_color: Color = Color(1.0, 0.82, 0.2)) -> Node3D:
	if character == null:
		return null
	var c_id := character.get_instance_id()
	if _active_auras.has(c_id):
		return _active_auras[c_id]

	var aura_root := Node3D.new()
	aura_root.name = "KiAuraEffect"
	character.add_child(aura_root)
	aura_root.position = Vector3(0.0, 0.1, 0.0)

	# 地表扩展能量光环 (Ground Pulsing Ring)
	var ground_ring := Sprite3D.new()
	ground_ring.name = "GroundAuraRing"
	ground_ring.axis = Vector3.AXIS_Y
	ground_ring.render_priority = 10
	var ring_mat := StandardMaterial3D.new()
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if ResourceLoader.exists(TEX_HIT_RING):
		ring_mat.albedo_texture = ResourceLoader.load(TEX_HIT_RING) as Texture2D
	ground_ring.material_override = ring_mat
	ground_ring.modulate = aura_color
	ground_ring.scale = Vector3.ONE * 1.6
	aura_root.add_child(ground_ring)

	# 升腾能量气焰精灵 (Vertical Energy Flame)
	var flame_sprite := Sprite3D.new()
	flame_sprite.name = "VerticalAuraFlame"
	flame_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	flame_sprite.render_priority = 12
	flame_sprite.position = Vector3(0.0, 0.8, 0.0)
	var flame_mat := StandardMaterial3D.new()
	flame_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flame_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if ResourceLoader.exists(TEX_AURA_FIRE):
		flame_mat.albedo_texture = ResourceLoader.load(TEX_AURA_FIRE) as Texture2D
	flame_sprite.material_override = flame_mat
	flame_sprite.modulate = aura_color * 1.3
	flame_sprite.scale = Vector3(1.4, 2.2, 1.4)
	aura_root.add_child(flame_sprite)

	# 动态脉冲聚气光源
	var aura_light := OmniLight3D.new()
	aura_light.name = "AuraLight"
	aura_light.light_color = aura_color
	aura_light.light_energy = 2.0
	aura_light.omni_range = 5.0
	aura_light.position = Vector3(0.0, 0.5, 0.0)
	aura_root.add_child(aura_light)

	# 循环微脉冲 Tween
	var loop_tween := aura_root.create_tween().set_loops()
	loop_tween.tween_property(flame_sprite, "scale", Vector3(1.6, 2.4, 1.6), 0.35).set_trans(Tween.TRANS_SINE)
	loop_tween.parallel().tween_property(ground_ring, "scale", Vector3.ONE * 2.0, 0.35).set_trans(Tween.TRANS_SINE)
	loop_tween.parallel().tween_property(aura_light, "light_energy", 3.2, 0.35)

	loop_tween.tween_property(flame_sprite, "scale", Vector3(1.3, 2.0, 1.3), 0.35).set_trans(Tween.TRANS_SINE)
	loop_tween.parallel().tween_property(ground_ring, "scale", Vector3.ONE * 1.5, 0.35).set_trans(Tween.TRANS_SINE)
	loop_tween.parallel().tween_property(aura_light, "light_energy", 1.8, 0.35)

	_active_auras[c_id] = aura_root
	return aura_root


## 3. 停止角色聚气气焰
func stop_ki_aura(character: Node3D) -> void:
	if character == null:
		return
	var c_id := character.get_instance_id()
	if not _active_auras.has(c_id):
		return

	var aura_root: Node3D = _active_auras[c_id]
	_active_auras.erase(c_id)

	if is_instance_valid(aura_root):
		var fade_tween := aura_root.create_tween().set_parallel(true)
		for child in aura_root.get_children():
			if child is Sprite3D:
				fade_tween.tween_property(child, "modulate:a", 0.0, 0.25)
			elif child is OmniLight3D:
				fade_tween.tween_property(child, "light_energy", 0.0, 0.25)
		fade_tween.chain().tween_callback(aura_root.queue_free)


## 4. 投射物能量爆裂 (Projectile Impact Burst)
func spawn_projectile_impact(pos: Vector3, _is_energy: bool = true) -> void:
	var impact_root := Node3D.new()
	impact_root.name = "ProjectileImpact"
	impact_root.global_position = pos
	add_child(impact_root)

	# 核心能量爆裂精灵
	var blast_sprite := Sprite3D.new()
	blast_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	blast_sprite.no_depth_test = true
	blast_sprite.render_priority = 28

	var blast_mat := StandardMaterial3D.new()
	blast_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blast_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	blast_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if ResourceLoader.exists(TEX_FLASH):
		blast_mat.albedo_texture = ResourceLoader.load(TEX_FLASH) as Texture2D
	blast_sprite.material_override = blast_mat
	blast_sprite.modulate = Color(1.0, 0.9, 0.4, 1.0)
	blast_sprite.scale = Vector3.ONE * 0.5
	impact_root.add_child(blast_sprite)

	# 尘烟扩散精灵 (Impact Smoke)
	var smoke_sprite := Sprite3D.new()
	smoke_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if ResourceLoader.exists(TEX_SMOKE):
		smoke_mat.albedo_texture = ResourceLoader.load(TEX_SMOKE) as Texture2D
	smoke_sprite.material_override = smoke_mat
	smoke_sprite.modulate = Color(0.8, 0.75, 0.7, 0.8)
	smoke_sprite.scale = Vector3.ONE * 0.4
	impact_root.add_child(smoke_sprite)

	# 光照爆发
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.9, 0.5)
	light.light_energy = 4.0
	light.omni_range = 6.0
	impact_root.add_child(light)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(blast_sprite, "scale", Vector3.ONE * 2.6, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(blast_sprite, "modulate:a", 0.0, 0.22)

	tween.tween_property(smoke_sprite, "scale", Vector3.ONE * 2.2, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(smoke_sprite, "modulate:a", 0.0, 0.45)

	tween.tween_property(light, "light_energy", 0.0, 0.25)
	tween.chain().tween_callback(impact_root.queue_free)
