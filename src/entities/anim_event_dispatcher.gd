class_name AnimEventDispatcher
extends Node

## DBO Animation Event Dispatcher
## 负责将 characterproperty.json 中解析出的动作时间轴事件，
## 在动画播放的精确毫秒帧通过定时调度派发给战斗系统与音频/特效系统。

signal hit_event_triggered(event_data: Dictionary)
signal foot_step_triggered(event_data: Dictionary)
signal visual_effect_triggered(event_data: Dictionary)
signal sound_triggered(event_data: Dictionary)
signal camera_shake_requested(factor: float, max_height: float)
signal projectile_spawn_requested(event_data: Dictionary)

var _active_tweens: Array[Tween] = []


func _exit_tree() -> void:
	_cancel_active_events()


## 当动画开始播放时调用，建立帧事件时间轴调度
func on_animation_played(character_name: String, anim_name: String) -> void:
	_cancel_active_events()

	if character_name.is_empty() or anim_name.is_empty():
		return

	var char_prop := DBOTableManager.get_character_property(character_name)
	if char_prop.is_empty():
		return

	var anim_table: Dictionary = char_prop.get("animation_table", {})
	var anims: Dictionary = anim_table.get("animations", {})

	# 匹配当前动画对应的事件列表
	var matched_events: Array = []
	for key in anims:
		var anim_entry: Dictionary = anims[key]
		var cfg_anim_name: String = anim_entry.get("anim_name", "")
		if cfg_anim_name.to_upper().get_basename() == anim_name.to_upper().get_basename() or cfg_anim_name.to_upper() == anim_name.to_upper():
			matched_events = anim_entry.get("events", [])
			break

	if matched_events.is_empty():
		return

	# 为每个事件创建延时触发调度
	for evt in matched_events:
		var trigger_time: float = evt.get("time", 0.0)
		var tween := create_tween()
		_active_tweens.append(tween)
		tween.tween_interval(maxf(trigger_time, 0.001))
		tween.tween_callback(_dispatch_single_event.bind(evt))


func _dispatch_single_event(event_data: Dictionary) -> void:
	var event_id: int = event_data.get("event_id", 0)

	match event_id:
		2:  # EVENT_ANIM_HIT
			hit_event_triggered.emit(event_data)
			if event_data.get("camera_shake", false):
				var factor: float = event_data.get("camera_shake_factor", 1.0)
				var max_h: float = event_data.get("camera_shake_max_height", 1.0)
				camera_shake_requested.emit(factor, max_h)

			var proj_type: int = event_data.get("projectile_effect_type", 0)
			if proj_type >= 2000:
				projectile_spawn_requested.emit(event_data)

		4:  # EVENT_ANIM_VISUAL_SOUND
			sound_triggered.emit(event_data)
			var snd1: String = event_data.get("sound_name1", "")
			if not snd1.is_empty() and is_instance_valid(AudioManager):
				var parent_node := get_parent() as Node3D
				if parent_node:
					AudioManager.play_sfx_3d(snd1, parent_node.global_position)

		5:  # EVENT_ANIM_FOOT_STEP
			foot_step_triggered.emit(event_data)

		3, 6:  # EVENT_ANIM_VISUAL_EFFECT / LINK_EFFECT
			visual_effect_triggered.emit(event_data)


func _cancel_active_events() -> void:
	for t in _active_tweens:
		if is_instance_valid(t):
			t.kill()
	_active_tweens.clear()
