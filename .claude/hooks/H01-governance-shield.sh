#!/usr/bin/env bash
# H01 - 治理文件保护
# 事件：PreToolUse (Edit|Write)
# 功能：阻止未经授权修改核心治理文件
# 保护范围：.claude/skills/governance-core/SKILL.md、.claude/settings.json

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# 提取相对路径（去除项目根目录前缀）
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
REL_PATH="${FILE_PATH#"$PROJECT_DIR"/}"

# 受保护的治理文件
PROTECTED_FILES=(
  ".claude/skills/governance-core/SKILL.md"
  ".claude/settings.json"
)

for protected in "${PROTECTED_FILES[@]}"; do
  if [[ "$REL_PATH" == "$protected" ]]; then
    echo "封驳：治理文件 $protected 受保护，不可直接修改。如需变更请经皇上裁决。" >&2
    exit 2
  fi
done

exit 0
