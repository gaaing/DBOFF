extends Node3D

## DBO Combat Text Manager (3D Floating Combat Billboards & Number Art)
## 100% 严格对标 OpenDBO-Core 官方规范与正统美术资产：
##   - DboClient/Lib/NtlPresentation/NtlPLDamageBox.cpp (CNtlPLDamageBox)
##   - DboClient/Lib/NtlSimulation/NtlFSMCharActEventProc.cpp
##   - DboClient/Lib/NtlSimulation/NtlSLVisualDeclear.h (NTL_VID_TEXT_*)
##
## 核心特性：
## 1. 杜绝硬编码与 Label3D 仿制字体：全部使用官方专用位图贴图渲染
##    - 伤害数字: pc_0.png~pc_9.png (玩家输出黄色字), mob_0.png~mob_9.png (怪物伤害红白字)
##    - 恢复数字: pcheal_0.png~pcheal_9.png (玩家生命/气力绿色字), mobheal_0.png~mobheal_9.png
##    - 战术判定: text_critical.png, text_block.png, text_miss.png, text_knockdown.png,
##               mob_immunity.png, text_resistance.png, text_counter_attack.png
## 2. 3D 看板 (Billboard) 投射：朝向摄像机，支持向上运动衰减、脉冲缩放与透明度渐隐。

enum DamageColorType {
	PC = 0,       # 玩家打出伤害 (黄色美术字)
	MOB = 1,      # 怪物打出伤害 (红白美术字)
	PC_HEAL = 2,  # 玩家恢复 (绿色美术字)
	MOB_HEAL = 3  # 怪物恢复 (绿色美术字)
}

const TEXTURE_DIR := "res://assets/tex/texture/effect/text/"

# 贴图缓存表
var _digits_cache: Dictionary = {}
var _banner_cache: Dictionary = {}
var _initialized: bool = false


func _init_textures() -> void:
	if _initialized:
		return
	_initialized = true

	# 加载数字贴图 (0~9)
	var type_prefixes := {
		DamageColorType.PC: "pc_",
		DamageColorType.MOB: "mob_",
		DamageColorType.PC_HEAL: "pcheal_",
		DamageColorType.MOB_HEAL: "mobheal_"
	}

	for ctype in type_prefixes:
		var prefix: String = type_prefixes[ctype]
		_digits_cache[ctype] = []
		for i in range(10):
			var tex_path := "%s%s%d.png" % [TEXTURE_DIR, prefix, i]
			var tex: Texture2D = (ResourceLoader.load(tex_path) as Texture2D) if ResourceLoader.exists(tex_path) else null
			_digits_cache[ctype].append(tex)

	# 加载判定标识贴图
	var banner_files := {
		"critical": "text_critical.png",
		"block": "text_block.png",
		"miss": "text_miss.png",
		"dodge": "text_miss.png",
		"knockdown": "text_knockdown.png",
		"immunity": "mob_immunity.png",
		"resistance": "text_resistance.png",
		"counter": "text_counter_attack.png"
	}

	for key: String in banner_files:
		var bfile: String = str(banner_files[key])
		var bpath: String = TEXTURE_DIR + bfile
		if ResourceLoader.exists(bpath):
			_banner_cache[key] = ResourceLoader.load(bpath)


func _ready() -> void:
	_init_textures()


## 快捷接口：生成伤害跳字与判定标识
func spawn_damage(world_pos: Vector3, damage: int, is_critical: bool = false, is_blocked: bool = false, is_mob_source: bool = false) -> Node3D:
	_init_textures()
	var color_type := DamageColorType.MOB if is_mob_source else DamageColorType.PC

	var container := Node3D.new()
	container.name = "CombatDamage_%d" % damage
	# 水平微小散布，防止多段连击重合
	var jitter := Vector3(randf_range(-0.3, 0.3), 1.6, randf_range(-0.3, 0.3))
	container.global_position = world_pos + jitter

	add_child(container)

	var sprites_to_fade: Array[Sprite3D] = []

	# 1. 暴击或格挡横幅 (置于数字正上方)
	if is_critical and _banner_cache.has("critical"):
		var crit_spr := _create_banner_sprite(_banner_cache["critical"], Vector3(0.0, 0.55, 0.0), 1.1)
		container.add_child(crit_spr)
		sprites_to_fade.append(crit_spr)
	elif is_blocked and _banner_cache.has("block"):
		var block_spr := _create_banner_sprite(_banner_cache["block"], Vector3(0.0, 0.5, 0.0), 1.0)
		container.add_child(block_spr)
		sprites_to_fade.append(block_spr)

	# 2. 数字贴图串联拼装
	var digit_sprites := _build_digit_sprites(damage, color_type)
	for d_spr in digit_sprites:
		container.add_child(d_spr)
		sprites_to_fade.append(d_spr)

	# 3. 动画：冲量缩放、上升与淡出销毁 (对标 NtlPLDamageBox.cpp)
	_play_combat_animation(container, sprites_to_fade, is_critical)
	return container


## 快捷接口：生成治疗跳字
func spawn_heal(world_pos: Vector3, amount: int, is_mob: bool = false) -> Node3D:
	_init_textures()
	var color_type := DamageColorType.MOB_HEAL if is_mob else DamageColorType.PC_HEAL

	var container := Node3D.new()
	container.name = "CombatHeal_%d" % amount
	var jitter := Vector3(randf_range(-0.25, 0.25), 1.6, randf_range(-0.25, 0.25))
	container.global_position = world_pos + jitter

	add_child(container)

	var sprites_to_fade: Array[Sprite3D] = []
	var digit_sprites := _build_digit_sprites(amount, color_type)
	for d_spr in digit_sprites:
		container.add_child(d_spr)
		sprites_to_fade.append(d_spr)

	_play_combat_animation(container, sprites_to_fade, false)
	return container


## 快捷接口：未命中 (Miss)
func spawn_miss(world_pos: Vector3) -> Node3D:
	return _spawn_single_banner(world_pos, "miss")


## 快捷接口：闪避 (Dodge)
func spawn_dodge(world_pos: Vector3) -> Node3D:
	return _spawn_single_banner(world_pos, "dodge")


## 快捷接口：击倒 (Knockdown)
func spawn_knockdown(world_pos: Vector3) -> Node3D:
	return _spawn_single_banner(world_pos, "knockdown")


## 快捷接口：免疫 (Immunity)
func spawn_immunity(world_pos: Vector3) -> Node3D:
	return _spawn_single_banner(world_pos, "immunity")


## 快捷接口：抗性防御 (Resistance)
func spawn_resistance(world_pos: Vector3) -> Node3D:
	return _spawn_single_banner(world_pos, "resistance")


## 快捷接口：绝地反击 (Counter Attack)
func spawn_counter(world_pos: Vector3) -> Node3D:
	return _spawn_single_banner(world_pos, "counter")


# ------------------------------------------------------------------------------
# 内部装配逻辑
# ------------------------------------------------------------------------------

func _spawn_single_banner(world_pos: Vector3, banner_key: String) -> Node3D:
	_init_textures()
	if not _banner_cache.has(banner_key):
		return null

	var container := Node3D.new()
	container.name = "CombatBanner_%s" % banner_key
	container.global_position = world_pos + Vector3(0.0, 1.6, 0.0)

	add_child(container)

	var spr := _create_banner_sprite(_banner_cache[banner_key], Vector3.ZERO, 1.1)
	container.add_child(spr)

	var list: Array[Sprite3D] = [spr]
	_play_combat_animation(container, list, false)
	return container


func _create_banner_sprite(tex: Texture2D, offset: Vector3, scale_mult: float = 1.0) -> Sprite3D:
	var spr := Sprite3D.new()
	spr.texture = tex
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.no_depth_test = true
	spr.render_priority = 32
	spr.pixel_size = 0.007 * scale_mult
	spr.position = offset
	return spr


func _build_digit_sprites(value: int, color_type: int) -> Array[Sprite3D]:
	var result: Array[Sprite3D] = []
	var tex_list: Array = _digits_cache.get(color_type, [])
	if tex_list.is_empty():
		return result

	var val_str := str(absi(value))
	var count := val_str.length()
	var digit_spacing := 0.22 # 相邻数字间距 (米)
	var start_x := -float(count - 1) * 0.5 * digit_spacing

	for i in range(count):
		var char_code := val_str.unicode_at(i) - 48 # '0' -> 0
		if char_code < 0 or char_code >= tex_list.size():
			continue

		var tex: Texture2D = tex_list[char_code]
		if tex == null:
			continue

		var spr := Sprite3D.new()
		spr.texture = tex
		spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		spr.no_depth_test = true
		spr.render_priority = 30
		spr.pixel_size = 0.009
		spr.position = Vector3(start_x + i * digit_spacing, 0.0, 0.0)
		result.append(spr)

	return result


func _play_combat_animation(container: Node3D, sprites: Array[Sprite3D], is_crit: bool) -> void:
	var base_scale := Vector3(1.3, 1.3, 1.3) if is_crit else Vector3.ONE
	container.scale = base_scale * 0.45

	var tween := container.create_tween().set_parallel(true)
	# 1. 缩放冲击脉冲 (Punch scale)
	tween.tween_property(container, "scale", base_scale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 2. 匀速抛射上浮 (对标 NTL_DAMAGEBOX_MOVE_SPEED)
	var target_y: float = container.position.y + (1.6 if is_crit else 1.2)
	tween.tween_property(container, "position:y", target_y, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. 后半段全精灵平滑渐隐 (对标 CNtlPLDamageBox alpha 衰减)
	for spr in sprites:
		tween.tween_property(spr, "modulate:a", 0.0, 0.35).set_delay(0.5)

	# 4. 销毁
	tween.chain().tween_callback(container.queue_free)
