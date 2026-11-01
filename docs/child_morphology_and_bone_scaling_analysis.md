# DBO 儿童素体形态畸变原因与骨骼形变技术分析报告

## 1. 目标清单与当前完成进度

| 任务项 | 描述 | 状态 | 详细说明 |
| :--- | :--- | :---: | :--- |
| **任务 1** | 修复 `character_visual.gd` 材质枚举解析错误 | [x] 已完成 | 将 `DEPTH_DRAW_NEVER` 修正为 Godot 4 的 `DEPTH_DRAW_DISABLED` |
| **任务 2** | 排查儿童素体形态异常与动画缓存报错机理 | [x] 已完成 | 查明官方 DFF 原始数据、RenderWare 骨骼形变机制与 400+ `AnimationMixer` 轨道缺失错误根因 |
| **任务 3** | 比对旧工程 5 个预烘焙素体 (`dbo_bake_child_mesh_glb.py`) | [x] 已完成 | 确认旧工程已通过离线数学烘焙 50 根骨骼参数解决形态畸变与蒙皮绑定问题 |
| **任务 4** | 引入 5 套正统预烘焙儿童素体并剔除冲突动画 | [x] 已完成 | 遵从用户指令执行方案 A：将 5 套预烘焙模型收纳进 `mesh_pc/`，剔除冲突动画并消除 400+ 报错 |
| **任务 5** | 地表材质属性与 BGM 优雅回退修复 | [x] 已完成 | 修复 `specular` 警告为 `metallic_specular`，解决 `BGM_Field_01` 大小写回退机制 |
| **任务 6** | 消除双重模型重影与场景建筑贴图颠倒 | [x] 已完成 | 阻止向自带服饰的儿童素体挂载成人静态 T 姿态装备，恢复场景物件全量 UV 垂直翻转纠偏 |
| **任务 7** | 天空穹顶、太阳光晕与大气环境光影 | [x] 已完成 | 挂载 `WorldSkybox` 与官方耀眼太阳 Lens Flare (`lensflare_01/02`)，开启 Bloom 与柔和大气雾 |
| **任务 8** | 场景物件原生动画自动循环播放 | [x] 已完成 | 优先检索 `animation/` 动态物件目录，自动循环播放棕榈树随风摇曳等原生环境动力学 |
| **任务 9** | 还原远景山川地貌背景画卷 | [x] 已完成 | 解除 `D0_TUTORIAL` 过滤，开启九宫格区块加载，忠实呈现 `tutorialmap` 远山与密林背景 |
| **任务 10** | 儿童素体贴图正向对齐修复 | [x] 已完成 | 修正 `DBOMaterialHelper` 判定，对儿童预烘焙素体全量执行 UV 垂直翻转纠偏，面部与服饰正向对齐 |

---

## 2. 问题深度剖析：为什么直接加载儿童网格会出现“缩小的成人”而非正统儿童？

在对客户端引擎核心源码（`OpenDBO-Core`）以及 DFF 原始文件结构进行深度反编译分析后，得出了确切的物理技术事实：

### 2.1 DBO 官方客户端的儿童形变机制
1. **DFF 模型并不是两套独立的骨骼比例模型**：
   官方 DFF 资源中的 `a_hch_h_m.dff`（人类男童）在原始顶点坐标系中，**与成人体型使用的是同一套基准成人比例骨架**。
2. **形态是由客户端引擎实时计算得出的**：
   在 `characterproperty.json`（对应 OpenDBO 的 `CharacterProperty.xml`）中，官方为所有幼年期角色（如 `A_HFI_M_CH`、`A_HFI_F_CH`、`A_NFI_CH` 等）硬性配置了 **50 组精细的骨骼缩放与位移矩阵**：
   - 头部骨骼（Head）：大幅放大横向与纵向比例（形成大头大眼的二头身/三头身比例）
   - 躯干脊柱（Spine / Pelvis）：大幅缩短纵向间距（压缩躯干长度）
   - 四肢腿部（Thigh / Calf）：缩短长度同时微调粗细
   - 整体全局比例：`vBaseScale = [0.65, 0.65, 0.65]`
3. **RenderWare 的渲染管线**：
   客户端在渲染时调用 `UpdatePreBoneScale` 和 `UpdatePostBoneScale`，将这 50 根骨骼的 `fLength`、`fWidth` 变换矩阵与动画矩阵相乘，再通过顶点的 **HAnim 蒙皮权重（Skin Weights，0x116 数据块）** 动态形变每一个顶点，从而在屏幕上呈现出纯正的龙珠儿童形态。

### 2.2 为什么在 DBOFF 中形态会变成“等比缩小的成人素体”？
在 `E:\DBOFF\assets\obj\character\mesh_pc\a_hch_h_m.glb` 中：
- 该文件在最初从 DFF 导出时，丢失了 `0x11E`（骨骼层级）和 `0x116`（顶点骨骼权重）信息，变成了 **0 个骨骼（skins: 0）、1 个纯静态网格（MeshInstance3D）**。
- 由于网格本身没有任何骨骼绑定关系，我们在 `character_factory.gd` 中执行的全局缩放 `visual.scale = Vector3(0.65, 0.65, 0.65)`，只能将一个成人比例的静态网格按比例缩小，导致角色头身比例依旧是成人的 7 头身，从而看起来严重变形（像微缩大人）。

---

## 3. 旧工程 `E:\DBO_Offline` 的处理机制剖析

在旧工程的 `E:\DBO_Offline\tools\dbo_bake_child_mesh_glb.py` 中，已经实现了完整的解法：
1. **读取 DFF 完整层级**：解析 `0x0E`（FrameList）、`0x11E`（HAnim 骨架）和 `0x116`（蒙皮权重）。
2. **结合 `characterproperty.json` 的 50 根骨骼缩放**：
   - 提取各骨节的局部缩放 `fLength`、`fWidth` 与位移偏移 `vPosOffset`。
   - 计算官方正统的正向运动学矩阵 `global_M_scaled_anim`。
   - 对每一个顶点的 4 组骨骼影响权重（Joints & Weights）进行蒙皮矩阵加权形变，直接将儿童的头身比、短肢干计算到顶点的原始位置中。
3. **输出 5 个预烘焙儿童素体**（位于 `E:\DBO_Offline\assets\models\characters\`）：
   - `human_m_child/human_m_child.glb`（251 KB，带 50 根骨骼、骨骼动画与烘焙后的正确形态）
   - `human_f_child/human_f_child.glb`（244 KB）
   - `namek_m_child/namek_m_child.glb`（318 KB）
   - `majin_m_child/majin_m_child.glb`（180 KB）
   - `majin_f_child/majin_f_child.glb`（194 KB）
4. 这些模型不仅具有正确正统的二头身儿童形态，而且包含了角色初始的新手服饰、裤子、靴子贴图，完全解决了素体裸露和比例失真的问题。

---

## 4. 新架构下的实施方案与请求

根据项目规则（严禁私自挪动或生成资产，缺失材料向用户报告）：

### 方案 A（标准方案，零性能开销，视觉 100% 还原正统）- **已全量执行完毕**
- **操作**：遵从用户明确授权与指令（“同意执行规范 禁止生成图片 仅生成五个glb模型规范命名”），将 5 套预烘焙正统儿童素体以轻量化 glTF 2.0 规范接入 `assets/obj/character/mesh_pc/`：
  - `human_m_child.glb` (人类男童)
  - `human_f_child.glb` (人类女童)
  - `namek_m_child.glb` (那美克幼体)
  - `majin_m_child.glb` (魔人男童)
  - `majin_f_child.glb` (魔人女童)
- **规格保证**：
  1. **零新增图片生成**：禁止生成任何新图片，材质 100% 外链复用既有的 `assets/tex/texture/item/` PNG 资源；
  2. **彻底剔除内置动画**：所有模型清空 `animations`，消除 AnimationMixer 骨骼轨道缺失报警；
  3. **架构完全同构**：网格具备烘焙后的正统二头身形态、完整骨骼层级与蒙皮权重；
- **配置**：在 [`character_factory.gd`](file:///e:/DBOFF/src/entities/character_factory.gd) 的 `PC_BASE_MODELS` 中将童年期状态映射至上述 5 个规范化模型。

### 方案 B（纯脚本运行时形变，动态 CPU 计算）
- **操作**：编写纯 GDScript 解析器，在角色加载时读取 DFF 权重或通过 MeshDataTool 在 CPU 端根据 50 根骨骼矩阵动态改变顶点坐标。
- **缺点**：在 Godot 中每个角色进场都需要遍历数千个顶点做 4 权重矩阵乘法，会导致帧率骤降并增加加载卡顿。

**建议采纳方案 A**。如您确认，请授权我们将旧工程这 5 套正统预烘焙模型规范接入新架构。
