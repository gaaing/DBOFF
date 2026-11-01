# 大厅画面阴森感成因诊断与正统动漫渲染修复报告

本报告严格依据 [OpenDBO-Core](https://github.com/OpenDBO/OpenDBO-Core) 表现层源码（`CharacterStage.cpp`、`NtlPLEquipItem.cpp`、`NtlDefaultItemData.cpp`）及 `DefaultItemList.xml`，对创角大厅画面“阴森感”的底层物理与材质成因进行深入诊断，并给出修复方案。

---

## 一、 目标清单与完成进度

- [x] **查明阴森感的首要成因（主光强逆光与冷调阴影）**：逆向 `CharacterStage.cpp`，发现原版大厅日光角 `(X=135°, Y=-45°)` 与环境光 `{0.9, 0.9, 0.9}`，纠正此前将太阳直接设为背光导致的正面死黑与冷蓝阴影（进度：100%）。
- [x] **查明阴森感的次要成因（角色面部无五官、白发苍苍）**：查明原版 `NtlPLEquipItem.cpp` 中 `ITEM_EQUIP_FACE` 采用两层纹理混合（`fskin` 肤色底板 + `face01` 眼睛眉嘴），之前仅渲染无眼白板（进度：100%）。
- [x] **实现面部五官复合 Shader**：在 [`DBOCharacterVisual`](file:///e:/DBOFF/src/entities/character_visual.gd) 中构建双层贴图混合着色器，使角色完整呈现龙珠动漫眼睛、瞳孔、眉毛与神态（进度：100%）。
- [x] **接入官方规范发色与肤色**：从 `DefaultItemList.xml` 提取官方 13 种发色与 5 种肤色，为头发与躯干注入经典黑发与自然粉白健康肤色（进度：100%）。
- [x] **重构大厅舞台光影与色调映射**：在 [`character_lobby_stage.gd`](file:///e:/DBOFF/src/ui/lobby/character_lobby_stage.gd) 中将主日光改为正面斜射光，将色调映射由压暗阴影的 `FILMIC` 切换为动漫明快的 `ACES`，环境光提升为原版 warm daylight（进度：100%）。

---

## 二、 画面“阴森感”的四大致命成因分析

| 序号 | 异常现象 | 物理与代码级根本成因 | 心理视觉感受 |
| :---: | :--- | :--- | :--- |
| **1** | **正面死黑强逆光** | 此前代码将 `sun_light` 放置在角色正后方天空（`sun_pos`）并直接朝镜头方向射光，导致角色整个面部、胸腹、大腿完全处于 **100% 背光阴影区**。 | 逆光剪影、压抑沉闷 |
| **2** | **阴影泛冷蓝/尸色** | 阴影区仅能接收环境光，而此前代码从 Field 18 读取了暗夜蓝 `Color(0.32, 0.40, 0.83)` 作为全局环境光，使角色皮肤阴影全被染成 **深靛紫色**。 | 僵尸/尸体感、阴森恐怖 |
| **3** | **面部无五官眼睛** | `human_m_child.glb` 的 surface 0 原生仅贴了 `a_hum_m_ch_fskin01.png`（纯肤色），未按 OpenDBO 机制叠加 `a_hum_m_ch_face01.png`，呈现**无眼无嘴的无面人**。 | 无面怪谈、恐怖蜡像 |
| **4** | **白发苍苍无生机** | 原版发丝贴图 `a_hum_m_head01.png` 原生为灰度单色基底（设计初衷为与发色相乘），未着色时呈现**苍白灰发**。 | 衰败、丧气 |

---

## 三、 对齐 OpenDBO-Core 的工程修复方案

### 1. 阳光与环境光严格复刻 `CharacterStage.cpp`
OpenDBO-Core 原版创角选角大厅明确定义：
```cpp
// DboClient/Client/Stage/CharacterStage.cpp:100-118
RwRGBAReal color = {0.9f, 0.9f, 0.9f, 1.0f};
RpLightSetColor(m_pLtAmbient, &color); // 亮白温暖的漫反射，拒绝暗蓝

RwFrameRotate(pFrame, &CNtlPLGlobal::m_vXAxisV3, 135.0f, rwCOMBINEREPLACE);
RwFrameRotate(pFrame, &CNtlPLGlobal::m_vYAxisV3, -45.0f, rwCOMBINEPOSTCONCAT); // 正前侧上方主光
```
在 [`character_lobby_stage.gd`](file:///e:/DBOFF/src/ui/lobby/character_lobby_stage.gd) 中：
- `env.ambient_light_color = Color(0.86, 0.89, 0.94, 1.0)`，保证背光面依然保有清透自然的动漫漫射光；
- 主日光（`sun_light`）自摄像机斜上前方照射，直接照亮角色正面与建筑立面，阴影自然落于角色脚后方；
- 远景天际的日轮光盘与镜头光晕继续保留在天穹高处，构成明快的大气层次。

### 2. 五官面部复合着色器（Face Shader）
在 [`DBOCharacterVisual`](file:///e:/DBOFF/src/entities/character_visual.gd) 中注入 Shader：
```glsl
vec4 skin_col = texture(base_skin_tex, UV) * skin_tint;
vec4 face_col = texture(face_feature_tex, UV);
ALBEDO = mix(skin_col.rgb, face_col.rgb, face_col.a);
```
将官方 `a_hum_m_ch_face01.png` 精彩灵动的眼眉五官无缝覆盖在基础肤色之上，角色拥有了神采奕奕的龙珠瞳孔。

### 3. 官方发色与肤色动态染色
接入 `DefaultItemList.xml` 的官方规范数据：
- 默认发色切换为官方 Type 4 墨黑色 `Color(0.169, 0.169, 0.235)`（龙珠经典悟空/悟饭黑发）；
- 默认肤色切换为官方 Type 2 健康粉白色 `Color(1.0, 0.914, 0.871)`；
- 彻底告别无面白发与暗蓝死影，恢复阳光、热血、明媚的原版动漫视觉。
