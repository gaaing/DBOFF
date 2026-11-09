# 幼年角色下装与双脚正常渲染修复报告

## 1. 用户反馈与问题定位

### 1.1 问题描述
用户反馈截图显示：人类幼年角色上衣穿戴正常，但下半身长裤与鞋靴完全隐形，只剩下一条白色的底裤（三角内裤）悬空浮在地面上，双腿与双脚全部断肢消失。
用户询问：“是因为你只重新导出了上衣没导出裤子和鞋子吗？”

### 1.2 资产与技术根因调查
1. **模型导出核查**：
   - 检查 `assets/obj/item/mesh_armor_humanmale/`，所有下装模型（如 `a_hfi_04_01_p_h_m.glb`）与鞋靴模型（如 `a_hfi_04_01_b_h_m.glb`）**均完整存在且三角面/法线无损**；
2. **底层设计原理与误判根源**：
   - 在 OpenDBO 中，幼年角色（Child）素体网格（如 `a_hch_h_m.glb`）自身已内置了专属的真双腿长裤（Primitive 3，`A_HFI_M_pants_skin`）、底裤（Primitive 4，`A_HUM_M_pants000`）和真双脚靴子（Primitive 2，`A_HFI_M_boots001`）；
   - 在 `character_factory.gd` 中，幼年角色穿戴下装与鞋靴时，将模型路径记录在 `equipped_glb_paths` 中，避免成人单侧模型因逆绑定矩阵不匹配导致甩飞插脖；
   - **核心 Bug**：`character_visual.gd` 的 `apply_character_customization` 在判断穿装状态时，直接使用了：
     ```gdscript
     var has_legs := (_slots.get("legs") != null)
     var has_feet := (_slots.get("feet") != null)
     ```
     由于幼年素体没有向 `_slots["legs"]` 挂接独立的外部 Mesh 节点，导致 `has_legs` 与 `has_feet` 被**误判为 false**；
3. **连锁错误逻辑**：
   - `has_legs == false` 导致程序误以为角色处于“脱光裤子”的状态：
     - 判定底裤（Primitive 4）需要显示，加载并渲染了白色三角底裤；
     - 判定裤子表面（Primitive 3）未穿外裤，直接执行 `mesh_inst.set_surface_override_material(s, inv_mat)` 设为完全透明隐形！
   - `has_feet == false` 同样将双脚靴子（Primitive 2）设为 `inv_mat` 隐形！
   - 最终导致画面呈现出“只有一条白色底裤悬空浮在天上，裤子和腿脚完全消失”的严重视觉破坏。

---

## 2. 修复措施

### 2.1 穿装状态判断补全 (`character_visual.gd`)
将装备判定条件升级为同时支持外部槽位节点与装备路径记录：
```gdscript
var has_torso := (_slots.get("torso") != null) or (equipped_glb_paths.has("torso") and not str(equipped_glb_paths.get("torso", "")).is_empty())
var has_legs := (_slots.get("legs") != null) or (equipped_glb_paths.has("legs") and not str(equipped_glb_paths.get("legs", "")).is_empty())
var has_hands := (_slots.get("hands") != null) or (equipped_glb_paths.has("hands") and not str(equipped_glb_paths.get("hands", "")).is_empty())
var has_feet := (_slots.get("feet") != null) or (equipped_glb_paths.has("feet") and not str(equipped_glb_paths.get("feet", "")).is_empty())
```

### 2.2 裤子与双脚表面材质派发逻辑归正
1. **穿裤状态（`has_legs == true`）**：
   - Surface 4（底裤）：设为 `inv_mat` 自动隐蔽；
   - Surface 3（长裤）：动态加载对应职业长裤贴图（武道家绿长裤、气功师袍裤、机械师工装裤等），以 `cull_mode = CULL_DISABLED` 双面饱满渲染，彻底解决背向透视与隐形问题；
2. **脱裤状态（`has_legs == false`）**：
   - Surface 4（底裤）：加载各族底裤贴图正常显示；
   - Surface 3（裸腿）：加载裸腿皮肤贴图（`a_hfi_m_pants_skin.png` 等）并通过 `CHARACTER_SKIN_SHADER` 皮肤着色器正常显示双腿肉色，**绝不隐形**，杜绝断肢；
3. **双脚靴子渲染保障**：
   - 穿鞋状态（`has_feet == true`）：加载对应职业鞋靴贴图，双面饱满渲染；
   - 赤足状态（`has_feet == false`）：通过皮肤着色器正常渲染原生双脚，脚掌永远可见。

### 2.3 那美克星人裤子贴图路径纠正
修正了 `_resolve_child_pants_texture` 中那美克星人裤子贴图路径：
- 将多余的 `_m_`（`a_nfi_m_pants04_01.png`）修正为真实的 `a_nfi_pants04_01.png` 与 `a_nmy_pants04_01.png`。

---

## 3. 验收标准
- 创角大厅与场景中的全职业全种族角色：
  - 穿戴新手下装时：正常显示各职业完整长裤与靴子，底裤自动隐形；
  - 脱下装备时：正常显示底裤与裸腿皮肤、裸足皮肤，绝不出现截断悬空。
