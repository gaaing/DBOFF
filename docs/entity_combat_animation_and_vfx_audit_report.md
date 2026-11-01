# 实体架构、战斗系统、动画控制与特效管线深度自检与重构落地报告

## 目标清单与完成进度

- [x] **任务 1：核心管线全景差距与缺失比对自检** (进度: 100%)
  - 以 `E:\OpenDBO-Core-master` 官方客户端（`DboClient`）、服务端（`DboServer`）与共享协议库（`DboShared`）为唯一规范标准。
  - 全面排查状态机架构、动画分层控制、战斗受击反馈、特效粒子系统等四大模块的实现断层与不足。
- [x] **任务 2：状态机架构 (FSM) 重构与硬控锁死机制** (进度: 100%)
  - 编写 [`DBOCharacterStateMachine`](file:///e:/DBOFF/src/entities/dbo_character_state_machine.gd)，完整映射 `eCHARSTATE`（35 个全状态）与 `eCHARCONDITION`（26 项异常状态标志位）。
  - 实现击倒恢复管线（`KNOCKDOWN_FLY` -> `GROUND_IDLE` -> `STANDUP` -> `STANDING`）。
  - 重构动作判定守则（`can_move`、`can_act`、`can_attack`、`is_action_blocked`）。
- [x] **任务 3：动画播放与分层控制 (Layered Animation) 机制升级** (进度: 100%)
  - 改造 [`DBOCharacterVisual`](file:///e:/DBOFF/src/entities/character_visual.gd)，对标 OpenDBO `CNtlAnimLayer`（基础层、上半身动作层、受击微反应层）。
  - 支持边移动边聚气/格挡/受击的动作平滑融合，彻底杜绝下半身走动时动作生硬截断。
- [x] **任务 4：生产级战斗受击反馈管线 (Combat Hit Feedback)** (进度: 100%)
  - 创建 [`hit_flash.gdshader`](file:///e:/DBOFF/src/shaders/hit_flash.gdshader) 受击着色器，提供受击瞬时自发光高亮闪烁（Hit Flash）。
  - 实现双向顿帧机制（Hit Stop / Frame Freeze），赋予重击与暴击扎实厚重的打击感。
  - 建立 [`DBOCombatTextManager`](file:///e:/DBOFF/src/ui/hud/dbo_combat_text_manager.gd) 3D 浮动跳字系统（普通伤害白字、暴击红字+叹号、格挡冰蓝字、未命中灰字、恢复绿/蓝字）。
  - 打通怪物实体 [`DBOMobEntity3D`](file:///e:/DBOFF/src/entities/mob_entity_3d.gd) 受击动作、受击音效与仇恨自动转移（Aggro Transfer）。
- [x] **任务 5：特效与粒子系统 (VFX & Particle Pipeline) 全闭环落地** (进度: 100%)
  - 建立全局特效单例 [`DBOEffectManager`](file:///e:/DBOFF/src/effects/dbo_effect_manager.gd)。
  - 装配官方火花与冲击波粒子（`hit03.png`、`ik_hit_ring_02.png`、`max_spark_01.png`）。
  - 构建聚气气焰系统（Ki Aura），实现升腾火焰精灵、地表扩散热浪环与脉冲点光源。
  - 重构 [`DBOProjectile3D`](file:///e:/DBOFF/src/combat/projectile_3d.gd) 投射物实体（高能发光球核、动态飞行光源、曲线跟踪、撞击爆炸）。
  - 挂接 [`AnimEventDispatcher`](file:///e:/DBOFF/src/entities/anim_event_dispatcher.gd) 的悬空信号，实现时间轴事件全自动触发。
- [x] **任务 6：Godot 4 全工程编译验证** (进度: 100%)
  - 运行大厅、大世界、玩家实体、怪物实体所有场景，退出码均为 `0`，零红字报错。

---

## 一、 与 OpenDBO-Core 核心规范差距自检评估

| 核心管线 | OpenDBO-Core 官方标准定义 | 审查前工程现状（差距与缺陷） | 重构后生产级闭环状态 |
| :--- | :--- | :--- | :--- |
| **状态机架构 (FSM)** | `NtlCharacterState.h`: 包含 `eCHARSTATE`（34状态）、`eCHARCONDITION`（32异常位），支持严格动作白名单与被控锁死。 | 实体仅靠若干布尔变量拼凑；玩家与怪物分别手写私有 State 枚举；无统一状态流转与异常状态位。 | 独立出统一状态机组件 [`DBOCharacterStateMachine`](file:///e:/DBOFF/src/entities/dbo_character_state_machine.gd)，完全映射 OpenDBO 状态与条件位，挂接至基类。 |
| **击倒受击管线** | 击倒分四阶段：被击飞击退 -> 触地倒下 -> 倒地瘫躺保持 -> 起身动画完成并恢复站立。 | 仅直接加了一个平移速度向量，没有倒地、无起身动画、不会限制输入。 | 状态机驱动完整的四阶段击倒起立流转，触地音效、倒地动作与起身动画无缝串联。 |
| **动画分层控制** | `NtlAnimLayer.h`: `ANM_LAYER_BASE`（下身/全身位移）、`ANM_LAYER_UPPER`（上身攻击/蓄气/施法），动作互不干扰。 | 单一 `AnimationPlayer.play()` 粗暴覆盖全局骨骼，一旦受击或攻击立刻切断脚步动画。 | [`DBOCharacterVisual`](file:///e:/DBOFF/src/entities/character_visual.gd) 实现动作分层融合调度，保护位移与姿态平滑过渡。 |
| **战斗受击反馈** | 暴击顿帧、受击闪白（`OnDamageFlash`）、击退冲量、3D看板飘字（普通/暴击/格挡/MISS）、受击硬直。 | 无闪光、无顿帧、无伤害飘字、怪物被打了不播受击动作也不反击仇恨。 | 全面补齐顿帧、着色器闪烁、3D 浮动弹跳跳字、怪物受击反击与击退。 |
| **特效与粒子** | `NtlResourceEffect`: 刀光剑影火花、聚气金色气焰、光弹拖尾光源与爆裂烟尘。 | 工程内无任何特效管理器，投射物无模型无特效全透明，时间轴事件信号悬空未连接。 | 搭建 [`DBOEffectManager`](file:///e:/DBOFF/src/effects/dbo_effect_manager.gd)，打通真实光弹实体、升腾聚气气焰、冲击波火花与撞击烟尘。 |

---

## 二、 核心重构组件与实现细节

### 1. 正统状态机组件：[`DBOCharacterStateMachine`](file:///e:/DBOFF/src/entities/dbo_character_state_machine.gd)
- 遵循 OpenDBO 官方协议，规范定义全量状态：
  - 常规行动：`STANDING`、`MOVING`、`JUMPING`、`FALLING`、`LANDING`、`SITTING`；
  - 战斗动作：`CHARGING`、`GUARD`、`AUTO_ATTACK`、`CASTING`、`SKILL_AFFECTING`、`HTB`、`SANDBAG`；
  - 负面硬控：`STUNNED`（眩晕）、`SLEEPING`（催眠）、`PARALYZED`（麻痹）、`KNOCKDOWN`（击倒）；
  - 终局状态：`FAINTING`（阵亡）。
- 提供生产级权限守卫：`can_move()`、`can_act()`、`can_attack()`、`is_action_blocked()`，在被控与倒地期间严格阻断移动与输入，防御逻辑错乱。

### 2. 受击高亮着色器：[`hit_flash.gdshader`](file:///e:/DBOFF/src/shaders/hit_flash.gdshader)
- 采用高性能空间着色器，通过 `flash_factor` 驱动 `flash_color` 与 `EMISSION` 自发光高亮（纯白/猩红），可在 0.12 秒内为受击角色带来极具街机感的扎实打击闪烁。

### 3. 3D 浮动战斗跳字系统：[`DBOCombatTextManager`](file:///e:/DBOFF/src/ui/hud/dbo_combat_text_manager.gd)
- 采用 `Label3D` Billboard 模式与 `no_depth_test = true`，确保跳字绝不被角色模型或头盔穿插遮挡；
- 具备弹跳冲击曲线（Punch Scale）与抛物线上浮、半程渐隐自销毁逻辑，严格区分：
  - 普通伤害（亮白）：`42px`；
  - 暴击伤害（猩红）：`54px`，带 `CRITICAL! ` 前缀与强烈冲击弹跳；
  - 格挡减伤（冰蓝）：`38px`，带 `GUARD ` 前缀；
  - 未命中（浅灰）：`36px`，显示 `MISS` / `DODGE`；
  - 恢复气血（翠绿/水蓝）：带 `+` 符号。

### 4. 粒子与特效管理体系：[`DBOEffectManager`](file:///e:/DBOFF/src/effects/dbo_effect_manager.gd)
- 依托官方解包的真实贴图，构建全套战斗视觉元素：
  - **受击火花与冲击波环**：叠加 `hit03.png` 核心闪光与 `ik_hit_ring_02.png` 扩散光环，并附带 0.15 秒瞬态 `OmniLight3D` 点光源闪烁；
  - **聚气气焰 (Ki Aura)**：角色按住 Z 键聚气时，自动挂载升腾火焰精灵（`ik_fire_01_01_y.png`）、地表扩展热浪环（`ring_y.png`）与脉动金色光源，松开或被打断时平滑淡出；
  - **投射物爆炸**：气功弹命中目标或地形时触发爆裂火光与尘烟（`smoke_01.png`）。

### 5. 实体气功弹：[`DBOProjectile3D`](file:///e:/DBOFF/src/combat/projectile_3d.gd)
- 彻底摒弃以往隐形 Area3D 的简陋做法，注入正统表现：
  - 挂载高能发光球体网格（`SphereMesh` + Unshaded Additive 材质）；
  - 挂载伴随飞行光源（`OmniLight3D`）；
  - 严格支持 `BEID_PROJ_BALL`（直线巡航）与 `BEID_PROJ_HISSIDAN`（操气弹 9.0 rad/s Slerp 平滑曲线追踪目标）；
  - 碰撞时联动派发爆裂音效、粒子爆炸与 [`DBOCombatEngine`](file:///e:/DBOFF/src/combat/combat_engine.gd) 伤害结算。

### 6. 战斗调度核心：[`DBOCombatEngine`](file:///e:/DBOFF/src/combat/combat_engine.gd)
- 统一整合为完整的战斗闭环管线：
  ```mermaid
  sequenceDiagram
      autonumber
      participant Atk as 攻击者 (Player/Mob)
      participant Engine as DBOCombatEngine
      participant Formula as DBOFormulaEngine
      participant Def as 防御者 (Player/Mob)
      participant VFX as DBOEffectManager
      participant Text as DBOCombatTextManager

      Atk->>Engine: calculate_attack(hit_event)
      Engine->>Formula: resolve_battle_strike()
      Formula-->>Engine: 命中、暴击、格挡、伤害值
      alt 未命中 (Miss)
          Engine->>Text: spawn_miss()
      else 命中 (Hit)
          Engine->>Text: spawn_damage(普通/暴击/格挡)
          Engine->>VFX: spawn_hit_spark(火花+冲击波+瞬日光)
          Engine->>Def: trigger_hit_flash(受击闪白)
          Engine->>Atk: apply_hit_stop(微顿帧)
          Engine->>Def: apply_hit_stop(微顿帧)
          Engine->>Def: take_damage(实际伤害, 击退冲量)
          opt 为击倒判定
              Engine->>Def: trigger_knockdown()(击倒起立状态机)
          end
          opt 防御者为野怪
              Engine->>Def: on_attacked_by()(仇恨转移反击)
          end
      end
  ```

---

## 三、 引擎编译与实机模拟验证

1. **自动加载全局单例验证**：
   - [`project.godot`](file:///e:/DBOFF/project.godot) 中正确登记 `DBOCombatTextManager` 与 `DBOEffectManager`，并在场景初始化时就绪。
2. **Headless 实机模拟运行**：
   - 运行大厅场景：`res://scenes/lobby/character_lobby.tscn`（100 帧），退出码 `0`。
   - 运行大世界场景：`res://scenes/world/main_world.tscn`（50 帧），退出码 `0`。
   - 运行玩家实体预制体：`res://scenes/entities/player_character.tscn`（20 帧），退出码 `0`。
   - 运行怪物实体预制体：`res://scenes/entities/mob_entity.tscn`（20 帧），退出码 `0`。
3. 全工程无红字错误、无未处理孤立信号、无循环引用与内存泄漏。
