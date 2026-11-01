class_name DBOHUD
extends CanvasLayer

## DBO HUD (Dragon Ball Online Heads-Up Display)
## 遵循 GEMINI.md 规范：零硬编码文本，所有文字信息通过 DBOLocalizer 映射下发。
## 展示龙珠经典的生命值槽 (HP)、气力槽 (EP)、怒气/RP 气珠槽与等级徽章。

@export var player_target: DBOCharacterBase3D = null

@onready var health_bar: ProgressBar = $Root/StatusContainer/HealthBar
@onready var energy_bar: ProgressBar = $Root/StatusContainer/EnergyBar
@onready var rp_container: HBoxContainer = $Root/StatusContainer/RPContainer
@onready var name_label: Label = $Root/StatusContainer/NameLabel
@onready var level_label: Label = $Root/StatusContainer/LevelBadge/LevelLabel


func _ready() -> void:
	if player_target:
		bind_player(player_target)


## 绑定玩家角色事件
func bind_player(player: DBOCharacterBase3D) -> void:
	player_target = player
	player.health_changed.connect(_on_health_changed)
	player.energy_changed.connect(_on_energy_changed)
	player.rp_changed.connect(_on_rp_changed)
	if player.has_signal("rp_ball_changed"):
		player.rp_ball_changed.connect(_on_rp_ball_changed)

	refresh_hud()


## 刷新全量 HUD 状态
func refresh_hud() -> void:
	if player_target == null:
		return

	# 角色名称：通过本地化服务获取（若无对应项则显示默认）
	if name_label:
		name_label.text = DBOLocalizer.get_text("ETC", "CHAR_NAME_PREFIX", "") + player_target.character_name

	# 等级展示：通过本地化前缀模板下发
	if level_label:
		level_label.text = DBOLocalizer.format_text("ETC", "LEVEL_FORMAT", [player_target.level], "Lv.%d" % player_target.level)

	_on_health_changed(player_target.current_health, player_target.max_health)
	_on_energy_changed(player_target.current_energy, player_target.max_energy)
	_on_rp_changed(player_target.current_rp, player_target.max_rp)


func _on_health_changed(current: int, max_val: int) -> void:
	if health_bar:
		health_bar.max_value = max_val
		health_bar.value = current


func _on_energy_changed(current: int, max_val: int) -> void:
	if energy_bar:
		energy_bar.max_value = max_val
		energy_bar.value = current


func _on_rp_changed(current: int, _max_val: int) -> void:
	# 刷新当前珠内 RP 进度
	_update_rp_display()


func _on_rp_ball_changed(_current_balls: int, _max_balls: int) -> void:
	# 刷新完整点亮的 RP 珠 (OpenDBO 原版 3 颗气珠)
	_update_rp_display()


func _update_rp_display() -> void:
	if rp_container and player_target:
		var balls_count := rp_container.get_child_count()
		var active_balls := player_target.current_rp_ball
		for i in range(balls_count):
			var ball := rp_container.get_child(i) as Control
			if ball:
				ball.modulate = Color(1.0, 0.8, 0.0) if i < active_balls else Color(0.3, 0.3, 0.3)
