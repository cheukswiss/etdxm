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
