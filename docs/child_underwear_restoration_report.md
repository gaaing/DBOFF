# 创角大厅素体内衣/底裤表面可见性修复报告

## 1. 目标清单与完成进度

- [x] **根因定位与排查**：定位创角大厅中 5 个儿童素体（人类男童、人类女童、那美克儿童、魔人男童、魔人女童）底裤表面被覆写为隐形材质 (`_invisible_mat`) 的具体逻辑分支。
- [x] **底裤显隐判定逻辑解耦**：
  - 移除原逻辑中误设的 `not is_adult` 强制隐藏条件。
  - 将内衣/底裤与外装的互斥判定重构为独立精准对应：`pants000` 仅在穿戴外裤（`has_legs`）时隐藏；`jacket000` 仅在穿戴上衣外装（`has_torso`）时隐藏。
  - 严禁影响已完备的多表面发型切换（Hair 01~10、发饰与超赛）、五官面部着色器替换与裸露皮肤色调着色器。
- [x] **底裤原生高清材质与回退保障**：
  - 在 [`src/entities/character_visual.gd`](file:///e:/DBOFF/src/entities/character_visual.gd) 中为未穿外装的素体生成不透明且背面剔除的标准材质（`StandardMaterial3D`，`Color.WHITE`，粗糙度 0.65）。
  - 新增 `_resolve_underwear_texture()` 映射函数，直接对标官方解包材质目录提取对应族群的原生底裤/内衣贴图（如 `a_hum_m_pants000.png`、`a_nam_pants000.png` 等），杜绝材质丢失或空网格现象。
- [x] **Godot 4 引擎无头运行验证**：
  - 完整执行创角舞台生命周期，退出码为 0，零红字报错。

---

## 2. 根因分析

在之前的素体装备隐藏重构过程中，`character_visual.gd` 的 `_update_base_body_visibility` 与 `apply_character_customization` 误引入了如下判断：
```gdscript
# 修复前存在的问题逻辑：
var is_wearing_outerwear := has_legs or has_torso or not is_adult
if is_wearing_outerwear:
    mesh_inst.set_surface_override_material(s, inv_mat)
```
由于创角大厅中素体为童年形态（`is_adult == false`），`not is_adult` 恒为 `true`，导致 5 个儿童素体的 `pants000`（以及女童与魔人女童的 `jacket000`）表面被全部赋予完全透明材质 `inv_mat`（`Color(0, 0, 0, 0)`），导致骨盆至大腿根部网格直接消失并露出空白孔洞。

---

## 3. 修复方案

1. **解耦判定**：
   - 当表面属于底裤（`pants000`）时，仅在穿戴下装外装（`has_legs == true`）时隐藏。
   - 当表面属于内衣（`jacket000`）时，仅在穿戴上装外装（`has_torso == true`）时隐藏。
   - 无外装状态下，强制渲染原生底裤，绝不隐形。
2. **材质保真与皮肤隔离**：
   - 将 `is_skin` 排除在 `is_jacket` / `is_pants` 之外，避免身体裸露皮肤表面被误当成装备覆盖，确保那美克星人肌肉条纹与各族肤色 Shader 保持完好。
   - 保证烘焙的多材质发型（`mat_hair_XX`）与超级赛亚人表面不受任何干扰。
