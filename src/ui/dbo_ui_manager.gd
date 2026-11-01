extends Node

## DBO UI Manager & Dynamic Layout Builder
## 统一管理 .srf（切片坐标）、.rsr（资源纹理）与 .frm（布局组件）映射表。
## 自动根据 ui_layout_dictionary.json 与 ui_atlas_dictionary.json 原生坐标与切片装配控件。

enum UIStyleMode {
	CLASSIC_BITMAP,
	MODERN_VECTOR
}

signal ui_style_changed(mode: UIStyleMode)

var current_style_mode: UIStyleMode = UIStyleMode.CLASSIC_BITMAP

var _atlas_dict: Dictionary = {}
var _layout_dict: Dictionary = {}
var _texture_cache: Dictionary = {}
var _atlas_cache: Dictionary = {}

const ATLAS_DICT_PATH: String = "res://assets/gui/ui_atlas_dictionary.json"
const LAYOUT_DICT_PATH: String = "res://assets/gui/ui_layout_dictionary.json"
const GUI_TEX_DIR: String = "res://assets/tex/texture/gui/"
const GUI_DIR: String = "res://assets/gui/"


func _ready() -> void:
	_load_dictionaries()


func _load_dictionaries() -> void:
	if not _atlas_dict.is_empty():
		return

	if FileAccess.file_exists(ATLAS_DICT_PATH):
		var file := FileAccess.open(ATLAS_DICT_PATH, FileAccess.READ)
		if file:
			var json_text := file.get_as_text()
			var parsed = JSON.parse_string(json_text)
			if parsed is Dictionary:
				_atlas_dict = parsed
			file.close()

	if FileAccess.file_exists(LAYOUT_DICT_PATH):
		var file := FileAccess.open(LAYOUT_DICT_PATH, FileAccess.READ)
		if file:
			var json_text := file.get_as_text()
			var parsed = JSON.parse_string(json_text)
			if parsed is Dictionary:
				_layout_dict = parsed
			file.close()


func set_ui_style_mode(mode: UIStyleMode) -> void:
	if current_style_mode != mode:
		current_style_mode = mode
		ui_style_changed.emit(current_style_mode)
		if Engine.has_singleton("DBOEventBus"):
			var bus = Engine.get_singleton("DBOEventBus")
			if bus:
				bus.ui_style_changed.emit(int(current_style_mode))


func get_ui_style_mode() -> UIStyleMode:
	return current_style_mode


func get_srf_entry(surface_name: String) -> Dictionary:
	if _atlas_dict.is_empty():
		_load_dictionaries()
	var key := surface_name.strip_edges()
	if _atlas_dict.has(key):
		return _atlas_dict[key]
	var lower_key := key.to_lower()
	if _atlas_dict.has(lower_key):
		return _atlas_dict[lower_key]
	return {}


func get_srf_rect(surface_name: String, fallback: Rect2 = Rect2()) -> Rect2:
	var entry := get_srf_entry(surface_name)
	if entry.has("rect"):
		var r: Array = entry["rect"]
		if r.size() >= 4:
			return Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
	return fallback


func get_srf_texture(surface_name: String, fallback_tex: Texture2D = null) -> Texture2D:
	var entry := get_srf_entry(surface_name)
	var tex_file: String = entry.get("texture", "")
	if tex_file.is_empty():
		return fallback_tex

	if _texture_cache.has(tex_file):
		return _texture_cache[tex_file]

	var p1 := GUI_TEX_DIR + tex_file
	var p2 := GUI_DIR + tex_file
	var tex: Texture2D = null
	if ResourceLoader.exists(p1):
		tex = load(p1) as Texture2D
	elif ResourceLoader.exists(p2):
		tex = load(p2) as Texture2D
	elif fallback_tex:
		tex = fallback_tex

	if tex:
		_texture_cache[tex_file] = tex
	return tex if tex else fallback_tex


func create_atlas(surface_name: String, fallback_rect: Rect2 = Rect2(), fallback_tex: Texture2D = null) -> AtlasTexture:
	if surface_name.is_empty():
		return null
	var cache_key := "%s_%s" % [surface_name, str(fallback_rect)]
	if _atlas_cache.has(cache_key):
		return _atlas_cache[cache_key]

	var rect := get_srf_rect(surface_name, fallback_rect)
	var tex := get_srf_texture(surface_name, fallback_tex)
	if tex == null:
		tex = fallback_tex

	if tex == null:
		return null

	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = rect
	_atlas_cache[cache_key] = atlas
	return atlas


func apply_texture_button_states(
	btn: TextureButton,
	normal_srf: String,
	hover_srf: String = "",
	pressed_srf: String = "",
	disabled_srf: String = "",
	fallback_tex: Texture2D = null
) -> void:
	if not normal_srf.is_empty():
		btn.texture_normal = create_atlas(normal_srf, Rect2(), fallback_tex)
	if not hover_srf.is_empty():
		btn.texture_hover = create_atlas(hover_srf, Rect2(), fallback_tex)
	if not pressed_srf.is_empty():
		btn.texture_pressed = create_atlas(pressed_srf, Rect2(), fallback_tex)
	if not disabled_srf.is_empty():
		btn.texture_disabled = create_atlas(disabled_srf, Rect2(), fallback_tex)


## 根据 .frm 布局文件自动装配并实例化原生界面的完整树结构
func build_frm_window(frm_name: String) -> Control:
	if _layout_dict.is_empty():
		_load_dictionaries()

	var f_key := frm_name.to_lower()
	if not _layout_dict.has(f_key):
		push_warning("[DBOUIManager] 布局字典中未收录此 frm: " + frm_name)
		return null

	var comps: Dictionary = _layout_dict[f_key]
	var root := Control.new()
	root.name = frm_name.get_basename()

	# 1. 查找窗口主底板 (dlgMain / dlgmain)
	var main_dlg: Dictionary = comps.get("dlgMain", comps.get("dlgmain", {}))
	if not main_dlg.is_empty():
		var mw := float(main_dlg.get("width", 0))
		var mh := float(main_dlg.get("height", 0))
		if mw > 0 and mh > 0:
			root.custom_minimum_size = Vector2(mw, mh)
			root.size = Vector2(mw, mh)
		var srf_name: String = main_dlg.get("surface", "")
		if not srf_name.is_empty():
			var bg := TextureRect.new()
			bg.name = "DialogBg"
			bg.texture = create_atlas(srf_name)
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			root.add_child(bg)

	# 2. 依次生成所有组件
	for comp_name in comps.keys():
		if comp_name.to_lower() == "dlgmain":
			continue

		var data: Dictionary = comps[comp_name]
		var type: String = data.get("type", "").to_lower()
		var node: Control = null

		match type:
			"button":
				var btn := TextureButton.new()
				apply_texture_button_states(
					btn,
					data.get("surface_up", ""),
					data.get("surface_focus", ""),
					data.get("surface_down", ""),
					data.get("surface_disable", "")
				)
				node = btn
			"staticbox":
				var lbl := Label.new()
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if data.get("text_style", "") == "center" else HORIZONTAL_ALIGNMENT_LEFT
				lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				node = lbl
			"inputbox":
				var le := LineEdit.new()
				le.max_length = int(data.get("maxlength", 20))
				node = le
			"panel":
				var pnl := TextureRect.new()
				var srf: String = data.get("surface", "")
				if not srf.is_empty():
					pnl.texture = create_atlas(srf)
				node = pnl

		if node:
			node.name = comp_name
			node.position = Vector2(float(data.get("x", 0)), float(data.get("y", 0)))
			var w := float(data.get("width", 0))
			var h := float(data.get("height", 0))
			if w > 0 and h > 0:
				node.size = Vector2(w, h)
			root.add_child(node)

	return root