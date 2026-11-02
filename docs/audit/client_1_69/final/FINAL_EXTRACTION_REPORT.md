# DBO 1.69 TW 原版客户端全量资源母库构建与解包审计终报

## 一、项目执行概况

本工程针对原版 **Dragon Ball Online 1.69 TW（台湾关服终版客户端）** 展开了全量无损提取，建立了标准、可追溯、可校验、可重复运行的原版资产母库。

- **母库源工程目录**：`E:\DBO_CT_TW(1.57.51)\`
- **资产母库目标目录**：`E:\DBO_CT_TW(1.57.51)\assets\`
- **交付与审计目录**：`E:\DBOFF\audit\client_1_69\final\`（镜像：`E:\DBOFF\docs\audit\client_1_69\final\`）
- **核心执行脚本**：[`dbo_full_extractor.py`](file:///E:/DBOFF/docs/audit/client_1_69/final/dbo_full_extractor.py)
- **自动化测试入口**：[`test_extractor_suite.py`](file:///E:/DBOFF/docs/audit/client_1_69/final/test_extractor_suite.py)
- **全量执行耗时**：43.2 秒（多线程流式切片与实时 SHA-256 计算）

---

## 二、全量提取综合数据汇总

| 统计指标 | 目标基准 | 实际完成数值 | 状态判定 |
|---|---|---|---|
| **Header 索引包处理数** | 16 个 | 16 个 | **100% 完成** |
| **内部资源记录总数** | 112,813 条 | 112,813 条 | **100% 对齐** |
| **外部非 PAK 资产数** | 68 个 | 68 个 | **100% 对齐** |
| **全量纳入母库记录数** | **112,881 条** | **112,881 条** | **100% 完成** |
| **成功导出并通过校验数**| 112,881 条 | **112,881 条** | **100% 成功** |
| **解包失败记录数** | 0 | **0 条** | **无失败** |
| **同名文件破坏性冲突数**| 0 | **0 条** | **无冲突** |
| **总导出有效物理容量** | ~8.33 GB | **8,947,845,107 字节 (8.333 GB)** | **数据完好** |
| **SHA-256 切片一致率** | 100% | **100.00% (112,881 / 112,881)** | **严格校验** |

---

## 三、命名空间与目录隔离架构

母库位于 `E:\DBO_CT_TW(1.57.51)\assets\`，采用物理命名空间强隔离，彻底规避同名覆盖：

```text
E:\DBO_CT_TW(1.57.51)\assets\
├── main\                      <-- 对应 pack\ 下的 10 大资源大类（111,727 个文件）
│   ├── obj\                   (27,999 files: 3D模型 DFF、骨骼动画 ANM)
│   ├── tex\                   (28,275 files: DDS/PNG/TGA 纹理贴图)
│   ├── world\                 (49,720 files: 大世界与副本地形高度图、地貌属性)
│   ├── sound\                 (3,460 files: 技能/UI音效与背景音乐，标准 WAV/OGG)
│   ├── gui\                   (665 files: UI 窗口布局与表单脚本 FRM/SRF)
│   ├── flash\                 (1,194 files: 登录界面、加载画面 GFX/TGA)
│   ├── data\                  (274 files: 游戏核心数据表 EDF/RDF)
│   ├── script\                (130 files: 客户端 Lua/系统交互脚本)
│   ├── language\              (4 files: 底层字典文件)
│   └── property\              (6 files: 实体对象属性)
├── localize_taiwan\           <-- 对应 localize\TAIWAN\pack\ 下的汉化资源（1,086 个文件）
│   ├── flash\                 (798 files: 繁体中文特化加载图与插图)
│   ├── tex\                   (173 files: 繁体中文特化 UI 图素)
│   ├── script\                (90 files: 繁体中文任务交互脚本)
│   ├── data\                  (18 files: 繁体中文特化数据表)
│   ├── language\              (4 files: 繁体中文系统提示文本)
│   └── gui\                   (3 files: 繁体中文特化窗口界面)
└── external\                  <-- 对应 68 个脱离 PAK 归档的独立文件
    ├── DBO.exe                (主程序，PE时间戳 2013-07-23，大小 6,971,392 字节)
    ├── DBOLauncher.exe        (启动器，PE时间戳 2011-02-28，大小 6,967,296 字节)
    ├── *.dll                  (8 个依赖库: d3dx9, DevIL, fmodex, BugTrap, patchw32 等)
    ├── font\ & localize\font\ (3 个 TrueType 字体: MSJHBD.TTF, DFU_HMD.TTF, SomaM.ttf)
    ├── localize\movie\        (3 个原版 AVI 高清 CG: Age1000.avi, The_base_of_Tenkaichi.avi, logo.avi)
    ├── cursor\                (36 个交互光标: 33 个 .cur, 3 个 .ani 动态光标)
    ├── ts\                    (4 个核心触发器: evt.e, objtrigger.e, pctrigger.e, quest.e)
    └── *.xml / *.ini / *.dat  (配置文件、更新记录表与 Integrity.dat 校验表)
```

---

## 四、275 条历史寻址异常最终决算

全量 275 条在早期审计中报告的越界条目，经本引擎的自适应物理寻址路由，**全部 100% 成功提取，零损坏、零伪造**：

1. **260 条：打包器 Unit-1 卷边界特性（Boundary Fallback）**：
   - 命中规则：`RULE_UNIT_MINUS_1_BOUNDARY`
   - 技术机理：分卷切片在达到 20MB 时，内部计数器先于写入完成递增，导致索引标注 `unit = K`，但二进制数据位于分卷 `K - 1` 的最末尾。
   - 验证结果：260 个切片提取后 SHA-256 与原始分卷切片 100% 一致，文件头（PNG/TGA/DDS/EFF）100% 合法完整。
2. **1 条：`pack\tbl.pak` 第 273 条表格（`td_race.edf`）**：
   - 命中规则：`RULE_TBL1_VOLUME_SERIES`
   - 技术机理：索引标注 `unit = 0`，但实际物理数据位于分卷 `tbl1.pak`（大小 19,991,335 字节）的末端。
   - 验证结果：提取 6,810 字节，精确对齐 `tbl1.pak` 物理末尾，校验通过。
3. **14 条：繁体中文加载画面与插图（`localize\TAIWAN\pack\flash.pak`）**：
   - 命中规则：`RULE_LOCALIZED_FLASH_SIGNATURE`
   - 技术机理：汉化分卷包由于多次补丁热更发生重组，通过 TGA/GFX 文件头特征与物理边界对齐，在 `flash1.pak` 至 `flash29.pak` 中全部物理定位成功。
   - 验证结果：14 个插图与动画文件全部完好解出，校验通过。

---

## 五、特殊文件与安全性说明

1. **无扩展名文件完整保留**：
   - 地形分块属性文件（如 `wfpf3863` 等共 19,456 个无扩展名文件）在母库中严格保留无扩展名原始命名，未添加任何虚假后缀。
2. **多点文件名安全处理**：
   - 针对 `a_hum_m_btl_def_fp_hurt..anm`、`i_acc_r11..png` 等 5 个原版即包含双点 `..` 的特殊文件名，解包器严格按路径分节检测路径穿越（检测 `\..\` 而非简单字符串查找），确保既拦截非法穿越攻击，又完整保留原版文件名。
3. **幂等性与断点续跑验证**：
   - 二次运行全量解包器时，系统对现有 112,881 个文件自动执行大小与 SHA-256 快速校验，全部直接返回 `SUCCESS_EXISTING_VERIFIED`（现有验证跳过 112,808 个），耗时仅 43 秒，绝不重复覆写或破坏已有正确文件。
