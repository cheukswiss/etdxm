# 单 Agent 基线

用**普通 Claude Code（单 Agent，无三省六部）**跑 `../tasks.json` 中的同一批任务，作为 etdxm 的对照组。

## 记录方式

每个任务建 `<task_id>.json`：

```json
{
  "task_id": "ST-01",
  "tier": "standard",
  "tokens_actual": 0,
  "wall_seconds": 0,
  "quality_score": 0,
  "notes": "单 Agent 直接实现，无规划/审议/覆奏环节"
}
```

`token` 取自单 Agent 会话的实际用量（Claude Code 可见的用量统计），`quality_score` 用与 etdxm 侧一致的 0–5 标准人工评分，保证可比。

## 对比口径

> ⚠️ 现状：`../run-eval.sh report` **不会**自动读取或并列本目录的基线文件——它仅汇总 etdxm 侧（`../results/*.json`）并打印一行指向本目录的提示。基线对比目前需**人工**进行。

人工对照时注意两侧字段口径不同：etdxm 侧记 `tokens_est`（下界估算值），本目录基线记 `tokens_actual`（会话实际用量）。关注两个比值：

- **成本比** = etdxm.tokens_est / baseline.tokens_actual
- **质量增益** = etdxm.quality_score − baseline.quality_score

当「质量增益」无法正当化「成本比」时，该 tier 不应走全流程。
