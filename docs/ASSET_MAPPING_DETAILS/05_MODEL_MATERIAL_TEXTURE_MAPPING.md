# DBOFF 模型、材质与贴图全量资产分布表 (Models & Textures Registry)

> 资产总计：**30,894** 个 `.glb` 3D 模型/动画与 **28,577** 张 `.png` 贴图文件。

## 1. 资产子系统分布统计表 (Category Breakdown)

| 资产顶级目录 | GLB 模型/动画数 | PNG 纹理贴图数 | WAV/OGG 音频数 | 主要用途 | 状态 |
|---|---|---|---|---|---|
| `assets/./` | **0** | **0** | **0** | 通用 | `VERIFIED` |
| `assets/effect/` | **0** | **0** | **0** | 通用 | `VERIFIED` |
| `assets/fonts/` | **0** | **0** | **0** | 通用 | `VERIFIED` |
| `assets/gui/` | **0** | **0** | **0** | UI 窗体与控件资源 | `VERIFIED` |
| `assets/lang/` | **0** | **0** | **0** | 通用 | `VERIFIED` |
| `assets/obj/` | **30,894** | **6** | **0** | 角色、防具、武器、大世界物件与道具网格 | `VERIFIED` |
| `assets/prop/` | **0** | **0** | **0** | 官方二进制属性 (ItemProperty, CharProperty 等) | `VERIFIED` |
| `assets/sound/` | **0** | **0** | **3,475** | 背景音乐 (BGM)、环境声效、NPC 语音与技能音效 | `VERIFIED` |
| `assets/tbl/` | **0** | **0** | **0** | RDF 反编译 JSON 数据表 | `VERIFIED` |
| `assets/tex/` | **0** | **28,571** | **0** | GUI界面、角色贴图、物品纹理、地图切片 | `VERIFIED` |

## 2. 材质与着色器架构 (Shader & Material Pipeline)

- **角色皮肤着色器**: `res://src/shaders/character_skin_tint.gdshader` 支持全种族调色板，防止魔人与人族肤色白模失真；
- **面部五官叠加着色器**: `res://src/shaders/character_face_multitex.gdshader` 严格对标原版 `FACE_MULTI_TEXTURE`，支持五官与底色双通道混合；
- **大世界物件材质修正**: `DBOMaterialHelper.fix_node_materials` 自动处理 Alpha 切除、双面渲染与 UV 垂直翻转。
