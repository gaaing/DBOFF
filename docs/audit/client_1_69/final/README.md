# DBO 1.69 TW 原版客户端解包工具包运行说明

## 一、环境与依赖要求

- **操作系统**：Windows 10 / 11 (x64)
- **运行环境**：Python 3.8+ (已在 Python 3.14 环境实测验证)
- **核心依赖库**：
  ```bash
  pip install pycryptodome
  ```

---

## 二、目录结构说明

- **解包器与工具目录**：`E:\DBOFF\docs\audit\client_1_69\final\`（镜像：`E:\DBOFF\audit\client_1_69\final\`）
- **源客户端目录**：`E:\DBO_CT_TW(1.57.51)\`
- **全量资产母库输出目录**：`E:\DBO_CT_TW(1.57.51)\assets\`

---

## 三、脚本执行指南

### 1. 运行自动化测试套件
在执行解包前，可运行测试套件验证环境与解包逻辑：
```powershell
python E:\DBOFF\docs\audit\client_1_69\final\test_extractor_suite.py
```
- 该脚本在独立内存/临时沙箱中运行 20 项测试（覆盖六大家族、本地化、Unit-1 边界回退、tbl1.pak、路径穿越安全、冲突检测等）。
- 测试完成后自动清理临时沙箱，预期输出 `20/20 PASSED`。

### 2. 运行全量资源提取
启动全量解包与母库构建：
```powershell
python E:\DBOFF\docs\audit\client_1_69\final\run_full_extraction.py
```
- 自动解密 16 个 Header PAK。
- 采用 8 线程并发流式切片与实时 SHA-256 计算。
- 提取 112,813 个内部资源并流式复制 68 个外部文件至 `E:\DBO_CT_TW(1.57.51)\assets\`。
- 支持安全断点续跑：已存在且哈希一致的文件会自动识别并跳过，不会重复覆写。

---

## 四、主要交付物文件清单

1. `dbo_full_extractor.py`：解包引擎核心模块。
2. `test_extractor_suite.py`：自动化回归测试入口。
3. `run_full_extraction.py`：全量多线程生产运行入口。
4. `FINAL_EXTRACTION_REPORT.md`：全量解包执行终报。
5. `FINAL_TEST_RESULTS.md`：测试套件执行明细报告。
6. `FINAL_RESOURCE_MANIFEST.csv`：全量 112,881 项资源的溯源与校验清单。
7. `FINAL_FAILURES.csv`：解包失败记录表（当前为 0 失败，仅包含表头）。
8. `FINAL_EXTRACTION_CHECKSUMS.txt`：交付文件的 SHA-256 完整性校验表。
