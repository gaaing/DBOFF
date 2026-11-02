# DBOFF 骨骼动画资产全量映射登记表 (Animation Registry)

> 统计基准：共计 **5,302** 个独立 GLB 骨骼动画切片文件。
> 映射机制：AnimationPlayer + AnimationLibrary 纯动态内存注入，零冗余场景烘焙。

## 1. 各族群与对象动画库统计 (Animation Libraries)

| 动画库名称 | 资源路径 | 动画文件数量 | 适用对象 | 证据状态 |
|---|---|---|---|---|
| `animation_candy` | `res://assets/obj/character/animation_candy/` | **2** | Candy | `VERIFIED` |
| `animation_humanfemale` | `res://assets/obj/character/animation_humanfemale/` | **312** | Humanfemale | `VERIFIED` |
| `animation_humanmale` | `res://assets/obj/character/animation_humanmale/` | **391** | Humanmale | `VERIFIED` |
| `animation_majinfemale` | `res://assets/obj/character/animation_majinfemale/` | **278** | Majinfemale | `VERIFIED` |
| `animation_majinmale` | `res://assets/obj/character/animation_majinmale/` | **373** | Majinmale | `VERIFIED` |
| `animation_mob` | `res://assets/obj/character/animation_mob/` | **0** | Mob | `VERIFIED` |
| `animation_namek` | `res://assets/obj/character/animation_namek/` | **382** | Namek | `VERIFIED` |
| `animation_npc` | `res://assets/obj/character/animation_npc/` | **3,171** | Npc | `VERIFIED` |
| `animation_vehicle` | `res://assets/obj/character/animation_vehicle/` | **240** | Vehicle | `VERIFIED` |
| `animation_weapon` | `res://assets/obj/item/animation_weapon/` | **153** | Weapon | `VERIFIED` |

## 2. 核心状态机动作映射表 (Core Action Keys)

| 动作键名 (Action Key) | 动作含义 | 优先匹配候选名 | 状态 |
|---|---|---|---|
| `idle` | 站立待机 | `idle`, `nml_idle_loop`, `idle_front` | `VERIFIED` |
| `walk` | 向前行走 | `walk`, `nml_walk_loop`, `walk_front` | `VERIFIED` |
| `run` | 疾跑 | `run`, `nml_run_loop`, `run_front` | `VERIFIED` |
| `walk_back` | 后退 | `walk_back`, `nml_walk_back_loop`, `walk_back_front` | `VERIFIED` |
| `run_back` | 后退疾跑 | `run_back`, `nml_run_back_loop`, `run_back_front` | `VERIFIED` |
| `jump_start` | 起跳 | `jump_start`, `nml_jump_start_loop`, `jump_start_front` | `VERIFIED` |
| `jump_hover` | 空中悬停/滞空 | `jump_hover`, `nml_jump_hover_loop`, `jump_hover_front` | `VERIFIED` |
| `jump_landing` | 着地 | `jump_landing`, `nml_jump_landing_loop`, `jump_landing_front` | `VERIFIED` |
| `charge_start` | 聚气起始 | `charge_start`, `nml_charge_start_loop`, `charge_start_front` | `VERIFIED` |
| `charge_loop` | 聚气循环 | `charge_loop`, `nml_charge_loop_loop`, `charge_loop_front` | `VERIFIED` |
| `charge_end` | 聚气收招 | `charge_end`, `nml_charge_end_loop`, `charge_end_front` | `VERIFIED` |
| `sit_down` | 坐下 | `sit_down`, `nml_sit_down_loop`, `sit_down_front` | `VERIFIED` |
| `sit_idle` | 打坐待机 | `sit_idle`, `nml_sit_idle_loop`, `sit_idle_front` | `VERIFIED` |
| `block_loop` | 格挡防守 | `block_loop`, `nml_block_loop_loop`, `block_loop_front` | `VERIFIED` |
| `attack_01` | 普通攻击 1 段 | `attack_01`, `nml_attack_01_loop`, `attack_01_front` | `VERIFIED` |
| `attack_02` | 普通攻击 2 段 | `attack_02`, `nml_attack_02_loop`, `attack_02_front` | `VERIFIED` |
| `attack_03` | 普通攻击 3 段 | `attack_03`, `nml_attack_03_loop`, `attack_03_front` | `VERIFIED` |
| `hurt` | 受击硬直 | `hurt`, `nml_hurt_loop`, `hurt_front` | `VERIFIED` |
| `faint` | 眩晕昏厥 | `faint`, `nml_faint_loop`, `faint_front` | `VERIFIED` |
| `knockdown_fall` | 击倒倒地 | `knockdown_fall`, `nml_knockdown_fall_loop`, `knockdown_fall_front` | `VERIFIED` |

## 3. 骨骼重定向与成人/儿童防拉伸机制

- **路径精准重定向**: `load_character_animations` 读取 GLB 中的 `Bone_X` 或 `Bip01 ...` 轨道，映射至角色当前的真实 Skeleton3D 骨骼名称；
- **子骨骼位移过滤**: 仅允许根骨骼 `Bip01` 携带位移轨道，子骨骼的位移一律剥离，杜绝成人肢体长度强行拉扯儿童骨骼导致撕裂；
- **根骨骼高程补偿**: 对 `Bip01` 根骨骼位移计算 `delta_y`，使儿童脚底 100% 严密贴合地面。
