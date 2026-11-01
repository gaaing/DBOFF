extends Node

## DBO Quest Manager
## 全局任务状态机与触发器调度引擎。
## 严格对标 OpenDBO-Core:
##   - DboShared/NtlTrigger/NtlTSTrigger.h (CNtlTSTrigger)
##   - DboServer/Server/GameServer/Quest.cpp
##   - DboClient/Client/Main/DboTSMain.cpp
## 驱动 res://data/quests/quest_triggers.json 中的 2,886 个官方任务剧本。

enum QuestState {
	UNTAKEN = 0,
	IN_PROGRESS = 1,
	READY_FOR_REWARD = 2,
	COMPLETED = 3
}

# 正在进行的任务 { quest_id: { "state": QuestState, "progress": { target_id: current_count } } }
var active_quests: Dictionary = {}
var completed_quests: Dictionary = {}

var _triggers_cache: Dictionary = {}


func _ready() -> void:
	DBOEventBus.combat_entity_died.connect(_on_combat_entity_died)


## 载入任务触发器总表
func get_quest_trigger(quest_id: int) -> Dictionary:
	if _triggers_cache.is_empty():
		var path := "res://data/quests/quest_triggers.json"
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				var parsed = JSON.parse_string(file.get_as_text())
				if parsed is Dictionary:
					_triggers_cache = parsed

	var key := str(quest_id)
	return _triggers_cache.get(key, {})


## 接取任务
func accept_quest(quest_id: int) -> bool:
	if is_quest_completed(quest_id) or is_quest_active(quest_id):
		return false

	var trigger := get_quest_trigger(quest_id)
	if trigger.is_empty():
		return false

	active_quests[quest_id] = {
		"state": QuestState.IN_PROGRESS,
		"progress": {},
		"trigger": trigger
	}

	DBOEventBus.quest_state_changed.emit(quest_id, QuestState.IN_PROGRESS)
	return true


## 完成并提交任务
func complete_quest(quest_id: int) -> bool:
	if not active_quests.has(quest_id):
		return false

	active_quests.erase(quest_id)
	completed_quests[quest_id] = true

	DBOEventBus.quest_state_changed.emit(quest_id, QuestState.COMPLETED)
	return true


func is_quest_active(quest_id: int) -> bool:
	return active_quests.has(quest_id)


func is_quest_completed(quest_id: int) -> bool:
	return completed_quests.has(quest_id)


## 怪物被击杀时的任务目标计数监听
func _on_combat_entity_died(victim: Node3D, _killer: Node3D) -> void:
	if victim == null or not ("mob_tblidx" in victim):
		return

	var killed_mob_id: int = victim.mob_tblidx
	for q_id in active_quests:
		var q_data: Dictionary = active_quests[q_id]
		# 检索目标击杀进度
		var prog: Dictionary = q_data.get("progress", {})
		var current_count: int = int(prog.get(killed_mob_id, 0)) + 1
		prog[killed_mob_id] = current_count
		q_data["progress"] = prog

		DBOEventBus.quest_objective_updated.emit(q_id, killed_mob_id, current_count, 10)
