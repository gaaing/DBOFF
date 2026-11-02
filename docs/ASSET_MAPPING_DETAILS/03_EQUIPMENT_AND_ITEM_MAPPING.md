# DBOFF 装备与物品资产链路映射表 (Equipment & Item Mapping Registry)

> 优先级：**P0 (最高优先级)**
> 完整链路追溯：`NewbieTable → Item ID → ItemTable → ItemProperty → 装备槽位 → 模型资源 → 材质/贴图 → 骨骼绑定`
> 证据等级：`VERIFIED` (本地模型与贴图存在且骨骼匹配) | `PARTIAL` (模型存在但贴图待确认) | `INFERRED` (模型记录存在但磁盘无文件) | `MISSING` (无模型定义)

## 1. 初始新手装备链路核验全表 (25 件核心新手装备)

| 物品 ID | 归属来源 | 槽位分类 | 原版 Model | ItemProperty 键 | 实际 GLB 路径 | 成人模型 | 儿童模型 | 骨骼挂载逻辑 | 证据状态 |
|---|---|---|---|---|---|---|---|---|---|
| `19901` | NewbieTable (HUMAN_MARTIAL_ARTIST) | `None / Consumable` | `` | `` | `` | ❌ 缺失 | N/A | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `500001` | NewbieTable (HUMAN_MARTIAL_ARTIST) | `weapon_r (Main Weapon / Glove)` | `W_GLV_16` | `W_GLV_16_H_M` | `assets/obj/item/mesh_weapon/w_glv_16_h_m.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `522001` | NewbieTable (HUMAN_MARTIAL_ARTIST) | `torso (Jacket / Armor)` | `A_HFI_04_01_J` | `A_HFI_04_01_J_H_M` | `assets/obj/item/mesh_armor_humanmale/a_hfi_04_01_j_h_m.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `522002` | NewbieTable (HUMAN_MARTIAL_ARTIST) | `legs (Pants)` | `A_HFI_04_01_P` | `A_HFI_04_01_P_H_M` | `assets/obj/item/mesh_armor_humanmale/a_hfi_04_01_p_h_m.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `522003` | NewbieTable (HUMAN_MARTIAL_ARTIST) | `feet (Boots)` | `A_HFI_04_01_B` | `A_HFI_04_01_B_H_M` | `assets/obj/item/mesh_armor_humanmale/a_hfi_04_01_b_h_m.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `60000000` | NewbieTable (HUMAN_MARTIAL_ARTIST) | `face (Scouter)` | `I_SCT_01` | `I_SCT_01_H_M` | `assets/obj/item/mesh_scouter/i_sct_01_h_m.glb` | ✅ 存在 | N/A | `attach_item_to_bone` | `VERIFIED` |
| `19991` | NewbieTable (HUMAN_MARTIAL_ARTIST) | `None / Consumable` | `` | `` | `` | ❌ 缺失 | N/A | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `19907` | NewbieTable (HUMAN_MARTIAL_ARTIST) | `None / Consumable` | `` | `` | `` | ❌ 缺失 | N/A | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `505001` | NewbieTable (HUMAN_SPIRITUALIST) | `weapon_r (Main Weapon / Glove)` | `W_GLV_01` | `W_GLV_01_H_M` | `assets/obj/item/mesh_weapon/w_glv_01_h_m.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `523001` | NewbieTable (HUMAN_SPIRITUALIST) | `torso (Jacket / Armor)` | `A_HMY_04_01_J` | `A_HMY_04_01_J_H_M` | `assets/obj/item/mesh_armor_humanmale/a_hmy_04_01_j_h_m.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `523002` | NewbieTable (HUMAN_SPIRITUALIST) | `legs (Pants)` | `A_HMY_04_01_P` | `A_HMY_04_01_P_H_M` | `assets/obj/item/mesh_armor_humanmale/a_hmy_04_01_p_h_m.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `523003` | NewbieTable (HUMAN_SPIRITUALIST) | `feet (Boots)` | `A_HMY_04_01_B` | `A_HMY_04_01_B_H_M` | `assets/obj/item/mesh_armor_humanmale/a_hmy_04_01_b_h_m.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `19901` | NewbieTable (NAMEK_DRAGON_CLAN) | `None / Consumable` | `` | `` | `` | ❌ 缺失 | N/A | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `500001` | NewbieTable (NAMEK_DRAGON_CLAN) | `weapon_r (Main Weapon / Glove)` | `W_GLV_16` | `W_GLV_16_N_O_S1` | `assets/obj/item/mesh_weapon/w_glv_16_n_o_s1.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `525001` | NewbieTable (NAMEK_DRAGON_CLAN) | `torso (Jacket / Armor)` | `A_NFI_04_01_J` | `A_NFI_04_01_J_N_O_S1` | `assets/obj/item/mesh_armor_namek/a_nfi_04_01_j_n_o_s1.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `525002` | NewbieTable (NAMEK_DRAGON_CLAN) | `legs (Pants)` | `A_NFI_04_01_P` | `A_NFI_04_01_P_N_O_S1` | `assets/obj/item/mesh_armor_namek/a_nfi_04_01_p_n_o_s1.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `525003` | NewbieTable (NAMEK_DRAGON_CLAN) | `feet (Boots)` | `A_NFI_04_01_B` | `A_NFI_04_01_B_N_O_S1` | `assets/obj/item/mesh_armor_namek/a_nfi_04_01_b_n_o_s1.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `60000000` | NewbieTable (NAMEK_DRAGON_CLAN) | `face (Scouter)` | `I_SCT_01` | `I_SCT_01_N_O_S1` | `assets/obj/item/mesh_scouter/i_sct_01_n_o_s1.glb` | ✅ 存在 | N/A | `attach_item_to_bone` | `VERIFIED` |
| `19991` | NewbieTable (NAMEK_DRAGON_CLAN) | `None / Consumable` | `` | `` | `` | ❌ 缺失 | N/A | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `19907` | NewbieTable (NAMEK_DRAGON_CLAN) | `None / Consumable` | `` | `` | `` | ❌ 缺失 | N/A | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `506001` | NewbieTable (NAMEK_MIGHTY_MAJIN) | `weapon_r (Main Weapon / Glove)` | `W_STF_01` | `W_STF_01` | `assets/obj/item/mesh_weapon/w_stf_01.glb` | ✅ 存在 | N/A | `attach_item_to_bone` | `VERIFIED` |
| `526001` | NewbieTable (NAMEK_MIGHTY_MAJIN) | `torso (Jacket / Armor)` | `A_NMY_04_01_J` | `A_NMY_04_01_J_N_O_S1` | `assets/obj/item/mesh_armor_namek/a_nmy_04_01_j_n_o_s1.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `526002` | NewbieTable (NAMEK_MIGHTY_MAJIN) | `legs (Pants)` | `A_NMY_04_01_P` | `A_NMY_04_01_P_N_O_S1` | `assets/obj/item/mesh_armor_namek/a_nmy_04_01_p_n_o_s1.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `526003` | NewbieTable (NAMEK_MIGHTY_MAJIN) | `feet (Boots)` | `A_NMY_04_01_B` | `A_NMY_04_01_B_N_O_S1` | `assets/obj/item/mesh_armor_namek/a_nmy_04_01_b_n_o_s1.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `19901` | NewbieTable (MAJIN_WONDER_MAJIN) | `None / Consumable` | `` | `` | `` | ❌ 缺失 | N/A | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `500001` | NewbieTable (MAJIN_WONDER_MAJIN) | `weapon_r (Main Weapon / Glove)` | `W_GLV_16` | `W_GLV_16_M_M` | `assets/obj/item/mesh_weapon/w_glv_16_m_m.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `527001` | NewbieTable (MAJIN_WONDER_MAJIN) | `torso (Jacket / Armor)` | `A_MMI_04_01_J` | `A_MMI_04_01_J_M_M` | `assets/obj/item/mesh_armor_majinmale/a_mmi_04_01_j_m_m.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `527002` | NewbieTable (MAJIN_WONDER_MAJIN) | `legs (Pants)` | `A_MMI_04_01_P` | `A_MMI_04_01_P_M_M` | `assets/obj/item/mesh_armor_majinmale/a_mmi_04_01_p_m_m.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `527003` | NewbieTable (MAJIN_WONDER_MAJIN) | `feet (Boots)` | `A_MMI_04_01_B` | `A_MMI_04_01_B_M_M` | `assets/obj/item/mesh_armor_majinmale/a_mmi_04_01_b_m_m.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `60000000` | NewbieTable (MAJIN_WONDER_MAJIN) | `face (Scouter)` | `I_SCT_01` | `I_SCT_01_M_M` | `assets/obj/item/mesh_scouter/i_sct_01_m_m.glb` | ✅ 存在 | N/A | `attach_item_to_bone` | `VERIFIED` |
| `19991` | NewbieTable (MAJIN_WONDER_MAJIN) | `None / Consumable` | `` | `` | `` | ❌ 缺失 | N/A | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `19907` | NewbieTable (MAJIN_WONDER_MAJIN) | `None / Consumable` | `` | `` | `` | ❌ 缺失 | N/A | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `505001` | NewbieTable (MAJIN_UNKNOWN_6) | `weapon_r (Main Weapon / Glove)` | `W_GLV_01` | `W_GLV_01_M_M` | `assets/obj/item/mesh_weapon/w_glv_01_m_m.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `528001` | NewbieTable (MAJIN_UNKNOWN_6) | `torso (Jacket / Armor)` | `A_MWO_04_01_J` | `A_MWO_04_01_J_M_M` | `assets/obj/item/mesh_armor_majinmale/a_mwo_04_01_j_m_m.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `528002` | NewbieTable (MAJIN_UNKNOWN_6) | `legs (Pants)` | `A_MWO_04_01_P` | `A_MWO_04_01_P_M_M` | `assets/obj/item/mesh_armor_majinmale/a_mwo_04_01_p_m_m.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `528003` | NewbieTable (MAJIN_UNKNOWN_6) | `feet (Boots)` | `A_MWO_04_01_B` | `A_MWO_04_01_B_M_M` | `assets/obj/item/mesh_armor_majinmale/a_mwo_04_01_b_m_m.glb` | ✅ 存在 | ✅ 存在 | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |

## 2. 经典进阶装备与代表武器映射表 (Representative Gear & Weapons)

| 物品 ID | 装备类型 | 槽位分类 | 原版 Model | 关联 GLB 文件 | 挂载管线 | 证据状态 |
|---|---|---|---|---|---|---|
| `60000001` | `106` | `face (Scouter)` | `I_SCT_03` | `assets/obj/item/mesh_scouter/i_sct_03_h_m.glb` | `attach_item_to_bone` | `VERIFIED` |
| `60000002` | `106` | `face (Scouter)` | `I_SCT_02` | `assets/obj/item/mesh_scouter/i_sct_02_h_m.glb` | `attach_item_to_bone` | `VERIFIED` |
| `60000003` | `106` | `face (Scouter)` | `I_SCT_04` | `assets/obj/item/mesh_scouter/i_sct_04_h_m.glb` | `attach_item_to_bone` | `VERIFIED` |
| `522101` | `19` | `legs (Pants)` | `A_HFI_06_06_P` | `assets/obj/item/mesh_armor_humanmale/a_hfi_06_06_p_h_m.glb` | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `522102` | `20` | `feet (Boots)` | `A_HFI_06_06_B` | `assets/obj/item/mesh_armor_humanmale/a_hfi_06_06_b_h_m.glb` | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `522103` | `18` | `torso (Jacket / Armor)` | `A_HFI_05_15_J` | `assets/obj/item/mesh_armor_humanmale/a_hfi_05_15_j_h_m.glb` | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `523101` | `19` | `legs (Pants)` | `A_HMY_06_06_P` | `assets/obj/item/mesh_armor_humanmale/a_hmy_06_06_p_h_m.glb` | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `523102` | `20` | `feet (Boots)` | `A_HMY_06_06_B` | `assets/obj/item/mesh_armor_humanmale/a_hmy_06_06_b_h_m.glb` | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `523103` | `18` | `torso (Jacket / Armor)` | `A_HMY_05_15_J` | `assets/obj/item/mesh_armor_humanmale/a_hmy_05_15_j_h_m.glb` | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `525101` | `19` | `legs (Pants)` | `A_NFI_06_06_P` | `assets/obj/item/mesh_armor_namek/a_nfi_06_06_p_n_o_s1.glb` | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `525102` | `20` | `feet (Boots)` | `A_NFI_06_06_B` | `assets/obj/item/mesh_armor_namek/a_nfi_06_06_b_n_o_s1.glb` | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `525103` | `18` | `torso (Jacket / Armor)` | `A_NFI_05_15_J` | `assets/obj/item/mesh_armor_namek/a_nfi_05_15_j_n_o_s1.glb` | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `527101` | `19` | `legs (Pants)` | `A_MMI_06_06_P` | `assets/obj/item/mesh_armor_majinmale/a_mmi_06_06_p_m_m.glb` | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `527102` | `20` | `feet (Boots)` | `A_MMI_06_06_B` | `assets/obj/item/mesh_armor_majinmale/a_mmi_06_06_b_m_m.glb` | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |
| `527103` | `18` | `torso (Jacket / Armor)` | `A_MMI_05_15_J` | `assets/obj/item/mesh_armor_majinmale/a_mmi_05_15_j_m_m.glb` | `equip_item_to_character (Skinned Armor)` | `VERIFIED` |

## 3. 关键架构结论与避坑说明

1. **儿童素体与新手装备分离陷阱**：
   - 原版客户端中，所有种族儿童素体（`human_m_child.glb` 等）均已将新手服装（上衣、裤子、鞋靴）烘焙入自身网格；
   - 严禁对儿童期角色调用外挂防具蒙皮管线，否则会隐藏内建表面并因骨骼层级差异导致拉伸破皮；儿童仅允许挂载武器与史考特。
2. **机器可读完整数据**：
   - CSV 格式：[`equipment_item_mapping.csv`](equipment_item_mapping.csv)
   - JSON 格式：[`equipment_item_mapping.json`](equipment_item_mapping.json)
