---
usage: "由太子在探活/shutdown 超时判定时精确查阅"
---

# 超时策略详情

## 防重检查超时阈值规则

创建任何 Teammate 前，若检查到同名成员已存在，须执行探活：

- 向该 Teammate 发送一条 SendMessage 探活（如"状态确认"）
- **探活超时阈值：30 秒**
- 30 秒内收到回复 → **复用**，不重复创建
- 30 秒内无回复 → 标记为**疑似失活**，**仍不创建新实例**（避免系统追加 `-2` 后缀导致寻址失效），上报太子决定是否清理重建

> **已知限制**：Claude Code 无法区分 idle 与 terminated Teammate（[Issue #29271](https://github.com/anthropics/claude-code/issues/29271)）。探活是当前唯一可用手段。

## Shutdown 超时处理

太子发送 `shutdown_request` 后须等待 `shutdown_response`（协议层已支持 approve/reject）。

- 30 秒内收到 `shutdown_response { approve: true }` → 确认关闭，更新 config 状态
- 30 秒内无 `shutdown_response` → 标记该 Teammate 为**疑似失活**（与探活超时处置一致），不视为"关闭成功"
- 后续若需再创建同角色 Teammate，仍须执行防重检查流程
