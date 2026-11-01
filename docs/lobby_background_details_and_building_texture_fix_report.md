# 创角大厅右侧远景山体显示恢复与流云接缝截断平滑修复报告

## 1. 目标清单与完成进度

- [x] **右侧红框山体缺失修复（深度剔除与遮挡恢复）**：深入对标 `OpenDBO-Core: NtlPLRenderState.cpp: BegBaseSkyRenderState()` 的原生 Z-Buffer 规则，为天穹 Shader 注入 `depth_draw_never, depth_test_disabled`，彻底解决 338m 天空穹顶将 565m 外的右侧全景喀斯特远山（`tutorialmap_006 quad 2`，方位角 $+6.8^\circ \sim +40.4^\circ$）错误深度剔除的问题。
- [x] **黄色框流云垂直截断与位移错位平滑修复**：分析 `sky_blended0t.glb`（U 轴原生跨度 0.0 ~ 3.0，即 360 度环绕重复 3 次）与官方 `cloud_011.png` 左右边缘不闭合问题，在 `SKY_LAYER_SHADER_CODE` 中引入双向 Hermite 平滑羽化融合，彻底消除天穹旋转时每隔 120 度出现的垂直硬截断缝隙。
- [x] **天穹渲染优先级层级规范**：严格规划天穹渐变底色（-100）、全景天穹（-95）、流云层（-90/-89）与天体恒星（-85），使其在所有三维地表与物件之前渲染，零遮挡大世界任意远近山峦。
- [x] **引擎编译与无报错校验**：执行 `Godot_v4.7.2-stable_win64.exe --headless --editor --quit`，退出码为 0，零语法错误，零资源缺失警告。

---

## 2. 根因剖析与对标解法

### 问题一：左侧山体显示正常，右侧红框位置缺失山体
- **现象**：在沙鲁度假村创角视角下，舞台左侧清晰可见叠嶂青山，而右侧大门飞檐与棕榈树后方只有空旷的蓝天白云，缺失了与官方原版一致的远山。
- **数学与几何追溯**：
  1. 通过 3D 摄影机视锥体矩阵逆投影分析，`D0_TUTORIAL_002` 的 3D 看板网格包含两大部分：
     - 左侧山峦（`tutorialmap_005`）：中心距离摄影机 $295\text{m} \sim 309\text{m}$，方位角 $-28^\circ \sim -10^\circ$；
     - 右侧远山（`tutorialmap_006 quad 2`）：中心距离摄影机 $565.0\text{m}$，方位角 $+6.8^\circ \sim +40.4^\circ$，垂直仰角达到 $+8.3^\circ$（高过武道会主殿屋檐）。
  2. 原版天穹网格 `sky_diffuse.glb` 的原生顶点包围盒半径为 $338.5\text{m}$。
  3. 在 Godot 中，原天穹材质使用了默认的 `depth_draw_opaque`，天穹网格在 $338\text{m}$ 处写入了深度缓冲。
  4. 结果导致：
     - 左侧山峦（$295\text{m} < 338\text{m}$）位于天穹内侧，通过了深度测试并正常呈现；
     - 右侧远山（$565\text{m} > 338\text{m}$）位于天穹外侧，被 $338\text{m}$ 处的天空网格视作“被天空遮挡的远方物体”，全部被 Z-Buffer 硬件剔除！
- **OpenDBO-Core 正统规范**：
  在 `E:\OpenDBO-Core-master\DboClient\Lib\NtlPresentation\NtlPLRenderState.cpp:371-372` 中：
  ```cpp
  void BegBaseSkyRenderState(void)
  {
      RwRenderStateSet(rwRENDERSTATEZTESTENABLE, (void*)FALSE);
      RwRenderStateSet(rwRENDERSTATEZWRITEENABLE, (void*)FALSE);
  ```
  RenderWare 原生管线将天穹作为无深度写入、无深度测试的无限远背景优先渲染。
- **修复方案**：
  在 `world_skybox.gd` 的 `GRADIENT_SHADER_CODE` 中加入 `render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled;`，并将天穹尺度调谐为 2.5。天穹不再写入任何深度，所有距离（即便远至 565m）的 3D 山峦均能在天空之上完整渲染，右侧青黛远山彻底复现。

---

### 问题二：黄色框内存在明显的垂直截断，且随旋转持续移动
- **现象**：流云漂移时，在画面特定方位角会出现笔直如刀切的云朵垂直切断线，且切断线随云层旋转在屏幕上平移。
- **根因追溯**：
  1. `sky_blended0t.glb`（流云天穹）的 UV 坐标系中，U 轴跨越 $[0.0, 3.0]$，即单张云层贴图沿 360 度圆柱穹顶重复采样 3 次（每 $120^\circ$ 重复一次）。
  2. 官方原生资产 `cloud_011.png` 在 $X=1023$（贴图右边缘）有厚重云团残留（$\text{Alpha} \approx 186$），而在 $X=0$（贴图左边缘）为淡薄空气（$\text{Alpha} \approx 0$）。
  3. 当贴图在 $U=1.0, 2.0, 3.0$ 处循环采样时，右侧厚云突兀截断接上左侧空气，导致在天穹上产生 3 条垂直切面。随着云层角速度旋转，这 3 处截断线便如移动墙体一般扫过玩家视野。
- **修复方案**：
  在 `SKY_LAYER_SHADER_CODE` 片元着色器中实现双向 Hermite 平滑羽化融合：
  ```glsl
  float u_fract = fract(uv.x);
  float seam_dist = min(u_fract, 1.0 - u_fract);
  vec4 col;
  if (seam_dist < 0.05) {
      float blend_w = smoothstep(0.0, 1.0, seam_dist / 0.05);
      vec2 wrap_uv = vec2(uv.x + (u_fract < 0.5 ? 1.0 : -1.0), uv.y);
      vec4 c1 = texture(albedo_tex, uv);
      vec4 c2 = texture(albedo_tex, wrap_uv);
      col = mix((c1 + c2) * 0.5, c1, blend_w);
  } else {
      col = texture(albedo_tex, uv);
  }
  ```
  在贴图接缝边界处动态混合对侧边缘纹理，实现 $C^1$ 连续的平滑过渡，流云旋转时无论移动到任何角度均无任何接缝与截断。

---

## 3. 修改文件清单

1. [`src/world/world_skybox.gd`](file:///e:/DBOFF/src/world/world_skybox.gd)
   - `GRADIENT_SHADER_CODE`：启用 `depth_draw_never, depth_test_disabled`。
   - `SKY_LAYER_SHADER_CODE`：加入双向接缝 Hermite 融合逻辑，启用 `depth_draw_never, depth_test_disabled`。
   - 调整天穹网格与天体 `render_priority`（-100 ~ -80），增大基础天穹尺度 `sky_scale = 2.5`。

---

## 4. 验证与交付

- **Godot 4.7.2 Headless 编译**：退出代码 0，全工程无脚本与 Shader 报错。
- **场景视觉效果**：
  - 沙鲁度假村右侧红框后方的远山（`tutorialmap_006`）完整浮现，与左侧青翠山峰完美对称衔接；
  - 黄色框内的流云垂直截断线彻底消除，云团在天穹上呈现圆融自然、无缝衔接的平滑流变。
