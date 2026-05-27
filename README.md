<div align="center">

<h1>🏛️ etdxm · 三省六部 · Agent Teams</h1>

<p><em>取法唐制三省六部，以古法治今器</em></p>

<p>一套纯 <code>.md</code> 文件构成的多 Agent 协作治理框架<br>专为 Claude Code Agent Teams 设计</p>

<p>
<code>👑 太子分拣</code> → <code>📜 中书规划</code> → <code>🔍 门下封驳</code> → <code>📮 尚书派发</code> → <code>⚔️ 六部并行</code> → <code>📋 覆奏回报</code>
</p>

<p><strong>零代码 · 近零依赖 · 零基础设施<br>Claude Code 即是运行时</strong></p>

<p>
<a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-22C55E?style=flat-square" alt="License: MIT"></a>
<img src="https://img.shields.io/badge/Claude_Code-原生运行-E86C1D?style=flat-square" alt="Claude Code">
<img src="https://img.shields.io/badge/Agents-10_专职-8B5CF6?style=flat-square" alt="Agents">
<img src="https://img.shields.io/badge/依赖-近零_(jq)-blue?style=flat-square" alt="Near Zero Deps">
</p>

</div>

---

## 🏮 项目动机——缘起

> *天下事，分则理，合则乱。*

### ⚡ 现有方案的痛点

Claude Code 的 Agent Teams 机制让多个 Agent 协作成为可能，但开箱即用的协作方式是扁平的——所有 Teammate 地位平等，由 Lead 直接调度。当任务复杂度上升，这种"一人治天下"的模式会遇到几个问题：

- **缺乏审议环节**：方案直接执行，没有 review 和制衡——如同天子独断，无言官谏诤
- **协调成本高**：Lead 既要规划又要派发还要汇总——既当中书令又当尚书令，分身乏术
- **质量难保证**：没有独立的审查角色——做完就交，无人覆奏，产出全靠运气

### 🏯 为什么选择三省六部制

唐朝的三省六部制恰好解决了类似问题：

- **封驳机制 = 内建质量门**：门下省拥有否决权，方案必须通过审议才能下发——不合格的设计在执行前就被拦截
- **层级分离 = 关注点隔离**：中书省决策、门下省审议、尚书省执行，各司其职互不干涉
- **历史验证的治理智慧**：这套制度在唐朝运转了近三百年，其治理逻辑经得起检验

### 💡 核心理念

- **纯 Markdown 定义**：全部角色、流程、规则由 `.md` 文件承载，不引入任何编程语言
- **零代码侵入**：不修改你的项目代码，不添加运行时依赖
- **Claude Code 原生运行**：完全基于 Agent Teams、Skill、Hook 等 Claude Code 原生机制，无需额外基础设施

---

## ✨ 功能特性

> *文武百官各司其职，方能四海升平。*

- **完整的多 Agent 治理流水线**：10 个 Agent、三层架构（内廷 → 三省 → 六部），从规划到执行到审查全链路覆盖
- **内建质量保障**：封驳（门下省审议否决）+ 覆奏（执行后双重复核），方案和产出都有独立审查
- **并行执行**：跨部门无冲突任务同时执行；部门内启用堂官-员外郎模式，最多 3 个员外郎在独立 worktree 中并行
- **26 个 Skill（25 个按需加载 + 常驻 governance-core）**：如锦衣卫之密旨，用时宣召、事毕封存——上下文零浪费
- **10 个自动化 Hooks 治理层**：文件保护、危险命令拦截、操作审计、消息网关、预算熔断、工单校验——御史台常驻监察，开箱即用
- **运行时强制层（schema 校验 + 预算熔断）**：通信拓扑、工单/回奏/草案三类 schema 在运行时强制校验，单会话 token 累计超限自动熔断——劝谕入律令
- **容错与熔断机制**：超时重试、失败换人、连续失败自动熔断——超时就斩，崩了就换
- **早朝制度**：`/morning-court` 一键收集系统状态与未完成任务，呈上朝报
- **零代码零基础设施，复制即用**：把文件放进项目目录，启动 Claude Code，开朝理政

---

## 🚀 如何嵌入你的工程

> *三步开朝，即刻理政。*

**第一步** — 将以下文件复制到你的项目根目录：

```
你的项目/
├── CLAUDE.md          ← 系统声明，Claude Code 启动时自动加载
├── eval/              ← 评测任务与基线（成本/质量验证）
└── .claude/
    ├── settings.json  ← Hooks 注册 + 环境变量（含 ENFORCE 开关、token 预算）
    ├── HARNESS.md     ← 强制层权威说明
    ├── hooks/         ← 10 个治理 Hook 脚本（含 lib/validate-payload.sh）
    ├── schemas/       ← 工单/回奏/草案三类 JSON Schema（canonical 规约）
    ├── scripts/       ← 运维脚本（metrics-report.sh 等）
    └── skills/        ← 26 个 Skill 模块（25 个按需加载 + 常驻 governance-core）
```

**第二步** — 按需修改 `CLAUDE.md` 中的配置

**第三步** — 正常启动 Claude Code：

```bash
cd your-project
claude
```

Claude Code 自动加载 `CLAUDE.md` → 加载 governance-core Skill → 太子就位。之后你的每一条消息都会经过三省六部的完整流程。

---

## ⚙️ 环境要求

> *开朝前，先备齐仪仗。*

本项目基于 Claude Code Agent Teams 架构，需启用实验性功能：

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

或写入 `.claude/settings.json`：

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
    "GOVERNANCE_ENFORCE": "1",
    "GOVERNANCE_TOKEN_BUDGET": "400000"
  }
}
```

- `GOVERNANCE_ENFORCE`：`1` 硬拦截模式（违规 exit 2），`0` 仅观察告警。影响 H04 交付校验、H08 消息网关、H09 预算熔断、H10 工单适配。
- `GOVERNANCE_TOKEN_BUDGET`：单会话 token 预算上限（估算口径），供 H09 预算熔断判定。

### 📦 系统依赖

全部 Hook 脚本（H01–H10）与 `lib/validate-payload.sh` 均使用 `jq` 解析 JSON 输入，请确保已安装：

```bash
# macOS
brew install jq

# Ubuntu / Debian
sudo apt-get install jq

# Arch Linux
sudo pacman -S jq
```

> **jq 为硬依赖，必须安装**。审计类 Hook（如 H03）在缺 jq 时会静默降级（日志记为 "unknown"）不阻断；但 schema 校验类 Hook（H08 消息网关、H10 工单适配）依赖 jq 完成结构校验，缺 jq 将无法正常强制治理。请务必安装。

---

## 🔐 强制层全景——劝谕入律令

> *早期的「劝谕」靠 Skill 文档自觉遵循；第二代将三纲（通信·预算·验收）硬化为运行时律令。*

在第一代「Hook + Skill」治理之上，本项目落地了一层**运行时强制层**，把原先靠文档约束的协作纪律变为可执行、可熔断的硬规则：

| 组件 | 位置 | 职责 |
|------|------|------|
| 三类 Schema | `.claude/schemas/{ticket,report,plan}.schema.json` | 工单/回奏/草案的 canonical 字段规约 |
| 载荷校验器 | `.claude/hooks/lib/validate-payload.sh` | 三 schema 的 jq 运行时强制实现（零外部依赖），供 H08/H10 调用 |
| 消息网关 H08 | `.claude/hooks/H08-message-gateway.sh` | SendMessage 前校验通信拓扑 + 三类 schema |
| 预算熔断 H09 | `.claude/hooks/H09-budget-guard.sh` | 建队/发消息前，token 累计 ≥80% 预警、≥100% exit 2 熔断 |
| 工单适配 H10 | `.claude/hooks/H10-ticket-adapter.sh` | TaskCreate 时校验工单 schema |
| ENFORCE 开关 | `GOVERNANCE_ENFORCE` | `1` 硬拦截 / `0` 仅观察告警 |
| 预算上限 | `GOVERNANCE_TOKEN_BUDGET` | 单会话 token 预算，供 H09 判定 |
| 评测基线 | `eval/`（任务、基线、`run-eval.sh`） | 成本与质量验证 |
| 观测产物 | `.claude/metrics.jsonl`、`.claude/scripts/metrics-report.sh` | 运行指标采集与汇总 |

> 强制层的设计原理、开关语义、观测口径与诚实标注以 **`.claude/HARNESS.md`** 为唯一权威源，此处不重述细节。

---

## ⚠️ 注意事项

### 💰 Token 消耗——养朝廷自然比养谋士费粮

> **重要提示**：三省六部完整流转意味着多个 Agent 同时活跃，每个旨意经过规划 → 审议 → 派发 → 执行 → 审查 → 覆奏全链路，**Token 消耗显著高于单 Agent 使用**。请在使用前充分了解这一成本特征。

三省六部的完整治理流转涉及多个 Agent 之间的多轮通信（太子 → 中书 → 门下 → 尚书 → 六部 → 刑部审查 → 门下覆奏），这是治理质量的代价。

供参考的量级感受：

| 任务类型 | 预估 Token 消耗 | 说明 |
|---------|---------------|------|
| 太子直办 / fast_track | 数千 ~ 1 万 | 简单任务，跳过三省全流程 |
| 标准旨意（单部门） | 5 万 ~ 15 万 | 完整三省流转 + 单部门执行 |
| 复杂旨意（多部门并行） | 15 万 ~ 40 万+ | 完整流转 + 多部门 + 覆奏 |

> **治理之道，在于量入为出**。杀鸡毋用牛刀——改一行配置无需惊动满朝文武，太子直办即可；而重构核心架构这等大事，走完三省六部的完整流程才稳妥。善用 `fast_track` 与太子直办，方能在质量与成本间取得平衡。

### ✅ 适用场景——何时开朝理政

- **中大型开发任务**：需要需求分析、方案设计、多模块并行开发、代码审查的完整工程流程
- **多角色协作**：任务天然涉及规划、开发、测试、文档等不同职责，需要分工与协调
- **质量敏感项目**：需要方案审议（封驳）、执行后复核（覆奏）等质量把关环节
- **重构与架构调整**：涉及多文件、多模块的系统性变更，需要全局规划与风险评估

### 🚫 不适用场景——无需兴师动众

- **单文件快速修改**：改一行配置、修一个 typo——太子直办即可，无需惊动三省
- **简单问答与闲聊**：太子会自动识别并直答，无需引入治理流程
- **Token 预算有限的场景**：完整流转的 Token 消耗显著，预算紧张时建议直接使用单 Agent
- **对延迟极度敏感的场景**：完整流转会增加多轮 Agent 交互，不适合要求秒级响应的场景
- **非 Claude Code 环境**：本框架深度依赖 Claude Code 的 Agent Teams、Skill、Hook 等原生机制，无法移植到其他平台

> **提示**：简单任务太子会自动判定走直办或 fast_track，不会每次都走全流程。无需担心"杀鸡用牛刀"——太子会替你判断。

### 🔒 已知限制

> **Claude Code 的 Agent Teams（多 Agent 协作）目前为实验性功能**

- 需要 Claude Code **>= 2.1.40**
- 作为实验性功能，行为和 API 可能在后续版本中变化
- Agent Teams 不支持 per-teammate 模型指定（所有 Agent 使用同一模型）
- 本项目的并行执行（堂官-员外郎模式）依赖 Agent Teams 的 Teammate 机制和 `worktree` 隔离
- 适合有一定 Claude Code 使用经验的用户，初次接触建议先熟悉基础功能

---

## 🏗️ 架构

> *内廷分拣、三省流转、六部执行——层级分明，各安其位。*

10 个 Agent，三个层级：

```
                        ┌────────────────────┐
                        │     👑 你（皇上）    │
                        └─────────┬──────────┘
                                  │
                        ┌─────────▼──────────┐
                        │   👑 太子 · Gateway  │
                        │  闲聊直答 / 旨意传中书 │
                        └─────────┬──────────┘
                                  │
              ┌───────────────────▼───────────────────┐
              │                三 省                   │
              │                                       │
              │  📜 中书省          制定方案、拆解任务   │
              │       ↓                               │
              │  🔍 门下省          审议方案、封驳退回   │
              │       ↓              ↑ 封驳循环         │
              │  📮 尚书省          派发、协调、汇总     │
              └───────┬───────┬───────┬───────┬───────┘
                      │       │       │       │
              ┌───────▼───────▼───────▼───────▼───────┐
              │                六 部                   │
              │                                       │
              │  📋 吏部  人事     💰 户部  数据        │
              │  📝 礼部  文档     ⚔️ 兵部  运维        │
              │  ⚖️ 刑部  合规     🔧 工部  开发        │
              └───────────────────────────────────────┘
```

**完整流转：**

```
下旨 → 太子分拣 → 中书草诏 → 门下审议 → 尚书派发 → 六部执行
                        ↑         │
                        └─ 封驳 ──┘
                                         ↓
            回奏 ← 门下覆奏 ← 尚书汇总 ← 刑部审查
```

- **封驳** — 门下省可驳回中书方案，三次封驳自动上报你裁决
- **覆奏** — 执行完毕后门下省复核，确保产出符合原始需求
- **并行** — 无冲突任务跨部门同时执行；部门内启用堂官-员外郎模式，各自在独立 worktree 中工作

---

## 👥 角色一览

> *十位臣工，各有所长。*

| 层级 | 部门 | 角色 | Team 角色 | 职责 |
|------|------|------|-----------|------|
| 内廷 | 👑 太子 | Gateway | **Lead** | 分拣消息：闲聊直答，旨意传中书，不确定反问 |
| 三省 | 📜 中书省 | Planner | Teammate | 接旨 → 分析需求 → 拆解子任务 → 出草案 |
| 三省 | 🔍 门下省 | Reviewer | Teammate | 审议草案 → 准奏放行 / 封驳退回 |
| 三省 | 📮 尚书省 | Coordinator | Teammate | 解析依赖 → 派发六部 → 协调进度 → 汇总回奏 |
| 六部 | 📋 吏部 | HR | Teammate | Agent 管理、权限分配、考核 |
| 六部 | 💰 户部 | Data | Teammate | 数据处理、资源核算、报表 |
| 六部 | 📝 礼部 | Docs | Teammate | 文档编写、规范制定 |
| 六部 | ⚔️ 兵部 | Ops | Teammate | 部署、运维、CI/CD、安全加固 |
| 六部 | ⚖️ 刑部 | QA | Teammate | 测试、代码审查、安全扫描、红线执行 |
| 六部 | 🔧 工部 | Dev | Teammate | 功能开发、架构设计、技术攻坚 |

---

## 🔗 核心机制

> *制度之妙，在于环环相扣、层层把关。*

**🚫 封驳 — 门下省的绝对否决权**
中书省出的方案不合格？门下省直接打回重做。连续三次封驳同一方案，自动上报你裁决。每个方案都必须过门下省，没有例外。

**🔍 覆奏 — 做完了还要查**
六部干完活，先经刑部技术审查（红线 R01-R10），再经门下省覆奏核查产出是否符合原始需求。一个管"做法对不对"，一个管"做的是不是你要的"。

**⚡ 堂官-员外郎并行 — 一个部门同时干多件事**
同一部门收到多个不冲突任务时，自动切换堂官模式：最多 3 个员外郎各自在独立 worktree 中并行工作，堂官合并产出。

**🛡️ 容错 — 超时就斩，崩了就换**
故障分三级：F1 自动重试，F2 打回重做或换人，F3 上报决策。5 分钟内连续失败 3 次触发熔断。

---

## 🎯 快速上手

> *上朝议事、宣读圣旨、退朝归宫——皆有礼制可循。*

etdxm 提供了一系列 `/` 指令（Slash Commands），让你以朝廷礼制与系统交互：

| 指令 | 功能 | 说明 |
|------|------|------|
| `/morning-court` | 开早朝 | 太子收集系统状态与未完成任务，呈上朝报 |
| `/shengzhi` | 下圣旨 | 结构化下达正式旨意，确保关键信息完整 |
| `/tuichao` | 退朝 | 有序关闭所有 Teammate，汇总本次朝会工作 |
| `/keju` | 科举 | 检查 Skill 配置、Hook 语法、governance-core 一致性 |
| `/biannian` | 编年 | 扫描 git 历史，生成三省六部风格的 CHANGELOG |

你也可以直接用自然语言下旨，太子会自动判断意图：

```
帮我重构这个模块的错误处理    # 太子判定为旨意 → 三省流转 → 六部执行
这个函数是干嘛的？            # 太子判定为闲聊 → 直接回答
/shengzhi P0 修复登录鉴权漏洞  # 快捷下旨 → 加急流程
```

---

## 📜 Skill 模块

> *诸道密旨，按需宣读，用毕封存——不占朝堂一席之地。*

共 26 个 Skill，其中 25 个按需加载、用完释放、不占上下文（常驻的 governance-core 由会话初始化加载，不在此表）：

| 类别 | Skill | 触发时机 |
|------|-------|---------|
| 皇上指令 | `morning-court` | `/morning-court` 开早朝 |
| | `shengzhi` | `/shengzhi` 下圣旨，结构化引导旨意 |
| | `tuichao` | `/tuichao` 退朝，有序关闭 Teammate |
| | `keju` | `/keju` 科举，系统配置健康检查 |
| | `biannian` | `/biannian` 编年，生成 CHANGELOG |
| | `qijuzhu` | 起居注：早朝/退朝时记录朝会动态 |
| 太子专用 | `intent-classification` | 太子分拣消息意图 |
| | `team-bootstrap` | 首次创建 Teammate 引导 |
| | `zouzhe` | 太子向皇上呈报重要事项 |
| | `hanlin` | 联网查证 Claude Code 官方文档与 Issues |
| 三省流程 | `analysis-framework` | 中书规划 / 门下审议 |
| | `veto-mechanism` | 门下封驳 |
| | `review-coverage` | 门下覆奏 |
| | `dispatch-rules` | 尚书派发任务 |
| | `audit-boundaries` | 刑部审查 / 门下覆奏分界 |
| | `special-directives` | 加急旨意 / 皇上直令 |
| 格式规范 | `ticket-format` | 尚书派发工单格式 |
| | `report-format` | 尚书回奏格式 |
| | `communication-protocols` | 跨部门协作 / 异常上报 |
| 规则红线 | `redline-reference` | 刑部红线 R01-R10 |
| | `permission-matrix` | 权限变更审批 |
| 系统运维 | `fault-tolerance` | 超时 / 失败 / 熔断 |
| | `token-optimization` | Token 优化与上下文管理 |
| | `architecture-overview` | 全局架构与六部角色参考 |
| | `parallel-execution` | 堂官-员外郎并行模式 |

---

## 🛡️ Hooks 治理层

> *御史台常驻监察，十道关卡，无声守护。*

10 个 Hook 脚本（`.claude/hooks/`）提供自动化治理：

| Hook | 事件 / matcher | 功能 |
|------|---------------|------|
| H01 治理文件保护 | PreToolUse `Edit\|Write` | 命中受保护清单（governance-core/SKILL.md、settings.json）→ exit 2 封驳——动了龙椅，御史弹劾 |
| H02 危险命令拦截 | PreToolUse `Bash` | 拦截 `rm -rf /`、`DROP`、裸 DELETE/UPDATE 无 WHERE 等高危命令——刀下留人 |
| H03 操作审计日志 | PostToolUse | 记录所有工具调用至 audit.log + metrics.jsonl，并按字节估算累计 token 入 budget.json（不阻断）——起居注，笔笔有据 |
| H04 任务完成验证 | TaskCompleted | 校验主题非空、deliverables 非空、无 merge conflict，否则 exit 2 |
| H05 空闲质量门 | TeammateIdle | 空闲前未暂存文件 >10 → exit 2 提醒确认 |
| H06 配置变更哨兵 | ConfigChange | project_settings 变更 → exit 2 拦截；skills 仅审计放行 |
| H07 会话生命周期 | SessionStart | 初始化 session.id 与 budget.json；仅真新会话清零累计预算（resume/compact 保留） |
| H08 消息网关 | PreToolUse `SendMessage` | 发消息前校验通信拓扑 + ticket/report/plan 三类 schema（经 lib/validate-payload.sh） |
| H09 预算熔断 | PreToolUse `Agent\|SendMessage` | 建队/发消息前，token 累计 ≥80% 预警 / ≥100% → exit 2 熔断 |
| H10 工单适配 | PreToolUse `TaskCreate` | 建任务时校验 ticket schema；无工单元数据则记 dead_letter 放行 |

> H04（deliverables）、H08、H09、H10 受 `GOVERNANCE_ENFORCE` 开关控制：`1` 硬拦截，`0` 仅观察告警。

运行时产物（均已加入 `.gitignore`，不提交）：审计日志 `.claude/audit.log`、运行指标 `.claude/metrics.jsonl`、预算累计 `.claude/budget.json`(`.lock`)、会话标识 `.claude/session.id`。

---

## 🤝 Contributing

> *广开才路，集思广益。*

欢迎贡献：新 Skill 模块 · Agent 角色优化 · 文档改进 · Issue 反馈。详见 [贡献指南](CONTRIBUTING.md)

---

## 🙏 致谢

本项目的三省六部创意源自 [**Edict**](https://github.com/cft0808/edict)——基于 OpenClaw 平台构建的全栈多 Agent 治理系统。本项目受其启发，将相同的治理理念针对 Claude Code 原生机制进行了深度适配。

> 感谢 Edict 项目及其作者的开创性工作——理念同源，路径各异。

---

## 📄 License

[MIT](LICENSE)
