# 那美克星人 5 套官方全量原生皮肤贴图体系修复报告

## 1. 目标清单与完成进度

- [x] **根因定位与排查**：
  - 查明那美克星人肤色在创角界面切换时无法更换为之前提取的 5 套官方原生精调纹理的原因。
  - 查明为何“只有头发会变色且颜色与之前几套皮肤颜色不一致”：定位到此前将 XML 残留参数（粉色、黄色、青色、紫色、红色）盲目应用到触角材质 `albedo_color`，而身体与面部贴图始终未做动态路径切换的根因。
- [x] **触角（头部）原生贴图与肤色 100% 对齐恢复**：
  - 在 [`src/entities/character_visual.gd`](file:///e:/DBOFF/src/entities/character_visual.gd) 中，当 `c_race == 1` 时，发型材质动态挂接官方 50 种全覆盖原生贴图：`a_nam_head%02d_%02d.png`（发型 1~10 × 肤色 1~5）。
  - 触角材质色统一使用 `Color.WHITE`，彻底消除粉/黄/紫/红等错误杂色，使触角与身体各部位肤色色相 100% 绝对一致。
- [x] **面部五官（Face）官方多肤色底板动态解析**：
  - 根据肤色编号 `skin_col_num` 动态寻址 `a_nam_ch_fskin%02d_%02d.png`（童年）与 `a_nam_ad_fskin%02d_%02d.png`（成人），缺失脸型优雅回退至该肤色编号下的 `01` 号底板。
  - 配合五官线条贴图（`a_nam_ch_face01~10.png`），在着色器中以 `Color.WHITE` 完整呈现正统肤色底纹与清晰五官。
- [x] **身体原生皮肤（胸背手臂与裤腿）全套贴图动态装配**：
  - 上身躯干与手臂皮肤表面（`A_NFI_AD_jacket_skin01`）严格映射对应 `skin_col_num` 的 `a_nfi_ad_jacket_skin%02d.png`（01~05）。
  - 下身裤腿皮肤表面（`A_NAM_pants_skin01`）严格映射对应 `skin_col_num` 的 `a_nam_pants_skin%02d.png`（01~05）。
  - 保留 `CHARACTER_SKIN_SHADER` 的红条纹保护逻辑与 `Color.WHITE` 保真度，5 套皮肤原汁原味切换：1-经典比克绿、2-土黄色、3-翠绿色、4-嫩黄绿、5-异星青蓝。
- [x] **创角 UI 步进联动与互斥规约同步**：
  - 在 [`src/ui/lobby/character_lobby_ui.gd`](file:///e:/DBOFF/src/ui/lobby/character_lobby_ui.gd) 中，当那美克星人点击“发色”步进按钮时，同步联动切换其对应的 5 种正统触角/肤色纹理，杜绝发色与肤色脱节。
- [x] **引擎无头验证**：Godot 4.7.2 运行退出码为 0，零红字报错。

---

## 2. 5 套官方原生精调纹理资源映射对照

那美克星人的 5 种官方肤色体系并非基于通用单图的乘法染色，而是由官方美术专门绘制的高清五套独立纹理：

| 肤色编号 | 官方视觉风格 | 头部触角贴图 | 上身上衣皮肤贴图 | 下身裤腿皮肤贴图 | 面部底模贴图 |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **1** | 经典比克草绿 (Piccolo Green) | `a_nam_headXX_01.png` | `a_nfi_ad_jacket_skin01.png` | `a_nam_pants_skin01.png` | `a_nam_ch_fskinXX_01.png` |
| **2** | 泥土灰褐/赭黄 (Earthy Ochre) | `a_nam_headXX_02.png` | `a_nfi_ad_jacket_skin02.png` | `a_nam_pants_skin02.png` | `a_nam_ch_fskinXX_02.png` |
| **3** | 鲜艳翠绿 (Vibrant Emerald) | `a_nam_headXX_03.png` | `a_nfi_ad_jacket_skin03.png` | `a_nam_pants_skin03.png` | `a_nam_ch_fskinXX_03.png` |
| **4** | 浅黄嫩绿 (Lime Pale Green) | `a_nam_headXX_04.png` | `a_nfi_ad_jacket_skin04.png` | `a_nam_pants_skin04.png` | `a_nam_ch_fskinXX_04.png` |
| **5** | 异星青蓝 (Alien Cyan) | `a_nam_headXX_05.png` | `a_nfi_ad_jacket_skin05.png` | `a_nam_pants_skin05.png` | `a_nam_ch_fskinXX_05.png` |

---

## 3. 完备性防护

- **人类与魔人族群**：染色着色器与常规发色、皮肤配色逻辑完全保持原有规范，未受任何改动影响。
- **超级赛亚人形态**：人类 4 个素体的 `mat_hair_ssj` 表面与变身着色逻辑保持原有规范。
- **素体内衣底裤**：无外装时底裤完全显示与有外装时自动剔除逻辑保持原有规范。
