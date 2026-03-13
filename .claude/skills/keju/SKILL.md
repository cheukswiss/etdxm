---
name: keju
description: 系统一致性验证——检查 Skill frontmatter、Hook 语法、governance-core 与 team-bootstrap 角色一致性、受保护文件同步
user-invocable: true
disable-model-invocation: true
---

# Skill: 科举

> **适用 Agent**：太子（Lead）
> **加载时机**：皇上输入 `/keju` 时，或系统自检时

## 功能

全面验证三省六部系统的内部一致性，发现配置偏差与潜在问题。类似 lint + integration test。

## 检查项目

### 一、Skill frontmatter 格式检查

遍历 `.claude/skills/*/SKILL.md`，逐个检查：

| 检查项 | 规则 | 严重度 |
|--------|------|--------|
| name 字段 | 必须存在且为英文小写+连字符 | ERROR |
| description 字段 | 必须存在且非空 | ERROR |
| user-invocable | 若为 true，必须同时有 description | WARN |
| disable-model-invocation | 布尔值，可选 | INFO |
| frontmatter 格式 | 以 `---` 包裹的有效 YAML | ERROR |

### 二、Hook 脚本语法检查

遍历 `.claude/hooks/H*.sh`，对每个脚本执行：

```bash
bash -n <script>  # 语法检查
```

| 检查项 | 规则 | 严重度 |
|--------|------|--------|
| bash 语法 | `bash -n` 通过 | ERROR |
| 可执行权限 | 文件有 +x 权限 | WARN |
| shebang | 首行为 `#!/usr/bin/env bash` 或 `#!/bin/bash` | WARN |

### 三、角色名/agent_id 一致性

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

### 四、受保护文件列表同步检查

比对以下位置的受保护文件列表：

| 来源 | 位置 |
|------|------|
| H01-governance-shield.sh | 脚本内的 PROTECTED_FILES 变量 |
| H06-config-sentinel.sh | 脚本内的监控文件列表 |
| settings.json | hooks 注册的文件模式 |

检查项：
- 核心治理文件（CLAUDE.md、settings.json、governance-core）必须在所有保护列表中
- 无遗漏保护的关键文件

## 输出格式

```
📋 科举成绩单

考试日期：2026-03-13

一、Skill Frontmatter（x/y 通过）
    ✅ morning-court — 通过
    ❌ xxx — ERROR: 缺少 description 字段

二、Hook 脚本（x/y 通过）
    ✅ H01-governance-shield.sh — 通过
    ⚠️ H03-audit-logger.sh — WARN: 缺少可执行权限

三、角色一致性（通过/未通过）
    检查 agent_id 集合...
    ✅ 所有来源一致
    或
    ❌ roles-liubu.md 中缺少 agent_id: libu_hr

四、受保护文件同步（通过/未通过）
    ✅ 核心文件均在保护列表中
    或
    ⚠️ H06 未包含 CLAUDE.md

总评：x ERROR / y WARN / z INFO
      状元 🏆 / 进士 / 举人 / 落榜
```

**评级规则**：
- 0 ERROR + 0 WARN = 状元
- 0 ERROR + ≤3 WARN = 进士
- 0 ERROR + >3 WARN = 举人
- ≥1 ERROR = 落榜

## 约束

1. 检查过程为只读操作，不修改任何文件
2. 发现 ERROR 时建议修复方案但不自动修复
3. 成绩单必须呈报皇上，不得隐瞒不通过项
