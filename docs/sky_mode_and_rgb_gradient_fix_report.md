# 天空黑白原因诊断与 OpenDBO-Core 渲染管线正统对齐报告

本报告严格依据 [OpenDBO-Core](https://github.com/OpenDBO/OpenDBO-Core) 表现层 C++ 源码（`DboClient/Lib/NtlPresentation/NtlPLSky.h`、`NtlPLSky.cpp`）以及原始世界切片二进制文件（`wfpf*`），对天空渲染异常（黑白/灰阶）进行字节级与代码级溯源，并说明修复方案。

---

## 一、 目标清单与完成进度

- [x] **溯源排查 JSON 引用链路**：确认 `data/terrain/select_character_chunks/environment.json` 及全 50 个大世界环境配置均正确解析自官方原版世界切片二进制 `wfp`（进度：100%）。
- [x] **查明黑白/灰阶天空的根本成因**：逆向 OpenDBO-Core `NtlPLSky.cpp`，发现 `_BaseSkyMode = 1`（`eBSM_RGB_MODE`）与 `_BaseSkyMode = 2`（`eBSM_TEX_MODE`）的分支机制，查明 `sky_sp.png` 为 256x128 灰色占位纹理（进度：100%）。
- [x] **重构 [`WorldSkybox`](file:///e:/DBOFF/src/world/world_skybox.gd)**：完整实现三阶天空渲染管线（`sky_diffuse.glb` 三阶顶点高度渐变 Shader、`sky_base.glb` 全景贴图、`sky_blended0t.glb` 与 `sky_blended1t.glb` 双层流云）（进度：100%）。
- [x] **重构 [`character_lobby_stage.gd`](file:///e:/DBOFF/src/ui/lobby/character_lobby_stage.gd) 与 [`world_scene_driver.gd`](file:///e:/DBOFF/src/world/world_scene_driver.gd)**：全面接入 `apply_environment_preset`，支持按 Stage 与 Zone 动态注入官方天空模式与流变（进度：100%）。

---

## 二、 天空出现黑白的根本原因解析

### 1. JSON 引用完全正确
引用的配置为 `data/terrain/select_character_chunks/environment.json`，其中大厅四大舞台分别对应官方二进制切片：
- **Stage -1（沙鲁创角大厅）**：对应 Field 18，`wfpf18` 中 `_BaseSkyMode = 1`，天空底图字符串为 `"sky_sp"`，云层为 `"cloud_011"`，天顶颜色为 `(77, 14, 149)`（深靛紫），地平线颜色为 `(0, 162, 255)`（蔚蓝），地面颜色为 `(0, 0, 0)`（纯黑）。
- **Stage 0（人类选角大厅）**：对应 Field 42，`wfpf42` 中 `_BaseSkyMode = 2`，基础天空贴图为 `"sky00"`，云层为 `"cloud_022"`。
- **Stage 1（那美克选角大厅）**：对应 Field 45，`wfpf45` 中 `_BaseSkyMode = 1`，天顶颜色为 `(72, 0, 72)`，地平线颜色为 `(60, 179, 113)`（那美克绿），双层浮云 `"cloud-p01"` 与 `"cloud-p02"`。
- **Stage 2（魔人选角大厅）**：对应 Field 21，`wfpf21` 中 `_BaseSkyMode = 1`，天顶深蓝，地平线柔青。

### 2. 为什么之前渲染出来是黑白的？
在 OpenDBO-Core 表现层中：
```cpp
// DboClient/Lib/NtlPresentation/NtlPLSky.h & NtlPLSky.cpp:305-330
if (pNtlFieldProp->_BaseSkyMode == eBSM_RGB_MODE) {
    m_pBaseSkyLayer[0]->_pRender = TRUE;  // diffuse sky (sky_diffuse.dff)
    m_pBaseSkyLayer[1]->_pRender = FALSE; // textured sky (sky_base.dff)
    SetColorOfDiffuseSkyAtomic(pNtlFieldProp->_RGBSkyColor);
} else if (pNtlFieldProp->_BaseSkyMode == eBSM_TEX_MODE) {
    m_pBaseSkyLayer[0]->_pRender = FALSE;
    m_pBaseSkyLayer[1]->_pRender = TRUE;
    // 载入 pNtlFieldProp->_BaseSkyTexName
}
```
1. 官方资源库中 `assets/tex/texture/ntlwe/sky/sky_sp.png` 是一张尺寸为 256x128、RGB 像素集中在 `(89~118, 98~118, 100~118)` 的**全灰度单色占位贴图**。
2. 官方原版程序在 `_BaseSkyMode == 1`（`eBSM_RGB_MODE`）时，**完全忽略 `_BaseSkyTexName`（即 `sky_sp`）**，而是直接将 `_RGBSkyColor` 的三阶颜色应用到漫反射渐变天穹 `sky_diffuse.dff` 上。
3. 之前 Godot 端代码因未实现 `sky_mode` 分支逻辑，盲目将 `sky_sp.png` 当作全景漫反射贴图赋予天空穹顶，导致将灰阶占位图直接绘制在整个天空中，呈现黑白/灰色。

---

## 三、 表现层管线修复方案

### 1. 严格实现 `sky_diffuse` 三阶高度渐变 Shader
根据 `NtlPLSky.cpp` 中 `SetColorOfDiffuseSkyAtomic` 的宏定义与顶点高度分配：
- `dNTL_PL_DIFFUSE_SKY_RGB_HEIGHT0` (300) / `HEIGHT1` (280)：天顶色 `top_color`（Stage -1 为靛紫色）；
- `dNTL_PL_DIFFUSE_SKY_RGB_HEIGHT2` (210)：天顶与地平线 50% 混合色；
- `dNTL_PL_DIFFUSE_SKY_RGB_HEIGHT3` (140)：地平线色 `horizon_color`（Stage -1 为蔚蓝色）；
- `dNTL_PL_DIFFUSE_SKY_RGB_HEIGHT4` (40)：地平线与地面 50% 混合色；
- `dNTL_PL_DIFFUSE_SKY_RGB_HEIGHT5` (0) / `HEIGHT6` (-180)：地面色 `bottom_color`。

在 [`world_skybox.gd`](file:///e:/DBOFF/src/world/world_skybox.gd) 中构建精确对齐的无光照着色器，并在片元着色器中按高度实现平滑插值，彻底消除分段色阶。

### 2. 双天穹与双浮云层四轨并行
- `_diffuse_sky_instance`（`sky_diffuse.glb`）：在 `sky_mode == 1` 时激活，`render_priority = -30`；
- `_base_sky_instance`（`sky_base.glb`）：在 `sky_mode == 2` 时激活，`render_priority = -30`；
- `_cloud_0_instance`（`sky_blended0t.glb`）：挂载 `cloud_0`（如 `cloud_011.png`），以 `cloud_speed_0` 沿 Y 轴旋转，`render_priority = -10`；
- `_cloud_1_instance`（`sky_blended1t.glb`）：挂载 `cloud_1`（如 `cloud-p02.png`），以 `cloud_speed_1` 沿 Y 轴旋转，`render_priority = -9`。

### 3. 数据层接入
- [`character_lobby_stage.gd`](file:///e:/DBOFF/src/ui/lobby/character_lobby_stage.gd) 调用 `_skybox_instance.apply_environment_preset(preset)`，大厅创角（Stage -1）实时呈现官方紫蓝渐变与流云，人类大厅（Stage 0）呈现官方 `sky00` 晴空与静态云层，那美克大厅（Stage 1）呈现官方黄绿异星天际与双层浮云。
- [`world_scene_driver.gd`](file:///e:/DBOFF/src/world/world_scene_driver.gd) 同步支持根据世界区域配置全自动应用预设。
