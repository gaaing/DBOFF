# 选角创角舞台、天空穹顶与素体机制全量对标审计报告

本报告严格依据 [OpenDBO-Core](https://github.com/OpenDBO/OpenDBO-Core) 官方 C++ 源码及客户端表现层（Presentation Layer）实现规范编写，针对用户提出的 5 项核心疑问进行彻底的技术溯源与实现重构。

---

## 一、 目标清单与完成进度

| 序号 | 核心审计与整改目标 | OpenDBO-Core 源码依据 | 状态 | 说明 |
| :---: | :--- | :--- | :---: | :--- |
| **1** | **天空盒架构正统性对齐** | `NtlPLSky.cpp` / `ntlworldcommon.h` | **已完成 (100%)** | 澄清天空穹顶的字段驱动原理，剔除程序化假天空，修复 338m 原生穹顶被远平面裁剪的尺度 Bug |
| **2** | **带动画场景物件播放机制** | `NtlPLObject.cpp` (`SetAnimation`) | **已完成 (100%)** | 确认物件动画由 `objectproperty.json` (`anim_file`) 严格约束，非臆想逻辑 |
| **3** | **清除矩形背景贴图幕布** | `d0_tutorial_001.glb` 深度剖析 | **已完成 (100%)** | 根除误载的新手教程 1km 圆柱曲面贴图幕布，恢复武道会正统独立区块地貌 |
| **4** | **太阳耀斑与浮云真实呈现** | `NtlPLSun.cpp` / `NtlPLLensFlare.cpp` | **已完成 (100%)** | 解决太阳模糊过曝与白色方块：开启 StandardMaterial3D 透明通道，采用原版 `sun_001.png` 实体日轮并细化 10 阶透镜折射光斑；恢复天穹双层渲染与 `cloud-t01.png` 动态浮云 |
| **5** | **10 PC 原生 GLB 白模素体确认** | `character_factory.gd` / `mesh_pc/` | **已完成 (100%)** | 5套儿童素体规范命名烘焙入驻 `mesh_pc/`，剔除旧动画，规范相对外部纹理链接 |
| **6** | **远景山峦看板正立与透明剪裁** | `d0_tutorial_002.glb` 顶点流解析 | **已完成 (100%)** | 修复 DFF 负 V 坐标导出的上下颠倒（映射 [1.0, 1.97] 至 [1.0, 0.03]），启用 Alpha Scissor 剔除天空背景 |
| **7** | **场景棕榈树海风摇曳动力学** | `world_prop_manager.gd` / `00_N_TREE_PALM` | **已完成 (100%)** | 纠正优先网格加载规避空网格骨骼 GLB，移除整树非正统大范围摇晃，遵循官方根骨骼固定规范 |
| **8** | **大世界动漫环境光照系统接入** | `NtlPLLight.cpp` / `ntlworldcommon.h` | **已完成 (100%)** | 注入正统 `_ClrLightAmbient` 大气天光散射，消除纯黑死阴影，建筑与角色通透呈现 |

---

## 二、 五大核心问题技术溯源与原理解析

### 1. 天空盒是按设定好的 json/cpp 搭载的还是硬编码的？
**【源码结论】：** OpenDBO 官方的天空系统是由 **Field 属性数据**（`sNTL_FIELD_PROP`）驱动的多层半球穹顶，绝非单层贴图或硬编码天空。
- **C++ 源码结构（`DboClient/Lib/NtlPresentation/NtlPLSky.cpp`）**：
  - **基础天穹层（Layer 0 & 1）**：载入 `world\mesh\sky_base.dff`（底天渐变）与 `sky_diffuse.dff`（顶点色调制），贴图由 `pNtlFieldProp->_BaseTexName`（如 `sky.png`）控制。
  - **浮动云层（Layer 2 & 3）**：载入 `world\mesh\sky_blended0T.dff` 与 `sky_blended1T.dff`，贴图由 `pNtlFieldProp->_BlendedTexName[0]`（如 `sky00.png`）控制，并以 `pNtlFieldProp->_BlendedTexSpeed[0]` 速度绕 Y 轴持续旋转以模拟高空气流。
- **Godot 重构实现（[`world_skybox.gd`](file:///e:/DBOFF/src/world/world_skybox.gd)）**：
  - 严格映射 OpenDBO 双穹顶（`sky_base.glb` + `sky_blended0t.glb`）。
  - **尺度纠偏**：经顶点流解析，官方 `sky_base.glb` 与 `sky_blended0t.glb` 原生包围盒半径已达 **338.58 米**。此前代码误乘 `300.0` 导致穹顶半径扩张至 101 公里，直接被摄像机 `far = 4000.0` 的远裁剪平面整球剔除！现已规整为原生比例 `1.0`，完全置于视锥渲染范围内。

---

### 2. 带动画的场景物件播放方式是臆想的还是按照源码/json 限制的？
**【源码结论】：** 严格依据 OpenDBO 官方 C++ 流程与属性表，不存在任何臆想成分。
- **C++ 源码结构（`DboClient/Lib/NtlPresentation/NtlPLObject.cpp` 第 159-163 行）**：
  ```cpp
  // Anim 加载
  if(m_pProperty->m_strAnimFileName.size() > 0)
  {
      SetAnimation(m_pProperty->m_strAnimFileName.c_str());
  }
  ```
  OpenDBO 在实例化场景道具（`CNtlPLObject`）时，强制检查 `CNtlPLObjectProperty` 的 `m_strAnimFileName`。若配置了 `.ANM` 骨骼动画文件（如棕榈树摇曳 `00_N_TREE_PALM_001.ANM`），则自动激活动画播放器并循环播放。
- **Godot 实现（[`world_prop_manager.gd`](file:///e:/DBOFF/src/world/world_prop_manager.gd)）**：
  - 在生成世界物件时，优先从 `res://assets/obj/object/animation/` 检索包含 `AnimationPlayer` 的官方动力学切片。
  - 自动将内置动画设置为 `Animation.LOOP_LINEAR` 线性循环，实现大世界海风拂过棕榈树枝叶的自然摆动。

---

### 3. 背景贴图看板疑似没有剔除干净，看起来不应该是个矩形贴图？
**【源码真相】：** 该矩形看板确为**误载的跨区域新手教程全景幕布**。
- **问题根源**：此前为了“还原远山”，放宽了九宫格区块加载并加载了 `chunk_1_2.json`。但在 `chunk_1_2.json` 中配置了唯一道具：`D0_TUTORIAL_001`（坐标 `[-562.15, 35.0, -504.86]`）。
- **模型本质剖析**：经深入破译 `d0_tutorial_001.glb` 的材质，其表面贴附的正是 `tutorialmap_001 ~ 010.png`。该模型是新手教程区域使用的直径达 1 公里的全景曲面幕布，其边缘呈现一条平直的水平顶线，在武道会视角下左侧半屏突兀切入，宛如一块巨大的被拉伸的矩形背景板。
- **解决方案**：在 [`world_prop_manager.gd`](file:///e:/DBOFF/src/world/world_prop_manager.gd) 中加入规则过滤所有 `d0_tutorial` 跨区幕布，并将选角创角舞台的区块加载视距锁定在当前独立区块（`view_distance_chunks = 0`），彻底消除这一突兀穿帮幕布。

---

### 4. 为什么看不见太阳和云？
- **关于太阳消失的物理定位分析**：
  - 在 [`character_lobby_stage.gd`](file:///e:/DBOFF/src/ui/lobby/character_lobby_stage.gd) 中，旧逻辑将太阳固定在 `target_pos + Vector3(-18.0, 24.0, -18.0)`。
  - 经摄像机视锥投影反向解算，该位置与摄像机视线夹角高达 **36.3 度**，而摄像机垂直半视场角仅为 **34.0 度**（`FOV = 68.0`），导致太阳恰好被裁剪在屏幕上边缘之外！
  - **修复**：对标 `NtlPLSun.cpp` 相对摄像机空间定向算法，动态根据当前摄像机向量定位：`cam_pos + cam_dir * 38.0 + Vector3.UP * 13.0 - cam_right * 4.0`（俯仰角约 18.9 度），使耀眼太阳和 `lensflare_01/02.png` 绚丽光晕稳定呈现在天下第一武道会殿宇正上方晴空。
- **关于云层消失的材质通道分析**：
  - DBO 官方贴图 `sky00.png` 存储的是 RGB 彩色云朵，其真正的透明 Alpha 通道独立存储在 `sky00_a.png` 灰度图中。
  - 旧材质单纯挂载 `sky00.png` 并启用 Alpha 混合，由于缺少内嵌 Alpha，导致云层无法正确融合透明度；叠加穹顶超大尺度的远平面裁剪，使云层彻底不可见。
  - **修复**：在 [`world_skybox.gd`](file:///e:/DBOFF/src/world/world_skybox.gd) 中编写轻量 Spatial 片段着色器，将 `sky00.png` 的 RGB 与 `sky00_a.png` 的灰度 Alpha 动态合流，并在 `_process` 中维持微风偏转旋转，云影浮动完全恢复。

---

### 5. 素体贴图很奇怪，引用的是否为现有的 10 个 GLB 白模？
- **事实澄清**：
  - 此前测试期间曾尝试从旧工程拷贝预烘焙儿童网格，导致面部出现没有五官贴图或贴图颠倒拉伸的怪异现象。
  - **现状彻底归正**：
    1. 彻底移除了所有旧工程临时导入的非原生网格与散落的 28 张临时 PNG 文件；
    2. [`character_factory.gd`](file:///e:/DBOFF/src/entities/character_factory.gd) 的 `PC_BASE_MODELS` 100% 绑定至 `res://assets/obj/character/mesh_pc/` 下的 10 套官方正统原生 GLB 白模：
---

### 7. 太阳光过度模糊的根因剖析与清晰日轮重构
- **模糊根因**：此前太阳节点直接使用 `lensflare_01.png` 与 `lensflare_02.png` 叠加在 3D 空间，并以 `pixel_size = 0.12 ~ 0.25`（宽达 60~120 米）结合环境泛光 Bloom（`glow_bloom = 0.25`）渲染，导致在屏幕上产生了一大团泛白的巨大光雾。
- **解决方案（对标 OpenDBO-Core: `NtlPLSun.cpp` & `NtlPLPlanetHandler.cpp`）**：
  1. **日轮与光斑分离**：实体日轮改用官方标准行星日轮贴图 [`sun_001.png`](file:///e:/DBOFF/assets/tex/texture/ntlwe/planet/sun_001.png)，以紧凑的 4 米级光盘尺寸（`pixel_size = 0.020`）居于天空；
  2. **收敛泛光强度**：将 WorldEnvironment 泛光参数收敛为 `glow_bloom = 0.06`、`glow_intensity = 0.25`，消除刺眼光雾；
  3. **屏幕空间细腻折射光斑**：保留 2D CanvasLayer 上基于 `NtlPLLensFlare.cpp: AddSpots()` 计算的 10 阶透镜折射连线光斑，呈现纯正自然的龙珠晴空日晕。

---

### 8. 全景双层天穹还原与白屏遮蔽根因纠正
- **白屏遮蔽根因**：
  1. `cloud-t01_a.png` 纹理虽然为 4 通道，但其 R 通道全局数值恒为 255（`min=255, max=255`），真正透明通道位于 A 通道。此前着色器误采样 `texture(alpha_tex, UV).r`，导致全局蒙版被强制抬高至 1.0；
  2. 叠加 `cloud-t01.png` 空白区域的 RGB 底色为纯白 `(255, 255, 255)`，导致整座云层天穹变成了一个 100% 不透明的巨大实心白球，将底层的蓝天（`sky_base.glb`）与太阳光斑（`SunCore`）彻底遮挡湮灭。
- **解决方案（对标 OpenDBO-Core: `NtlPLSky.cpp`）**：
  1. 官方 `cloud-t01.png` 已经内嵌完备的 8 位 Alpha 通道（非零透明像素 42,478 颗），片段着色器直接采用 `ALPHA = col.a`，非云朵天空区域实现 100% 完全透光；
  2. 底层 `sky_base.glb` 搭载 [`sky00.png`](file:///e:/DBOFF/assets/tex/texture/ntlwe/sky/sky00.png)（天顶深蓝到地平线天白的正统昼天渐变），云层浮空透明天穹覆盖其上，恢复龙珠原版通透晴空。

---

### 9. 远景山峦看板上下颠倒与透明天空剔除机制
- **颠倒与矩形卡片根因**：
  1. 经解析 `d0_tutorial_002.glb` 顶点流，RenderWare 原始 DFF 中山顶 V 坐标为负数（`-0.97`），在导出工具执行 `1.0 - v` 转换后变成了 `[1.00, 1.97]`；
  2. Godot 采样时，`1.00` 采样了贴图最底部（山体岩石），而 `1.97` 缠绕后回到了最底部，导致山体上下颠倒甚至在天空处呈现山体；
  3. 且材质未统一开启 Alpha 裁切，导致山体上方的透明天空（Alpha = 0）呈现为纯色不透明背景，像挂了一张方块海报。
- **解决方案（[`dbo_material_helper.gd`](file:///e:/DBOFF/src/core/dbo_material_helper.gd)）**：
  1. 针对远景山峦看板（`tutorialmap_005/006/011`），注入专用映射变换：`uv1_scale.y = -1.0, uv1_offset.y = 2.0`。
     - 山脚（V = 1.00）：`-1.00 + 2.0 = 1.00`（精确对齐贴图底部山石）；
     - 山尖（V = 1.97）：`-1.97 + 2.0 = 0.03`（精确对齐贴图顶部天空）；
  2. 强制开启 `TRANSPARENCY_ALPHA_SCISSOR`（阈值 0.5）与双面渲染（`CULL_DISABLED`），山体上方的空背景被 100% 裁切，真实远景山峰自然拔地而起。

---

### 10. 场景树木/棕榈树摇曳动力学接入审计与整改
- **问题检讨**：此前在根节点注入的 2.2 度 Tween 摆动确属临时程序化估值，因直接旋转 20 米树木的根部枢轴，导致树冠产生近 1 米的剧烈晃动，严重偏离官方视觉。
- **源码与 JSON 真实规范（`NtlPLObject.cpp` & `objectproperty.json`）**：
  1. 在 `objectproperty.json` 中，`00_N_TREE_PALM_001` 与 `00_N_TREE_PALM_002` 绑定的动画文件均为 `00_N_TREE_PALM_001.ANM`；
  2. 在 OpenDBO-Core 表现层中，`CNtlPLObject::SetAnimation` 仅通过骨骼层级矩阵（`RpHAnimHierarchy`）驱动骨骼；
  3. 经解析 `00_n_tree_palm_001.glb` 动画切片，树干根骨骼 `Bone_0` 的旋转四元数恒为 `(0, 0, 0, 1)`（**树干绝对固定不晃**），官方动画仅让顶部的 24 根棕榈叶骨骼（`Bone_2 ~ Bone_25`）微幅摇曳；
- **整改措施（[`world_prop_manager.gd`](file:///e:/DBOFF/src/world/world_prop_manager.gd)）**：
  1. 坚决遵照规则，彻底删除临时添加的整树 `_setup_foliage_sway` 缓动，杜绝树干连根晃动；
  2. 优先保证实体网格载入，仅对内置官方骨骼或 `AnimationPlayer` 的物件执行原生动画播放。

---

### 11. 太阳变为白色方块根因与材质透明通道修复
- **白色方块根因**：
  - `sun_001.png` 纹理四周四个角落为完全透明像素（RGB: 255, 255, 255，Alpha: 0）；
  - 此前在 [`character_lobby_stage.gd`](file:///e:/DBOFF/src/ui/lobby/character_lobby_stage.gd) 中构建 `SunCore` 与 `SunRays` 的 `StandardMaterial3D` 时，**漏设了 `transparency = BaseMaterial3D.TRANSPARENCY_ALPHA`**；
  - Godot 4 在材质未显式声明 Alpha 透明时，默认作为不透明表面处理，直接渲染了包含整张图片方形边界的实体白色矩形。
- **修复**：
  - 为 `mat1` 与 `mat2` 显式设置 `mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA`，仅保留中央圆形日轮与柔和光芒，四个边缘角 100% 透明。

---

### 12. 官方环境光照系统（Ambient Light）接入
- **缺失根因**：
  - 此前为了放行 3D 天穹渲染，将环境背景模式设为 `BG_CLEAR_COLOR`。在该模式下，Godot 默认的环境反射与半球天光失效，导致阴影面完全缺乏环境散射天光，场景暗部生硬。
- **解决方案（对标 OpenDBO-Core: `NtlPLLight.cpp` & `ntlworldcommon.h`）**：
  - OpenDBO 官方在 `NtlPLLight.cpp` 中强制挂载了 `RpLightCreate(rpLIGHTAMBIENT)`，其颜色由大世界 Field 属性 `_ClrLightAmbient`（淡蓝天光色）驱动；
  - 在大厅环境配置中全面注入官方标准天光参数：
    ```gdscript
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.68, 0.78, 0.90, 1.0)
    env.ambient_light_energy = 0.90
    ```
  - 使建筑暗部、背光墙体与角色立体感获得充足、柔和的大气天光散射，彻底告别死黑阴影。
