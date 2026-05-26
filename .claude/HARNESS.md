# etdxm Harness 强制层

> 本文档记录把「markdown 软规则」下沉为「代码硬约束」的 harness 工程改造。
> 核心理念：模型是随机的，harness 应在「需要保证」处确定。凡需保证之事，写进 hook，而非 prompt。

## 改造全景

| # | harness 原则 | 落地物 | 状态 |
|---|------------|--------|------|
| 1 | 把 spec 编译成 validator | `schemas/*.schema.json` + `hooks/lib/validate-payload.sh` | ✅ 已落地 |
| 2 | 收缩 action space（通信拓扑硬约束） | `hooks/H08-message-gateway.sh` | ✅ 已落地（拓扑渐进强制，见下） |
| 3 | 闭环验收 | `report.schema.json`(criteria_verification) + H08 + H04 deliverables 检查 | ✅ 已落地 |
| 4 | 可观测性 | `H03` 累计 + `metrics.jsonl` + `scripts/metrics-report.sh` | ✅ 已落地 |
| 5 | 成本即一等控制 | `H07` 初始化预算 + `H03` 累计 + `H09-budget-guard.sh` 熔断 | ✅ 已落地 |
| 6 | 确定性上下文装配 | — | ⛔ 受限：Agent Teams 不支持按 mode 注入系统提示，hook 无法强制 |
| 7 | eval 驱动 | `eval/`（tasks + run-eval + baseline） | ✅ 已落地（半自动驱动） |
| 8 | 异质模型破除同模型回音 | `model-routing.json` | ⛔ 阻塞上游：Agent Teams 暂不支持 per-teammate 模型；配置已备，待开放即生效 |

## 开关（settings.json → env）

| 变量 | 默认 | 含义 |
|------|------|------|
| `GOVERNANCE_ENFORCE` | `1` | `1`=硬拦截(exit 2)；`0`=仅观察告警(exit 0) |
| `GOVERNANCE_TOKEN_BUDGET` | `400000` | 单会话 Token 预算上限（估算口径） |

## Hook 清单（新增/增强）

| Hook | 事件 | 作用 |
|------|------|------|
| **H08** message-gateway | PreToolUse `SendMessage` | 通信拓扑校验 + ticket/report/plan schema 校验 |
| **H09** budget-guard | PreToolUse `Agent\|SendMessage` | Token 预算 80% 预警 / 100% 熔断 |
| **H10** ticket-adapter | PreToolUse `TaskCreate` | 派工工单 canonical 适配 + ticket.schema 强制（已注册，见下） |
| H03 audit-logger（增强） | PostToolUse | 既有审计 + 结构化 metrics + token 累计 |
| H04 task-gate（增强） | TaskCompleted | 既有检查 + task_done 指标 + deliverables 闭环检查 |
| H07 session-lifecycle（增强） | SessionStart | 既有记录 + 初始化 session.id 与 budget.json |

## 渐进式强制（observe → enforce）

H08 的**拓扑校验**在「发送方身份不可判定」时 **fail-open**（记录 `topology_unverified` 后放行）。原因：Agent Teams 为实验功能，`SendMessage` 的 hook 输入是否携带发送方身份尚待确认。

**收紧路径**：
1. 让系统跑一段，观察 `audit.log` / `metrics.jsonl` 中 `GATEWAY` 行的实际字段；
2. 确认发送方字段名后，在 H08 的 `SENDER=` 提取处补上正确字段；
3. 此后越权通信即被全量硬拦截（R10 红线从软变硬）。

> schema 校验不受此限——只要检测到结构化载荷即按 `GOVERNANCE_ENFORCE` 处置。

## H10 ticket-adapter（M3：派工工单 schema 由虚设转强制）

### 背景缺口（M3 诊断）
`ticket.schema` 要求 canonical `{task:{...}}`，但平台 `TaskCreate` 工单实为扁平
`tool_input {subject, description, activeForm?, metadata?}`，无 `.task` 包裹层；
故 H08 的 `jq -e '.task'` 闸门对派工**从不触发** → ticket schema 校验长期形同虚设。
（取证见 M-00：`TaskCreate` 在 hook 管道内，H03 PostToolUse 对其触发为证。）

### 修复
新增 **H10-ticket-adapter**（PreToolUse `TaskCreate`）：把派工载荷映射为 canonical
`{task:{...}}` 后交 `lib/validate-payload.sh ticket` 校验，使「工单合规」由劝谕入律令。
配套收紧 `validate-payload.sh` ticket 校验：`title` 不可为空字符串（`length > 0`，治本·同惠 H08/H10；
jq 的 `and .task.title` 对 `""` 判真会漏过）。
**已正式纳入** — 太子 2026-05-26 裁准；xingbu M-A3R 复测确认**零误拒**（无 `.task` 的真实扁平流量不进
`validate-payload`、`report`/`plan` 不受连带、仅拒本应拒的空 title 工单）。

### 派工约定 + dead-letter 监测（皇上 2026-05-26 裁：监测非强制）
canonical 工单字段**可选**置于 `TaskCreate.tool_input.metadata.task`：
`metadata.task = {id, title?, assigned_to, status, acceptance_criteria, ...}`。
- **携 metadata.task** → H10 映射 canonical（以 `subject` 补 `title`，null/缺失/空串皆补、补后仍空封驳）
  → 校 `ticket.schema`，失败 `exit 2`。
- **无 metadata.task**（含未遵约定的真实扁平派工、普通会话待办）→ 记 **dead-letter 观察日志**
  （`event=dead_letter`，公示 audit.log / metrics.jsonl）后**放行不阻断**。
皇上裁定：**不采强制约定、不改派工、不动 SKILL**；H10 对真实流量为**监测**（诚实暴露未遵约定者、
量化采纳率），非强制。

**superset 取舍（太子 2026-05-26 裁甲·接受·纯标注不改逻辑）**：因无可靠启发式区分「似派工」与
「普通会话待办」，H10 对**所有**无 `metadata.task` 的 `TaskCreate` 一律记 `dead_letter`——honest
superset，为皇上「似派工」措辞在无启发式现实下的忠实退路、非违旨。边界与代价：
- 约定未推行期间，每次建任务各记一条 `dead_letter`；
- 故**采纳率量化须俟 `metadata.task` 约定推行后方有信息量**（此前 `dead_letter` 占比≈全量、无判别力）；
- `audit.log` / `metrics.jsonl` 噪音可后续加启发式（按 subject 模式 / 来源辨别派工）优化降噪。

### 注册状态：已注册（皇上 settings.json 执行）
H10 已注册进生产 `settings.json` 的 PreToolUse(`TaskCreate`)，command 路径
`"$CLAUDE_PROJECT_DIR"/.claude/hooks/H10-ticket-adapter.sh`，在体生效。
注册写操作撞 **H01**（护 `settings.json`），故由**皇上直接执行**（治理正路、未旁路）；
太子已亲核通过（matcher 命中、JSON 合法）。脚本已通过脚本级九用例测试 + M-A3R 复测回归。

### ⚠️ 诚实标注·残余两条（皇上 2026-05-26 裁定）

**残余一·在体强制未验**：「PreToolUse 对 `TaskCreate` 触发并 honor exit 2 阻断」**未做在体端到端实测**——
唯一隔离验证机制（嵌套 headless `claude --settings` 子进程）被平台安全分类器判为
「创建不安全 agent」而禁止，**连人在环（太子授权）亦被挡**（见 M-A1 阶段1）。
现据三支撑判定该机制【高置信成立】，据以落地 H10：
1. **M-00 四证据链**：可阻断 hook 活跃(ENFORCE=1，H01/H08/H09 实接线)；`TaskCreate`
   已证在 hook 管道内(H03 PostToolUse 对 12 次 `TaskCreate` 触发)；PreToolUse matcher
   已证可匹配编排类工具(SendMessage/Agent)；适配器脚本侧沙箱实证可读载荷 + exit 2。
2. **Claude Code Pre/Post hook 对称性**：PostToolUse 既对 `TaskCreate` 触发，PreToolUse
   同名 matcher 应同样匹配同一 tool_name。
3. **编排工具 matcher 先例**：生产 `settings.json` 已有 SendMessage/Agent 的 PreToolUse 实活。

**残余二·真实流量为监测非强制**：皇上裁定不采 `metadata.task` 强制约定、不改派工。
对未携 `metadata.task` 的真实扁平派工，H10 仅记 dead-letter 观察日志、放行不阻断——即**监测而非强制**。
当前真强制仅及「已按约定填 `metadata.task`」之工单；待派工方采约定后方对真实流量真强制。

**复议条件**（任一满足即应重验/收紧对应残余）：
- [残余一] 平台放开嵌套沙箱 agent，或提供官方 hook dry-run / 录制能力 → 即补在体冒烟实测；
- [残余一] `audit.log` 出现 H10 的 `violation` / `ticket_ok` 行（H10 在体已对真实派工触发）→ 自然清零；
- [残余一] Claude Code 官方文档明确 `TaskCreate` 的 PreToolUse 行为 → 据文档确认后移除标注；
- [残余二] `dead_letter` 观察日志显示派工已普遍采 `metadata.task`（采纳率达标）→ 可评估升为强制。

## Token 估算口径

H03 按 `字节数/4` 估算 token，且 INPUT 已被 `head -c 10000` 截断，故为**下界代理值**：
- ✅ 适合：相对趋势、失控调用量检测、跨会话对比、预算熔断的粗粒度触发；
- ❌ 不适合：精确计费。

若 Agent Teams 后续在 hook 输入中暴露真实 usage，可在 H03 用真实值替换估算。

## 观测与评测

```bash
bash .claude/scripts/metrics-report.sh          # 人读度量报告
bash .claude/scripts/metrics-report.sh --json   # 结构化输出
bash eval/run-eval.sh list                       # 评测任务
bash eval/run-eval.sh start ST-01                # 框定窗口并打印 prompt
bash eval/run-eval.sh finish ST-01               # 收口落盘
bash eval/run-eval.sh report                     # 汇总 + 基线对比
```

## 数据产物（已纳入 .gitignore）

`audit.log`、`metrics.jsonl`、`budget.json`、`session.id`、`*.lock` 为运行时产物，不入库。
