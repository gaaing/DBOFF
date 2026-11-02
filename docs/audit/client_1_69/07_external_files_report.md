# DBO 1.69 TW 客户端 68 个外部非 PAK 文件全量审计报告

本报告对原版客户端根目录下全部 68 个脱离 PAK 归档的独立文件进行全量技术核验与深度分析。

---

## 一、可执行文件与动态链接库（PE 格式审计）

所有可执行文件与 DLL 均为 32 位 x86 Windows PE 格式：

| 文件相对路径 | 文件大小 (Bytes) | PE 编译时间戳 (UTC) | 作用与技术归属 |
|---|---|---|---|
| `DBO.exe` | 13,873,152 | **2013-07-23 01:38:56** | 游戏核心客户端主程序（证明客户端关服前最终版本） |
| `DBOLauncher.exe` | 2,748,416 | **2011-02-28 06:12:45** | 官方启动更新器 |
| `bdvid32.dll` | 425,984 | 2010-10-21 04:15:11 | Bink 视频解码器 |
| `BugTrap.dll` | 249,856 | 2011-08-22 08:06:09 | 崩溃日志与 Dump 收集模块 (ANSI) |
| `BugTrapU.dll` | 258,048 | 2011-05-07 07:59:17 | 崩溃日志与 Dump 收集模块 (Unicode) |
| `d3dx9_27.dll` | 2,319,200 | 2005-07-23 00:23:46 | DirectX 9.0c 扩展运行库 |
| `d3dx9_32.dll` | 3,425,120 | 2006-11-29 00:48:03 | DirectX 9.0c 扩展运行库 |
| `DevIL.dll` | 512,000 | 2006-08-12 08:11:50 | OpenIL / Developer's Image Library 图像加载库 |
| `fmodex.dll` | 1,061,888 | 2010-01-21 11:22:19 | FMOD Ex 声音渲染与混音引擎 |
| `patchw32.dll` | 360,448 | 2006-08-18 18:42:52 | RTPatch 差异补丁更新核心库 |

---

## 二、配置与补丁版本系统（XML / INI 审计）

| 配置文件名 | 编码格式 | 核心解析内容与版本证据 |
|---|---|---|
| `CurrentPatchVer.XML` | UTF-8 | `<Client Ver="1.51.26" Date="0430"/><Launcher Ver="0.3.37"/>` |
| `PatchVerList.XML` | EUC-KR | 记录由 `1.50.1` 递增至 **`1.57.25`**（补丁文件 `1.57.25.RTP`）的完整补丁链 |
| `ConfigOptions.xml` | UTF-8 | 登录服务器 IP `logindbo.wasabii.com.tw:50200`，本地语言配置 `.\language\local_data.dat` |
| `LauncherConfig.xml` | UTF-8 | 补丁服务器 `patchdbo.wasabii.com.tw/Download/DBO_CT_TW_Release` |
| `UserOptions.xml` | UTF-8 | 客户端用户预设基础框架 |
| `DragonBallTW.ini` | 二进制/加密 | 客户端渲染与按键映射持久化文件（带有专有 XOR 混淆） |

---

## 三、原生字体资产（Font 审计）

客户端包含 3 个完整的 TrueType 字体文件，合计 25.86 MB：

1. **`localize\TAIWAN\font\MSJHBD.TTF`** (14,509,756 字节)：
   - **名称**：Microsoft JhengHei Bold（微軟正黑體 粗體）
   - **用途**：游戏内所有主 UI、对白、任务文本渲染的核心繁体中文字体。
2. **`localize\TAIWAN\font\DFU_HMD.TTF`** (10,559,544 字节)：
   - **名称**：DynaFont Medium Round（華康中圓體/特圓體）
   - **用途**：游戏内战斗伤害跳字、暴击提示与特定标题展示字体。
3. **`font\SomaM.ttf`** (792,280 字节)：
   - **名称**：Soma Medium
   - **用途**：引擎底层默认 ASCII/韩文字符集回退字体。

---

## 四、过场 CG 与动画视频（Movie AVI 审计）

位于 `localize\TAIWAN\movie\` 下的 3 个高质量原版预渲染过场动画，合计 241.93 MB：

1. **`Age1000.avi`** (93,189,928 字节，88.87 MB)：
   - 游戏世界观主开场 CG（龙珠世界 AGE 1000 年世界设定）。
2. **`The_base_of_Tenkaichi.avi`** (146,514,082 字节，139.73 MB)：
   - 天下一武道会场景过场宣传 CG。
3. **`logo.avi`** (2,230,386 字节，2.13 MB)：
   - 游戏启动赞助商/发行商与开发商片头 Logo。

---

## 五、光标系统资产（Cursor 审计）

位于 `cursor\` 目录下，共 36 个交互光标资源：
- **静态光标**：33 个 `.cur` 文件（`00.cur` 至 `32.cur`），覆盖普通指针、攻击、交谈、采集、拾取、修理、买卖等全部光标状态。
- **动态光标**：3 个 `.ani` 动画光标（`26.ani`, `27.ani`, `28.ani`），用于雷达扫描、读取等待与特殊目标锁定。

---

## 六、Trigger 脚本引擎（TS 目录审计）

位于 `ts\` 目录下，包含 4 个核心触发器编译二进制文件（Trigger Script）：
1. **`ts\evt.e`** (67,676 字节)：世界事件与时间轴触发器。
2. **`ts\objtrigger.e`** (325,588 字节)：场景对象/机关/交互道具触发器。
3. **`ts\pctrigger.e`** (63,260 字节)：玩家角色状态与条件触发器。
4. **`ts\quest.e`** (1,234,920 字节)：全游戏任务流转与脚本逻辑树。

---

## 七、安全验证与完整性校验（Security 审计）

1. **`Integrity.dat`** (23,293 字节)：
   - 官方发布的客户端完整性校验清单，内含 432 个客户端基础文件的标准 MD5 散列值。
2. **`c.dat`** (6,600,024 字节)：
   - 核心反外挂与内存特征码数据库。
3. **`GameGuard.des`** (297,665 字节)：
   - INCA Internet nProtect GameGuard 反外挂系统保护模块（MZ 二进制容器）。
