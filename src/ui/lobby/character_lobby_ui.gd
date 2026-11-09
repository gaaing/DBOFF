class_name CharacterLobbyUI
extends Control

## Character Lobby UI Controller
## 严格保留工程原版节点引用与架构，仅修复 1024x768 居中与切片映射错位。

signal avatar_rot_input(direction: int) # -1: left, 0: stop, 1: right
signal camera_zoom_requested(is_zoom_in: bool)
signal avatar_visual_changed(race: int, gender: int, class_id: int, hair: int, hair_color: int, face: int, skin_color: int, equipped_items: Array)
signal mode_changed(is_create_mode: bool)

# 官方 GUI 图集纹理
var tex_lobby1: Texture2D = null
var tex_lobby2: Texture2D = null
var tex_lobby3: Texture2D = null
var tex_lobby4: Texture2D = null

# 模式与创角状态
var is_create_mode: bool = false
@export var part_panel_left_aligned: bool = false

var cur_race: int = 0         # 0: 人类, 1: 那美克星人, 2: 魔人
var cur_class_idx: int = 0    # 0: 第一职业, 1: 第二职业
var cur_gender: int = 0       # 0: 男, 1: 女
var cur_hair: int = 0         # 0..9 (1..10)
var cur_hair_color: int = 0   # 0..12 (1..13)
var cur_face: int = 0         # 0..9 (1..10)
var cur_skin_color: int = 0   # 0..4 (1..5)

# 账号与角色槽位
var account_meta: Dictionary = {}
var char_list: Array = []
var selected_char_id: int = 0
var slot_buttons: Array[TextureButton] = []

# 节点引用 (共享)
@onready var left_rot_btn: TextureButton = $LeftRotBtn
@onready var right_rot_btn: TextureButton = $RightRotBtn

# 节点引用 (选角模式)
@onready var select_mode_root: Control = $SelectModeRoot
@onready var char_info_panel: Control = $SelectModeRoot/CharInfoPanel
@onready var info_bg_up: TextureRect = $SelectModeRoot/CharInfoPanel/BackgroundUp
@onready var info_bg_center: TextureRect = $SelectModeRoot/CharInfoPanel/BackgroundCenter
@onready var info_bg_bottom: TextureRect = $SelectModeRoot/CharInfoPanel/BackgroundBottom
@onready var info_title_label: Label = $SelectModeRoot/CharInfoPanel/TitleLabel

@onready var bar_name: TextureRect = $SelectModeRoot/CharInfoPanel/BarName
@onready var bar_level: TextureRect = $SelectModeRoot/CharInfoPanel/BarLevel
@onready var bar_class: TextureRect = $SelectModeRoot/CharInfoPanel/BarClass
@onready var bar_zenny: TextureRect = $SelectModeRoot/CharInfoPanel/BarZenny
@onready var bar_pos: TextureRect = $SelectModeRoot/CharInfoPanel/BarPos

@onready var name_key: Label = $SelectModeRoot/CharInfoPanel/NameKey
@onready var name_val: Label = $SelectModeRoot/CharInfoPanel/NameVal
@onready var level_key: Label = $SelectModeRoot/CharInfoPanel/LevelKey
@onready var level_val: Label = $SelectModeRoot/CharInfoPanel/LevelVal
@onready var class_key: Label = $SelectModeRoot/CharInfoPanel/ClassKey
@onready var class_val: Label = $SelectModeRoot/CharInfoPanel/ClassVal
@onready var zenny_key: Label = $SelectModeRoot/CharInfoPanel/ZennyKey
@onready var zenny_val: Label = $SelectModeRoot/CharInfoPanel/ZennyVal
@onready var pos_key: Label = $SelectModeRoot/CharInfoPanel/PosKey
@onready var pos_val: Label = $SelectModeRoot/CharInfoPanel/PosVal

@onready var char_selecter_panel: Control = $SelectModeRoot/CharSelecterPanel
@onready var sel_bg_up: TextureRect = $SelectModeRoot/CharSelecterPanel/BackgroundUp
@onready var sel_bg_center: TextureRect = $SelectModeRoot/CharSelecterPanel/BackgroundCenter
@onready var sel_bg_bottom: TextureRect = $SelectModeRoot/CharSelecterPanel/BackgroundBottom
@onready var sel_title_label: Label = $SelectModeRoot/CharSelecterPanel/TitleLabel
@onready var slot_list_root: Control = $SelectModeRoot/CharSelecterPanel/SlotList
@onready var del_char_btn: TextureButton = $SelectModeRoot/CharSelecterPanel/DelCharBtn
@onready var del_label: Label = $SelectModeRoot/CharSelecterPanel/DelCharBtn/DelLabel

@onready var enter_game_btn: TextureButton = $SelectModeRoot/EnterGameBtn
@onready var enter_label: Label = $SelectModeRoot/EnterGameBtn/EnterLabel

# 节点引用 (创角模式)
@onready var create_mode_root: Control = $CreateModeRoot
@onready var name_back: TextureRect = $CreateModeRoot/NameBack
@onready var name_input: LineEdit = $CreateModeRoot/NameBack/NameInput
@onready var create_btn: TextureButton = $CreateModeRoot/NameBack/CreateBtn
@onready var create_btn_label: Label = $CreateModeRoot/NameBack/CreateBtn/CreateBtnLabel
@onready var return_btn: TextureButton = $CreateModeRoot/ReturnBtn
@onready var return_btn_label: Label = $CreateModeRoot/ReturnBtn/ReturnBtnLabel

@onready var part_panel: Control = $CreateModeRoot/PartPanel
@onready var bg_up: TextureRect = $CreateModeRoot/PartPanel/BackgroundUp
@onready var bg_center: TextureRect = $CreateModeRoot/PartPanel/BackgroundCenter
@onready var bg_bottom: TextureRect = $CreateModeRoot/PartPanel/BackgroundBottom
@onready var part_title_label: Label = $CreateModeRoot/PartPanel/TitleLabel

@onready var race_label: Label = $CreateModeRoot/PartPanel/RaceLabel
@onready var btn_human: TextureButton = $CreateModeRoot/PartPanel/BtnHuman
@onready var btn_namek: TextureButton = $CreateModeRoot/PartPanel/BtnNamek
@onready var btn_majin: TextureButton = $CreateModeRoot/PartPanel/BtnMajin
@onready var race_select_ring: TextureRect = $CreateModeRoot/PartPanel/RaceSelectRing

@onready var class_label: Label = $CreateModeRoot/PartPanel/ClassLabel
@onready var btn_class1: TextureButton = $CreateModeRoot/PartPanel/BtnClass1
@onready var btn_class2: TextureButton = $CreateModeRoot/PartPanel/BtnClass2
@onready var class_select_ring: TextureRect = $CreateModeRoot/PartPanel/ClassSelectRing

@onready var gender_label: Label = $CreateModeRoot/PartPanel/GenderLabel
@onready var btn_male: TextureButton = $CreateModeRoot/PartPanel/BtnMale
@onready var btn_female: TextureButton = $CreateModeRoot/PartPanel/BtnFemale
@onready var gender_select_ring: TextureRect = $CreateModeRoot/PartPanel/GenderSelectRing

@onready var hair_row: Control = $CreateModeRoot/PartPanel/HairRow
@onready var hair_color_row: Control = $CreateModeRoot/PartPanel/HairColorRow
@onready var face_row: Control = $CreateModeRoot/PartPanel/FaceRow
@onready var skin_row: Control = $CreateModeRoot/PartPanel/SkinRow

@onready var random_btn: TextureButton = $CreateModeRoot/PartPanel/RandomBtn
@onready var random_btn_label: Label = $CreateModeRoot/PartPanel/RandomBtn/RandomBtnLabel


func _ready() -> void:
	_load_textures()
	_apply_atlas_textures()
	_refresh_localized_labels()
	_build_slot_buttons()
	_connect_events()

	if is_instance_valid(name_input):
		var empty_sb := StyleBoxEmpty.new()
		name_input.add_theme_stylebox_override("normal", empty_sb)
		name_input.add_theme_stylebox_override("focus", empty_sb)
		name_input.add_theme_stylebox_override("read_only", empty_sb)
		name_input.flat = true

	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()

	DBOEventBus.ui_style_changed.connect(_on_ui_style_changed)
	_load_account_data()


func _on_ui_style_changed(_mode: int) -> void:
	_apply_atlas_textures()
	_build_slot_buttons()


func _load_textures() -> void:
	tex_lobby1 = load("res://assets/tex/texture/gui/pc_create.png")
	tex_lobby2 = load("res://assets/tex/texture/gui/pc_create2.png")
	tex_lobby3 = load("res://assets/tex/texture/gui/pc_create3.png")
	tex_lobby4 = load("res://assets/tex/texture/gui/pc_create4.png")


func _get_srf_atlas(surface_name: String, fallback_rect: Rect2 = Rect2(), fallback_tex: Texture2D = null) -> AtlasTexture:
	return DBOUIManager.create_atlas(surface_name, fallback_rect, fallback_tex)


func _apply_atlas_textures() -> void:
	var bg_up_atlas = _get_srf_atlas("srfBackgroundUp")
	var bg_cen_atlas = _get_srf_atlas("srfBackgroundCenter")
	var bg_bot_atlas = _get_srf_atlas("srfBackgroundBottom")

	if info_bg_up: info_bg_up.texture = bg_up_atlas
	if info_bg_center: info_bg_center.texture = bg_cen_atlas
	if info_bg_bottom: info_bg_bottom.texture = bg_bot_atlas

	if sel_bg_up: sel_bg_up.texture = bg_up_atlas
	if sel_bg_center: sel_bg_center.texture = bg_cen_atlas
	if sel_bg_bottom: sel_bg_bottom.texture = bg_bot_atlas

	if bg_up: bg_up.texture = bg_up_atlas
	if bg_center: bg_center.texture = bg_cen_atlas
	if bg_bottom: bg_bottom.texture = bg_bot_atlas

	var bar_atlas = _get_srf_atlas("srfBar")
	if bar_name: bar_name.texture = bar_atlas
	if bar_level: bar_level.texture = bar_atlas
	if bar_class: bar_class.texture = bar_atlas
	if bar_zenny: bar_zenny.texture = bar_atlas
	if bar_pos: bar_pos.texture = bar_atlas

	if left_rot_btn:
		left_rot_btn.texture_normal = _get_srf_atlas("srfBtnLeftRotUp")
		left_rot_btn.texture_hover = _get_srf_atlas("srfBtnLeftRotFoc")
		left_rot_btn.texture_pressed = _get_srf_atlas("srfBtnLeftRotDown")

	if right_rot_btn:
		right_rot_btn.texture_normal = _get_srf_atlas("srfBtnRightRotUp")
		right_rot_btn.texture_hover = _get_srf_atlas("srfBtnRightRotFoc")
		right_rot_btn.texture_pressed = _get_srf_atlas("srfBtnRightRotDown")

	var btn_normal = _get_srf_atlas("srfNormalBtnUp")
	var btn_hover = _get_srf_atlas("srfNormalBtnFoc")
	var btn_pressed = _get_srf_atlas("srfNormalBtnDown")

	if enter_game_btn:
		enter_game_btn.texture_normal = btn_normal
		enter_game_btn.texture_hover = btn_hover
		enter_game_btn.texture_pressed = btn_pressed

	if return_btn:
		return_btn.texture_normal = btn_normal
		return_btn.texture_hover = btn_hover
		return_btn.texture_pressed = btn_pressed

	if random_btn:
		random_btn.texture_normal = btn_normal
		random_btn.texture_hover = btn_hover
		random_btn.texture_pressed = btn_pressed

	if del_char_btn:
		del_char_btn.texture_normal = _get_srf_atlas("srfDelBtlUp")
		del_char_btn.texture_hover = _get_srf_atlas("srfDelBtlFoc")
		del_char_btn.texture_pressed = _get_srf_atlas("srfDelBtlDown")
		del_char_btn.texture_disabled = _get_srf_atlas("srfDelBtlDis")

	var ring_atlas = _get_srf_atlas("srfSelect")
	if race_select_ring: race_select_ring.texture = ring_atlas
	if class_select_ring: class_select_ring.texture = ring_atlas
	if gender_select_ring: gender_select_ring.texture = ring_atlas
	if name_back: name_back.texture = _get_srf_atlas("srfNameBack")

	if create_btn:
		create_btn.texture_normal = _get_srf_atlas("srfCreateCharBtnUp")
		create_btn.texture_hover = _get_srf_atlas("srfCreateCharBtnFoc")
		create_btn.texture_pressed = _get_srf_atlas("srfCreateCharBtnDown")
		create_btn.texture_disabled = _get_srf_atlas("srfCreateCharBtnDis")

	if btn_human:
		btn_human.texture_normal = _get_srf_atlas("srfHumanBtnUp")
		btn_human.texture_hover = _get_srf_atlas("srfHumanBtnFoc")
		btn_human.texture_pressed = _get_srf_atlas("srfHumanBtnDown")
		btn_human.texture_disabled = _get_srf_atlas("srfHumanBtnDis")

	if btn_namek:
		btn_namek.texture_normal = _get_srf_atlas("srfNamekBtnUp")
		btn_namek.texture_hover = _get_srf_atlas("srfNamekBtnFoc")
		btn_namek.texture_pressed = _get_srf_atlas("srfNamekBtnDown")
		btn_namek.texture_disabled = _get_srf_atlas("srfNamekBtnDis")

	if btn_majin:
		btn_majin.texture_normal = _get_srf_atlas("srfMajinBtnUp")
		btn_majin.texture_hover = _get_srf_atlas("srfMajinBtnFoc")
		btn_majin.texture_pressed = _get_srf_atlas("srfMajinBtnDown")
		btn_majin.texture_disabled = _get_srf_atlas("srfMajinBtnDis")

	_update_class_icons()
	_update_gender_icons()

	var row_bg = _get_srf_atlas("srfLeftRightBackground")
	var l_up = _get_srf_atlas("srfLeftBtnUp")
	var l_foc = _get_srf_atlas("srfLeftBtnFoc")
	var l_down = _get_srf_atlas("srfLeftBtnDown")
	var l_dis = _get_srf_atlas("srfLeftBtnDis")

	var r_up = _get_srf_atlas("srfRightBtnUp")
	var r_foc = _get_srf_atlas("srfRightBtnFoc")
	var r_down = _get_srf_atlas("srfRightBtnDown")
	var r_dis = _get_srf_atlas("srfRightBtnDis")

	for row in [hair_row, hair_color_row, face_row, skin_row]:
		if row == null: continue
		var bg_node = row.get_node_or_null("Bg") as TextureRect
		if bg_node: bg_node.texture = row_bg
		var l_btn: TextureButton = row.get_node_or_null("LeftBtn") as TextureButton
		if l_btn:
			l_btn.texture_normal = l_up
			l_btn.texture_hover = l_foc
			l_btn.texture_pressed = l_down
			l_btn.texture_disabled = l_dis

		var r_btn: TextureButton = row.get_node_or_null("RightBtn") as TextureButton
		if r_btn:
			r_btn.texture_normal = r_up
			r_btn.texture_hover = r_foc
			r_btn.texture_pressed = r_down
			r_btn.texture_disabled = r_dis


func _refresh_localized_labels() -> void:
	if info_title_label: info_title_label.text = DBOLocalizer.get_text("GUI", "DST_LOBBY_CARACTER_INFO", "角色信息")
	if name_key: name_key.text = "%s:" % DBOLocalizer.get_text("GUI", "DST_STATUS_NAME", "姓名").trim_suffix(":")
	if level_key: level_key.text = "%s:" % DBOLocalizer.get_text("GUI", "DST_LOBBY_CHAR_LEVEL", "等级").trim_suffix(":")
	if class_key: class_key.text = "%s:" % DBOLocalizer.get_text("GUI", "DST_LOBBY_CHAR_CLASS", "职业").trim_suffix(":")
	if zenny_key: zenny_key.text = "%s:" % DBOLocalizer.get_text("GUI", "DST_LOBBY_ZENNY", "索尼").trim_suffix(":")
	if pos_key: pos_key.text = "%s:" % DBOLocalizer.get_text("GUI", "DST_LOBBY_POSITION", "所在区域").trim_suffix(":")

	if sel_title_label: sel_title_label.text = DBOLocalizer.get_text("GUI", "DST_LOBBY_CHARACTER_LIST", "角色列表")
	if del_label: del_label.text = DBOLocalizer.get_text("GUI", "DST_LOBBY_DEL_CHAR", "删除")
	if enter_label: enter_label.text = DBOLocalizer.get_text("GUI", "DST_LOBBY_GAME_START", "开始游戏")

	if create_btn_label: create_btn_label.text = DBOLocalizer.get_text("GUI", "DST_LOBBY_MAKE", "创建")
	if return_btn_label: return_btn_label.text = DBOLocalizer.get_text("GUI", "DST_LOBBY_RETURN", "返回")

	if part_title_label: part_title_label.text = DBOLocalizer.get_text("GUI", "DST_LOBBY_CHARACTER_ATTRIBUTE", "角色属性")
	if race_label: race_label.text = DBOLocalizer.get_text("GUI", "DST_LOBBY_RACE", "种族")
	if class_label: class_label.text = DBOLocalizer.get_text("GUI", "DST_LOBBY_CLASS", "职业")
	if gender_label: gender_label.text = DBOLocalizer.get_text("GUI", "DST_LOBBY_GENDER", "性别")

	if hair_row and hair_row.get_node_or_null("Label"): hair_row.get_node("Label").text = DBOLocalizer.get_text("GUI", "DST_LOBBY_HAIR", "发型")
	if hair_color_row and hair_color_row.get_node_or_null("Label"): hair_color_row.get_node("Label").text = DBOLocalizer.get_text("GUI", "DST_LOBBY_HAIRCOLOR", "发色")
	if face_row and face_row.get_node_or_null("Label"): face_row.get_node("Label").text = DBOLocalizer.get_text("GUI", "DST_LOBBY_FACE", "脸型")
	if skin_row and skin_row.get_node_or_null("Label"): skin_row.get_node("Label").text = DBOLocalizer.get_text("GUI", "DST_LOBBY_SKIN", "肤色")

	if random_btn_label: random_btn_label.text = DBOLocalizer.get_text("GUI", "DST_LOBBY_RANDOM_CHOICE", "随机外观")


func _build_slot_buttons() -> void:
	if slot_list_root == null:
		return
	slot_buttons.clear()
	for child in slot_list_root.get_children():
		child.queue_free()

	for i in range(8):
		var btn := TextureButton.new()
		btn.name = "SlotBtn_%d" % i
		btn.custom_minimum_size = Vector2(198, 54)
		btn.size = Vector2(198, 54)
		btn.position = Vector2(0, i * 58)

		DBOUIManager.apply_texture_button_states(btn, "srfCharSlotBtnUp", "srfCharSlotBtnFoc", "srfCharSlotBtnDown", "srfCharSlotBtnDis")

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.position = Vector2(10, 10)
		icon.size = Vector2(33, 33)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon)

		var n_lbl := Label.new()
		n_lbl.name = "NameLabel"
		n_lbl.position = Vector2(48, 8)
		n_lbl.size = Vector2(142, 18)
		n_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(n_lbl)

		var l_lbl := Label.new()
		l_lbl.name = "LevelLabel"
		l_lbl.position = Vector2(48, 28)
		l_lbl.size = Vector2(142, 16)
		l_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
		l_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(l_lbl)

		var e_lbl := Label.new()
		e_lbl.name = "EmptyLabel"
		e_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		e_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		e_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		e_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		e_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(e_lbl)

		slot_list_root.add_child(btn)
		slot_buttons.append(btn)


func _connect_events() -> void:
	if enter_game_btn: enter_game_btn.pressed.connect(_on_enter_game_pressed)
	if del_char_btn: del_char_btn.pressed.connect(_on_delete_character_pressed)
	if return_btn: return_btn.pressed.connect(_on_return_pressed)
	if create_btn: create_btn.pressed.connect(_on_create_confirm_pressed)

	if left_rot_btn:
		left_rot_btn.button_down.connect(func(): avatar_rot_input.emit(-1))
		left_rot_btn.button_up.connect(func(): avatar_rot_input.emit(0))
	if right_rot_btn:
		right_rot_btn.button_down.connect(func(): avatar_rot_input.emit(1))
		right_rot_btn.button_up.connect(func(): avatar_rot_input.emit(0))

	if btn_human: btn_human.pressed.connect(func(): _select_race(0))
	if btn_namek: btn_namek.pressed.connect(func(): _select_race(1))
	if btn_majin: btn_majin.pressed.connect(func(): _select_race(2))

	if btn_class1: btn_class1.pressed.connect(func(): _select_class_slot(0))
	if btn_class2: btn_class2.pressed.connect(func(): _select_class_slot(1))

	if btn_male: btn_male.pressed.connect(func(): _select_gender(0))
	if btn_female: btn_female.pressed.connect(func(): _select_gender(1))

	if hair_row:
		var l = hair_row.get_node_or_null("LeftBtn") as TextureButton
		var r = hair_row.get_node_or_null("RightBtn") as TextureButton
		if l: l.pressed.connect(func(): _step_attribute("hair", -1))
		if r: r.pressed.connect(func(): _step_attribute("hair", 1))

	if hair_color_row:
		var l_hc = hair_color_row.get_node_or_null("LeftBtn") as TextureButton
		var r_hc = hair_color_row.get_node_or_null("RightBtn") as TextureButton
		if l_hc: l_hc.pressed.connect(func(): _step_attribute("hair_color", -1))
		if r_hc: r_hc.pressed.connect(func(): _step_attribute("hair_color", 1))

	if face_row:
		var l_fc = face_row.get_node_or_null("LeftBtn") as TextureButton
		var r_fc = face_row.get_node_or_null("RightBtn") as TextureButton
		if l_fc: l_fc.pressed.connect(func(): _step_attribute("face", -1))
		if r_fc: r_fc.pressed.connect(func(): _step_attribute("face", 1))

	if skin_row:
		var l_sk = skin_row.get_node_or_null("LeftBtn") as TextureButton
		var r_sk = skin_row.get_node_or_null("RightBtn") as TextureButton
		if l_sk: l_sk.pressed.connect(func(): _step_attribute("skin_color", -1))
		if r_sk: r_sk.pressed.connect(func(): _step_attribute("skin_color", 1))

	if random_btn: random_btn.pressed.connect(_on_random_pressed)


func _load_account_data() -> void:
	account_meta = DBOSaveManager.load_account_meta()
	char_list = account_meta.get("character_brief_list", [])
	selected_char_id = account_meta.get("last_played_char_id", 0)

	_render_character_slot_list()
	_set_ui_mode(false)


func _render_character_slot_list() -> void:
	var max_slots: int = account_meta.get("character_max_slots", 8)
	var found_selected: bool = false
	var first_occupied_cid: int = 0
	var first_occupied_brief: Dictionary = {}

	var icon_human = _get_srf_atlas("srfHuman")
	var icon_namek = _get_srf_atlas("srfNamek")
	var icon_majin = _get_srf_atlas("srfMajin")

	for i in range(slot_buttons.size()):
		var btn = slot_buttons[i]
		for conn in btn.pressed.get_connections():
			btn.pressed.disconnect(conn.callable)

		var icon: TextureRect = btn.get_node("Icon")
		var n_lbl: Label = btn.get_node("NameLabel")
		var l_lbl: Label = btn.get_node("LevelLabel")
		var e_lbl: Label = btn.get_node("EmptyLabel")

		if i < char_list.size() and i < max_slots:
			var brief: Dictionary = char_list[i]
			var cid: int = brief.get("char_id", 0)
			var cname: String = brief.get("char_name", "Hero")
			var race: int = brief.get("race", 0)
			var cls: int = brief.get("class_id", 0)
			var lvl: int = brief.get("level", 1)

			btn.disabled = false
			icon.visible = true
			n_lbl.visible = true
			l_lbl.visible = true
			e_lbl.visible = false

			match race:
				0: icon.texture = icon_human
				1: icon.texture = icon_namek
				2: icon.texture = icon_majin
				_: icon.texture = icon_human

			n_lbl.text = cname
			l_lbl.text = "Lv.%d %s" % [lvl, _get_class_name(cls)]

			btn.pressed.connect(_on_slot_character_selected.bind(i, cid, brief))

			if first_occupied_cid == 0:
				first_occupied_cid = cid
				first_occupied_brief = brief

			if cid == selected_char_id:
				found_selected = true
				_on_slot_character_selected(i, cid, brief)
		else:
			btn.disabled = true
			icon.visible = false
			n_lbl.visible = false
			l_lbl.visible = false
			e_lbl.visible = true
			e_lbl.text = "[ %s ]" % DBOLocalizer.get_text("GUI", "DST_LOBBY_CHARACTER_MAKE", "新建角色")
			btn.disabled = false
			btn.pressed.connect(_on_empty_slot_clicked)

	if not found_selected and first_occupied_cid != 0:
		selected_char_id = first_occupied_cid
		_on_slot_character_selected(0, first_occupied_cid, first_occupied_brief)
	elif char_list.is_empty():
		_clear_char_info()


func _on_slot_character_selected(slot_index: int, char_id: int, brief: Dictionary) -> void:
	selected_char_id = char_id
	if enter_game_btn: enter_game_btn.disabled = false
	DBOSaveManager.set_active_character_id(char_id)

	for i in range(slot_buttons.size()):
		if i < char_list.size():
			if i == slot_index:
				DBOUIManager.apply_texture_button_states(slot_buttons[i], "srfCharSlotBtnDown")
			else:
				DBOUIManager.apply_texture_button_states(slot_buttons[i], "srfCharSlotBtnUp")

	var full_char_data: Dictionary = DBOSaveManager.load_character_data(char_id)
	var prof: Dictionary = full_char_data.get("character_profile", {})
	var cname: String = brief.get("char_name", prof.get("char_name", "Hero"))
	var race: int = brief.get("race", prof.get("race", 0))
	var gender: int = brief.get("gender", prof.get("gender", 0))
	var cls: int = brief.get("class_id", prof.get("class_id", 0))
	var lvl: int = brief.get("level", full_char_data.get("stats", {}).get("level", 1))

	var hair: int = clampi(int(brief.get("hair_style", prof.get("hair_style", 1))), 1, 10)
	var hair_color: int = clampi(int(brief.get("hair_color", prof.get("hair_color", 1))), 1, 13)
	var face: int = clampi(int(brief.get("face_style", prof.get("face_style", 1))), 1, 10)
	var skin_color: int = clampi(int(brief.get("skin_color", prof.get("skin_color", 1))), 1, 5)

	var zenny: int = full_char_data.get("stats", {}).get("zenny", 0)
	var world_id: int = full_char_data.get("world_transform", {}).get("world_id", 1)

	if name_val: name_val.text = cname
	if level_val: level_val.text = "%d" % lvl
	if class_val: class_val.text = _get_class_name(cls)
	if zenny_val:
		if zenny == 0:
			zenny_val.text = DBOLocalizer.get_text("GUI", "DST_LOBBY_NO_HAVE_ZENNY", "0 索尼")
		else:
			zenny_val.text = "%s %s" % [_format_zenny(zenny), DBOLocalizer.get_text("GUI", "DST_ZENNY", "索尼")]
	if pos_val: pos_val.text = _get_location_name(race, world_id)

	var equipped_items: Array = []
	var inv_items: Array = full_char_data.get("containers", {}).get("inventory_items", [])
	for item in inv_items:
		if not (item is Dictionary) or item.is_empty():
			continue
		var place := int(item.get("byPlace", item.get("place", 0)))
		var pos := int(item.get("byPosition", item.get("pos", 255)))
		if place == 0 and pos != 255:
			var norm_item: Dictionary = item.duplicate(true)
			norm_item["pos"] = pos
			norm_item["item_tblidx"] = int(item.get("item_tblidx", item.get("tblidx", 0)))
			equipped_items.append(norm_item)

	avatar_visual_changed.emit(race, gender, cls, hair, hair_color, face, skin_color, equipped_items)
	camera_zoom_requested.emit(false)


func trigger_initial_avatar_sync() -> void:
	if not is_create_mode:
		if char_list.is_empty():
			_set_ui_mode(true)
			_update_avatar_preview()
		else:
			var target_idx: int = 0
			var target_cid: int = selected_char_id
			var target_brief: Dictionary = {}
			for i in range(char_list.size()):
				if char_list[i].get("char_id", 0) == target_cid:
					target_idx = i
					target_brief = char_list[i]
					break
			if target_brief.is_empty() and not char_list.is_empty():
				target_idx = 0
				target_brief = char_list[0]
				target_cid = target_brief.get("char_id", 0)
			if not target_brief.is_empty():
				_on_slot_character_selected(target_idx, target_cid, target_brief)
			else:
				_set_ui_mode(true)
				_update_avatar_preview()
	else:
		_update_avatar_preview()


func _clear_char_info() -> void:
	if name_val: name_val.text = ""
	if level_val: level_val.text = ""
	if class_val: class_val.text = ""
	if zenny_val: zenny_val.text = ""
	if pos_val: pos_val.text = ""
	if enter_game_btn: enter_game_btn.disabled = true


func _format_zenny(amount: int) -> String:
	var s := str(amount)
	var res := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			res = "," + res
		res = s[i] + res
		count += 1
	return res


func _get_location_name(race: int, _world_id: int) -> String:
	match race:
		0: return DBOLocalizer.get_text("GUI", "DST_LOBBY_DEFAULT_POSITION_HUMAN", "柯卡拉村")
		1: return DBOLocalizer.get_text("GUI", "DST_LOBBY_DEFAULT_POSITION_NAMEK", "天天神殿")
		2: return DBOLocalizer.get_text("GUI", "DST_LOBBY_DEFAULT_POSITION_MAJIN", "悟饭老爷爷家")
	return DBOLocalizer.get_text("GUI", "DST_LOBBY_DEFAULT_POSITION_HUMAN", "柯卡拉村")


func _on_empty_slot_clicked() -> void:
	_set_ui_mode(true)


func _on_enter_game_pressed() -> void:
	if selected_char_id <= 0:
		return
	DBOSaveManager.set_active_character_id(selected_char_id)
	get_tree().change_scene_to_file("res://scenes/world/main_world.tscn")


func _on_delete_character_pressed() -> void:
	if selected_char_id <= 0:
		return
	DBOSaveManager.delete_character(selected_char_id)
	_load_account_data()


func _on_return_pressed() -> void:
	_set_ui_mode(false)


func _set_ui_mode(create_mode: bool) -> void:
	is_create_mode = create_mode
	if select_mode_root: select_mode_root.visible = not create_mode
	if create_mode_root: create_mode_root.visible = create_mode
	mode_changed.emit(create_mode)

	if is_create_mode:
		_select_race(0)
		camera_zoom_requested.emit(false)
	else:
		if not char_list.is_empty():
			_render_character_slot_list()


func _select_race(race_idx: int) -> void:
	cur_race = race_idx
	if race_select_ring:
		match cur_race:
			0: race_select_ring.position = btn_human.position if btn_human else Vector2.ZERO
			1: race_select_ring.position = btn_namek.position if btn_namek else Vector2.ZERO
			2: race_select_ring.position = btn_majin.position if btn_majin else Vector2.ZERO

	_update_class_icons()
	_update_gender_icons()
	_apply_race_mutex_rules()
	_update_avatar_preview()


func _update_class_icons() -> void:
	if btn_class1 == null or btn_class2 == null:
		return
	match cur_race:
		0:
			DBOUIManager.apply_texture_button_states(btn_class1, "srfHumanFighterBtnUp", "srfHumanFighterBtnFoc", "srfHumanFighterBtnDown", "srfHumanFighterBtnDis")
			DBOUIManager.apply_texture_button_states(btn_class2, "srfHumanMysticBtnUp", "srfHumanMysticBtnFoc", "srfHumanMysticBtnDown", "srfHumanMysticBtnDis")
		1:
			DBOUIManager.apply_texture_button_states(btn_class1, "srfNamekFighterBtnUp", "srfNamekFighterBtnFoc", "srfNamekFighterBtnDown", "srfNamekFighterBtnDis")
			DBOUIManager.apply_texture_button_states(btn_class2, "srfNamekMysticBtnUp", "srfNamekMysticBtnFoc", "srfNamekMysticBtnDown", "srfNamekMysticBtnDis")
		2:
			DBOUIManager.apply_texture_button_states(btn_class1, "srfMajinMightyBtnUp", "srfMajinMightyBtnFoc", "srfMajinMightyBtnDown", "srfMajinMightyBtnDis")
			DBOUIManager.apply_texture_button_states(btn_class2, "srfMajinWonderBtnUp", "srfMajinWonderBtnFoc", "srfMajinWonderBtnDown", "srfMajinWonderBtnDis")

	_select_class_slot(0)


func _update_gender_icons() -> void:
	if btn_male == null or btn_female == null:
		return
	match cur_race:
		0:
			btn_male.visible = true
			btn_female.visible = true
			DBOUIManager.apply_texture_button_states(btn_male, "srfMaleBtnUp", "srfMaleBtnFoc", "srfMaleBtnDown")
			DBOUIManager.apply_texture_button_states(btn_female, "srfFemaleBtnUp", "srfFemaleBtnFoc", "srfFemaleBtnDown")
		1:
			btn_male.visible = true
			btn_female.visible = false
			DBOUIManager.apply_texture_button_states(btn_male, "srfNamekBtnUp", "srfNamekBtnFoc", "srfNamekBtnDown")
		2:
			btn_male.visible = true
			btn_female.visible = true
			DBOUIManager.apply_texture_button_states(btn_male, "srfMaleBtnUp", "srfMaleBtnFoc", "srfMaleBtnDown")
			DBOUIManager.apply_texture_button_states(btn_female, "srfFemaleBtnUp", "srfFemaleBtnFoc", "srfFemaleBtnDown")


func _select_class_slot(slot_idx: int) -> void:
	cur_class_idx = slot_idx
	if class_select_ring and btn_class1 and btn_class2:
		class_select_ring.position = btn_class1.position if slot_idx == 0 else btn_class2.position
	_update_avatar_preview()


func _select_gender(gender_idx: int) -> void:
	if cur_race == 1:
		return
	cur_gender = gender_idx
	if gender_select_ring and btn_male and btn_female:
		gender_select_ring.position = btn_male.position if gender_idx == 0 else btn_female.position
	_apply_race_mutex_rules()
	_update_avatar_preview()


func _apply_race_mutex_rules() -> void:
	if cur_race == 1:
		cur_gender = 0
		if btn_male: btn_male.visible = true
		if btn_female: btn_female.visible = false
		if gender_select_ring and btn_male:
			gender_select_ring.visible = true
			gender_select_ring.position = btn_male.position
		cur_hair_color = cur_skin_color
	elif cur_race == 2:
		if btn_male: btn_male.visible = true
		if btn_female: btn_female.visible = true
		if gender_select_ring and btn_male and btn_female:
			gender_select_ring.visible = true
			gender_select_ring.position = btn_male.position if cur_gender == 0 else btn_female.position
		if cur_gender == 0:
			cur_hair_color = cur_skin_color
	else:
		if btn_male: btn_male.visible = true
		if btn_female: btn_female.visible = true
		if gender_select_ring and btn_male and btn_female:
			gender_select_ring.visible = true
			gender_select_ring.position = btn_male.position if cur_gender == 0 else btn_female.position


func _step_attribute(attr_name: String, dir: int) -> void:
	match attr_name:
		"hair":
			cur_hair = posmod(cur_hair + dir, 10)
			camera_zoom_requested.emit(true)
		"hair_color":
			if cur_race == 1 or (cur_race == 2 and cur_gender == 0):
				cur_skin_color = posmod(cur_skin_color + dir, 5)
				cur_hair_color = cur_skin_color
			else:
				var max_col: int = 5 if (cur_race == 2 and cur_gender == 1) else 13
				cur_hair_color = posmod(cur_hair_color + dir, max_col)
			camera_zoom_requested.emit(true)
		"face":
			cur_face = posmod(cur_face + dir, 10)
			camera_zoom_requested.emit(true)
		"skin_color":
			cur_skin_color = posmod(cur_skin_color + dir, 5)
			if cur_race == 1 or (cur_race == 2 and cur_gender == 0):
				cur_hair_color = cur_skin_color
			camera_zoom_requested.emit(true)

	_apply_race_mutex_rules()
	_update_avatar_preview()


func _on_random_pressed() -> void:
	cur_hair = randi() % 10
	cur_face = randi() % 10
	cur_skin_color = randi() % 5
	if cur_race == 1 or (cur_race == 2 and cur_gender == 0):
		cur_hair_color = cur_skin_color
	elif cur_race == 2 and cur_gender == 1:
		cur_hair_color = randi() % 5
	else:
		cur_hair_color = randi() % 13

	_apply_race_mutex_rules()
	_update_avatar_preview()
	camera_zoom_requested.emit(false)


func _get_actual_class_id() -> int:
	match cur_race:
		0: return 0 if cur_class_idx == 0 else 1
		1: return 3 if cur_class_idx == 0 else 4
		2: return 5 if cur_class_idx == 0 else 6
	return 0


func _update_avatar_preview() -> void:
	var actual_class := _get_actual_class_id()
	# 创角模式角色预览动态搭载对应职业的新手装备（武道家绿道服、气功师气功袍、机械师工装等，严格对标 OpenDBO）
	var preview_equipped: Array = DBOSaveManager.get_newbie_starter_items(cur_race, actual_class)

	if hair_row and hair_row.get_node_or_null("Label"):
		hair_row.get_node("Label").text = "%s %d" % [DBOLocalizer.get_text("GUI", "DST_LOBBY_HAIR", "发型"), cur_hair + 1]
	if hair_color_row and hair_color_row.get_node_or_null("Label"):
		hair_color_row.get_node("Label").text = "%s %d" % [DBOLocalizer.get_text("GUI", "DST_LOBBY_HAIRCOLOR", "发色"), cur_hair_color + 1]
	if face_row and face_row.get_node_or_null("Label"):
		face_row.get_node("Label").text = "%s %d" % [DBOLocalizer.get_text("GUI", "DST_LOBBY_FACE", "脸型"), cur_face + 1]
	if skin_row and skin_row.get_node_or_null("Label"):
		skin_row.get_node("Label").text = "%s %d" % [DBOLocalizer.get_text("GUI", "DST_LOBBY_SKIN", "肤色"), cur_skin_color + 1]

	avatar_visual_changed.emit(cur_race, cur_gender, actual_class, cur_hair + 1, cur_hair_color + 1, cur_face + 1, cur_skin_color + 1, preview_equipped)


func _on_create_confirm_pressed() -> void:
	if name_input == null:
		return
	var char_name := name_input.text.strip_edges()
	if char_name.is_empty():
		return

	var new_char_id: int = 100001
	for b in char_list:
		if b.get("char_id", 0) >= new_char_id:
			new_char_id = b.get("char_id", 0) + 1

	var actual_class := _get_actual_class_id()
	DBOSaveManager.create_character_from_newbie(
		new_char_id,
		char_name,
		cur_race,
		actual_class,
		cur_gender,
		cur_hair + 1,
		cur_hair_color + 1,
		cur_face + 1,
		cur_skin_color + 1
	)

	name_input.text = ""
	_load_account_data()


func _get_class_name(cls: int) -> String:
	match cls:
		0: return DBOLocalizer.get_text("GUI", "DST_CLASS_HUMAN_FIGHTER", "武道家")
		1: return DBOLocalizer.get_text("GUI", "DST_CLASS_HUMAN_MYSTIC", "气功师")
		3: return DBOLocalizer.get_text("GUI", "DST_CLASS_NAMEK_FIGHTER", "战士")
		4: return DBOLocalizer.get_text("GUI", "DST_CLASS_NAMEK_MYSTIC", "龙族")
		5: return DBOLocalizer.get_text("GUI", "DST_CLASS_MIGHTY_MAJIN", "大魔人")
		6: return DBOLocalizer.get_text("GUI", "DST_CLASS_WONDER_MAJIN", "意魔人")
	return DBOLocalizer.get_text("GUI", "DST_CLASS_HUMAN_FIGHTER", "武道家")


## 居中 1024x768 虚拟画布与原版对齐
func _apply_responsive_layout() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var iWidth: float = vp_size.x
	var iHeight: float = vp_size.y
	if iWidth <= 0.0 or iHeight <= 0.0:
		return

	var iButtonCenterX: float = iWidth / 2.0
	if is_instance_valid(left_rot_btn):
		left_rot_btn.position = Vector2(iButtonCenterX - 206.0, iHeight - 194.0)
	if is_instance_valid(right_rot_btn):
		right_rot_btn.position = Vector2(iButtonCenterX + 150.0, iHeight - 194.0)

	# 创角面板固定吸附在右侧，底部输入栏居中
	if is_instance_valid(part_panel):
		part_panel.position = Vector2(iWidth - 230.0, 40.0)
	if is_instance_valid(name_back):
		name_back.position = Vector2(iButtonCenterX - 151.0, iHeight - 88.0)
	if is_instance_valid(return_btn):
		return_btn.position = Vector2(iWidth - 165.0, iHeight - 75.0)