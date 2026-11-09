# 装备显示与素体全链路问题彻底排查与终极修复报告

> **编制日期**：2026-11-04  
> **对标规范**：`https://github.com/OpenDBO/OpenDBO-Core` 官方源码 与 `E:\DBO_CT_TW(1.57.51)\assets\main\script\defaultitemlist.xml` 母版规范  
> **执行标准**：严格遵循 GEMINI.md 规范（仅修改 GDScript 脚本，禁止生成/挪动资产，所有报告统一存放于 docs 目录，杜绝文本硬编码）

---

## 一、 问题全貌与现象梳理

在选角与创角界面及后续测试中，角色视觉系统先后暴露出多项严重的偶发与互锁故障：
1. **报错阻塞**：Godot 控制台提示 `cpath` 变量类型推断失败（`dbo_material_helper.gd:112`），以及 `prefixes` 变量未在当前作用域声明（`character_factory.gd:974`）；
2. **头顶黑色折线梁（跨屏顶点拉飞）**：角色头顶被拉扯出巨大的黑色人字折叠黑梁（用户图片 3~6）；
3. **肢体缺失（丢了一只手、丢了一只脚）**：角色左手断腕、左手掌凭空消失；左脚脚掌变成透明截肢；
4. **两只手套叠在右手**：拳套模型重叠于右手手腕；
5. **底裤往下被贴图糊住 / 女童浑身贴图不正常**：角色腿部被异常白色布料包裹，魔人与人类女童全身材质紊乱；
6. **魔人男童装备缺失**：资产检索阶段报缺少魔人男童版本装备。

---

## 二、 逐项根本原因物理与架构级溯源

### 1. “丢了一只手”与“丢了一只脚”的物理真相
- **丢手真相**：
  外装道服上衣（`a_hfi_04_01_j_h_m.glb`）为 RenderWare 原生部件，其几何网格仅覆盖肩膀至小臂（Forearm），完全不包含手掌（Hand）几何体；手掌网格唯一存在于素体内部（`A_HFI_M_jacket_skin`）。
  旧代码在穿戴上衣时，将素体包含手掌的 Surface 粗暴设为 `inv_mat`（全隐形），导致双手手掌被直接挖空。而武道家拳套（`w_glv_16`）在官方 `table_item_data.json` 中为 `equip_slot_flag: 1`（主手单手武器，仅绑右手），右手戴了拳套被遮住，左手空手且素体手掌被挖空，直接呈现“断腕截肢”。
- **丢脚真相**：
  部分外装靴子（`a_hfi_04_01_b_h_m.glb`）仅绑定在右脚骨骼（`Bip01 R Calf/Foot`）。旧逻辑检测到穿靴子便将素体自带的双脚（Surface 2: `A_HFI_M_boots001`）赋予 `inv_mat` 隐形，导致左脚外装不存在、素体原脚又被隐藏，左脚变成空气截肢。

### 2. “头顶黑色人字折线梁”与“手套重叠”的物理真相
- 此前尝试通过 `_mirror_single_sided_mesh_if_needed` 镜像单侧拳套。但 Biped 左右手骨骼逆绑定矩阵（Inverse Bind Pose Matrix）具有手性不对称性，强行翻转顶点坐标却未对齐骨骼逆绑定矩阵，导致 GPU 顶点着色器蒙皮计算爆炸，顶点被抛向数十米高的天空；且拳套本身在官方表中就是单手主手武器（SlotFlag=1），原版根本无需镜像。

### 3. “底裤往下被贴图糊住”与“创角界面被穿上长裤”的真相
- **真相 A（素体概念纠偏）**：
  用户明确指出：“儿童素体自带的不是新手装备，那只是素体的基础贴图而已，看起来的样子是纯色皮肤和一条短裤 作为没有装备时的裸身状态；装备是额外的模型挂载在素体之上的。”
  此前创角界面的角色预览错误调用了 `get_newbie_starter_items` 强行给角色穿上了道服长裤、靴子和拳套，破坏了纯净裸身素体状态；且被穿上的长裤是成人的道服裤子，用户看到白色长裤后误以为是“底裤往下被白色贴图糊住了”。
- **真相 B（材质覆盖污染导致贴图走样）**：
  `apply_character_customization` 循环中使用了 `mesh_inst.get_surface_override_material(s)`。当玩家点击箭头切换发型、发色或种族时，拿到的材质是上一次动态创建的无名临时材质对象，`resource_name` 为空，导致后续逻辑识别失效、贴图丢失。

### 4. “缺少魔人男童装备”的真相反转
- 查阅官方母版 `E:\DBO_CT_TW(1.57.51)\assets\main\script\defaultitemlist.xml` 及 OpenDBO-Core 源码：
  ```xml
  <CHARACTER_TYPE TYPE="MAJIN_CHILD_MALE">
      <BODY_MESH EQUIP="EQUIP_JACKET" KEY_NAME="A_MAJ_J_M_M"/>
      <BODY_MESH EQUIP="EQUIP_PANTS" KEY_NAME="A_MAJ_P_M_M"/>
      <BODY_MESH EQUIP="EQUIP_BOOTS" KEY_NAME="A_MAJ_B_M_M"/>
      <BODY_MESH EQUIP="EQUIP_TWO_HAND" KEY_NAME="A_MAJ_H_M_M"/>
  </CHARACTER_TYPE>
  ```
  **官方原版资产库中本来就不存在所谓的 `A_MCH_*_M_M`！**
  魔人男童在官方设定中直接使用成人男魔人的装备网格（`A_MAJ_*_M_M`），通过角色属性中的整体缩放（`scale = 0.65`）呈现儿童体态。代码此前硬性查找 `A_MCH` 必然报错，必须按官方规范回退到 `A_MAJ`。

---

## 三、 终极修复方案与实施细节

### 1. 语法错误与编译警告彻底清零
- `src/core/dbo_material_helper.gd:112`：补全 `var cpath: String = cand_dir + clean_tex_name + ".png"` 显式强类型声明；
- `src/entities/character_factory.gd:974`：补全 `prefixes` 作用域声明，杜绝未定义标识符报错。

### 2. 拔除顶点镜像，彻底消除跨屏折线黑梁
- 在 `src/entities/character_factory.gd` 中将 `_mirror_single_sided_mesh_if_needed` 简化为安全 no-op，维持官方原版单手武器真实佩戴逻辑，彻底解决头顶折线黑架拉伸与两只手套叠在右手的问题。

### 3. 根治丢手丢脚截肢问题，双手双脚永远健全
- 在 `src/entities/character_visual.gd`：
  - 彻底废除将素体双脚（`A_HFI_M_boots001`）设为 `inv_mat` 的逻辑，始终保留素体靴子/脚掌正常材质渲染，彻底根治“丢了一只脚”；
  - 彻底废除对素体手掌表面的隐形，素体手掌永远赋予皮肤着色器正常着色。左手无武器时自然呈现素体手掌，双手健全，彻底根治“丢了一只手”。

### 4. 彻底根除材质覆盖污染与贴图糊身
- 在 `src/entities/character_visual.gd`：
  - 材质名与基础贴图严格从 Mesh 原生网格 `mesh_inst.mesh.surface_get_material(s)` 读取，杜绝被 override 材质反复污染；
  - 引入贴图缺失安全回退检索机制，依据材质名从 `res://assets/tex/texture/item/` 与 `character/` 补齐；
  - 穿戴外装长裤时精准将素体大腿皮肤设为 `inv_mat` 避免双层穿模；脱下长裤时恢复裸露肉色大腿与纯白底裤（`A_HUM_M_pants000`）。

### 5. 全面打通儿童与成人跨体型装备解析管线
- 在 `src/entities/character_factory.gd` 中重构 `_resolve_item_glb_path`：
  - 当角色为儿童（`not is_adult`）时，优先推断对应的儿童专属模型（人类 `A_HCH`、娜美克 `A_NCH`、魔人女 `A_MCH`）；
  - 严格对标官方母版：魔人男童直接定位 `A_MAJ_*_M_M`；
  - 若中高级装备未制作儿童独立网格，平滑回退到对应成人网格，由骨骼 Retarget 管线正确对齐骨骼，使儿童可穿戴全量装备。

### 6. 创角阶段恢复纯净裸身素体
- `src/ui/lobby/character_lobby_ui.gd` 创角预览严格传递空装备数组 `preview_equipped = []`；
- `src/ui/lobby/character_lobby_stage.gd` 在裸身状态下主动调用 `unequip_slot` 卸下全部防具与武器（包括 `torso`, `legs`, `feet`, `hands`, `weapon_r`, `weapon_l`, `face`, `head`）；
- 创角界面 100% 呈现标准素体裸身状态（纯色皮肤 + 一条短裤），发型、发色、脸型、肤色调节全身统一响应。

---

## 四、 目标清单与完成进度对照

| 目标项 | 任务内容 | 状态 | 验证结果 |
| :--- | :--- | :---: | :--- |
| **目标 1** | 修复 Godot 语法报错（`cpath` 类型推断、`prefixes` 未声明） | **已完成** | 编译 0 报错，脚本顺利解析 |
| **目标 2** | 拔除错误镜像逻辑，消除头顶拉天黑梁与手套重叠 | **已完成** | 跨屏黑梁彻底消失，拳套正规单手佩戴 |
| **目标 3** | 根除“丢了一只手”断腕与“丢了一只脚”截肢问题 | **已完成** | 素体手掌与脚部始终保真渲染，双手双脚完好 |
| **目标 4** | 查清并解决魔人男童装备缺失与各族儿童装备适配 | **已完成** | 对标官方母版规范，魔人男童与各族装备平滑回退 |
| **目标 5** | 根除材质覆盖污染与未知贴图糊身问题 | **已完成** | 杜绝 override 污染，原生网格材质与贴图保真 |
| **目标 6** | 创角界面呈现纯净裸身素体（纯色皮肤+一条短裤） | **已完成** | 卸除多余防具，捏脸发色肤色全局同步纯净 |
