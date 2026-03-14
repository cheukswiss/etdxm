---
name: qijuzhu-format
description: 起居注文件命名规范、必填字段定义与记录示例
type: reference
usage: "由太子在写入或读取起居注时查阅格式规范"
---

# 起居注格式规范

## 文件命名规范

- 路径：`.claude/qijuzhu/`
- 主文件名：`YYYY-MM-DD.md`（使用会话实际日期）
- 同日第二次会话：`YYYY-MM-DD-2.md`，以此类推
- 示例：`2026-03-14.md`、`2026-03-14-2.md`

## 必填字段

| 字段 | 说明 |
|------|------|
| **会话日期** | 格式 `YYYY-MM-DD`，与文件名一致 |
| **处理旨意** | 本次会话皇上下达的旨意摘要（一句话） |
| **完成任务** | 已完结的 Task ID 及说明列表 |
| **遗留事项** | 未完成、跨会话续办的任务（含 Task ID） |
| **待裁决** | 需皇上下次会话确认或决策的事项 |

## 记录示例

```markdown
---
date: 2026-03-14
session: 1
---

# 起居注 · 2026-03-14

## 处理旨意
重构六部 Skill 为三层结构，提升 Token 加载效率。

## 完成任务
- T-001：team-bootstrap 拆为 L2+L3（bootstrap-checklist/prompts/timeout-policy）
- T-002：fault-tolerance 拆为 L2+L3
- T-003：parallel-execution 拆为 L2+L3
- T-004：keju + analysis-framework 拆为 L2+L3

## 遗留事项
- T-005：special-directives + dispatch-rules 引用注解（in_progress）
- T-006：更新 CLAUDE.md 三层架构说明（pending）
- T-007：/keju 验收 + 门下覆验（pending）

## 待裁决
（无）
```
