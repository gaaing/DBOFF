# DBOFF 角色、种族与职业架构映射表 (Character & Class Registry)

> 对标 OpenDBO-Core: `NtlCharacterState.h`、`NewbieTable.h`、`CNtlPLCharacter.cpp`。

## 1. 种族与职业晋升图谱 (Race & Class Progression)

| 种族 ID | 种族名称 | 基础职业 (Class ID) | 一转大师职业 (Master Class ID) | 核心特性 |
|---|---|---|---|---|
| `0` | **人类** (HUMAN) | `武道家` (ID:0) | `战士` (ID:1) / `剑客` (ID:2) | 气功/近战平衡 |
| `0` | **人类** (HUMAN) | `气功师` (ID:1) | `鹤仙流` (ID:3) / `龟仙流` (ID:4) | 气功/近战平衡 |
| `1` | **那美克星人** (NAMEK) | `战士` (ID:2) | `魔界战士` (ID:5) / `魔导士` (ID:6) | 气功/近战平衡 |
| `1` | **那美克星人** (NAMEK) | `龙族` (ID:3) | `天天导士` (ID:7) / `波克导士` (ID:8) | 气功/近战平衡 |
| `2` | **魔人** (MAJIN) | `大魔人` (ID:4) | `至尊魔人` (ID:9) / `食神魔人` (ID:10) | 气功/近战平衡 |
| `2` | **魔人** (MAJIN) | `意魔人` (ID:5) | `幻魔人` (ID:11) / `影魔人` (ID:12) | 气功/近战平衡 |

## 2. 素体模型与骨骼配置映射 (Base Body Models & Skeletons)

| 角色类别 | 对应 GLB 文件 | 状态 | 文件体积 | 骨骼数量 (Joints) | 网格 Surfaces | 结构说明 |
|---|---|---|---|---|---|---|
| `human_male_adult` | `a_hum_m_ad.glb` | `VERIFIED` | 179,780 B | 0 | 16 | 裸模素体 (走模块化防具拼装) |
| `human_female_adult` | `a_hum_f_ad.glb` | `VERIFIED` | 201,728 B | 0 | 21 | 裸模素体 (走模块化防具拼装) |
| `namek_adult` | `a_nam_ad.glb` | `VERIFIED` | 108,400 B | 0 | 15 | 裸模素体 (走模块化防具拼装) |
| `majin_male_adult` | `a_maj_m_m.glb` | `VERIFIED` | 129,172 B | 0 | 16 | 裸模素体 (走模块化防具拼装) |
| `majin_female_adult` | `a_maj_m_f_ad.glb` | `VERIFIED` | 141,908 B | 0 | 17 | 裸模素体 (走模块化防具拼装) |
| `human_male_child` | `human_m_child.glb` | `VERIFIED` | 319,352 B | 50 | 21 | 内嵌新手武道服图元 (免外挂防具) |
| `human_female_child` | `human_f_child.glb` | `VERIFIED` | 355,312 B | 52 | 26 | 内嵌新手武道服图元 (免外挂防具) |
| `namek_child` | `namek_m_child.glb` | `VERIFIED` | 198,132 B | 54 | 18 | 内嵌新手武道服图元 (免外挂防具) |
| `majin_male_child` | `majin_m_child.glb` | `VERIFIED` | 229,416 B | 50 | 19 | 内嵌新手武道服图元 (免外挂防具) |
| `majin_female_child` | `majin_f_child.glb` | `VERIFIED` | 254,432 B | 57 | 20 | 内嵌新手武道服图元 (免外挂防具) |

## 3. 挂点骨骼与装备槽位对应 (Bone Attachments)

- **头部/眼部 (Scouter)**: `nulleye`（首选，若无则回退到 `Bip01 Head`）
- **主手武器 (Main Weapon)**: `Bip01 R Hand`（手部骨骼附件节点，位置 `Vector3.ZERO`）
- **副手武器 (Sub Weapon)**: `Bip01 L Hand`
- **成人蒙皮防具 (Skinned Armor)**: 共享素体主 `Skeleton3D` 节点，使用 `IMPORT_FLAG_USE_NAMED_SKIN_BINDS`。

