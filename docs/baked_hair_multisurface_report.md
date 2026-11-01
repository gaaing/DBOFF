# 烘焙发型表面多材质无缝切换与超级赛亚人形态技术实现报告

## 1. 目标清单与完成进度

- [x] **基准对齐与空间换算**：以 5 个儿童素体自带 1 号发型（Hair 01）为 100% 绝对空间轮廓基准，提取骨骼头顶局部变换矩阵。
- [x] **全素体发型模型烘焙 (Multi-surface Baking)**：
  - [x] 人类男童 (`human_m_child.glb`)：内嵌 1~10 号发型表面 + `mat_hair_ssj` 超级赛亚人发型表面。
  - [x] 人类女童 (`human_f_child.glb`)：内嵌 1~10 号发型表面（含发饰独立表面） + `mat_hair_ssj` 超级赛亚人发型表面。
  - [x] 那美克儿童 (`namek_m_child.glb`)：内嵌 1~10 号触角/头部特征表面。
  - [x] 魔人男童 (`majin_m_child.glb`)：内嵌 1~10 号头顶触角表面。
  - [x] 魔人女童 (`majin_f_child.glb`)：内嵌 1~10 号发辫/触角表面。
  - [x] 人类成年男 (`a_hum_m_ad.glb`)：内嵌 1~10 号发型表面 + `mat_hair_ssj` 超级赛亚人发型表面。
  - [x] 人类成年女 (`a_hum_f_ad.glb`)：内嵌 1~10 号发型表面（含发饰独立表面） + `mat_hair_ssj` 超级赛亚人发型表面。
  - [x] 那美克成年 (`a_nam_ad.glb`)：内嵌 1~10 号触角特征表面。
  - [x] 魔人成年男 (`a_maj_m_m.glb`)：内嵌 1~10 号触角特征表面。
  - [x] 魔人成年女 (`a_maj_m_f_ad.glb`)：内嵌 1~10 号特征表面。
- [x] **五官表面 (Face) 规范**：五官使用既有 `fskin` UV 表面配合 `CHARACTER_FACE_SHADER` 动态替换纹理，保持纯净，不在网格中冗余烘焙多重脸型。
- [x] **代码端 0 开销隐形材质切换 (Material Swapping)**：
  - [x] [`src/entities/character_visual.gd`](file:///e:/DBOFF/src/entities/character_visual.gd) 实现基于材质名称 (`mat_hair_XX`) 的智能识别与表面覆写。
  - [x] 非激活发型表面赋予 `_invisible_mat`（通道全剔除、零渲染开销）。
  - [x] 激活发型表面绑定标准染色材质，发饰表面保持默认白色。
  - [x] 超级赛亚人形态 (`set_super_saiyan`) 激活 `mat_hair_ssj` 表面并赋予高亮金发发光材质。
- [x] **Godot 4.7.2 编译与运行验证**：
  - [x] Godot 无头编译执行退出码 0，无红字报错，无 Parse/Compile Error。

---

## 2. 烘焙空间基准与参数对齐矩阵

各素体合并烘焙时计算的绝对空间对齐参数如下：

| 素体 GLB | 目标发型总数 | 额外表面 | 烘焙缩放因子 (Scale) | 相对偏移 (Offset: X, Y, Z) | 挂接骨骼 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `human_m_child.glb` | 10 | `mat_hair_ssj` | [1.48, 1.48, 1.48] | [0.010, -1.079, 0.019] | `Bip01 Head` (Joint 0) |
| `human_f_child.glb` | 10 | `mat_hair_ssj`, `_acc` | [1.438, 1.401, 1.448] | [0.008, -0.754, 0.026] | `Bip01 Head` (Joint 0) |
| `namek_m_child.glb` | 10 | 无 | [1.50, 1.50, 1.50] | [0.010, -1.483, 0.037] | `Bip01 Head` (Joint 0) |
| `majin_m_child.glb` | 10 | 无 | [0.95, 0.95, 0.95] | [0.000, -0.449, -0.008] | `Bip01 Head` (Joint 0) |
| `majin_f_child.glb` | 10 | 无 | [1.15, 1.15, 1.15] | [0.000, -0.632, 0.015] | `Bip01 Head` (Joint 0) |
| `a_hum_m_ad.glb` | 10 | `mat_hair_ssj` | [1.0, 1.0, 1.0] | [0.0, 0.0, 0.0] | `Bip01 Head` (Joint 0) |
| `a_hum_f_ad.glb` | 10 | `mat_hair_ssj`, `_acc` | [1.0, 1.0, 1.0] | [0.0, 0.0, 0.0] | `Bip01 Head` (Joint 0) |
| `a_nam_ad.glb` | 10 | 无 | [1.0, 1.0, 1.0] | [0.0, 0.0, 0.0] | `Bip01 Head` (Joint 0) |
| `a_maj_m_m.glb` | 10 | 无 | [1.0, 1.0, 1.0] | [0.0, 0.0, 0.0] | `Bip01 Head` (Joint 0) |
| `a_maj_m_f_ad.glb` | 10 | 无 | [1.0, 1.0, 1.0] | [0.0, 0.0, 0.0] | `Bip01 Head` (Joint 0) |

---

## 3. 运行管线与代码实现

在 [`src/entities/character_visual.gd`](file:///e:/DBOFF/src/entities/character_visual.gd) 中，创角与角色生成时的发型切换直接在模型的主表面材质槽位上执行：

1. **识别材质槽位**：
   ```gdscript
   var is_hair_slot := mat_name.begins_with("mat_hair_")
   ```
2. **状态判定**：
   - 超级赛亚人状态下：`mat_hair_ssj` 为激活状态，其余所有常规发型表面（`mat_hair_01` 至 `mat_hair_10`）均隐藏。
   - 常规状态下：仅 `mat_hair_%02d`（及对应 `_acc` 发饰表面）激活，其余常规发型表面与 `mat_hair_ssj` 均赋予 `_invisible_mat` 隐藏。
3. **着色与材质覆盖**：
   - 激活发型表面覆写基础着色器或 `StandardMaterial3D`，应用从 `default_item_list.json` 读取的官方全种族 RGB 颜色。
   - `mat_hair_ssj` 表面激活时，着色为赛亚人经典金黄发色 `Color(1.0, 0.88, 0.35)` 并开启发光 (Emission)。
   - 隐藏表面直接绑定 `_invisible_mat`，避免产生几何体 Draw Call 与像素光栅化开销。
