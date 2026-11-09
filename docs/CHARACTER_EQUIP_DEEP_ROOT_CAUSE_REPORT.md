# 龙珠Online (DBOFF) 角色素体与装备显示反复异常深度根因排查与架构解耦重构方案

> 报告存放路径：`docs/CHARACTER_EQUIP_DEEP_ROOT_CAUSE_REPORT.md`  
> 源码权威对照：`E:\OpenDBO-Core-master\DboClient\Lib\NtlPresentation\NtlPLEquipItem.cpp`  
>              `E:\OpenDBO-Core-master\DboClient\Lib\NtlSimulation\NtlSobCharProxyEquip.cpp`  
>              `E:\DBO_CT_TW(1.57.51)\assets\main\script\defaultitemlist.xml`

---

## 目录
1. [核心问题：为什么装备显示改了无数轮，却始终无法彻底正常？](#1-核心问题为什么装备显示改了无数轮却始终无法彻底正常)
2. [对照 OpenDBO 官方底层源码：原版真正的装备与素体渲染机制](#2-对照-opendbo-官方底层源码原版真正的装备与素体渲染机制)
3. [当前工程的致命结构冲突：缝合怪大杂烩 vs 外挂装备](#3-当前工程的致命结构冲突缝合怪大杂烩-vs-外挂装备)
4. [全量母版资产与当前资产盘点（DFF 与 GLB 1:1 核对）](#4-全量母版资产与当前资产盘点dff-与-glb-11-核对)
5. [架构解耦重构方案：模块化插槽装配系统（彻底对标 OpenDBO）](#5-架构解耦重构方案模块化插槽装配系统彻底对标-opendbo)

---

## 1. 核心问题：为什么装备显示改了无数轮，却始终无法彻底正常？

在过去多轮修改中，系统始终在以下四种异常状态之间恶性循环：
1. **断手/断肢问题**：人类、那美克、魔人男童/女童丢失左手，右手看似叠加两个手套；
2. **底裤与大腿穿模糊住问题**：穿上新手道服后，双腿被白色底裤布料糊满，上身变成裸身光膀子；
3. **身体不自然膨胀与重叠问题**：那美克儿童躯体异常肿大，身上套了多层素体；
4. **缺少装备误判**：误以为资产库缺失魔人男童装备。

每次修改一个地方，另一个地方就会崩溃。**其根本原因绝不是简单的几行代码语法写错，而是当前工程沿用的旧架构与官方 OpenDBO 的正规管线存在根本性的逻辑冲突！**

---

## 2. 对照 OpenDBO 官方底层源码：原版真正的装备与素体渲染机制

通过深入查阅 `E:\OpenDBO-Core-master` 客户端源码与 `defaultitemlist.xml`，揭示了官方 100% 的真实设计：

### (1) 官方根本不存在“连体素体大杂烩”
在原版 DBO 中，**角色由 6 个完全独立的插槽（Slot）模块化拼装而成**（见 `NtlPLEquipItem.cpp` 第 307~332 行 与 `defaultitemlist.xml`）：
- `HEAD_MESH`：独立发型部件（如 `A_HCH_HEAD01_H_M` 至 `10`）
- `FACE_MESH`：独立脸部部件（如 `A_HCH_FACE_H_M`）
- `BODY_MESH / EQUIP_JACKET`：上身躯干（未穿时为裸身皮肤 `A_HCH_J_H_M`；穿道服时为 `A_HFI_04_01_J_H_M`）
- `BODY_MESH / EQUIP_PANTS`：下身（未穿时为打底裤+大腿裸身 `A_HCH_P_H_M`；穿道服长裤时为 `A_HFI_04_01_P_H_M`）
- `BODY_MESH / EQUIP_BOOTS`：脚部（未穿时为赤足光脚 `A_HCH_B_H_M`；穿靴子时为 `A_HFI_04_01_B_H_M`）
- `BODY_MESH / EQUIP_TWO_HAND`：手部（未穿时为手掌皮肤 `A_HCH_H_H_M`；戴拳套时为 `W_GLV_*`）

### (2) 槽位互斥替换原则（Slot Mutex Replacement）
查阅 `NtlPLEquipItem.cpp` 第 101~118 行：
```cpp
// Body는 Slot에 하나만 장착이 가능 하다. (身体部件在同一个槽位中只能装一个)
for(; it != m_listItem.end(); ++it)
{
    CNtlPLItem *plistItem = *it;
    if( g_CheckItemBody(plistItem->GetResType()) )
    {
        if(plistItem->GetEquipSlotType() == eEquipSlotType)
        {
            plistItem->SetRemoveEquip(); // 卸下旧部件
            m_listItem.erase(it);
            break;
        }
    }
}
pItem->SetChangeEquip(m_pOwner, bAttach); // 挂载新部件
m_listItem.push_back(pItem);
```
**关键事实**：
当角色穿上道服长裤时，**默认的打底裤部件直接被卸下移除了！**
角色的腿上**永远只有一层网格**！
因为旧部件直接被卸下了，所以官方从物理上**根本不存在衣服和肉身穿模的问题，也根本不需要在着色器里痛苦地猜测要把哪一个 surface 设成透明！**

---

## 3. 当前工程的致命结构冲突：缝合怪大杂烩 vs 外挂装备

当前工程之所以无数次修不好，是因为历史遗留代码采用了一种与官方完全背道而驰的畸形架构：

### 冲突 1：319KB 的 `human_m_child.glb` 连体大杂烩素体
- 检查 `assets/obj/character/mesh_pc/human_m_child.glb` 发现，它把：
  - 10 种全部发型（`mat_hair_01` ~ `mat_hair_10` + 超赛）
  - 脸部
  - 光膀子（`jacket_skin`）
  - 白色底裤（`pants000`）
  - 大腿皮肤（`pants_skin`）
  - 靴子（`boots001`）
  全部强行缝合在同一个网格里的 21 个 Surface 中！
- 然后，`character_factory.gd` 把这个大杂烩作为 `BaseBody` 加载出来。

### 冲突 2：用着色器透明度（`inv_mat`）盲猜隐藏引发全面崩盘
- 当角色穿上道服和手套时，外装作为一个新的 MeshInstance3D 挂在骨架上。
- 为了不让里面的 `BaseBody` 露出来，`character_visual.gd` 写了上千行复杂的材质覆盖代码，试图去猜哪一个 surface 是手、哪一个是衣服，并赋予全透明材质 `inv_mat`。
- **灾难爆发**：
  1. `human_m_child.glb` 的左手和右手**在同一个 Surface 上**！
  2. 官方原版 DFF 资产中，对称武器（手套 `W_GLV_*`）和靴子在模型里**只有右侧网格**（原版客户端是在运行时镜像）！
  3. 当代码检测到穿手套，把双手 Surface 赋予 `inv_mat` 时，**左手瞬间被截肢，彻底变成空气断臂**！而右手套着拳套，给用户造成“两个手套叠在右手、左手断掉”的假象！
  4. 上一任开发者发现断手断腿后，在代码中加了 `and is_adult`（仅限成人隐藏，儿童不隐藏）。这一加，导致儿童穿上道服长裤后，底下的白色短裤根本没有被隐藏，直接穿透长裤爆出来，双腿被白色底裤布料糊满！
  5. 另一处逻辑又试图在 `_resolve_item_glb_path` 里把道服拦截换成 `A_HCH_P_H_M`，导致在已有大杂烩底裤外面又套了一层底裤，躯体严重膨胀！

---

## 4. 全量母版资产与当前资产盘点（DFF 与 GLB 1:1 核对）

我们对母版目录 `E:\DBO_CT_TW(1.57.51)` 与当前工程 `E:\DBOFF` 进行了全量检索：

| 部件类型 | 人类男童 (HUMAN_M) | 人类女童 (HUMAN_F) | 那美克儿童 (NAMEK) | 魔人男童 (MAJIN_M) | 魔人女童 (MAJIN_F) | 状态 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **发型 (Head)** | `a_hch_head01_h_m.glb` | `a_hch_head01_h_f.glb` | `a_nam_head01_n_o_s1.glb`| `a_maj_head01_m_m.glb` | `a_mch_head01_m_f.glb` | **全部存在** |
| **脸部 (Face)** | `a_hch_face_h_m.glb`   | `a_hch_face_h_f.glb`   | `a_nam_face_n_o_s1.glb`  | `a_maj_face_m_m.glb`   | `a_mch_face_m_f.glb`   | **全部存在** |
| **上身 (Jacket)** | `a_hch_j_h_m.glb`     | `a_hch_j_h_f.glb`     | `a_nam_j_n_o_s1.glb`     | `a_maj_j_m_m.glb`     | `a_mch_j_m_f.glb`     | **全部存在** |
| **下身 (Pants)** | `a_hch_p_h_m.glb`     | `a_hch_p_h_f.glb`     | `a_nam_p_n_o_s1.glb`     | `a_maj_p_m_m.glb`     | `a_mch_p_m_f.glb`     | **全部存在** |
| **脚部 (Boots)** | `a_hch_b_h_m.glb`     | `a_hch_b_h_f.glb`     | `a_nam_b_n_o_s1.glb`     | `a_maj_b_m_m.glb`     | `a_mch_b_m_f.glb`     | **全部存在** |
| **手部 (Hands)** | `a_hch_h_h_m.glb`     | `a_hch_h_h_f.glb`     | `a_nam_h_n_o_s1.glb`     | `a_maj_h_m_m.glb`     | `a_mch_h_m_f.glb`     | **全部存在** |

**结论**：
当前工程资产库中，**各族所有儿童的独立模块化部件一应俱全，全量存在于 `assets/obj/item/` 目录下！资产完全不需要重新导出或伪造，母版资源完整无缺！**

---

## 5. 架构解耦重构方案：模块化插槽装配系统（彻底对标 OpenDBO）

为了彻底根治这一问题，杜绝脚本语句冲突与材质猜谜，必须将系统重构成清爽的**模块化插槽架构**：

```
+-------------------------------------------------------------+
|                      DBOCharacterVisual                     |
+-------------------------------------------------------------+
                              |
                     Skeleton3D (唯一骨架)
                              |
       +----------+----------+----------+----------+----------+
       |          |          |          |          |          |
    [head]     [face]     [torso]    [legs]     [feet]     [hands]
     发型       脸部       上装       下装       鞋部       手/武器
  (独立模型) (独立模型) (互斥替换) (互斥替换) (互斥替换) (互斥镜像)
```

### 解耦后各槽位运行规则：
1. **脱光裸身状态（未穿装备）**：
   - `torso` 槽位挂载对应种族的裸身上身（如 `a_hch_j_h_m.glb`，光膀子皮肤）
   - `legs` 槽位挂载对应种族的默认短裤（如 `a_hch_p_h_m.glb`，白色短裤）
   - `feet` 槽位挂载默认光脚（如 `a_hch_b_h_m.glb`）
   - `hands` 槽位挂载默认双手（如 `a_hch_h_h_m.glb`）
2. **穿戴装备状态**：
   - 当装备新手道服上衣 `A_HFI_04_01_J` 时：直接将 `torso` 槽位旧的 `a_hch_j_h_m` **销毁移除**，替换为 `a_hfi_04_01_j_h_m.glb`！
   - 当装备新手道服长裤 `A_HFI_04_01_P` 时：直接将 `legs` 槽位旧的短裤 `a_hch_p_h_m` **销毁移除**，替换为 `a_hfi_04_01_p_h_m.glb`！
   - 当装备靴子时：将 `feet` 槽位直接替换为靴子；
   - 当装备手套时：将 `hands` 槽位直接替换为双侧镜像拳套；
3. **彻底根除三大历史毒瘤**：
   - **零穿模**：每个部位永远只有一件衣服，物理上不存在双层重叠；
   - **零断肢**：手和脚是独立部件，永远不会因为上衣下衣隐藏而被误伤截肢；
   - **零材质猜谜**：不再需要任何 `inv_mat` 猜 Surface，也不需要任何 `s == 4` 的脆弱硬编码。
