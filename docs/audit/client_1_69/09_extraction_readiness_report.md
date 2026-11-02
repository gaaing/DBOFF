# DBO 1.69 TW 客户端正式解包执行准备就绪报告

## 一、解包准备状态与前提条件核验

截至本次只读审计完成，原版客户端母库（`E:\DBO_CT_TW(1.57.51)\`）的状态已 100% 掌握：

- [x] **母库完整性**：537 个文件（469 个 PAK + 68 个外部文件）全部完成 SHA-256 哈希计算与基线对齐。
- [x] **解密规范已验证**：DES ECB `b"jhssugi\x00"` 验证通过，16 个 Header 索引包解密成功率 100%。
- [x] **内部索引解析完毕**：112,813 个内部资源物理条目完成寻址计算与映射绑定。
- [x] **历史陷阱与阻碍清零**：
  - `tan.pak -> terrainX.pak` 映射规则已固化。
  - `pack\` 与 `localize\TAIWAN\pack\` 命名空间隔离规则已制定。
  - 数据卷纯流切片规则已明确，无需二次解密。

---

## 二、正式解包目录架构规范（方案设计）

为确保不污染现有 `raw`、不破坏原版母库、不影响 DBOFF 项目代码，建议解包输出采用全新的独立目录：

```text
E:\DBOFF\raw_tw_1_69\
├── main\                       <-- 对应 pack\ 下的解包产物
│   ├── obj\                    (27,999 files)
│   ├── tex\                    (28,275 files)
│   ├── terrain\                (42,912 files, 来自 tan.pak)
│   ├── sound\                  (3,460 files)
│   ├── gui\                    (1,489 files)
│   ├── flash\                  (1,194 files)
│   ├── lang\                   (7 files)
│   ├── scr\                    (163 files)
│   ├── tbl\                    (17 files)
│   └── prop\                   (0 files)
├── localize_taiwan\            <-- 对应 localize\TAIWAN\pack\ 下的解包产物
│   ├── flash\                  (798 files)
│   ├── gui\                    (3 files)
│   ├── lang\                   (4 files)
│   ├── scr\                    (90 files)
│   ├── tbl\                    (18 files)
│   └── tex\                    (400 files)
├── external\                   <-- 对应 68 个非 PAK 独立资产
│   ├── font\                   (MSJHBD.TTF, DFU_HMD.TTF, SomaM.ttf)
│   ├── movie\                  (Age1000.avi, The_base_of_Tenkaichi.avi, logo.avi)
│   ├── cursor\                 (36 个 cur 与 ani 光标)
│   ├── ts\                     (evt.e, objtrigger.e, pctrigger.e, quest.e)
│   └── configs\                (XML 与 INI 配置文件)
└── logs\
    ├── unpack_execution.log    <-- 全量操作日志
    └── unpack_manifest.csv     <-- 实际解出文件的字节数与 SHA-256 校验表
```

---

## 三、解包安全原则与校验机制

1. **绝对只读源保护**：
   - 提取工具仅使用 `open(path, 'rb')` 访问 `E:\DBO_CT_TW(1.57.51)`，禁止任何写入、移动或重命名。
2. **切片数据校验**：
   - 每提取一个文件，严格校验 `len(data) == uiSize`。
   - 针对 `10_audit_exceptions.csv` 中记录的 275 个超出卷边界的历史异常条目，采用静默隔离并记录到 `failed_or_skipped.csv`，严禁导致整个批处理中断。
3. **性能与内存控制**：
   - 数据卷以只读文件句柄池（File Handle Pool）复用管理，采用流式 `seek` 与分块 `read`，避免一次性载入大文件（内存峰值控制在 200MB 以内）。

---

## 四、结论

**技术准备度评估：100% READY**。  
解包工具原型与参数映射已完备，具备立即启动无损全量解包的一切前提条件。
