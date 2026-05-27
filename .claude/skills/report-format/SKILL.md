---
name: report-format
description: 尚书省 report 模式回奏格式规范，定义回奏必备字段与结构
---

# Skill: 回奏格式

> **适用 Agent**：尚书省
> **加载时机**：尚书省 report 模式（汇总完毕准备回奏时）

## 回奏报告格式

```json
{
  "report": {
    "plan_id": "PLAN-20260312-001",
    "title": "用户登录模块开发",
    "status": "delivered",
    "summary": "简要执行结果描述",
    "subtask_results": [
      {
        "task_id": "TASK-001",
        "department": "gongbu",
        "status": "done",
        "output": "src/auth/login.ts"
      },
      {
        "task_id": "TASK-002",
        "department": "xingbu",
        "status": "done",
        "output": "tests/auth/login.test.ts"
      }
    ],
    "criteria_verification": [
      { "criterion": "JWT Token 正确签发", "result": "pass", "evidence": "src/auth/login.ts:42 签发逻辑 + 单测通过" },
      { "criterion": "单元测试覆盖率 > 80%", "result": "pass", "evidence": "coverage 报告 87%" }
    ],
    "issues": [],
    "recommendations": ""
  }
}
```

## 回奏流程

尚书省编写回奏报告后，通过 SendMessage 发送至太子（Lead），由太子汇总呈报皇上。太子不得修改回奏内容，仅负责中转与格式化呈报。

## 必备字段

- `plan_id`：关联的方案编号
- `status`：delivered / partial / failed / rejected
- `summary`：一段话概括执行结果
- `subtask_results`：每个子任务的完成状态与产出物
- `issues`：执行过程中遇到的问题（即使已解决也需记录）

## 闭环验收（status=delivered 强制）

`status` 标记为 `delivered` 时，**必须**附 `criteria_verification[]` 逐条验收原草案的 `acceptance_criteria`，且：

- 数组非空，每条含 `criterion` / `result` / `evidence`
- 每条 `result` 必须为 `pass`（存在 `fail` 则不得标记 delivered）
- 每条 `evidence` 须非空，给出可核验的取证（文件路径、测试结果、覆盖率数据等）

此为运行时律令：H08 message-gateway 经 `validate-payload.sh` 强制校验，不满足则封驳。`partial` / `failed` / `rejected` 状态不要求闭环验收，但应在 `issues` / `summary` 中说明缺口。
