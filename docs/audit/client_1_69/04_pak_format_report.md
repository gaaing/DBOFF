# DBO 1.69 TW 客户端 PAK 格式全量审计与二进制规范报告

## 一、PAK 整体架构设计原理

Dragon Ball Online (DBO) 客户端采用分卷式资源打包体系（NtlPLResourcePack）。其核心架构设计特征如下：

1. **索引与数据分离架构**：
   - 每个资源大类（Family）包含一个且仅一个 **Header 索引包**（如 `obj.pak`、`tex.pak`、`tan.pak`）。
   - 实际资源数据流被切片存放在多个连续编号的 **Data Volume 数据卷** 中（如 `obj0.pak` .. `obj104.pak`）。
   - 数据卷单文件容量上限标准为约 20 MB（20,971,520 字节），超过该阈值时自动切入下一个 Volume 卷。

2. **加密机制**：
   - **Header 索引包**：全量采用 **DES ECB 模式** 对称加密。
   - **解密密钥**：`b"jhssugi\x00"`（8 字节 ASCII 密钥）。
   - **Data Volume 数据卷**：为**纯原始二进制数据流切片（Raw Concatenated Stream）**，内部没有任何文件头、魔数或加密包裹，资源偏移与大小完全由 Header 索引包中的条目绝对寻址。

---

## 二、Header 索引包二进制物理结构

Header 包解密后遵循严谨的 140 字节定长记录表：

### 1. 文件起始魔数与版本（2 字节）
- 偏移 `0x0000 - 0x0001`：`uint16_t`，值为 `5639`（`0x1607`），标识资源包格式版本号。

### 2. 资源索引条目结构（140 字节定长循环数组）
每个资源文件条目（SFilePackHeaderElement）占用严格对齐的 140 字节：

| 字节偏移 (Offset) | 字段名称 (Field) | 数据类型 (Type) | 长度 (Bytes) | 含义与规范 |
|---|---|---|---|---|
| `0x00 - 0x7F` | `chName` | `char[128]` | 128 | 内部相对路径，ASCII 编码，`\0` 终止，多余字节填充 `0xFD` 或 `0x00` |
| `0x80 - 0x82` | `padding` | `uint8_t[3]` | 3 | 结构体内存对齐填充字节（固定为 `0x00, 0x00, 0x00`） |
| `0x83 - 0x86` | `uiSize` | `uint32_t` (LE) | 4 | 资源未压缩实际字节大小 (Little-Endian) |
| `0x87 - 0x8A` | `uiOffset` | `uint32_t` (LE) | 4 | 在对应分卷数据包中的起始绝对字节偏移 (Little-Endian) |
| `0x8B` | `byUnitKey` | `uint8_t` | 1 | 目标数据卷的编号索引（如 `0` 代表 `vol0.pak`） |

> **关键技术发现与逆向修正**：
> 早期部分社区工具误以为 `byUnitKey` 在首字节（偏移 0），但实际上在 1.69 TW 客户端中，`chName` 严格位于 0..127 字节，`uiSize` 位于 131..134，`uiOffset` 位于 135..138，`byUnitKey` 位于 139 字节。

---

## 三、PAK 资源家族分类与映射规范表

原版客户端共包含 469 个 PAK，划分为 **10 大资源家族** 与 **2 大作用域**（Main 基础包 vs Localize 台湾汉化包）：

| 家族代码 (Family) | 索引包路径 (Header PAK) | 对应数据分卷命名规则 | 分卷总数 | 索引条目总数 | 核心资源类型 |
|---|---|---|---|---|---|
| **obj** | `pack\obj.pak` | `pack\obj{0..104}.pak` | 105 | 27,999 | 3D角色/怪物/场景模型 (.dff, .clp) |
| **tex** | `pack\tex.pak` | `pack\tex{0..60}.pak` | 61 | 28,275 | 贴图纹理 (.png, .dds, .tga) |
| **tan** (terrain) | `pack\tan.pak` | `pack\terrain{0..162}.pak` | 163 | 42,912 | 大世界地图地形高度图、地貌与分块网格 |
| **sound** | `pack\sound.pak` | `pack\sound{0..65}.pak` | 66 | 3,460 | 背景音乐、技能音效、UI音效 (.ogg, .wav) |
| **gui** | `pack\gui.pak` | `pack\gui{0..8}.pak` | 9 | 1,489 | UI界面窗口配置文件与位图 |
| **flash** | `pack\flash.pak` | `pack\flash{0..15}.pak` | 16 | 1,194 | 动画界画、过场CG UI、加载图 (.swf, .gfx, .tga) |
| **lang** | `pack\lang.pak` | `pack\lang0.pak` | 1 | 7 | 语言本地化底层系统字典 |
| **scr** | `pack\scr.pak` | `pack\scr0.pak` | 1 | 163 | 客户端交互脚本与系统逻辑 |
| **tbl** | `pack\tbl.pak` | `pack\tbl0.pak` | 1 | 17 | 客户端游戏静态数据表格 (Table RDF/Binary) |
| **prop** | `pack\prop.pak` | (无分卷，单包索引) | 0 | 0 | 场景实体对象属性配置 |
| **loc_flash** | `localize\TAIWAN\pack\flash.pak` | `localize\TAIWAN\pack\flash{0..30}.pak` | 31 | 798 | 繁体中文加载画面与过场动画 |
| **loc_gui** | `localize\TAIWAN\pack\gui.pak` | `localize\TAIWAN\pack\gui0.pak` | 1 | 3 | 繁体中文特化 UI 窗体覆盖包 |
| **loc_lang** | `localize\TAIWAN\pack\lang.pak` | `localize\TAIWAN\pack\lang0.pak` | 1 | 4 | 繁体中文系统提示文本字典 |
| **loc_scr** | `localize\TAIWAN\pack\scr.pak` | `localize\TAIWAN\pack\scr0.pak` | 1 | 90 | 繁体中文客户端特定脚本覆盖 |
| **loc_tbl** | `localize\TAIWAN\pack\tbl.pak` | `localize\TAIWAN\pack\tbl0.pak` | 1 | 18 | 繁体中文游戏数据表覆盖 (Table RDF/Binary) |
| **loc_tex** | `localize\TAIWAN\pack\tex.pak` | `localize\TAIWAN\pack\tex0.pak` | 1 | 400 | 繁体中文特化贴图 (如带中文的UI字图) |

---

## 四、历史工具致命缺陷溯源（Critical Flaw）

现存社区解包工具（如 `DBO Unpacker.exe` 及多种 Python 批处理脚本）在处理 1.69 TW 客户端时存在两处严重缺陷：

1. **Terrain 分卷命名映射硬编码崩溃**：
   - 社区工具代码通常采用硬编码逻辑：`vol_name = pak_name[:-4] + str(unit_key) + ".pak"`。
   - 当解包 `tan.pak` 时，社区工具尝试寻找 `tan0.pak`、`tan1.pak`... 但客户端实际分卷文件名为 `terrain0.pak`、`terrain1.pak`...
   - **后果**：导致 42,912 个地形资源（163 个分卷包）解包率 0%，全部抛出 `File Not Found`。
2. **Localize 覆盖层破坏性覆盖**：
   - 社区解包脚本未对 `pack\` 与 `localize\TAIWAN\pack\` 做命名空间隔离，导致提取输出时发生覆盖或路径错乱。
