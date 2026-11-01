# DBO 全量装备、武器与饰品资产再提取与双体型管线重构报告

## 1. 概述与核心目标清单

针对角色创角与选角界面中出现的“成人体型巨型 T 姿态重影浮空”、“儿童素体未正确挂载装备”、“史考特掉落地面”以及“全量资产未按正统规则完全导出”的问题，本次重构执行了一次性全量资产重提取与双体型（成人 / 儿童）深度适配。

### 目标清单与完成进度
- [x] **目标 1**: 建立全量 DFF 资产再提取管线并记录全部原始路径（13 个分类目录，共 6,146 个模型）。
- [x] **目标 2**: 实现 glTF 2.0 蒙皮与刚体双体型烘焙转换器（支持成人 50 骨骼 IBM 与儿童 STypeBoneData 顶点形变烘焙）。
- [x] **目标 3**: 优化 GLB 材质架构，采用外部相对 URI 贴图引用，轻量化文件并注入 `.gdignore` 杜绝 Godot 导入卡死。
- [x] **目标 4**: 重构 `src/entities/character_factory.gd` 装备解析管线，支持多族多性别精准寻址并优先匹配 `child/` 变体。
- [x] **目标 5**: 重构 `src/entities/character_visual.gd` 骨骼物件挂载机制，修复 `BoneAttachment3D` 时序问题，消除史考特与武器掉落地面 Bug。
- [x] **目标 6**: 修复 `src/ui/lobby/character_lobby_stage.gd` 穿戴过滤限制，使创角与选角界面正常显示新手基础装备。
- [x] **目标 7**: 全面清理旧版本遗留废弃资产（清理全部 6,146 个失效 `.glb.import` 索引以及 `animation_weapon` 历史假网格，确保目录 100% 纯净）。
- [x] **目标 8**: 输出全量原始资产路径与架构技术报告。

---

## 2. 原始资产路径清单与提取范围 (Raw Asset Inventory)

源目录基准路径：`E:/DBO_Offline/pipeline/raw_source/extracted/obj/item/`  
输出目录基准路径：`E:/DBOFF/assets/obj/item/`

| 序号 | 资产子目录 | 模型类型 | DFF 数量 | 导出策略 | 输出目标路径 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `mesh_armor_humanmale` | 人类男性防具 | 369 | 成人蒙皮 + 儿童烘焙蒙皮 | `assets/obj/item/mesh_armor_humanmale/` 及 `/child/` |
| 2 | `mesh_armor_humanfemale` | 人类女性防具 | 369 | 成人蒙皮 + 儿童烘焙蒙皮 | `assets/obj/item/mesh_armor_humanfemale/` 及 `/child/` |
| 3 | `mesh_armor_namek` | 那美克防具 | 348 | 成人蒙皮 + 儿童烘焙蒙皮 | `assets/obj/item/mesh_armor_namek/` 及 `/child/` |
| 4 | `mesh_armor_majinmale` | 魔人男性防具 | 333 | 成人蒙皮 + 儿童烘焙蒙皮 | `assets/obj/item/mesh_armor_majinmale/` 及 `/child/` |
| 5 | `mesh_armor_majinfemale` | 魔人女性防具 | 357 | 成人蒙皮 + 儿童烘焙蒙皮 | `assets/obj/item/mesh_armor_majinfemale/` 及 `/child/` |
| 6 | `mesh_battlesuit` | 战斗服 | 255 | 成人蒙皮 + 儿童烘焙蒙皮 | `assets/obj/item/mesh_battlesuit/` 及 `/child/` |
| 7 | `mesh_ccbd_armor` | 胶囊公司/特装防具 | 225 | 成人蒙皮 + 儿童烘焙蒙皮 | `assets/obj/item/mesh_ccbd_armor/` 及 `/child/` |
| 8 | `mesh_common_armor` | 通用族群防具 | 270 | 成人蒙皮 + 儿童烘焙蒙皮 | `assets/obj/item/mesh_common_armor/` 及 `/child/` |
| 9 | `mesh_costume` | 全时装 (武道服/便服) | 1,840 | 蒙皮时装 + 刚体配饰 | `assets/obj/item/mesh_costume/` 及 `/child/` |
| 10 | `mesh_costume_engineer` | 工程师专用时装 | 369 | 成人蒙皮 + 儿童烘焙蒙皮 | `assets/obj/item/mesh_costume_engineer/` 及 `/child/` |
| 11 | `mesh_scouter` | 战力探测器 (史考特) | 175 | 刚体眼部挂件 | `assets/obj/item/mesh_scouter/` |
| 12 | `mesh_weapon` | 武器 (手套/杖/剑/斧/枪) | 1,222 | 手套(蒙皮) / 手持(刚体) | `assets/obj/item/mesh_weapon/` 及 `/child/` |
| 13 | `drop item` | 掉落道具/宝箱模型 | 14 | 刚体道具模型 | `assets/obj/item/drop item/` |
| **合计** | **全部 13 个道具资产分类** | **全装备与道具** | **6,146** | **100% 成功提取 (0 失败)** | **全部按规范对齐落盘** |

---

## 3. 根因剖析与技术架构突破

### 3.1 导致成人体型巨型 T 姿态与装备不附着的原因
1. **历史模型导出缺失蒙皮 (`skins: 0`)**：
   原有工具将防具与手套 DFF 导成了单节点静态网格，未写入 `Skin` 逆绑定矩阵与骨骼权重，导致挂载到角色骨骼后无法随动画变形。
2. **顶点坐标处于成人高度（$Y \in [1.1, 1.6]$ 米）**：
   静态网格的局部原点在角色脚底，但防具的网格顶点直接位于成人胸腹部与手臂位置。当挂载在仅有 ~1 米高的儿童骨骼上时，直接在后上方悬空，形成了巨大的成人 T-Pose“鬼影”。
3. **史考特掉落地面（原点 (0,0,0)）**：
   在 Godot 4 中，动态创建 `BoneAttachment3D` 时，若在 `add_child` 之前设置 `bone_name`，此时附件节点尚未进入场景树，无法向父节点 `Skeleton3D` 检索对应的 `bone_idx`（导致 `bone_idx = -1`）。当加入场景树后，节点始终停留在局部原点（即角色双脚之间的地面）。
4. **创角界面装备限制逻辑**：
   历史代码在 `character_lobby_stage.gd` 中硬编码了 `and current_visual_instance.is_adult` 判断，直接禁用了童年期素体的装备穿戴。

### 3.2 解决方案与双体型数学烘焙
1. **成人素体蒙皮方案**：
   提取 DFF 中的 `rwID_SKIN (0x116)`，将 50 根骨骼的层次结构、列主序逆绑定矩阵（Column-Major IBM）以及归一化权重（`JOINTS_0`, `WEIGHTS_0`）注入 glTF 2.0，使装备与素体 Skeleton3D 100% 共享动作动画。
2. **儿童素体顶点烘焙方案 (Offline Vertex Morph Baking)**：
   依据 OpenDBO 官方 `character_bone_scales.json`（对应 `STypeBoneData`），在离线导出时计算骨骼变形正向运动学：
   $$v_{child} = \sum_{m=0}^3 w_m \cdot M_{skin\_final}[j_m] \cdot M_{adult\_bind}^{-1}[j_m] \cdot v_{adult}$$
   同时使用逆转置矩阵纠正法线向量：
   $$n_{child} = \text{normalize}\left(\sum_{m=0}^3 w_m \cdot \left(M_{skin\_final}[j_m] \cdot M_{adult\_bind}^{-1}[j_m]\right)^{-T} \cdot n_{adult}\right)$$
   将计算好的儿童 IBM 写入 `child/` 目录下的专用 GLB，彻底消除穿模与悬空。
3. **轻量化贴图 URI 架构**：
   摒弃在 11,000+ 个 GLB 中重复内嵌数千张 PNG 的落后方式，使用标准相对 URI（`../../../tex/texture/item/<tex>.png` 及 `../../../../tex/texture/item/<tex>.png`），使每个 GLB 仅为 20KB~40KB。
4. **导入防卡死保护 (`assets/obj/item/.gdignore`)**：
   在道具目录注入 `.gdignore`，指示 Godot 编辑器无需为这 11,000+ 个通过 `GLTFDocument` 动态加载的模型建立沉重的编辑器缓存，彻底消除项目启动与检测卡死。

---

## 4. 关键代码变更清单

### 4.1 `src/entities/character_factory.gd`
- 更新 `_resolve_item_glb_path`：移除将所有装备强行转换为通用新手服 `A_HCH_J` 的错误逻辑，改为精准查找官方映射，并在童年期优先路由到 `child/` 烘焙模型。
- 全面使用 `FileAccess.file_exists` 替代 `ResourceLoader.exists`，支持 `.gdignore` 目录下的动态即时读取。

### 4.2 `src/entities/character_visual.gd`
- 修复 `attach_item_to_bone` 与 `attach_object_to_bone`：
  ```gdscript
  var attachment := BoneAttachment3D.new()
  attachment.name = "ItemAttach_" + slot_name
  _skeleton.add_child(attachment)
  attachment.bone_idx = bone_idx
  attachment.bone_name = _skeleton.get_bone_name(bone_idx)
  if not is_adult:
      mesh_inst.scale = Vector3(0.65, 0.65, 0.65)
  attachment.add_child(mesh_inst)
  ```
  保证附件节点先接入骨骼树再绑定骨骼索引，并将非蒙皮道具按儿童身材比例缩放。

### 4.3 `src/ui/lobby/character_lobby_stage.gd`
- 解除行 563 对儿童素体装备加载的拦截，使创角与选角阶段童年期角色能够正常穿着各自种族职业的官方新手初始装备（道服上衣、下装、靴子、手套与史考特）。

### 4.4 历史旧 GLB 与失效索引清理 (Legacy Asset Cleanup)
为保证工程极致整洁与轻量化，彻底清理了以下历史遗留产物：
1. **全面覆盖旧 GLB**：全部 6,146 个道具模型在原路径执行了覆写替换，原有无蒙皮（`skins: 0`）静态网格已 100% 被替换为规范的带 50 骨骼蒙皮或规范刚体的新模型。
2. **清理 `animation_weapon` 历史假网格**：该目录在 raw 资产中纯属 `.anm` 动作文件，清理了历史工具在此处误生成的 316 个假 GLB 及相关文件。
3. **清除 6,146 个历史 `.glb.import` 冗余索引**：配合 `.gdignore` 的加入，彻底清空了旧版静态 GLB 导入时残留的 6,146 个 `.glb.import` 文件，杜绝了编辑器打开时的校验哈希冲突与重复扫描开销。

---

## 5. 总结

本次重构彻底解决了角色装备显示异常与 T-Pose 鬼影问题，全量 6,146 个道具模型全部重新烘焙导出完成，兼顾了成人期与童年期的体型表现，并确保了 Godot 引擎的极致性能与轻量化加载。
