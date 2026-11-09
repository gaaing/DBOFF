# “丢了一只手、丢了一只脚、头顶拉出折线黑梁”全链路根本原因深度排查与终极修复报告

> **编制日期**：2026-11-04  
> **报告位置**：`docs/HAND_AND_FOOT_ROOT_CAUSE_AND_RESOLUTION_REPORT.md`  
> **权威参考**：  
> - OpenDBO-Core 官方客户端底层源码：`E:\OpenDBO-Core-master\DboClient\Lib\NtlPresentation\NtlPLEquipItem.cpp`、`NtlPLItem.cpp`、`NtlPLItemData.h`  
> - 官方配置基准：`E:\DBO_CT_TW(1.57.51)\assets\main\script\defaultitemlist.xml`、`assets/tbl/table_item_data.json`  

---

## 目标清单与完成进度

- [x] **目标 1：查清“丢了一只脚”的物理截肢根本原因并根治**（进度：100%）
- [x] **目标 2：查清“丢了一只手”的断腕截肢根本原因并根治**（进度：100%）
- [x] **目标 3：查清“角色头顶拉出巨大折线黑梁与手套重叠”的顶点飞天根本原因并拔除**（进度：100%）
- [x] **目标 4：查清“底裤往下被未知贴图糊住与女童浑身贴图不正常”的成因并恢复素体纯净裸身**（进度：100%）
- [x] **目标 5：查清并阐明魔人男童装备官方真实规范**（进度：100%）
- [x] **目标 6：维护工作进度文档并形成技术归档**（进度：100%）

---

## 一、用户反馈现象与全链路病因复盘

### 1. 为什么“丢了一只脚”？
- **底层资产事实**：
  经 Python 深入扫描 `E:\DBO_CT_TW(1.57.51)` 与当前项目 `assets/obj/item/` 下的靴子模型（如 `a_hfi_04_01_b_h_m.glb`）：原版 RenderWare 导出的靴子网格**仅绑定了右侧下肢骨骼**（`Bip01 R Calf`, `Bip01 R Foot`, `Bip01 R Toe0`），文件里根本没有左脚网格。
- **脚本冲突致死点**：
  在 `src/entities/character_visual.gd` 第 904~906 行中，旧逻辑写道：
  ```gdscript
  elif is_boots:
      if has_feet:
          mesh_inst.set_surface_override_material(s, inv_mat)
  ```
  只要检测到挂载了靴子（`has_feet = true`），代码就把素体自带的双脚表面（Surface 2: `A_HFI_M_boots001`）**全量设为 `inv_mat`（完全透明隐形）**！
- **恶果**：
  右脚穿戴了外装靴子；而左脚外装不存在，素体原生的左脚又被 `inv_mat` 挖空成空气，**导致角色左腿直接物理截肢！**

---

### 2. 为什么“丢了一只手”？
- **底层资产事实**：
  经 Python 深度解析新手道服上衣 `a_hfi_04_01_j_h_m.glb` 的骨骼绑定权重：该模型仅覆盖至双臂小臂（`Forearm`），**完全不包含手掌网格（没有绑定 Hand 骨骼）**！双手手掌网格只存在于素体 Surface 5（`A_HFI_M_jacket_skin`）中。
- **脚本冲突致死点**：
  在 `character_visual.gd` 第 842~844 行中：
  ```gdscript
  if should_hide_torso: # 当穿戴上装 has_torso 为 true 时
      mesh_inst.set_surface_override_material(s, inv_mat)
  ```
  只要穿戴了上装，代码就把素体 Surface 5（包含胸腹肌与双手手掌）**整体设为 `inv_mat` 隐形**！
- **恶果**：
  素体原生的双手手掌被全部挖空成透明空气；右手上刚好挂了主手武器拳套（`w_glv_16`），遮住了右手；但左手没有武器，原本的素体左手掌又被隐藏，**导致角色左手手腕以下完全截肢，变成空秃秃的断腕！**

---

### 3. 为什么“头顶拉出巨大的折线黑梁”与“两个手套叠在右手”？
- **底层数学与规范事实**：
  1. 查阅官方 `table_item_data.json`，拳套 `W_GLV_16` 的属性为 `equip_slot_flag: 1`（**主手武器**）。在原版 DBO 中，武道家本身即为**单手佩戴拳套**（只佩戴在右手上）！
  2. 此前脚本误以为拳套是防具手套，在 `_mirror_single_sided_mesh_if_needed` 中强行把网格顶点取负（`v.x = -v.x`）并重新分配给左侧骨骼。
  3. 但 3ds Max Biped（Bip01）骨骼系统中，左右两侧的逆绑定矩阵（Inverse Bind Matrix）包含空间坐标轴旋转差异，单纯翻转顶点而不变换逆绑定矩阵，导致 GPU 顶点着色器在每帧蒙皮运算时，坐标发生灾难性爆炸，顶点被抛向数十米高的天空，在创角大厅穹顶拉扯出巨大的人字形黑色折线大梁（用户截屏 3~6）；若骨骼映射未生效，网格则重叠在右手上（用户反馈“两个手套叠在右手”）。

---

### 4. 为什么“底裤往下应该是裸露的腿的部分被不知名贴图糊住了”？
- **架构事实**：
  用户明确指出：“*儿童素体自带的不是新手装备，那只是素体的基础贴图而已，看起来的样子是纯色皮肤和一条短裤 作为没有装备时的裸身状态*”。
- **脚本错误事实**：
  1. 在 `character_lobby_ui.gd` 的 `_update_avatar_preview()` 中，在创角预览阶段居然错误调用了 `get_newbie_starter_items`，给素体强行套上了整套外装道服裤子、靴子和拳套；
  2. 在材质切换时，若 `orig_tex` 为 `null`，皮肤着色器采样了未知纹理，导致底裤以下大腿小腿被错误纹理模糊糊住。

---

### 5. 官方事实：魔人男童装备规范
- 查阅 `E:\DBO_CT_TW(1.57.51)\assets\main\script\defaultitemlist.xml`：
  ```xml
  <CHARACTER_TYPE TYPE="MAJIN_CHILD_MALE">
      <FACE_MESH><DATA TYPE="1" KEY_NAME="A_MAJ_FACE_M_M"/></FACE_MESH>
      <BODY_MESH>
          <DATA TYPE="1" EQUIP="EQUIP_JACKET" KEY_NAME="A_MAJ_J_M_M"/>
          <DATA TYPE="1" EQUIP="EQUIP_PANTS" KEY_NAME="A_MAJ_P_M_M"/>
          <DATA TYPE="1" EQUIP="EQUIP_BOOTS" KEY_NAME="A_MAJ_B_M_M"/>
          <DATA TYPE="1" EQUIP="EQUIP_TWO_HAND" KEY_NAME="A_MAJ_H_M_M"/>
      </BODY_MESH>
  </CHARACTER_TYPE>
  ```
- **官方真相**：魔人男童在官方模型体系中，**直接复用 `A_MAJ_*_M_M` 装备**（通过整体 Scale = 0.65 呈现儿童体型），官方本来就根本不存在所谓的 `A_MCH_*_M_M` 装备！

---

## 二、终极解耦与修复实施

### 1. `src/entities/character_visual.gd`
- **素体手掌与双臂 100% 保护**：废除对手部表面的 `inv_mat` 隐形，不论角色是否穿戴手部装备，素体手部表面永远保留标准皮肤着色器渲染，确保双手双手健全，左手掌永远完好无损。
- **素体双脚 100% 保护**：废除对 `is_boots` 的 `inv_mat` 隐形，素体双脚永远保留正常贴图与材质，彻底根治左脚截肢。
- **材质安全自动补齐**：在遍历表面时加入纹理回退扫描，若 `orig_tex == null`，依据材质名从 `res://assets/tex/texture/item/` 与 `res://assets/tex/texture/character/` 自动补全 PNG，100% 杜绝未知贴图糊身。

### 2. `src/entities/character_factory.gd`
- **彻底拔除飞天拉伸逻辑**：移除 `_mirror_single_sided_mesh_if_needed` 的调用并将该函数置为安全空实现。拳套 `W_GLV_16` 作为 SlotFlag=1 主手武器，保持原版正规渲染规范，彻底消除头顶人字形飞天黑梁与手套重叠。

### 3. `src/ui/lobby/character_lobby_ui.gd` 与 `character_lobby_stage.gd`
- **创角界面回归纯净素体裸身**：创角预览阶段（`_update_avatar_preview`），`preview_equipped` 严格传递空数组 `[]`，并主动卸下残留防具部件。创角捏脸时，角色完美呈现标准的基础裸身素体状态（纯色皮肤 + 一条短裤），捏发型、选发色、调肤色全身各部位 100% 统一明晰。
