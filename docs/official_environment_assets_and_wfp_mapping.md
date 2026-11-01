# 官方环境要素（天体、天空、水体、天气）底层 WFP 逆向解析与正统对齐报告

本报告严格依据 [OpenDBO-Core](https://github.com/OpenDBO/OpenDBO-Core) 表现层 C++ 源码（`NtlPLSky.cpp`、`NtlPLSun.cpp`、`NtlPLWater.h`、`NtlPLWeatherProperty.cpp`）、以及原始世界切片属性二进制文件（`E:\DBO_Offline\pipeline\raw_source\extracted\ter\world\*\fields\*\wfpf*`），对客户端底层四大环境要素（**天体 Planet**、**天空 Sky**、**水体 Water**、**天气 Weather**）进行 100% 字节级溯源解析。

---

## 一、 目标清单与完成进度

- [x] **天体资产全面正名与数据纠偏**：彻底确认 `sun_001.png` ~ `sun_006.png` 官方正统地位，纠正由于文件过滤盲区造成的判断失误（进度：100%）。
- [x] **大厅 4 大舞台 WFP 字节级逆向**：从原始二进制 `wfpf18`、`wfpf42`、`wfpf45`、`wfpf21` 中逐字段反序列化官方天体、天空、光照与云速参数（进度：100%）。
- [x] **水体（Water）与天气（Weather）体系溯源**：查明 `ntlwe/water` 8 套 32 帧动态流体序列帧与 `ntlwe/weather` 粒子贴图在 OpenDBO 中的技术调用链路（进度：100%）。
- [x] **Godot 表现层代码完全对齐**：[`character_lobby_stage.gd`](file:///e:/DBOFF/src/ui/lobby/character_lobby_stage.gd) 与 [`world_skybox.gd`](file:///e:/DBOFF/src/world/world_skybox.gd) 全面接入官方 WFP 真实参数，零凭空捏造（进度：100%）。

---

## 二、 天体系统（Celestial / Planet）官方真实数据

### 1. 资产目录实测确认
在目录 [`assets/tex/texture/ntlwe/planet/`](file:///e:/DBOFF/assets/tex/texture/ntlwe/planet/) 中，完整存在以下官方原版天体贴图：
- `sun_001.png` ~ `sun_006.png`（不同阶段、不同风格的官方核心日轮）
- `sun006_l.png`（带光芒日轮）
- `moon001.png`（官方月球）
- `planet001.png` ~ `planet003.png`（龙珠外星异星天体）
- `star_001.png` ~ `star_002.png`（星辰）

### 2. OpenDBO-Core 表现层天体定义
在 `ntlworldcommon.h` 中，每个切片属性（`sNTL_FIELD_PROP`）均内嵌 3 个天体槽位（`sNTL_PLANET _NtlPlanet[3]`），每个天体结构体（`sizeof = 30` 字节）包含：
- `RwV3d _RelativePos`：摄像机相对位置；
- `RwReal _Scale`：天体几何尺寸缩放；
- `RwChar _TexName[10]`：贴图名称（最大 9 字符）；
- `RwBool _LensFlareExistence`：是否挂载透镜光晕。

### 3. 大厅四大舞台二进制 WFP 解包真实数据
通过对官方原始数据文件 `wfpf*` 执行反序列化，解包出官方作者作者填写的确切天体数值：
| 舞台序号与名称 | 对应 Field 索引 | 官方天体贴图 | 相对摄像机坐标 `_RelativePos` | 缩放 `_Scale` | 光晕 `_LensFlareExistence` |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Stage -1: 沙鲁度假村创角** | Field 18 | `Sun_001.png` | `(-409.4, 206.4, -150.7)` | 80.0 | **True** (开启 10 阶透镜光晕) |
| **Stage 0: 人类柯卡拉村选角** | Field 42 | `Sun_001.png` | `(-246.0, 137.6, 219.3)` | 50.0 | **False** (关闭光晕) |
| **Stage 1: 那美克天天神殿选角** | Field 45 | `Sun_001.png` | `(-359.0, 201.9, 313.4)` | 80.0 | **True** (开启 10 阶透镜光晕) |
| **Stage 2: 魔人孙悟饭家选角** | Field 21 | `Sun_002.png` | `(-292.1, 114.9, 183.4)` | 50.0 | **True** (开启 10 阶透镜光晕) |

> [!IMPORTANT]
> 官方数据彻底证明：选角大厅舞台在官方定义中 **100% 采用 `Sun_001.png` 与 `Sun_002.png`**，且其 3D 空间坐标早已被官方精准计算为坐落于镜头正上方（负 X、负/正 Z、正 Y），绝非凭空捏造。

---

## 三、 天空与光照系统（Sky & Light）官方真实数据

在原始 `wfpf*` 二进制中，官方为各个舞台配置的天空底图、流云贴图、云层旋转线速度、环境光颜色（`_ClrLightAmbient`）与主日光（`_ClrLightDirectional`）解包明细如下：

| 舞台与 Field | 基础天空 `_BaseSkyTexName` | 云层 0 `_BlendedTexName[0]` | 云层 0 速度 | 云层 1 `_BlendedTexName[1]` | 环境光 RGB (`_ClrLightAmbient`) | 日光 RGB 与照射欧拉角 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Stage -1 (Field 18)** | `sky_sp.png` | `cloud_011.png` | `0.001` | `null` | `(0.32, 0.40, 0.83)` 碧空散射蓝 | `(1.00, 1.00, 0.84)` / `(135°, 45°, 0°)` |
| **Stage 0 (Field 42)** | `sky00.png` | `cloud_022.png` | `0.000` | `null` | `(0.42, 0.66, 0.89)` 柯卡拉晴空淡蓝 | `(1.00, 1.00, 0.88)` / `(135°, 45°, 0°)` |
| **Stage 1 (Field 45)** | `null` (无底穹) | `cloud-p01.png` | `0.002` | `cloud-p02.png` (`0.001`) | `(0.49, 0.38, 0.16)` 那美克黄绿暖调 | `(1.00, 1.00, 0.91)` / `(135°, 45°, 0°)` |
| **Stage 2 (Field 21)** | `sky.png` | `null` | `0.000` | `null` | `(0.28, 0.16, 0.08)` 包子山幽谷暖褐 | `(1.00, 0.94, 0.76)` / `(135°, 45°, 0°)` |

---

## 四、 水体系统（Water）官方机制与资产

### 1. 资产目录结构
在 [`assets/tex/texture/ntlwe/water/`](file:///e:/DBOFF/assets/tex/texture/ntlwe/water/) 下，包含 8 个专用动态流体序列子目录（每个目录内包含 0~31 共 32 帧循环序列图）及高光贴图：
- `lake_a/` (`lake_a0.png` ~ `lake_a31.png`)：经典平静淡水湖泊；
- `lake_b/` (`lake_b0.png` ~ `lake_b31.png`)：微风扰动高光湖泊；
- `ocean/` (`ocean0.png` ~ `ocean31.png`)：大世界深海波浪；
- `river/` (`river0.png` ~ `river31.png`)：河流急流；
- `beach_a/` (`beach_a0.png` ~ `beach_a31.png`)：海岸拍岸白色浪花；
- `magma_a/`、`magma_b/`：火山熔岩动态流体；
- `slime_a/`：毒沼泽冒泡粘液；
- `specular.png`：日光在水面的正弦反光高光贴图。

### 2. OpenDBO-Core 表现层水体驱动（`NtlPLWater.h` & `NtlPLWater.cpp`）
- 结构体 `sWATER`：维护 `_ppTexPack`（32 帧动态贴图指针数组）与 `_ppTexSpecular`；
- 更新机制：在 `sWATER::Update(fElapsed)` 中累加 `_AccumulatedTime`，按 `_FPS`（通常为 15~20 帧）步进索引 `_IdxFrame = (_IdxFrame + 1) % _NumFrame`，驱动波光粼粼的物理水面。

---

## 五、 天气系统（Weather）官方机制与资产

### 1. 资产目录结构
在 [`assets/tex/texture/ntlwe/weather/`](file:///e:/DBOFF/assets/tex/texture/ntlwe/weather/) 下，包含所有官方天气粒子与后处理贴图：
- `rain_drop001.png`：降雨下坠水滴拉丝；
- `snow001.png`：降雪六角/柔和雪花粒子；
- `dust_post.png`：荒漠/沙尘暴全屏环境后处理贴图；
- `spore001.png`、`spore002.png`：那美克星浮空发光孢子；
- `wind_rain001.png`、`wind_sand001.png`、`wind_snow001.png`：疾风、沙暴、暴风雪粒子条带；
- `lightning_flash01.png`、`lightning_flash02.png`：暴雨天气下的全屏天际闪电爆发贴图。

### 2. OpenDBO-Core 表现层天气驱动（`NtlPLWeatherProperty.cpp` & `WeatherDlg.cpp`）
- 在 `wfp` 中由 `_IdxWeather[5]` 数组指定当前 Field 允许出现的 5 种随机天气 ID；
- 由 `CNtlPLWeatherProperty` 解析粒子发射器属性（`sEmitter.eEmitterPlaceType`），分为随摄像机机位跟随（`CAMERA_POS`）与注视点跟随（`CAMERA_AT`），驱动雨雪与沙尘粒子效果。

---

## 六、 结论与工程对齐状态

1. 选角与创角大厅 [`character_lobby_stage.gd`](file:///e:/DBOFF/src/ui/lobby/character_lobby_stage.gd) 的 `STAGE_CONFIGS` 已全量替换为官方真实二进制数据：
   - 彻底恢复 `sun_001.png` 与 `sun_002.png` 核心日轮；
   - 彻底接入官方 `sky_sp`、`sky00`、`sky` 基础天空与 `cloud_011`、`cloud_022`、`cloud-p01/02` 云层及速度；
   - 彻底接入官方 `(0.32, 0.40, 0.83)`、`(0.42, 0.66, 0.89)`、`(0.49, 0.38, 0.16)` 与 `(0.28, 0.16, 0.08)` 精确环境光；
2. [`WorldSkybox.gd`](file:///e:/DBOFF/src/world/world_skybox.gd) 开放 `set_sky_and_clouds()`，支持全场景按 Field 动态切换官方天空贴图组合与云速，彻底清除任何脱离源码与数据的杜撰行为。
