---
name: keju-checklist
description: 科举四类检查规则详情——Skill frontmatter、Hook 语法、角色一致性、受保护文件同步
type: reference
usage: "由太子在执行 /keju 自检时逐项核对"
---

# 科举检查规则详情

## 一、Skill frontmatter 格式检查

遍历 `.claude/skills/*/SKILL.md`，逐个检查：

| 检查项 | 规则 | 严重度 |
|--------|------|--------|
| name 字段 | 必须存在且为英文小写+连字符 | ERROR |
| description 字段 | 必须存在且非空 | ERROR |
| user-invocable | 若为 true，必须同时有 description | WARN |
| disable-model-invocation | 布尔值，可选 | INFO |
| frontmatter 格式 | 以 `---` 包裹的有效 YAML | ERROR |

## 二、Hook 脚本语法检查

遍历 `.claude/hooks/H*.sh`，对每个脚本执行：

```bash
bash -n <script>  # 语法检查
```

| 检查项 | 规则 | 严重度 |
|--------|------|--------|
| bash 语法 | `bash -n` 通过 | ERROR |
| 可执行权限 | 文件有 +x 权限 | WARN |
| shebang | 首行为 `#!/usr/bin/env bash` 或 `#!/bin/bash` | WARN |

## 三、角色名/agent_id 一致性

交叉比对以下来源中的角色名：

| 来源 | 字段 |
|------|------|
| architecture-overview 角色总览表 | agent_id 列 |
| team-bootstrap SKILL.md | Teammate name 列 |
| roles-liubu.md | 各部标题中的 agent_id |
| communication-protocols SKILL.md | 通信矩阵中的 Agent 名 |

检查项：
- 所有来源中的 agent_id 集合必须一致
- 无孤立 agent_id（某来源有而其他来源无）
- 大小写完全匹配

## 四、受保护文件列表同步检查

比对以下位置的受保护文件列表：

| 来源 | 位置 |
|------|------|
| H01-governance-shield.sh | 脚本内的 PROTECTED_FILES 变量 |
| H06-config-sentinel.sh | 脚本内的监控文件列表 |
| settings.json | hooks 注册的文件模式 |

检查项：
- 核心治理文件（CLAUDE.md、settings.json、governance-core）必须在所有保护列表中
- 无遗漏保护的关键文件
