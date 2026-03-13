#!/usr/bin/env bash
# H05 - Teammate 空闲质量门
# 事件：TeammateIdle
# 功能：Teammate 进入空闲前检查是否有未完成的工作

set -euo pipefail

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_FILE="$PROJECT_DIR/.claude/audit.log"

TEAMMATE=$(echo "$INPUT" | jq -r '.teammate_name // "unknown"')
TEAM=$(echo "$INPUT" | jq -r '.team_name // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 确保审计日志目录存在
mkdir -p "$(dirname "$LOG_FILE")"

# 记录空闲事件
echo "$TIMESTAMP | IDLE | teammate=$TEAMMATE | team=$TEAM" >> "$LOG_FILE" 2>/dev/null || true

# 检查：工作区是否有未暂存的修改（可能是未完成的工作）
DIRTY_COUNT=$(cd "$PROJECT_DIR" && git diff --name-only 2>/dev/null | wc -l) || DIRTY_COUNT=0
if [[ "$DIRTY_COUNT" -gt 10 ]]; then
  echo "提醒：$TEAMMATE 工作区有 $DIRTY_COUNT 个未暂存文件，请确认工作已完成。" >&2
  exit 2
fi

exit 0
