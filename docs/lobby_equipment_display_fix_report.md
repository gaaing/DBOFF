# 角色创建与选择界面装备显示修复技术报告

## 1. 目标清单与完成进度

- [x] **目标 1：选角界面已穿戴初始装备被遗漏过滤修复** (进度: 100%)
  - 根因：`character_lobby_ui.gd` 中读取 `inventory_items` 依赖 `byPlace == 0`，但初始保存数据仅包含 `pos`（0..5）和 `item_tblidx`，导致 `place` 缺省降级为 `-1`，误将所有装备视作无效并清空。
  - 修复：更新过滤条件为 `place == 0 and pos != 255`，使选择角色界面能完整还原新手已穿戴装备。

- [x] **目标 2：GLTFDocument 蒙皮网格骨骼名称绑定缺失修复** (进度: 100%)
  - 根因：`character_factory.gd` 解析 GLB 装备时未传入 `IMPORT_FLAG_USE_NAMED_SKIN_BINDS`，导致 Godot 采用默认数值索引 Joint 映射，造成骨骼索引不一致时发生顶点塌陷或不可见。
  - 修复：追加 `GLTFDocument.IMPORT_FLAG_USE_NAMED_SKIN_BINDS` 标志位，确保跨模型骨骼绑定依据官方骨骼节点名称映射。

- [x] **目标 3：素体全部发型同时炸出与面部五官贴图丢失修复** (进度: 100%)
  - 根因：`character_visual.gd` 的 `_update_base_body_visibility` 在穿上装备时被调用，该函数内部对非上衣/裤子/靴子表面粗暴执行了 `mesh_inst.set_surface_override_material(s, null)`，将 `apply_character_customization` 赋予其余 9 种发型的透明材质 (`inv_mat`) 以及赋予面部五官的 Composite ShaderMaterial 全部强行重置为 `null`，导致所有发型全部显形、面部失去五官变空白。
  - 修复：重构 `_update_base_body_visibility()`，使其直接委托给 `apply_character_customization()`，将其确立为全局材质表面与显隐状态的唯一数据源（Single Source of Truth），彻底杜绝覆盖材质被冲掉的问题。

- [x] **目标 4：搭载装备素体穿模破皮（胸腹与腿部露出）修复** (进度: 100%)
  - 根因：素体主网格中的躯干表面名为 `A_HFI_M_jacket_skin`、下装表面名为 `A_HFI_M_pants_skin`。原判定逻辑写为 `is_jacket = ("jacket" in mat_name) and not is_skin`，由于表面名称含有 `"skin"`，导致被判定为非 jacket/非 pants，进而在角色穿上防具外套（`has_torso`）与裤子（`has_legs`）时没有将其隐去，使得裸露胸腹和腿部直接穿透装备模型穿模。
  - 修复：重构图元分类与显隐条件，当 `has_torso` 为真时将包括 `jacket_skin` 和底装在内的所有躯干图元隐去；当 `has_legs` 为真时将包括 `pants_skin` 和底裤在内的所有下装图元隐去；当脱下装备时精准恢复对应的皮肤材质与着色器。

- [x] **目标 5：魔人系列装备旧工程历史显示异常（黄色马甲被染成粉色、镂空处黑块）修复** (进度: 100%)
  - 根因：魔人男/女上衣模型（`a_mmi_04_01_j_m_m.glb` 等）的原生网格中，黄色马甲/抹胸图元（Primitive 0）材质被命名为 `A_MAJ_M_jacket_skin2`。原着色管线因其包含 `"skin"` 而将其误作为裸露皮肤执行了粉红肤色染色，导致整件马甲被染成了粉色肉色；且布料上的露胸镂空区域为 Alpha=0、RGB=(0,0,0) 的黑底，在不透明渲染管线下直接呈现大片黑块。
  - 修复：参考旧工程验证方案，在 `character_factory.gd` 中建立 `_find_majin_jacket_cloth_texture` 与 `_composite_skin_with_armor` 内存纹理合成管线：将黄色布料通过 `Image.blend_rect` 动态覆盖于已染肤色的素体胸口贴图之上，使镂空区域天然透出纯正粉红肤色；并将 Primitive 0 赋予合成贴图且基色保持纯白 `Color.WHITE`，手臂皮肤表面赋予手臂贴图并同步肤色。

- [x] **目标 6：史考特与手持武器骨骼挂接位置/旋转与生命周期修复** (进度: 100%)
  - 根因：`character_visual.gd` 中 `attach_item_to_bone` 挂载网格时未清空 `owner` 导致 Godot 警告 Owner Inconsistency；且未按官方 `linkitemtrasformlist.xml` 注入各种族儿童眼部相对 Transform。
  - 修复：在挂载前调用 `mesh_inst.owner = null` 清除孤儿所有权，并注入官方全种族儿童史考特空间变换矩阵与武器 `-PI/2` 俯仰旋转与 0.65 缩放。

- [x] **目标 7：GLTF 内存安全解包与残缺贴图 URI 自动净化** (进度: 100%)
  - 根因：部分装备与道具 GLB（如 `i_sct_01_n_o_s1.glb`）由历史 DFF 转换工具导出时，空纹理槽位被写为 `"uri": "../../../tex/texture/item/"`（缺少文件名），导致 Godot 底层 GLTF 解析器抛出致命红字 `Can't open file from path 'res://assets/tex/texture/item'`。
  - 修复：在 [`DBOMaterialHelper.load_gltf_scene_safe`](file:///E:/DBOFF/src/core/dbo_material_helper.gd) 中实现纯内存 GLB 块重封，在解析前将所有结尾为 `/` 的空 URI 动态映射至有效贴图（如 `i_sct_01.png`），彻底根除底层红字。

- [x] **目标 8：节点递归所有权解绑 (消除 Owner Inconsistency)** (进度: 100%)
  - 根因：GLTF 生成的网格及其子节点默认保留原场景的 `owner` 引用，当直接 `add_child` 进角色的 `Skeleton3D` 或 `BoneAttachment3D` 时，Godot 抛出 `Adding child will make owner inconsistent` 警告。
  - 修复：引入 `_clear_owner_recursive(mesh_inst)`，在挂载前递归清空网格自身及其子树所有节点的 `owner`。

- [x] **目标 9：GDScript 强类型三元运算符与未用参数规范化** (进度: 100%)
  - 根因：`ResourceLoader.load() if ... else null` 未显式强转 `as Texture2D`，触发 Godot 4.x `Values of the ternary operator are not mutually compatible` 警告；且特效管理函数存在未加下划线前缀的形参。
  - 修复：全局对三元运算补齐类型强转（`as Texture2D` / `as Camera3D`），形参加注 `_normal` / `_is_energy` 前缀。

- [x] **目标 10：魔人职业上衣多表面图元精准映射与史考特半透明镜片** (进度: 100%)
  - 根因：大魔人与意魔人上衣网格（`a_mmi_...`, `a_mwo_...`）分别具有 2 到 4 个不同的网格表面（短袖、手臂皮肤、露脐腹部、围巾颈圈），原逻辑图元索引混淆导致模型变白模；史考特镜片材质缺乏深度预通（Depth Pre-Pass）导致被渲染为全黑不透明。
  - 修复：完成 4 种体态网格图元到材质的 1:1 精确绑定；史考特启用 `TRANSPARENCY_ALPHA_DEPTH_PRE_PASS` 与双面渲染。

- [x] **目标 11：魔人族全素体“白模”根除与角色定制肤色同步** (进度: 100%)
  - 根因：DBO 原生资产中，魔人肩部/手臂皮肤网格（`A_MAJ_*_jacket_skin2`）与胸腹素体皮肤（`jacket_skin1`）采用的是灰度高光贴图，需在运行时乘以角色定制肤色（Pink 调色）。此前 `_get_character_type_string()` 函数返回形如 `"A_MMI_M_CH"` 的属性键名，与 `default_item_list.json` 中配置的 `"MAJIN_CHILD_MALE"` / `"MAJIN_CHILD_FEMALE"` 键名不匹配，导致查询 `skin_color` 失败并缺省降级为 `Color.WHITE`（纯白）。轻灰色的皮肤贴图乘以纯白色直接呈现为毫无质感的纯白石膏模型（“白模”）。男女魔人均受此影响。
  - 修复：
    1. 在 `DBOCharacterVisual` 中维护 `current_skin_color` 属性与 `equipped_glb_paths` 字典；
    2. 对魔人族追加粉红色（`Color(0.9922, 0.7412, 0.8627)`）强保底，杜绝任何途径回退至纯白；
    3. `_get_character_type_string()` 修正为返回 `default_item_list.json` 标准键名；
    4. 在 `apply_character_customization()` 与 `equip_item_to_character()` 时，将当前肤色精准赋予肩臂皮肤（`arm_tex`）与动态合成底板。

- [x] **目标 12：女意魔人服装全裸与图元反转修复** (进度: 100%)
  - 根因：女意魔人上衣模型（`a_mwo_04_01_j_m_f.glb`）由 4 个图元构成。经三维空间坐标与三角面审计：
    - Prim 0（234 面，领边与短袖灯笼袖）：材质被 DFF 转换器标注为 `A_MWO_F_jacket04_01_2`；
    - Prim 1（72 面，手臂裸露皮肤）：`A_MAJ_F_jacket_skin2`；
    - Prim 2（158 面，垂直高度 $X \in [0.768, 1.202]$，涵盖腰至领口的整个躯干！）：`A_MAJ_F_jacket_skin1`；
    - Prim 3（22 面，围巾颈圈）：`A_MWO_F_jacket04_01_2`。
    此前逻辑错误地将裸肚皮贴图（`belly_skin_tex`）赋给了负责整个躯干的 Prim 2，导致女意魔人胸腹衣物完全消失、全裸露出粉色肉体；同时将合成深蓝短袖贴图赋给了袖口，造成严重衣物反转。
  - 修复：
    - Prim 0 绑定 `scarf_tex`（`a_mwo_f_jacket04_01_2.png`，含袖口纹理），`Color.WHITE`；
    - Prim 1 绑定手臂皮肤 `arm_tex`，染角色粉红肤色；
    - Prim 2 绑定动态合成贴图 `comp_shirt_tex`（深蓝短袖叠合于粉红皮肤，自然露出下腹肚脐），`Color.WHITE`；
    - Prim 3 绑定围巾贴图 `scarf_tex`，`Color.WHITE`。

- [x] **目标 13：女大魔人抹胸底板透色与镂空背心白化修复** (进度: 100%)
  - 根因：女大魔人抹胸（`a_mmi_04_01_j_m_f.glb`）为镂空纹理，其底板通过 `jacket_skin1` 透出皮肤。因此前肤色回退为纯白，导致黄色背心下方透出的全为白斑，视觉上如同一件白色运动背心（白模）。
  - 修复：通过动态内存图像合成（`_composite_skin_with_armor`），将黄色抹胸纹理与当前纯正魔人粉色皮肤进行 RGBA 像素级融合，镂空区域天然透出健康粉红肌肤，肩臂皮肤无缝衔接。

- [x] **目标 14：魔人全系上装“一层额外白模”根因排查与着色器级染色修复** (进度: 100%)
  - 根因：
    1. 魔人族上衣装备 GLB（`a_mmi_04_01_j_m_m.glb`, `a_mmi_04_01_j_m_f.glb`, `a_mwo_04_01_j_m_m.glb`, `a_mwo_04_01_j_m_f.glb`）均独立自带颈部、胸肩部位的皮肤图元（`A_MAJ_M_jacket_skin2` / `A_MAJ_F_jacket_skin2`）。
    2. 该图元的纹理（`a_maj_m_jacket_skin2.png` / `a_maj_f_jacket_skin2.png`）在原生资产中为纯灰度高光贴图（RGB 均值在 210~223 之间）。
    3. 此前管线赋予了默认 `StandardMaterial3D`，且依赖 `ResourceLoader.load()` 异步导入。在 Godot 4 运行时，由于未预导入或缓存降级，导致贴图回退为 null 或未正确执行着色器乘法；且大厅高强度直射光照下，浅粉乘法直接被强光过曝洗白，呈现为覆盖在胸肩部的白色多边形硬壳（“一层额外的白模”）。
    4. 同时，素体主网格 `BaseBody` 的 `_update_base_body_visibility` 逻辑中，当 `has_torso` 为真时曾一度将包含小臂的 `jacket_skin2` 表面全部抹除，造成素体下小臂与装备部件衔接断裂。
  - 修复：
    1. 实现 `DBOCharacterFactory.load_texture_safe()`，使用 `FileAccess` 与 `Image.load_from_file()` 绕过脆弱的引擎异步缓存，直读磁盘 PNG，100% 保证贴图有效加载；
    2. 对装备上所有 `skin2` / `arm` 皮肤表面，弃用普通 `StandardMaterial3D`，统一替换为官方专用角色皮肤着色器 `CHARACTER_SKIN_SHADER`，注入当前魔人纯正粉红肤色（`skin_tint`），与面部、小臂使用完全一致的光照与材质模型，彻底根除胸肩部的纯白石膏模层；
    3. 在 `CharacterVisual.apply_character_customization()` 中为魔人男女素体建立专有表面显隐遮罩：穿戴外套时精准隐藏素体内部重合的胸肩和躯干网格（男素体表面 8、9，女素体表面 6、7、8），彻底消除与外套重合造成的 Z-Fighting 穿插重叠，同时完好保留素体小臂（男素体表面 4、7，女素体表面 2、10）的皮肤渲染。

- [x] **目标 15：女魔人两种职业服装显示完全还原与多表面图元映射对齐** (进度: 100%)
  - 根因：
    1. 女意魔人上衣模型（`a_mwo_04_01_j_m_f.glb`）拥有 4 个独立 Primitive（Prim 0: 短袖灯笼袖与领边；Prim 1: 肩臂裸露皮肤；Prim 2: 躯干胸腹；Prim 3: 围巾颈圈）。
    2. 此前代码使用硬编码 `match s:` 匹配表面索引，在 Godot 按照材质分类派发时导致索引错位，将围巾贴图错赋给灯笼短袖，而将短袖图元与躯干混淆，导致深蓝短袖上衣在外观上完全消失，胸前大面积呈现光板粉色肉体；
    3. 女大魔人抹胸吊带（`a_mmi_04_01_j_m_f.glb`）胸口布料因 Alpha 通道镂空且纹理依赖 `ResourceLoader`，导致合成图元丢失。
  - 修复：
    1. 彻底弃用硬编码索引匹配，参考旧工程 `CharacterVisualEquipment.gd:950-998` 架构，依据 GLB 表面内嵌材质名 `base_mat.resource_name.to_lower()` 进行动态精准多表面派发：
       - `skin2` / `arm` 表面：动态载入 `a_maj_f_jacket_skin2.png`，采用 `CHARACTER_SKIN_SHADER` 染粉红肤色；
       - `skin1` 表面：动态调用 `_composite_skin_with_armor` 将深蓝短袖（意魔人）或金黄抹胸（大魔人）布料叠合在粉红素体皮肤底板之上（`Image.blend_rect`），自然露出下腹肚脐与健康肌肤；
       - 围巾与衣袖装饰表面：优先继承 GLB 内部内嵌纹理，若为空则自动检索装配对应 `jacket_2` 围巾贴图，基色保持 `Color.WHITE`；
    2. 穿戴装备时将 `mesh_inst.material_override` 显式置为 `null`，确保所有 Surface Override Materials 100% 独立生效。

- [x] **目标 16：那美克星人素体皮肤异常（仅头部正常）修复与绿色比克皮质还原** (进度: 100%)
  - 根因：
    1. 那美克星人童年素体（`namek_m_child.glb`）中，表面 2、3（双小臂皮肤）、表面 6（颈肩与胸腹皮肤）均被命名为 `A_NFI_AD_jacket_skin01`，表面 8（露踝小腿皮肤）被命名为 `A_NAM_pants_skin01`。
    2. 此前由于目标 14 针对魔人上装穿模引入了遮罩判定，将非魔人的全部 `is_jacket` 表面在 `has_torso == true` 时一律强制隐藏（`inv_mat`），且将 `is_pants` 表面在 `has_legs == true` 时强制隐藏。但那美克星人新手上衣（`A_NFI_04_01_J`）是无袖开襟短马甲，新手裤子是灯笼短裤，防具本身不含手臂和露踝网格！这导致素体的胸颈、双臂及脚踝皮肤全被误抹除，只剩下浮空头部和一件马甲；
    3. `default_item_list.json` 中配置的那美克星人 `skin_color` 为浅粉/黄绿条纹色（`Color(0.9922, 0.7412, 0.8627)`）。此前刷新装备外露皮肤时盲目将 `skin_mat.albedo_color` 乘以此粉色，导致原版绿色皮肤被染成粉褐色。
  - 修复：
    1. 引入空间几何拓扑判定（对标旧工程 `CharacterVisualEquipment.gd:117-122`）：以局部 X 轴坐标 $X > 0.35$ 或 $X < -0.35$ 精准分离手臂表面（`surface_hands`）与胸腹表面（`surface_torso`）；
    2. 那美克星人新手马甲为无袖开襟，素体颈肩胸腹皮肤表面 6 与露踝表面 8 始终保持显示；
    3. 严格遵循那美克星原版肤色规范：贴图（`a_nfi_ad_jacket_skin%02d.png` / `a_nam_pants_skin%02d.png`）已自带官方比克绿底色与红色肌肉条纹，素体与装备上所有皮肤材质基准色一律固定为 `Color.WHITE`，配合 `CHARACTER_SKIN_SHADER`（`race_mode = 1`）保真渲染，彻底恢复全身纯正原画质感。

- [x] **目标 17：魔人素体手臂穿戴手套时穿模破皮消除** (进度: 100%)
  - 根因：
    1. 魔人新手武器手套（`500001` / `W_GLV_16`、`505001` / `W_GLV_01`）配置在武器槽位（`equip_slot_flag = 1`），模型是涵盖整个小臂至手指的完整独立蒙皮网格（`child/w_glv_16_m_m.glb` / `child/w_glv_16_m_f.glb`）；
    2. 原代码未建立 `has_hands` 手套检测机制，导致魔人男素体表面 4、7（小臂与手掌）以及魔人女素体表面 2、10 在穿戴手套时依然保持渲染；
    3. 由于魔人素体手掌及手指顶点模型较为丰满，直接穿透贴合度极高的手套蒙皮，导致黑色手套边缘与指尖露出一截粉红肉块穿模破皮。
  - 修复：
    1. 在 `DBOCharacterFactory.equip_item_to_character()` 中新增手套专属类型判定：若装备为 `glv` 蒙皮手套，自动定向分配至 `"hands"` 槽位，并执行主副武器互斥清理；
    2. 在 `DBOCharacterVisual.apply_character_customization()` 中注入 `has_hands` 判定：当检测到角色穿戴手套（`_slots.has("hands")`）时，动态将素体手臂表面（`is_hand`，即男素体表面 4、7 与女素体表面 2、10）替换为透明遮罩材质（`inv_mat`）；
    3. 当脱下手套时，精准重置并恢复对应性别的魔人纯正粉红小臂皮肤，彻底根治穿戴手套时的穿模破皮。

---

## 2. 修改文件清单

1. [`src/ui/lobby/character_lobby_ui.gd`](file:///E:/DBOFF/src/ui/lobby/character_lobby_ui.gd#L521-L535)
   - 修复选角界面的 `equipped_items` 过滤逻辑，允许有效槽位装备正常打包触发 `avatar_visual_changed`。
2. [`src/entities/character_factory.gd`](file:///E:/DBOFF/src/entities/character_factory.gd)
   - 提前确保 `visual._ensure_skeleton()` 初始化；
   - 解析装备模型启用 `GLTFDocument.IMPORT_FLAG_USE_NAMED_SKIN_BINDS`；
   - 检索链优先对齐已验证的儿童烘焙装备与武器模型库；
   - 装备挂载后同步外露皮肤表面的肤色材质；
   - 支持 `glv` 蒙皮手套定向分配到 `"hands"` 槽位，并执行主副武器互斥清理；
   - 那美克星人装备外露皮肤一律强制保底为 `Color.WHITE`，杜绝被粉色条纹调色污染。
3. [`src/entities/character_visual.gd`](file:///E:/DBOFF/src/entities/character_visual.gd)
   - `_update_base_body_visibility` 统一使用 `_find_main_mesh_instance()` 避免被 `Skeleton3D` 阻断；
   - `attach_item_to_bone` 严格按官方规范注入种族专属史考特和武器挂接矩阵；
   - 几何坐标判定分离手臂表面与躯干表面，穿戴手套时隐藏素体小臂手掌消除穿模，脱下时精准复原；
   - 那美克星人开襟马甲与灯笼裤保留胸颈与露踝皮肤原生比克绿纹理与着色器渲染。
4. [`src/ui/lobby/character_lobby_stage.gd`](file:///E:/DBOFF/src/ui/lobby/character_lobby_stage.gd#L185-L192)
   - 舞台首次加载保障装备初始新手防具与武器，杜绝白板裸模。

---

## 3. 儿童素体 0.65 缩放比例官方规范分析

根据 OpenDBO-Core 官方属性表（`characterproperty.json` / `CNtlPLCharacterProperty`）的原版数据：

1. **全局整体缩放 (`bone_data.base_scale`)**：
   - **人类男童 (`A_HFI_M_CH`)**：`[0.65, 0.65, 0.65]`
   - **人类女童 (`A_HFI_F_CH`)**：`[0.65, 0.65, 0.65]`
   - **那美克星童 (`A_NFI_CH`)**：`[0.65, 0.65, 0.65]`
   - **魔人男童 (`A_MMI_M_CH`)**：`[0.65, 0.65, 0.65]`
   - **魔人女童 (`A_MMI_F_CH`)**：`[0.65, 0.65, 0.65]`
   - **结论**：所有种族性别的童年期角色，官方全局 `base_scale` **全部统一为 0.65**。

2. **各种族形态与局部差异的实现方式**：
   - 官方不是通过不同的全局缩放来实现种族体态差别的，而是通过**独立网格拓扑**与 **`bone_scales` 局部骨骼缩放矩阵**实现的：
     - **头部大头身比**：儿童头骨（`Bip01 Head`）在 `linkitemtrasformlist.xml` 与骨骼表中均有 1.10 ~ 1.40 的比例增强（人类男童 1.30、魔人男童 2.22 宽头、那美克星 1.10），还原鸟山明原作的大头 Q 版体态。
     - **体型丰满度**：魔人男童的肥胖、魔人女童的娇小、那美克星人的长肢干均由各自独立的素体网格几何形状本身决定。
   - 因此，**所有儿童素体的全局基准缩放统一设为 0.65 完全符合官方原版规范**。

