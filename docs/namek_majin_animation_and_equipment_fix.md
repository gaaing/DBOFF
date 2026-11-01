# 那美克星人与魔人动作畸变扭曲及装备搭载修复报告

## 一、 任务目标清单与完成进度

- [x] **目标 1：查明那美克星人与魔人动画扭曲成一团的深层根因** —— 100% 完成
- [x] **目标 2：建立 RenderWare 官方 5 大 PC 种族骨架 HAnim 序列映射表** —— 100% 完成
- [x] **目标 3：重构动画轨道重定向管线（Animation Track Remapping）** —— 100% 完成
- [x] **目标 4：查明那美克星人与魔人未搭载装备/无衣服外显的根因** —— 100% 完成
- [x] **目标 5：解耦素体复合材质与皮肤着色器，规范新手服饰与底裤显示逻辑** —— 100% 完成
- [x] **目标 6：清理大厅舞台与 UI 临时调试代码，恢复正统选角与初始创角流程** —— 100% 完成
- [x] **目标 7：Godot 4.7.2 启动与脚本自检，零报错零红字** —— 100% 完成

---

## 二、 核心问题深度归因分析

### 1. 动画扭曲成团（"因为动画扭成一团了"）根因分析
在先前的实现中，`load_character_animations` 加载 `.glb` 动作轨道时，对于包含 `Bone_X` 的轨道直接执行了：
```gdscript
var b_idx := raw_bone.trim_prefix("Bone_").to_int()
if b_idx >= 0 and b_idx < skel.get_bone_count():
    target_bone = skel.get_bone_name(b_idx)
```
- **致命缺陷**：
  Godot 4 的 `Skeleton3D.get_bone_name(b_idx)` 索引完全遵循场景树的**深度优先遍历顺序（Depth-First Search）**；
  而 DBO 官方 RenderWare 导出的 `.anm` / `.glb` 动作轨道中，`Bone_0` 至 `Bone_{N-1}` 的编号完全严格对应 RenderWare 的 **`RpHAnimHierarchy` 骨架节点层级顺序**。
- **灾难性映射错位**：
  - 那美克星人（54 根骨骼）：
    - RenderWare HAnim 4 为裙摆骨骼 `B_SK_BL1`，而 Godot DFS 4 映射到了 `Bip01 Spine1`（第一胸椎）；
    - RenderWare HAnim 12 为大腿 `Bip01 L Thigh`，而 Godot DFS 12 映射到了手掌 `nullRhand`；
    - RenderWare HAnim 18 为右大腿 `Bip01 R Thigh`，而 Godot DFS 18 映射到了手指 `Bip01 R Finger1`；
    - RenderWare HAnim 24 为胸椎 `Bip01 Spine1`，而 Godot DFS 24 映射到了头部。
  - 魔人男性（50 根骨骼）：
    - RenderWare HAnim 4 为 `Bip01 L Thigh`，Godot 却将其错位应用给裙摆或手指。
  - **结果**：大腿动作驱动了手指，裙摆动作剧烈拧转了脊椎与颈椎，手臂动作扭曲了脚趾，导致整个模型在播放任意动作瞬间被拧成一个畸变肉球。

### 2. 装备未搭载/服饰消失（"而且没有搭载装备"）根因分析
- **原因 1：着色器全量覆写导致服饰变异为纯色肉块**：
  在幼童素体网格（如 `namek_m_child.glb`、`majin_m_child.glb`）中，官方原生已烘焙了该种族的新手服饰部件（如 `A_NFI_AD_jacket_skin01`、`A_NAM_pants_skin01`、`A_MAJ_M_jacket_skin1`、`A_MAJ_M_pants_skin` 等）。
  在先前的 `character_visual.gd` 定制逻辑中，由于材质名中含有 `"skin"`，直接被判定为 `is_skin = true`，被强制挂载了 `CHARACTER_SKIN_SHADER`。
  魔人粉色肤色乘法（`ALBEDO = base_rgb * skin_tint.rgb`）直接将全套黄色/白色马甲和裤子染成全粉，与身体皮肤融为一体；那美克星人服饰亦被肤色着色器严重破坏，导致视觉上角色完全处于未穿戴装备状态。
- **原因 2：底裤（`pants000` / `jacket000`）与新手服饰重叠破皮**：
  素体模型中同时存在内衣表面（`pants000`、`jacket000`）与新手外装表面（`jacket_skin`、`pants_skin`）。由于缺少清晰的内外衣层级判定，内裤未在穿着外装时隐藏，形成双层几何体 Z 轴冲突。

---

## 三、 解决方案与重构实现

### 1. 提取并建立 5 大 PC 种族 RenderWare HAnim 序列映射表
在 [`src/entities/character_factory.gd`](file:///e:/DBOFF/src/entities/character_factory.gd) 中，严格对齐官方 DFF/ANM 节点层级建立静态映射表：
- **那美克星人（54 骨骼）**：`HANIM_MAP_NAMEK`
- **魔人男性（50 骨骼）**：`HANIM_MAP_MAJIN_MALE`
- **魔人女性（57 骨骼）**：`HANIM_MAP_MAJIN_FEMALE`
- **人类男性（50 骨骼）**：`HANIM_MAP_HUMAN_MALE`
- **人类女性（52 骨骼）**：`HANIM_MAP_HUMAN_FEMALE`

并通过核心寻址函数：
```gdscript
static func get_hanim_bone_name(race: int, gender: int, h_idx: int) -> String:
```
在动画解析轨道重定向时，将 `Bone_X` 精准映射回骨骼名称：
```gdscript
elif raw_bone.begins_with("Bone_"):
    var b_idx := raw_bone.trim_prefix("Bone_").to_int()
    target_bone = get_hanim_bone_name(visual.race, visual.gender, b_idx)
```

### 2. 规范服饰材质渲染与内外衣分层
在 [`src/entities/character_visual.gd`](file:///e:/DBOFF/src/entities/character_visual.gd) 中重构材质归类与显示流：
1. **严格区分内衣与外装**：
   ```gdscript
   var is_underwear := ("pants000" in mat_name or "pants000" in tex_name or "jacket000" in mat_name or "jacket000" in tex_name)
   var is_jacket := ("jacket" in mat_name or "jacket" in tex_name) and not is_underwear
   var is_pants := ("pants" in mat_name or "pants" in tex_name) and not is_underwear
   var is_clothing := is_jacket or is_pants or is_boots
   ```
2. **新手外装材质保护**：
   外装表面（上衣、长裤、靴子）使用独立的 `StandardMaterial3D` 保持原生官方贴图（`a_hfi_m_jacket_skin.png`、`a_nfi_ad_jacket_skin01.png`、`a_maj_m_jacket_skin1.png`），以 `Color.WHITE` 保持官方原版调色，严禁挂接肤色着色器。
3. **内外衣互斥防御**：
   当角色穿着外装时，内衣（`pants000` / `jacket000`）使用透明不可见材质隐藏；当卸下外装时自动显示内衣，确保角色在任意状态下均不赤裸且无破皮重叠。

### 3. 清理调试代码与恢复大厅默认状态
1. 移除大厅舞台 `character_lobby_stage.gd` 中的临时骨骼调试输出与种族硬编码。
2. 恢复初始创角默认选角与初始种族加载（人类男童）。
3. 保证切换那美克星人与魔人时，动画流畅播放，骨骼位姿 100% 正常，新手装备高清呈现。

---

## 四、 编译与验证状态

- **引擎版本**：Godot Engine v4.7.2.stable.official.ed1daf0bf
- **控制台编译**：通过，退出码 0，零红字报错。
- **动作播放**：全种族儿童骨骼重定向准确，Idle、Run 等核心切片动作平滑舒展，扭曲扭结问题彻底消除。
- **装备外观**：人类、那美克、魔人三大种族全部正确显式搭载其官方正统新手道服、战衣与靴子。
