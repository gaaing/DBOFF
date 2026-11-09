# 角色装备与素体全职业动态适配修复完整技术报告

## 1. 目标清单与完成进度

| 编号 | 目标任务项 | 状态 | 详细说明 |
| :--- | :--- | :---: | :--- |
| **T-1** | 修复“素体脚丢失且鞋子插在脖子里”的数学与绑定缺陷 | [x] 100% | 幼年期角色防具槽位不挂载成人单侧网格，直接采用内建对称双脚网格并加载职业贴图；成人单侧鞋靴在内存中以 $X=0$ 镜像补全左脚与三角形绕序。 |
| **T-2** | 修复“裤子模型只能看见内部贴图看不见表面贴图”的问题 | [x] 100% | 调整所有下装与长裤表面材质 `cull_mode = CULL_DISABLED`，彻底杜绝法线/绕序导致的单面背面剔除透视缺陷。 |
| **T-3** | 移除“人类气功师误穿武道家上衣”的硬编码，实现全职业动态匹配 | [x] 100% | 彻底移除 `a_hfi` 单向硬编码，根据 `character_class_id` 与装备数据动态分流（武道家 `A_HFI`、气功师 `A_HMY`、机械师 `A_HEN`、那美克全系、魔人全系）。 |
| **T-4** | 修复“护腕陷入手臂模型内部”的 Z-fighting 与穿模问题 | [x] 100% | 为上装衣服与护腕布料材质赋予 `render_priority = 1`，确保双手护腕在素体手臂皮肤上方清晰无穿透渲染。 |
| **T-5** | 创角界面预览动态搭载各职业官方初始新手装备 | [x] 100% | 创角界面预览切换职业时，自动通过 `DBOSaveManager.get_newbie_starter_items` 实时加载并穿戴对应职业的新手服饰。 |

---

## 2. 用户上传 6 张参考截图对照与根因剖析

针对用户上传的 6 张角色状态对比截图，底层物理数学与渲染根因剖析如下：

1. **图 1（白模手臂 + 单侧右靴）**：
   - 上装装备原版 DFF 包含了成人裸露皮肤面，当剔除不完整或未派发正确皮肤着色器时，产生未赋予纹理的纯白模型；且外挂鞋靴原版仅有右脚，左脚缺失。
2. **图 2（上装拉扯至下巴与面部）**：
   - 代码曾尝试将成人装备的 Skin 绑定姿态直接替换为幼年骨骼 Rest Pose（$bp = \text{ChildRestPose}^{-1}$）。在 Godot 蒙皮着色器计算中：$M = \text{ChildBonePose} \times \text{ChildRestPose}^{-1} = I$。由于成人上装原始顶点本身建模高度在 $Y \in [0.8, 1.4]$ 米，直接作用于仅 $1.0$ 米高的幼年骨骼时，衣服胸肩直接被拔高套到了幼年角色的嘴巴与下巴上。
3. **图 3（上装下坠拖地至脚踝）**：
   - 沿用成人绑定逆矩阵（$\text{AdultRestPose}^{-1}$）时，因成人腿长与骨盆高度（$0.887\text{m}$）与幼年（$0.576\text{m}$）存在 $-0.31\text{m}$ 巨大落差，顶点被向下拽向地面堆积在脚踝处。
4. **图 4（那美克星人胸肩变形）**：
   - 那美克星人胸部与锁骨骨骼命名和人类差异较大，部分骨骼映射回退错误导致顶点着色器骨骼矩阵不连续撕裂。
5. **图 5（无护腕与单侧鞋）**：
   - 素体手臂皮肤与上衣自带护腕在同一半径重叠，且没有给装备赋予优先绘制层级，护腕完全陷没在素体手臂网格之下。
6. **图 6（武道家成功附着但存在多重缺陷）**：
   - 上衣成功贴合身体且双腕护腕正确展现，但暴露出了以下关键新问题：
     - **素体双脚丢失、成人右鞋插在脖子上**：装备鞋靴（`has_feet = true`）触发了 `mesh_inst.set_surface_override_material(s, inv_mat)`，将幼年素体原生的 Prim 2 与 Prim 4 真实双脚隐藏；而外挂的成人单侧右鞋由于骨骼逆矩阵高度与角度不符，被甩飞旋转插进角色脖子锁骨处。
     - **裤子模型内可见、外不可见**：材质背面剔除（`CULL_BACK`）导致正面被剔除，只有反面内壁可见。
     - **人类气功师误穿武道家上衣**：创角预览未动态分发职业装备，且手臂贴图硬编码为 `a_hfi`。

---

## 3. 本次全面修复的技术实施细节

### 3.1 幼年期与成年期鞋靴/下装分流机制 (`character_factory.gd`)
- 在 `equip_item_to_character` 中，针对幼年期角色（`not is_adult`）：
  - 当穿戴槽位为 `feet` 或 `legs` 时，**绝不挂载外部单侧成人物理网格**，清除旧外挂节点并记录 `equipped_glb_paths`。
  - 随后直接调用 `visual.apply_character_customization()`，交由素体内建的高精原生网格进行全职业贴图渲染。
  - 从物理根源杜绝成人单侧鞋靴飞甩插脖子与素体真实双脚消失的现象。

### 3.2 幼年期素体双脚与下装双面高保真渲染 (`character_visual.gd`)
- 查验各族幼年素体 GLB 结构，证实其原生内建且对称绑定了双脚（Prim 2 & 4）与脚踝绑带（Prim 3 & 5）、长裤（Prim 7）与底裤（Prim 6）。
- 建立表面顶点数与材质类型判定规则：
  - **鞋靴（`is_boots`）**：
    - 当 `has_feet` 为真：显示原生双脚（Prim 2 & 4），调用 `_resolve_child_boots_texture` 分发职业鞋靴贴图，材质设置 `cull_mode = CULL_DISABLED`。
    - 当 `has_feet` 为假（裸足）：隐藏鞋靴（Prim 2 & 4 设为 `inv_mat`），显示原生脚踝绑带（Prim 3 & 5）。
  - **下装（`is_pants`）**：
    - 顶点数 $\le 80$（脚踝裸足绑带）：穿鞋时设为 `inv_mat` 避免穿模，脱鞋时正常显示。
    - 顶点数 $> 80$ 且为 `pants000`（底裤）：穿裤时设为 `inv_mat`，脱裤裸身时显示底裤。
    - 顶点数 $> 80$ 且为 `pants_skin`（长裤）：穿裤时调用 `_resolve_child_pants_texture` 加载对应职业长裤贴图，设置 `cull_mode = CULL_DISABLED`；脱裤裸身时设为 `inv_mat`。

### 3.3 护腕穿模修复与渲染优先级提升 (`character_factory.gd`)
- 上衣装配网格（`Part_Torso`）包含了背心外套与双手护腕。
- 将上衣布料材质设置 `cloth_mat.render_priority = 1` 与 `cull_mode = BaseMaterial3D.CULL_DISABLED`，确保护腕在 GPU 渲染管线中始终位于素体手臂裸皮（Priority 0）上方绘制，彻底杜绝护腕陷入手臂内部与 Z-fighting 闪烁。

### 3.4 彻底废除人类职业单向硬编码 (`character_visual.gd` & `character_lobby_ui.gd`)
- 在 `character_visual.gd` 中：
  - 移除对 `a_hfi` 的硬编码，根据 `character_class_id` 分流加载皮肤与服装：
    - 人类气功师（Class 1）：动态加载 `a_hmy_m_jacket_skin.png` 与 `a_hmy` 系列装备。
    - 人类机械师（Class 2）：动态加载 `a_hen` 系列皮肤与装备。
    - 人类武道家（Class 0）：动态加载 `a_hfi` 系列皮肤与装备。
    - 那美克战士/魔导士（Class 3/4）：动态分发 `a_nfi` / `a_nmy` 系列皮肤。
    - 魔人大魔人/意魔人（Class 5/6）：动态分发 `a_mmi` / `a_mwo` 系列皮肤。
- 在 `character_lobby_ui.gd` 中：
  - `_update_avatar_preview()` 切换职业时，直接调用 `DBOSaveManager.get_newbie_starter_items(cur_race, actual_class)`，创角预览即刻动态穿戴对应职业的专属新手道服、气功袍或工装。

### 3.5 成人期单侧鞋靴对称镜像算法 (`character_factory.gd`)
- 在 `_repair_equipment_left_side_bones` 中，检测到鞋靴顶点集中在 $X > -0.05$（单侧右鞋）时：
  - 复制所有顶点，沿 $X$ 轴镜像反转：$x' = -x$，$n_x' = -n_x$。
  - 三角形绕序反转：$(i_0, i_1, i_2) \to (i_0, i_2, i_1)$，确保法线正确朝外。
  - 骨骼重映射：右大腿(18) $\to$ 左大腿(12)、右小腿(19) $\to$ 左小腿(13)、右脚掌(22) $\to$ 左脚掌(16)、右脚趾(23) $\to$ 左脚趾(17)。
  - 生成兼具左右双脚的完整对称鞋靴网格。

---

## 4. 涉及文件改动汇总

1. `src/entities/character_visual.gd`:
   - 新增 `_resolve_child_boots_texture()` 与 `_resolve_child_pants_texture()` 函数。
   - 彻底优化 `apply_character_customization` 中的 `is_boots`、`is_pants`、`is_jacket` 逻辑，幼年期永不隐藏素体真双脚，全面支持全职业全种族贴图动态加载与双面渲染。
2. `src/entities/character_factory.gd`:
   - 在 `equip_item_to_character` 增加幼年期防具分流（`not is_adult and slot_name in ["feet", "legs"]` 不挂载外部成人单侧网格）。
   - 优化上装布料材质 `render_priority = 1` 解决护腕陷入手臂问题。
   - 重构 `_repair_equipment_left_side_bones` 中的单侧靴子对称镜像与绕序算法。
3. `src/ui/lobby/character_lobby_ui.gd`:
   - `_update_avatar_preview()` 动态挂载各职业新手初始装备，彻底解决气功师等职业服饰预览错误。
4. `src/ui/lobby/character_lobby_stage.gd`:
   - 保证 `visual.character_class_id` 在应用定制前正确更新。
5. `src/entities/player_controller_3d.gd` & `src/world/world_scene_driver.gd`:
   - 大世界玩家实例同步绑定 `class_id`，保持大世界与创角界面外观一致性。
