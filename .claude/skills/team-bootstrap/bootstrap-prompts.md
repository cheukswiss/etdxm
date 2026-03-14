---
usage: "由太子在创建三省或六部 Teammate 时构造 prompt 时读取"
---

# 分层创建策略：Prompt 构造详情

## 第一层：三省创建参数表

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
- ⚠️ **`name` 必须使用英文（ASCII）**：Claude Code 已知 Bug，含中文的 Teammate name 会导致通信失败。所有 name 必须为英文或拼音，禁止中文。✅ `zhongshu` `gongbu-2` ❌ `中书省`

## 第二层：六部 Prompt 注入说明

> **技术约束**：Teammate 的 Agent tool 已被 Claude Code 移除，只有 Lead（太子）能创建 Teammate。

**太子创建六部时的 prompt 须包含**：
- 该部门在 `.claude/skills/architecture-overview/roles-liubu.md` 中的身份定义段落（按 `##` 标题定位提取，含通信权限）
- 尚书省提供的任务上下文（task_id、acceptance_criteria 等）

**六部保留策略**：
- 已创建的六部 Teammate 在当前旨意完成后**可保留**，供后续任务复用
- 低频部门（吏部、户部）仅在相关任务时创建，无任务时不保留

## 第三层：员外郎创建流程细节

堂官-员外郎模式下，员外郎 Teammate 的创建流程：

```
堂官检测多任务可并行
  → SendMessage 向尚书省申请创建员外郎
  → 尚书省批准后，SendMessage 请求太子创建
  → 太子执行防重检查 → 通过 Agent tool 创建员外郎 Teammate（isolation: "worktree"）
  → 创建成功后通知尚书省 → 尚书省通知堂官 → 堂官派发子任务
```
