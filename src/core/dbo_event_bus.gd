extends Node

## DBO Event Bus (Dragon Ball Online Global Decoupled Signal Bus)
## 全局解耦事件总线。
## 严格遵照 GEMINI.md 架构：消除各系统间的硬耦合，提供全生命周期异步事件通知。

# 玩家数值与属性变更 (100% 对齐 OpenDBO sPC_DATA 与 HUD 同步)
@warning_ignore("unused_signal")
signal player_stats_changed(current_lp: int, max_lp: int, current_ep: int, max_ep: int, current_rp: int, max_rp: int, current_rp_ball: int, max_rp_ball: int)
@warning_ignore("unused_signal")
signal player_exp_changed(current_exp: int, required_exp: int, current_level: int)
@warning_ignore("unused_signal")
signal player_info_changed(player_name: String, level: int, char_class: int)

# 目标索敌与选择系统 (OpenDBO Logic_SobTarget)
@warning_ignore("unused_signal")
signal target_selected(target: Node3D)
@warning_ignore("unused_signal")
signal target_cleared()

# 战斗判定与伤害通知 (OpenDBO battle.cpp / char_battle.cpp)
@warning_ignore("unused_signal")
signal combat_damage_dealt(source: Node3D, target: Node3D, damage: int, is_crit: bool, is_energy: bool)
@warning_ignore("unused_signal")
signal combat_entity_died(victim: Node3D, killer: Node3D)

# 交互与对话系统 (NPC / 传送员 / 场景物件)
@warning_ignore("unused_signal")
signal npc_interaction_requested(npc: Node3D)
@warning_ignore("unused_signal")
signal dialogue_opened(speaker_name: String, dialog_text: String, options: Array)
@warning_ignore("unused_signal")
signal dialogue_closed()
@warning_ignore("unused_signal")
signal portal_menu_opened(portal_data: Dictionary)
@warning_ignore("unused_signal")
signal portal_travel_requested(dest_portal_id: int)

# 背包与装备道具系统
@warning_ignore("unused_signal")
signal inventory_updated()
@warning_ignore("unused_signal")
signal equipment_updated()
@warning_ignore("unused_signal")
signal zenny_changed(current_zenny: int)
@warning_ignore("unused_signal")
signal item_used(item_tblidx: int)

# 任务系统事件 (TS Trigger)
@warning_ignore("unused_signal")
signal quest_state_changed(quest_id: int, new_state: int)
@warning_ignore("unused_signal")
signal quest_objective_updated(quest_id: int, objective_idx: int, current_count: int, target_count: int)

# 系统广播与通知提示
@warning_ignore("unused_signal")
signal notification_requested(message: String, tag_category: String)
@warning_ignore("unused_signal")
signal zone_changed(world_id: int, zone_name: String)
@warning_ignore("unused_signal")
signal ui_style_changed(mode: int)


func _ready() -> void:
	# 全局自动挂接：任何 3D 网格进入场景树时，自动校正 DFF 衍生模型的贴图颠倒 (UV V 翻转)
	get_tree().node_added.connect(_on_node_added_global)


func _on_node_added_global(node: Node) -> void:
	if node is MeshInstance3D:
		DBOMaterialHelper.fix_mesh_materials(node as MeshInstance3D)
