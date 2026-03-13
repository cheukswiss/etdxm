# 贡献指南

三省六部（etdxm）是一个基于 Claude Code Agent Teams 的多智能体协作治理框架。欢迎参与贡献。

## 如何贡献

1. Fork 本仓库
2. 创建功能分支：`git checkout -b feature/your-feature`
3. 完成修改并提交
4. 推送到你的 Fork：`git push origin feature/your-feature`
5. 创建 Pull Request

## 可贡献的方向

### 新 Skill 模块

Skill 目录结构：每个 Skill 位于 `.claude/skills/<skill-name>/` 下，`SKILL.md` 为入口文件，子文件按需加载。

`SKILL.md` frontmatter 格式：

```yaml
---
name: skill-name           # Skill 唯一标识
description: 一句话描述      # 用途说明
disable-model-invocation: true/false  # 是否禁止模型自动调用
user-invocable: true/false  # 是否允许用户通过 /skill-name 手动调用
---
```

### Agent 角色优化

改进现有角色的 prompt、职责划分或协作流程。

### 文档改进

修正错误、补充说明、改善可读性。

### Bug 报告与修复

发现问题请提 Issue，附带修复 PR 更佳。

## 受保护文件

以下文件受 H01 Hook 保护，PR 中的修改会被自动拦截：

- `.claude/skills/governance-core/SKILL.md`
- `.claude/settings.json`

如需修改这些文件，请在 Issue 中说明理由，由维护者处理。

## Commit 规范

- 提交信息以中文为主
- 简明扼要描述变更内容
- 参照项目已有 commit 风格

## 代码风格

- Hook 脚本（`.claude/hooks/`）须包含 `set -euo pipefail`
- Skill 文件使用标准 Markdown 格式

## Issue 规范

**Bug 报告**请包含：
- Claude Code 版本
- 复现步骤
- 预期行为与实际行为

**Feature Request**请说明：
- 使用场景
- 期望的行为
