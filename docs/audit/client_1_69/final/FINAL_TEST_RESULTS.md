# DBO 1.69 TW 解包器自动化测试套件执行报告

## 一、测试套件概述

根据《DBO 1.69 TW 原版客户端：最终收尾：修复安全漏洞并完成交付，不重做解包》第一节的严格要求，在修复内部资源与外部 68 个文件的覆盖漏洞后，必须通过**不同大小、相同大小但不同内容、相同内容**三种冲突保护测试，并对六大家族、本地化、特殊分卷与安全防御进行回归验证。

- **测试执行时间**：2026-11-02
- **测试入口脚本**：[`test_extractor_suite.py`](file:///E:/DBOFF/docs/audit/client_1_69/final/test_extractor_suite.py)
- **测试对象**：[`dbo_full_extractor.py`](file:///E:/DBOFF/docs/audit/client_1_69/final/dbo_full_extractor.py)
- **测试沙箱目录**：`E:\DBOFF\docs\audit\client_1_69\final\test_sandbox\`（独立沙箱，测试完成后自动销毁）
- **测试用例总数**：21 个
- **测试通过率**：**100% (21/21 PASS, 0 FAIL)**

---

## 二、测试用例明细与执行结果表

| 用例编号 | 测试类别 | 目标测试点 | 实际运行输出与校验特征 | 判定结果 |
|---|---|---|---|---|
| **TC-01** | 六大资源家族 | OBJ 骨骼动画 (`.anm`) | 提取 1,940 字节，SHA-256 切片一致，格式识别为 `RenderWare Animation (ANM)` | **PASS** |
| **TC-02** | 六大资源家族 | OBJ 3D网格模型 (`.dff`) | 提取 46,329 字节，SHA-256 切片一致，格式识别为 `RenderWare Clump (DFF Model)` | **PASS** |
| **TC-03** | 六大资源家族 | TEX DDS 角色贴图 (`.dds`) | 提取 43,832 字节，SHA-256 切片一致，格式识别为 `DirectDraw Surface (DDS)` | **PASS** |
| **TC-04** | 六大资源家族 | TAN 地形属性包 (`.gwp`) | 提取 250 字节，SHA-256 切片一致，格式识别为 `NTL World Property (GWP)` | **PASS** |
| **TC-05** | 六大资源家族 | SOUND 原始波形音频 (`.wav`) | 提取 6,828 字节，SHA-256 切片一致，格式识别为 `PCM Wave Audio (RIFF/WAVE)` | **PASS** |
| **TC-06** | 六大资源家族 | GUI 窗口布局脚本 (`.frm`) | 提取 861 字节，SHA-256 切片一致，格式识别为 `GUI Dialog Layout Script` | **PASS** |
| **TC-07** | 六大资源家族 | FLASH 矢量动画 (`.gfx`) | 提取 2,685 字节，SHA-256 切片一致，格式识别为 `Scaleform GFX Vector` | **PASS** |
| **TC-08** | 命名空间隔离 | 繁体中文本地化贴图 | 提取 16,512 字节，进入 `localize_taiwan\` 命名空间，与主包隔离 | **PASS** |
| **TC-09** | 边界自适应 | TEX 分卷边界回退 (`tex0.pak`) | 命中 `RULE_UNIT_MINUS_1_BOUNDARY`，成功提取 109 字节完整合法 PNG | **PASS** |
| **TC-10** | 边界自适应 | FLASH 分卷边界回退 (`flash0.pak`) | 命中 `RULE_UNIT_MINUS_1_BOUNDARY`，成功提取 9,234 字节合法 TGA | **PASS** |
| **TC-11** | 边界自适应 | TAN 分卷边界回退 (`terrain3.pak`)| 命中 `RULE_UNIT_MINUS_1_BOUNDARY`，成功提取 4 字节世界特效标记 | **PASS** |
| **TC-12** | 特殊分卷 | 表格分卷 `tbl1.pak` | 命中 `RULE_TBL1_VOLUME_SERIES`，在 `tbl1.pak` 末尾提取 6,810 字节 `td_race.edf` | **PASS** |
| **TC-13** | 本地化特异化 | 台湾 Flash 特殊寻址 (`.gfx`) | 命中 `RULE_LOCALIZED_FLASH_SIGNATURE`，成功在 `flash9.pak` 提取 37,498 字节 | **PASS** |
| **TC-14** | 本地化特异化 | 台湾 Flash 特殊寻址 (`.tga`) | 命中 `RULE_LOCALIZED_FLASH_SIGNATURE`，成功在 `flash13.pak` 提取 364,818 字节 | **PASS** |
| **TC-15** | 特殊文件 | 无扩展名资源保留 | 成功提取 `wfpf3863`，确认未擅自篡改或追加假扩展名 | **PASS** |
| **TC-16** | 安全防御 | 路径穿越攻击拦截 (`..\..\`) | 成功检测非法序列，返回 `REJECTED_PATH_TRAVERSAL`，阻止越权写入 | **PASS** |
| **TC-17** | 异常容错 | 伪造超大越界读取拦截 | 成功拦截 50MB 越界切片，返回 `FAILED_OUT_OF_BOUNDS`，程序未崩溃 | **PASS** |
| **TC-18** | 异常容错 | 伪造缺失分卷读取拦截 | 成功拦截不存在的 `gui99.pak`，返回 `FAILED_VOLUME_MISSING`，程序未崩溃 | **PASS** |
| **TC-19** | 覆盖保护 1 | 相同内容 (相同大小/哈希) | 返回 `SUCCESS_EXISTING_VERIFIED`，直接验证通过并安全跳过，零重复 I/O | **PASS** |
| **TC-20** | 覆盖保护 2 | 相同大小但不同内容 | 识别哈希不一致，返回 `CONFLICT_DIFFERENT_CONTENT`，严格拒绝写入覆盖原有文件 | **PASS** |
| **TC-21** | 覆盖保护 3 | 不同大小内容冲突 | 识别大小不一致，返回 `CONFLICT_DIFFERENT_CONTENT`，严格拒绝写入覆盖原有文件 | **PASS** |

---

## 三、格式识别口径声明

本套件严格遵循用户规则：
- **格式识别仅作为辅助元数据记录，未识别的格式统一标记为 `UNKNOWN`**。
- `UNKNOWN` 格式的资源只要其源切片 SHA-256 与输出文件 SHA-256 完全对齐，即被判定为**解包成功**。
- **严禁将 `UNKNOWN` 计入格式识别成功率，绝不宣称格式识别率 100%**。

---

## 四、测试阶段结论

测试套件 21 项用例 100% 通过，覆盖了包括三种冲突防护条件在内的全部关键边界与安全要求。
