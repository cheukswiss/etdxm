# etdxm 评测套件（eval）

**目的**：用真实数据回答「三省六部完整流转，token 成本是否换来对等的质量提升」——这是验证整个框架价值、也是说服严肃用户采用的唯一手段。在此之前，所有 token 数字都只是 README 里的「预估」。

## 构成

| 文件 | 作用 |
|------|------|
| `tasks.json` | 12 个跨复杂度分层（fast_track / standard / complex）的真实任务 |
| `run-eval.sh` | 半自动评测驱动：框定窗口 → 抓度量 → 落盘 |
| `results/` | 每个任务的度量结果（token、事件数、耗时、人工质量分） |
| `baseline/` | 单 Agent（普通 Claude Code）跑同样任务的对照记录 |

## 为什么是「半自动」

Agent Teams 无法被脚本自动驱动——旨意必须在活跃会话中由皇上下达。因此 `run-eval.sh` 不自己跑任务，而是：
1. `start <id>` 打印 prompt 并在 `metrics.jsonl` 标记窗口起点；
2. 人把 prompt 投喂给一个干净的 etdxm 会话，跑完整轮次至回奏；
3. `finish <id>` 计算窗口内的度量增量并落盘；
4. 人工为产出补 `quality_score`(0–5)；
5. `report` 汇总 etdxm 侧各 task 结果，并打印一条指向 `baseline/` 的提示。

> ⚠️ 现状说明：`report` **不会**自动读取、解析或并列 `baseline/` 下的基线文件——它仅打印 etdxm 侧结果与一行 `见 eval/baseline/` 提示。与基线的对比目前为**人工**进行（见下「判读」）。

## 度量维度

- **tokens_est**：窗口内累计 token 估算（下界代理值，见 `.claude/HARNESS.md`）
- **metric_events**：工具调用 / 通信 / 封驳 / 覆奏等事件数（流程厚度）
- **wall_seconds**：墙钟耗时
- **quality_score**：人工 0–5 评分（正确性 + 完整性）

## 判读

对每个 tier，**人工**比较 etdxm 与单 Agent 基线的 token 与质量。注意两侧字段口径不同：etdxm 侧（`results/*.json`）记 `tokens_est`（下界估算值），基线侧（`baseline/*.json`）记 `tokens_actual`（会话实际用量）——对照时以「成本比 = etdxm.tokens_est / baseline.tokens_actual」「质量增益 = etdxm.quality − baseline.quality」衡量。若 etdxm 的「质量提升幅度」追不上「token 倍数」，说明该 tier 不值得走全流程——应下调 fast_track 阈值或直接太子直办。这把「多 agent 是否划算」从嘴炮变成数据。
