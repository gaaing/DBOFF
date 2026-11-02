# DBO 1.69 TW 原版客户端全量资源母库构建与解包审计终报

## 一、项目执行概况

本工程针对原版 **Dragon Ball Online 1.69 TW（台湾关服终版客户端）** 展开了全量无损提取，建立了标准、可追溯、可校验、可重复运行的原版资产母库。

- **母库源工程目录**：`E:\DBO_CT_TW(1.57.51)\`
- **资产母库目标目录**：`E:\DBO_CT_TW(1.57.51)\assets\`
- **交付与审计目录**：`E:\DBOFF\audit\client_1_69\final\`（镜像：`E:\DBOFF\docs\audit\client_1_69\final\`）
- **核心执行脚本**：[`dbo_full_extractor.py`](file:///E:/DBOFF/docs/audit/client_1_69/final/dbo_full_extractor.py)
- **自动化测试入口**：[`test_extractor_suite.py`](file:///E:/DBOFF/docs/audit/client_1_69/final/test_extractor_suite.py)
- **第二次全量运行核验耗时**：50.7 秒（112,881 个文件全部通过大小与 SHA-256 校验，0 重写，0 损坏）

---

## 二、覆盖漏洞修复与冲突防护验证

针对此前提取引擎可能存在的覆写风险，已完成两项关键防护加固：

1. **内部资源冲突防护重构**：
   - 彻底废除基于单纯大小相同的宽松跳过逻辑。
   - **机制**：无论目标文件大小是否相同，凡目标已存在，必须先计算预期源切片 SHA-256 与目标文件 SHA-256。完全对齐才标记 `SUCCESS_EXISTING_VERIFIED` 并跳过；若大小不同或哈希不同，立即返回 `CONFLICT_DIFFERENT_CONTENT`，严格禁止打开 `"wb"` 破坏现有文件。
2. **外部 68 个文件冲突防护重构**：
   - 废除无条件 `"wb"` 写入逻辑。
   - **机制**：对外部 68 个独立文件（PE可执行文件、DLL、字体、视频、光标、配置）执行前置哈希检查，相同才跳过，冲突时记录并拒绝覆写。
3. **三种冲突测试全量通过**：
   - **条件 1（相同内容）**：返回 `SUCCESS_EXISTING_VERIFIED`，安全跳过，零重复写入。
   - **条件 2（相同大小但不同内容）**：检测出 SHA-256 不符，返回 `CONFLICT_DIFFERENT_CONTENT`，文件受保护未被覆盖。
   - **条件 3（不同大小内容冲突）**：检测出文件尺寸与哈希不符，返回 `CONFLICT_DIFFERENT_CONTENT`，文件受保护未被覆盖。

---

## 三、14 条繁体中文特化 Flash 资源逐条核验确证表

对 `localize\TAIWAN\pack\flash.pak` 中的 14 条历史寻址记录进行了内部文件结构剖析，所有图像维度与矢量内部长度均与提取字节数达到数学级完全对齐，确认为 100% 真实有效的资源：

| 序号 | 内部资源相对路径 | 记录Unit/Offset/Size | 实际定位源分卷 | 提取字节数 | SHA-256 校验签名 | 图像/矢量物理内部结构核验 |
|---|---|---|---|---|---|---|
| **72** | `flash\loading_wzone_001\loading_wzone_001_i1.tga` | Unit 14 / 17,606,135 / 2,359,314 | `flash12.pak` | 2,359,314 B | `1e51e47ecd402ce3...` | TGA: 1024×768 @ 24bpp ($1024 \times 768 \times 3 + 18 = 2,359,314$) |
| **110** | `flash\loading_pdungeon_006\loading_pdungeon_006.gfx` | Unit 11 / 19,298,836 / 37,498 | `flash9.pak` | 37,498 B | `3c7f5e531ac714b2...` | Scaleform GFX ver=8, 内部标头长度为 37,498 字节 |
| **124** | `flash\tb_normal_title_red\tb_normal_title_red_i10.tga` | Unit 3 / 19,550,378 / 364,818 | `flash13.pak` | 364,818 B | `4b0193afb847e3b7...` | TGA: 380×240 @ 32bpp ($380 \times 240 \times 4 + 18 = 364,818$) |
| **159** | `flash\tmq2-3_opening\tmq2-3_opening_i29.tga` | Unit 0 / 18,534,785 / 10,834 | `flash16.pak` | 10,834 B | `fc5a9d63c558c6cb...` | TGA: 52×52 @ 32bpp ($52 \times 52 \times 4 + 18 = 10,834$) |
| **300** | `flash\tmq2-3_opening\tmq2-3_opening_i2d.tga` | Unit 21 / 18,545,619 / 10,834 | `flash16.pak` | 10,834 B | `d78ee4e1b4f54a86...` | TGA: 52×52 @ 32bpp ($52 \times 52 \times 4 + 18 = 10,834$) |
| **372** | `flash\tmq_s4_intermission_02\tmq_s4_intermission_02_i15.tga` | Unit 3 / 19,108,982 / 164,646 | `flash28.pak` | 164,646 B | `9ac1d12963ca55f0...` | TGA: 204×269 @ 24bpp ($204 \times 269 \times 3 + 18 = 164,646$) |
| **379** | `flash\tmq_epilogue1\tmq_epilogue1_i9.tga` | Unit 0 / 19,372,469 / 173,730 | `flash23.pak` | 173,730 B | `9c47f260dd74c05d...` | TGA: 517×84 @ 32bpp ($517 \times 84 \times 4 + 18 = 173,730$) |
| **400** | `flash\tmq_s2_intermission_01\tmq_s2_intermission_01_i4.tga` | Unit 28 / 19,469,735 / 414,498 | `flash25.pak` | 414,498 B | `2b29fbc820d4d550...` | TGA: 628×220 @ 24bpp ($628 \times 220 \times 3 + 18 = 414,498$) |
| **471** | `flash\tmq_s4_intermission_03\tmq_s4_intermission_03_i26.tga` | Unit 0 / 18,424,902 / 703,329 | `flash29.pak` | 703,329 B | `06863273e7d743a3...` | TGA: 749×313 @ 24bpp ($749 \times 313 \times 3 + 18 = 703,329$) |
| **477** | `flash\tmq2-1_opening\tmq2-1_opening_i22.tga` | Unit 1 / 19,043,612 / 342,018 | `flash15.pak` | 342,018 B | `62d42763ab48bd7f...` | TGA: 400×285 @ 24bpp ($400 \times 285 \times 3 + 18 = 342,018$) |
| **538** | `flash\tmq2_s1_intermission_01\tmq2_s1_intermission_01_id.tga` | Unit 24 / 19,203,767 / 352,860 | `flash17.pak` | 352,860 B | `da606ceceb325c67...` | TGA: 434×271 @ 24bpp ($434 \times 271 \times 3 + 18 = 352,860$) |
| **545** | `flash\tmq2_s2_intermission_02\tmq2_s2_intermission_02_i21.tga` | Unit 21 / 19,680,582 / 284,616 | `flash19.pak` | 284,616 B | `e9e4fee6a74ee53c...` | TGA: 326×291 @ 24bpp ($326 \times 291 \times 3 + 18 = 284,616$) |
| **707** | `flash\dbo_tutorial_01\dbo_tutorial_01_i58.tga` | Unit 5 / 17,359,584 / 1,000,018 | `flash1.pak` | 1,000,018 B | `7b003e8a7dea4873...` | TGA: 500×500 @ 32bpp ($500 \times 500 \times 4 + 18 = 1,000,018$) |
| **746** | `flash\tb_normal_title_blue\tb_normal_title_blue_i10.tga` | Unit 11 / 17,999,465 / 364,818 | `flash13.pak` | 364,818 B | `4b0193afb847e3b7...` | TGA: 380×240 @ 32bpp ($380 \times 240 \times 4 + 18 = 364,818$) |

---

## 四、全量母库决算与二次运行验证结果

| 状态分类 | 内部 PAK 条目数 | 外部独立文件数 | 全量合计项数 | 统计占比 |
|---|---|---|---|---|
| **已验证并安全保留 (SUCCESS / VERIFIED)** | 112,813 | 68 | **112,881** | **100.00%** |
| **解包失败 (FAILED)** | 0 | 0 | **0** | **0.00%** |
| **内容冲突 (CONFLICT)** | 0 | 0 | **0** | **0.00%** |
| **待处理 (PENDING)** | 0 | 0 | **0** | **0.00%** |
| **母库导出总文件数** | 112,813 | 68 | **112,881** | **100.00%** |
| **母库导出总物理容量** | 8,705,917,810 字节 | 241,927,297 字节 | **8,947,845,107 字节 (8.333 GB)** | **数据无损** |

### 二次全量运行验证结论（Idempotent Verification）
在全量解包完成后，重新运行解包引擎进行整体验证：
- **总处理条目**：112,881
- **Existing Verified Skip（已存在且校验一致跳过）**：**112,881**
- **重复写入数**：**0**
- **耗时**：50.7 秒
- **结论**：系统完美支持安全断点续跑与重复运行，未对已有正确资源产生任何覆写或破坏。

---

## 五、最终交付清单完整性核验

- **`FINAL_RESOURCE_MANIFEST.csv`**（35.5 MB）：
  - 包含全部 12 列法定字段：`namespace, source_pak, resource_path, output_path, source_volume, source_offset, expected_size, exported_size, source_sha256, output_sha256, detected_format, extraction_status`
  - 行数：112,882 行（1 行表头 + 112,881 条记录），无缺失，无空白行。
- **`FINAL_FAILURES.csv`**：
  - 仅包含标准表头，**失败行数为 0**。
- **`FINAL_TEST_RESULTS.md`**：
  - 记录 21 项自动化测试 100% 通过的详细报告。
- **`FINAL_EXTRACTION_CHECKSUMS.txt`**：
  - 记录上述所有交付物的 SHA-256 完整性防篡改签名。
