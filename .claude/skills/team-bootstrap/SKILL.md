---
name: team-bootstrap
description: 首次创建 Teammate 的引导流程——太子首次协作或尚书首次派发六部时加载，完成 Team 创建与分层启动
disable-model-invocation: true
---

# Skill: 会话引导（Team Bootstrap）

> **适用 Agent**：太子（Lead）、尚书省
> **加载时机**：会话中首次需要与 Teammate 通信前（收到旨意、执行早朝等）

## 术语约定

本项目中 **Agent** 与 **Teammate** 含义不同，不可混用：

| 术语 | 含义 | 示例 |
|------|------|------|
| **Agent** | 逻辑角色身份——governance-core 与 architecture-overview 中定义的十个角色 | "中书省 Agent 负责规划" |
| **Teammate** | Claude Code 运行时实例——通过 `Agent tool + team_name` 创建的进程 | "创建中书省 Teammate" |
| **Lead** | 团队领导的运行时实例——太子即 Lead | "太子（Lead）创建团队" |

**核心原则**：Agent 是设计图纸上的角色，Teammate 是实际上工的人。**SendMessage 只能送达已创建的 Teammate，不能凭空唤醒一个不存在的实例。**

## 引导流程

```
会话启动 → 太子就位（Lead）
  │
  ├─ 皇上消息为闲聊 → 太子直答，不创建任何 Teammate
  │
  └─ 皇上消息为旨意 / 早朝 / 需要 Teammate 协作
       │
       ├─ 步骤 1：TeamCreate（仅首次）
       │    └─ team_name: "sansheng-liubu"
       │
       ├─ 步骤 2：创建三省 Teammate（治理流转必备）
       │    ├─ 中书省 — 规划
       │    ├─ 门下省 — 审议
       │    └─ 尚书省 — 派发协调
       │
       ├─ 步骤 3：旨意进入三省流转
       │    └─ 太子通过 SendMessage 传旨给中书省
       │
       └─ 步骤 4：太子按需创建六部 Teammate（尚书省请求）
            ├─ 尚书省分析子任务后，SendMessage 请求太子创建所需六部
            ├─ 太子执行 Agent tool 创建（Teammate 无 Agent tool 权限）
            ├─ 低频部门（吏部、户部）仅在相关任务时创建
            └─ 员外郎由堂官申请、尚书省转请太子创建
```

## 三省职责原则

三省（中书、门下、尚书）是**决策与协调层**，不直接执行代码编写、测试、部署等具体操作。具体执行由尚书省派发至六部完成。三省职责边界：
- **中书省**：规划方案，不写代码
- **门下省**：审议与覆奏，不执行任务
- **尚书省**：派发协调汇总，不亲自动手

## 防重检查流程

创建任何 Teammate 前，**必须**执行以下检查：

1. **读取团队配置**：`Read ~/.claude/teams/sansheng-liubu/config.json`
2. **检查 members 数组**：是否已有同名成员（`name` 字段匹配）
3. **若已存在**：
   - 向该 Teammate 发送一条 SendMessage 探活（如"状态确认"）
   - 若收到回复 → **复用**，不重复创建
   - 若无回复 → 记录为疑似失活，**仍不创建新实例**（避免系统追加 `-2` 后缀导致寻址失效）
4. **若不存在** → 正常创建

> **已知限制**：Claude Code 无法区分 idle 与 terminated Teammate（[Issue #29271](https://github.com/anthropics/claude-code/issues/29271)）。探活是当前唯一可用手段。

## 分层创建策略

### 第一层：三省（太子创建，治理必备）

太子在首次需要 Teammate 协作时，**必须先创建三省**。三省是治理流转的骨干，缺一则流程断裂。

创建方式：使用 Agent tool，参数如下——

| Teammate | name | 创建时 prompt 须包含 |
|----------|------|---------------------|
| 中书省 | `zhongshu` | governance-core 中书省核心身份 + 通信权限（中书→门下✅、中书→太子✅） + 当前旨意上下文 |
| 门下省 | `menxia` | governance-core 门下省核心身份 + 通信权限 + 封驳规则概要 |
| 尚书省 | `shangshu` | governance-core 尚书省核心身份 + 通信权限 + 派发规则概要 |

**关键参数**：
- `team_name`：必须与 TeamCreate 时的 team_name 一致
- `name`：必须与 architecture-overview 角色总览中的 agent_id 一致（SendMessage 按 name 寻址）

### 第二层：六部（尚书省请求，太子代创建，按需启动或保留）

> **技术约束**：Teammate 的 Agent tool 已被 Claude Code 移除，只有 Lead（太子）能创建 Teammate。

尚书省收到准奏方案后，通过 SendMessage 请求太子创建所需六部：

```
尚书省分析子任务 → 确定需要哪些部门
  → SendMessage 请求太子创建（附部门名 + 任务上下文）
  → 太子执行防重检查 → 通过 Agent tool 创建六部 Teammate
  → 创建成功后通知尚书省 → 尚书省通过 SendMessage 派发工单
```

**太子创建六部时的 prompt 须包含**：
- 该部门在 `.claude/skills/architecture-overview/roles-liubu.md` 中的身份定义段落（按 `##` 标题定位提取，含通信权限）
- 尚书省提供的任务上下文（task_id、acceptance_criteria 等）

**六部保留策略**：
- 已创建的六部 Teammate 在当前旨意完成后**可保留**，供后续任务复用
- 低频部门（吏部、户部）仅在相关任务时创建，无任务时不保留

### 第三层：员外郎（堂官申请→尚书省批准→太子代创建）

堂官-员外郎模式下，员外郎 Teammate 的创建流程：

```
堂官检测多任务可并行
  → SendMessage 向尚书省申请创建员外郎
  → 尚书省批准后，SendMessage 请求太子创建
  → 太子执行防重检查 → 通过 Agent tool 创建员外郎 Teammate（isolation: "worktree"）
  → 创建成功后通知尚书省 → 尚书省通知堂官 → 堂官派发子任务
```

## 创建前检查清单

太子在创建 Teammate 前，须确认：

- [ ] Team 已通过 TeamCreate 创建（仅首次）
- [ ] **防重检查已通过**（读 config.json → 无同名成员 / 同名已探活确认失活）
- [ ] prompt 中包含该 Agent 的核心身份定义（三省见 governance-core，六部见 `architecture-overview/roles-liubu.md`）
- [ ] prompt 中包含通信权限约束（六部定义中已自带）
- [ ] prompt 中包含当前任务上下文（旨意/工单）
- [ ] name 参数与 architecture-overview 角色总览中的 agent_id 一致

## 释放策略

| Teammate | 释放时机 | 释放方式 |
|----------|---------|---------|
| 三省 | 当前旨意全部完成且无后续任务 | 太子发送 shutdown_request |
| 六部 | 尚书省确认无后续任务，或皇上明确要求清理 | 尚书省请求太子发送 shutdown_request（可选保留供后续复用） |
| 员外郎 | 子任务完成、堂官确认产出 | 堂官请求尚书省，尚书省转请太子 shutdown |

## 早朝场景特殊处理

早朝（`/morning-court`）流程中：
- **第一阶段（太子自查）**：不需要创建 Teammate，太子独立完成
- **第二阶段（联络三省）**：须先确保三省 Teammate 已创建，否则先执行本 Skill 的第一层创建
- **第三阶段（联络六部）**：仅在有活跃任务的部门已有 Teammate 时才联络，否则由太子根据 Task API 记录代为汇总
