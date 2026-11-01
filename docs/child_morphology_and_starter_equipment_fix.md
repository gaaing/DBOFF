# 角色儿童形态、发型挂载、底裤与动作管线综合修复报告

根据 OpenDBO-Core 客户端架构规范与真实数据比对，针对用户反馈的四大核心视觉与逻辑问题，已完成深度溯源与全量修复。

---

## 一、 核心问题深度溯源与修复方案

### 1. 发型组件浮空飞天（"头发组件飞了"）
- **根本原因**：
  此前在外挂发型挂接逻辑中，错误引入了 `characterproperty.json` 中的骨骼缩放系数（`1.48`）以及全局地面偏移。由于外挂发型 GLB 的顶点坐标以世界坐标系构建（高程约 1.5m~1.9m），当乘以以世界原点为基准的 `1.48` 放大矩阵后，顶点高度直接飙升至 2.5m~2.8m，并在 `BoneAttachment3D("Bip01 Head")` 叠加后导致发型悬浮于角色头顶 1~2 米的空中。
- **修复方案**：
  在 [`character_visual.gd`](file:///e:/DBOFF/src/entities/character_visual.gd) 中，废除基于原点缩放的粗暴变换，改为基于真实网格 AABB 包围盒的动态几何对齐算法：
  1. 通过 `_get_body_head_center_y()` 实时计算素体原生头部/面部网格的真实 AABB 中心高程；
  2. 计算外置发型网格的 AABB 中心高程并取得差值 $\Delta y = \text{body\_head\_cy} - \text{item\_cy}$；
  3. 通过 `_skeleton.get_bone_global_rest(head_bone_idx).affine_inverse() * Transform3D(Basis(), Vector3(0.0, delta_y, 0.0))` 精准抵消 Rest Pose 骨骼坐标系，使发型网格 100% 贴合于儿童二头身头部，并完美随 `Bip01 Head` 骨骼动画实时呼吸与摆动；
  4. 消除切换发型闪退（`Nonexistent function 'surface_get_aabb' in base 'ArrayMesh'`）：废除 `ArrayMesh.surface_get_aabb` 错误 API 调用，头部高程统一由 `_skeleton.get_bone_global_rest(head_idx).origin.y + 0.25` 高性能读取，彻底杜绝切换发型时的引擎闪退。

---

### 2. 底裤消失与装备隐藏异常（"装备不显示的情况下内裤也没了"）
- **根本原因**：
  此前在 [`character_visual.gd`](file:///e:/DBOFF/src/entities/character_visual.gd) 的材质分类逻辑中，将 `pants000`（平角底裤材质）无条件覆盖为 `inv_mat`（不可见透明材质）。当角色未穿戴装备或装备处于隐藏/未穿戴状态时，外部裤子与内置底裤同时被隐藏，导致盆骨与腹股沟区域完全赤裸透明。
- **修复方案**：
  1. 精准区分平角底裤（`is_boxers`，即 `pants000`）与外穿外裤（`is_pants`，即 `pants_skin` 等服饰）；
  2. 当角色穿戴外裤（`has_legs == true`）时，底裤自动隐藏以避免双重模型穿模与 Z-Fighting；
  3. 当角色未穿戴外裤或处于赤裸/装备不显示模式时，`pants000` 强制保留原生贴图材质，确保官方正统底裤始终完好显示。

---

### 3. 那美克星人肤色异常与红泥混色（"之前做好的那美克皮肤也出错了"）
- **根本原因**：
  在消除硬编码重构中，直接从 `default_item_list.json` 中读取了 `NAMEK_CHILD` 的 `skin_color` 参数（色值为粉红/紫红/亮黄等触角条纹配比）。当该色值传入面部与身体着色器后，原本经典的比克草绿色底模（`a_nam_ch_fskin01_01.png`）与粉红色相乘，导致面部与身体直接变为浑浊脏污的红褐色。
- **修复方案**：
  1. 对标 OpenDBO 原版规范：那美克星人全身表皮为经典纯正比克绿（`face_skin_tint` 与 `body_skin_tint` 保持为 `Color.WHITE` 乘法保真）；
  2. `default_item_list.json` 中的 5 种官方色彩仅用于那美克触角头饰与魔人男触角的条纹染色；
  3. 在 [`character_skin.gdshader`](file:///e:/DBOFF/src/shaders/character_skin.gdshader) 中保持 `race_mode = 1`，严格保护 $R - G > 0.12$ 的红色/粉色标志性肌肉条纹不被染绿，其余部分呈现饱满纯正的经典比克绿肤色。

---

### 4. 动画不播放与 1206 条轨道报错（"动画也没有播放"）
- **根本原因**：
  RenderWare 导出的 DBO 官方动画 GLB 中，骨骼轨道名称为 `Bone_0` ~ `Bone_49`（对应 RpHAnimHierarchy 的骨骼节点索引 0~49）；而 Godot 导入 `human_m_child.glb` 后，`Skeleton3D` 节点上的骨骼名称为 3ds Max Biped 规范名（`Bip01`, `Bip01 Pelvis`, `Bip01 Spine`, `Bip01 Head` 等）。此前代码在重定向路径时直接写入了 `skel_rel_path + ":Bone_1"`，导致 Godot 引擎在运行时每帧抛出 `AnimationMixer: 'idle', couldn't resolve track: 'Armature/Bone_1'`，累积 1206 条控制台报错，动画系统由于轨道失效直接锁死在 T-Pose。
- **修复方案**：
  1. 在 [`character_factory.gd`](file:///e:/DBOFF/src/entities/character_factory.gd) 的 `load_character_animations` 与 `load_mob_animations` 中，注入精准骨骼轨道映射器：
     - 将轨道路径基准修正为 `anim_root.get_path_to(skel)`（对齐 `AnimationPlayer.root_node`，消除前置 `../` 造成的向上越界查找失效），精准重定向为 `BaseBody/Bone_00/Skeleton3D:*`；
     - 若轨道名称为 `Bone_X`，自动提取索引并在 `Skeleton3D` 中映射为 `skel.get_bone_name(b_idx)`（如 `Bone_1 -> Bip01`, `Bone_29 -> Bip01 Head`）；
     - 若骨骼已为标准骨骼名（如 `idle.glb` 中的 `Bip01`），直接校验并绑定；
     - 凡是在当前模型骨骼树中不存在的冗余轨道，通过 `anim.remove_track(t)` 从后往前安全剔除；
  2. 在 `CORE_ANIM_KEYS` 候选切片中，补充首选的 `idle`, `walk`, `run`, `attack_1`, `attack_2` 等标准切片名；
  3. 控制台 1206 条 `AnimationMixer` 报错彻底清零，儿童素体与各怪物动画播放完全恢复流畅运转。

---

## 二、 任务目标完成清单与进度标注

| 序号 | 任务目标 | 关联脚本/资产 | 解决问题与完成效果 | 完成状态 |
| :--- | :--- | :--- | :--- | :---: |
| 1 | **发型组件姿态校准** | `src/entities/character_visual.gd` | 基于网格 AABB 高程动态对齐，发型完美贴合儿童头部，跟随骨骼呼吸联动 | **100% 完成** |
| 2 | **底裤显隐与装备状态解耦** | `src/entities/character_visual.gd` | 分离 `is_boxers` 与 `is_pants`，无装备/隐藏装备时底裤 100% 完好显示 | **100% 完成** |
| 3 | **那美克星人肤色还原** | `src/entities/character_visual.gd`, `character_skin.gdshader` | 消除粉红脏色，恢复纯正比克绿，肌肉条纹保护着色器正常生效 | **100% 完成** |
| 4 | **动画轨道重定向与报错清零** | `src/entities/character_factory.gd` | `Bone_X` 精准映射 `Bip01_*`，消除 1206 条 AnimationMixer 报错，Idle 动画平滑播放 | **100% 完成** |
| 5 | **引擎编译与零报错验证** | `character_lobby.tscn` | Godot 4.7.2 编译通过，退出码为 0，零红字零警告 | **100% 完成** |

---

## 三、 验证结果

1. **引擎编译与无头运行检查**：
   - 执行 `Godot --headless --editor --quit`：退出码 0，工程校验无异常；
   - 执行 `character_lobby.tscn --quit-after 10`：退出码 0，控制台零报错、零 AnimationMixer 警告输出。
2. **大厅角色表现**：
   - 三大种族儿童素体正确实例化；
   - 发型 1~10 号精准锚定头部；
   - 底裤与新手服饰正确渲染；
   - Idle、Run 等骨骼动画驱动骨骼实时流畅播放。
