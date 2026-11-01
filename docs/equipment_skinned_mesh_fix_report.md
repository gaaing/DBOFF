# 装备蒙皮管线修复报告（T-Pose 浮空根因排查）

## 问题现象（截图复盘）

| 现象 | 表现 |
|------|------|
| 手套 T-Pose 浮空 | 所有种族均出现黑色手套以张开姿势浮在角色两侧 |
| 史考特位置错误 | 史考特浮在脚边地面而非头部眼部 |
| 上装/下装不显示（人类/魔人女） | 上装和裤子缺失，人类仍仅内裤；那美克有盔甲说明部分 Skin 有效 |

---

## 根本原因（深度逆向分析）

### 原代码错误流程
```
load(glb_path)         → PackedScene
  → instantiate()      → 临时节点树
    → find_child("MeshInstance3D")
      → 取 mesh_inst.mesh  ⚠️ 只复制 Mesh 资源，丢弃 Skin
        → new MeshInstance3D()  ← 新节点没有骨骼绑定矩阵
          → skeleton.add_child()  ← 蒙皮数据为零
            → T-Pose 冻结浮空！
```

### 根本原理
每个骨骼蒙皮 GLB 导出时，顶点绑定了一套**逆绑定矩阵（Inverse Bind Matrix, IBM）**，存储在 `MeshInstance3D.skin` 中。当 `skin = null` 时，Godot 的 GPU 蒙皮器无法正确变形顶点，网格以 Rest Pose（T-Pose）静态渲染，随角色位置移动但不随骨骼弯曲。

旧工程 `report_equipment_and_weapon_visual_fix.md` 已明确记录：
> *"手套...不是普通的刚体道具，而是拥有 54 根骨骼的完整蒙皮网格！"*
> *"彻底废除 mesh_inst.skin = skinned_mesh.skin 的暴力覆盖，保留 GLTF 导入器为装备生成的原生独立 Skin"*

---

## 修复方案

### 1. `character_factory.gd` — `equip_item_to_character` 完全重写

**旧流程**：`load()` → `instantiate()` → 提取 `mesh`（丢失 Skin）  
**新流程**：`GLTFDocument.append_from_file()` → `generate_scene()` → 提取 `MeshInstance3D` 并保留其 `skin`

```
GLTFDocument.append_from_file(glb_path, state, 0)   # 动态解析 GLB
  → generate_scene(state)                            # 生成完整场景树
    → find MeshInstance3D                            # 找到蒙皮节点
      → own_skin = mesh_inst.skin                    # ✅ 保留原始 Skin
        → mesh_inst.skin = own_skin                  # ✅ 应用到新位置
          → mesh_inst.skeleton = NodePath("..")      # ✅ 指向同一 Skeleton3D
            → skeleton.add_child(mesh_inst)          # ✅ 正确蒙皮渲染
```

### 2. 装备分类路由

| 装备类型 | slot_flag | 处理方式 |
|---------|-----------|---------|
| 上装/下装/靴子 | 4/8/16 | GLTFDocument 蒙皮管线 |
| 手套 (`glv` in model) | 1 | GLTFDocument 蒙皮管线（同上） |
| 武器（非手套） | 1/2 | BoneAttachment3D 骨骼附件 |
| 史考特 | 32 | BoneAttachment3D 头部骨骼附件 |

### 3. `character_visual.gd` — 新增 `attach_item_to_bone()`

史考特和武器通过 `BoneAttachment3D` 挂载到 `nulleye`/`Bip01 Head` 骨骼（史考特）或 `nullRhand`/`Bip01 R Hand` 骨骼（武器），用 GLTFDocument 加载其 mesh，attach 到骨骼跟随动画运动。

---

## 保留的完备效果

- ✅ 多表面发型切换
- ✅ 那美克 5 套皮肤
- ✅ 面部着色器
- ✅ 内裤/内衣（`_update_base_body_visibility` 逻辑不变）
- ✅ 儿童/成人模型路由（`_to_child_model_key`）
- ✅ 发型 UV 翻转修正

---

## 修改文件

| 文件 | 修改内容 |
|------|---------|
| `src/entities/character_factory.gd` | `equip_item_to_character` 改用 GLTFDocument 保留 Skin；按 slot_flag+model 分类路由 |
| `src/entities/character_visual.gd` | 新增 `attach_item_to_bone()` 方法，用 BoneAttachment3D 挂载史考特/武器 |
