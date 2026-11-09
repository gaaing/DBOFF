# GDScript 作用域重名变量导致 62 个 Parse Errors 崩溃故障根除报告

## 1. 故障现象与根本原因

### 1.1 错误截图分析
用户在 Godot 4.7.2 编辑器中运行工程时，控制台抛出 62 个 Parser Errors：
- 核心首发报错：
  `res://src/entities/character_visual.gd:944 - Parse Error: There is already a variable named "is_underwear" declared in this scope.`
- 级联连锁报错：
  - `character_factory.gd:142: Could not parse global class "DBOCharacterVisual" from "res://src/entities/character_visual.gd"`
  - `character_lobby_stage.gd:144: Could not resolve external class member "equip_item_to_character"`
  - `player_controller_3d.gd:98: Could not resolve external class member "load_character_animations"`
  - `character_factory.gd:655: Cannot infer the type of "skeleton" variable because the value doesn't have a set type.`

### 1.2 根因定位 (GDScript 2.0 作用域规则)
在 Godot 4 的 GDScript 2.0 中：
- 函数作用域是扁平的。即使在不同的 `if/elif/else` 分支内部，只要在同一个函数体内使用 `var <name>` 重复声明相同的变量名，编译器就会抛出致命错误：`There is already a variable named "..." declared in this scope.`；
- 一旦核心全局脚本（如 `class_name DBOCharacterVisual`）产生语法解析错误，Godot 会直接注销该全局类，引发所有依赖此类的外部脚本出现多达数十个连锁的类未解析错误（Parser Errors）。

---

## 2. 详细整改与修复清单

### 2.1 `src/entities/character_visual.gd`
1. **彻底消除 `is_underwear` 重复声明**：
   - line 724: 保持布尔属性标记 `var is_underwear := ("pants000" in mat_name ...)`；
   - line 944: 将分支判断变量更名为 `var is_underwear_mesh := ("pants000" in mat_name or "underwear" in mat_name or is_underwear)`，并在 line 957 使用 `elif is_underwear_mesh:`。
2. **提取可复用材质与变量至函数作用域顶部**：
   - 在 `apply_character_customization` 循环外部声明：
     ```gdscript
     var smat: ShaderMaterial = null
     var umat: StandardMaterial3D = null
     var cmat: StandardMaterial3D = null
     var nmat: StandardMaterial3D = null
     var skin_tex: Texture2D = null
     var arm_path := ""
     var pfx := ""
     var stex_path := ""
     var gender_code_str := "f" if c_gender == 1 else "m"
     ```
   - 消除各分支内重复的 `var smat :=`, `var umat :=`, `var cmat :=`, `var nmat :=` 等。
3. **修复已穿戴外装刷新块中的变量遮蔽**：
   - 将 line 1068 的 `target_skin_col` 与 line 1070 的 `smat`、line 1074 的 `skin_mat` 二次声明修改为独立变量名 `part_target_skin_col`, `part_mat`, `part_skin_mat`。
4. **修复静态贴图解析函数中的变量冲突**：
   - 在 `_resolve_child_boots_texture` 中提取 `var is_female` 与 `var gender_code` 到函数开头；
   - 在 `_resolve_child_pants_texture` 中提取 `var gender_code` 到函数开头。

### 2.2 `src/entities/character_factory.gd`
1. **提升 `joint_names` 与 `smat` 声明至函数顶部/分支外部**：
   - 之前因将 `joint_names` 放在 `if own_skin` 分支内，导致第 798 行 `slot_name == "torso"` 分支无法访问该变量（报 `Identifier "joint_names" not declared in the current scope`）。现将 `var joint_names := get_glb_joint_names(glb_path)` 提升至部件挂载逻辑顶部，全作用域共享；
   - 之前因在 `elif slot_name == "torso"` 内部局部声明 `var smat`，导致平行的 `else:` 分支访问未声明的 `smat`（报 `Identifier "smat" not declared in the current scope`）。现将 `var smat: Material = null` 提至材质分发循环外部单一声明，且显式注解类型 `var m_name: String`，完全消除类型推断失败与未声明错误；
2. 修复 `load_character_animations` line 405 的 `b_idx` 重复声明，更名为 `bip_bone_idx`；
3. 修复 `_apply_majin_jacket_materials` line 1088 的 `tex` 重复声明，更名为 `item_tex`；
3. 消除 line 798 `joint_names`、line 868 `smat` 的重复声明。

### 2.3 全工程潜在 Duplicate Vars 彻底清理
静态扫描并修复了全工程以下文件中的同函数内多次 `var` 声明：
- `src/core/audio_manager.gd`: line 172 `res` 重命名为 `default_res`；
- `src/core/dbo_inventory_manager.gd`: line 82-83 胶囊盒循环变量更名为 `kit_tblidx`, `kit_pos`；
- `src/ui/dbo_ui_manager.gd`: line 45-48 `_load_dictionaries` 变量更名为 `l_file`, `l_json_text`, `l_parsed`；
- `src/ui/lobby/character_lobby_ui.gd`: line 385-398 左右按钮声明区分 `l_hc/r_hc`, `l_fc/r_fc`, `l_sk/r_sk`；
- `src/world/world_prop_manager.gd`: line 71-74 动画变量更名为 `ext_anim_list`, `ext_first_anim`, `ext_anim`，line 131 场景变量更名为 `a_scene`；
- `src/world/world_spawn_manager.gd`: line 68-76 NPC 刷新表变量更名为 `npc_file`, `n_loc`, `nx`, `nz`, `n_cell`。

---

## 3. 验收结果

- **全项目脚本扫描**：`src/` 目录下所有 GDScript 文件目前已实现 **0 duplicate local variables**；
- **Godot 编译器恢复**：`character_visual.gd` 不再产生任何语法解析中断，`DBOCharacterVisual` 成功恢复全局类注册；
- **级联报错解除**：原控制台中的 62 个 Parser Errors 全部消失，创角大厅与场景完全恢复正常加载与运行。
