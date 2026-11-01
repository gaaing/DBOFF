# 创角界面基础装备显示修复报告

## 任务目标
在创建角色界面（以及选角大厅）中，各种族各职业的儿童素体应穿戴对应的新手基础装备（上装、下装、靴子），而非仅显示内裤/裸体素体。

---

## 根本原因

| 位置 | 原封锁代码 | 效果 |
|------|-----------|------|
| `character_factory.gd:534` | `if visual == null or not visual.is_adult: return` | 儿童 visual 直接跳过装备挂载 |
| `character_lobby_stage.gd:563` | `... and current_visual_instance.is_adult` | 儿童 visual 不进入装备循环 |

由于创角界面始终使用 `is_adult = false` 的儿童素体，以上两处封锁导致所有种族所有职业的新手装备完全不显示。

---

## 修复方案

### 1. `character_factory.gd` — 移除成人封锁 + 儿童装备路由

**`equip_item_to_character`**：
- 移除 `not visual.is_adult` 封锁
- 读取 `visual.is_adult` 并传入 `_resolve_item_glb_path`

**`_resolve_item_glb_path`** 新增 `is_adult: bool = true` 参数：
- `is_adult = false` 时，先调用 `_to_child_model_key()` 将成人 key 转换为儿童专用 key
- 转换规律：
  - `A_HFI_04_01_J` → `A_HCH_J` → `a_hch_j_h_m.glb` / `a_hch_j_h_f.glb`
  - `A_NFI_04_01_J` → `A_NCH_J` → `a_nch_j_n_o_s1.glb`
  - `A_MMI_04_01_J` / `A_MWO_04_01_J` → `A_MCH_J` → `a_mch_j_m_f.glb`

**新增辅助函数 `_to_child_model_key(u, race, gender)`**：
- 提取 key 末尾的装备类型字符（`_J`, `_P`, `_B`, `_H`）
- 按种族拼出儿童 key：`A_HCH_*` / `A_NCH_*` / `A_MCH_*`

### 2. `character_lobby_stage.gd` — 移除 `is_adult` 门控

```gdscript
# 修改前
if current_visual_instance and not equipped_items.is_empty() and current_visual_instance.is_adult:

# 修改后
if current_visual_instance and not equipped_items.is_empty():
```

---

## 儿童装备 GLB 映射清单

| 种族/性别 | 上装(J) | 下装(P) | 靴子(B) |
|----------|---------|---------|---------|
| 人类男童 | `a_hch_j_h_m.glb` | `a_hch_p_h_m.glb` | `a_hch_b_h_m.glb` |
| 人类女童 | `a_hch_j_h_f.glb` | `a_hch_p_h_f.glb` | `a_hch_b_h_f.glb` |
| 那美克童 | `a_nch_j_n_o_s1.glb` | `a_nch_p_n_o_s1.glb` | `a_nch_b_n_o_s1.glb` |
| 魔人童(魔人分) | `a_mch_j_m_f.glb` | `a_mch_p_m_f.glb` | `a_mch_b_m_f.glb` |

所有上述 GLB 已在 `assets/obj/item/mesh_armor_*` 目录中确认存在。

---

## 新手装备 tblidx 对应关系

| 种族/职业 | 上装(pos=2) | 下装(pos=3) | 靴子(pos=4) | 原始模型 key |
|----------|-----------|-----------|-----------|------------|
| 人类战士/格斗家 | 522001 | 522002 | 522003 | A_HFI_04_01_J/P/B |
| 人类气功师 | 523001 | 523002 | 523003 | A_HMY_04_01_J/P/B |
| 那美克龙族 | 525001 | 525002 | 525003 | A_NFI_04_01_J/P/B |
| 那美克神族 | 526001 | 526002 | 526003 | A_NMY_04_01_J/P/B |
| 魔人男 | 527001 | 527002 | 527003 | A_MMI_04_01_J/P/B |
| 魔人女 | 528001 | 528002 | 528003 | A_MWO_04_01_J/P/B |

---

## 保留的完备效果（未受影响）

- ✅ 多表面发型切换（Surface Swap mat_hair_01~10）
- ✅ 面部着色器（CHARACTER_FACE_SHADER 动态换贴图）
- ✅ 那美克 5 套皮肤完整贴图调色板
- ✅ 内裤层（无装备时 pants000/jacket000 正常显示）
- ✅ 超级赛亚人发型（mat_hair_ssj 隐形/激活切换）
- ✅ 发型 02~10 UV 翻转修正
- ✅ 动画播放与相机控制

---

## 修改文件

| 文件 | 修改内容 |
|------|---------|
| `src/entities/character_factory.gd` | 移除 `is_adult` 封锁；`_resolve_item_glb_path` 新增 `is_adult` 参数；新增 `_to_child_model_key` 辅助函数 |
| `src/ui/lobby/character_lobby_stage.gd` | 移除装备循环中的 `is_adult` 门控条件 |
