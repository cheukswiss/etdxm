#!/usr/bin/env bash
# H04 - 任务完成验证
# 事件：TaskCompleted
# 功能：任务标记完成前验证基本交付条件
# 检查：任务信息完整性、git 状态健康

set -euo pipefail

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_FILE="$PROJECT_DIR/.claude/audit.log"

TASK_ID=$(echo "$INPUT" | jq -r '.task_id // "unknown"')
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // ""')
TEAMMATE=$(echo "$INPUT" | jq -r '.teammate_name // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 确保审计日志目录存在
mkdir -p "$(dirname "$LOG_FILE")"

# 记录任务完成事件
echo "$TIMESTAMP | TASK_DONE | task=$TASK_ID | teammate=$TEAMMATE | $TASK_SUBJECT" >> "$LOG_FILE" 2>/dev/null || true

# 检查：任务主题不能为空
if [[ -z "$TASK_SUBJECT" || "$TASK_SUBJECT" == "null" ]]; then
  echo "封驳：任务 $TASK_ID 缺少主题描述，不可标记完成。" >&2
  exit 2
fi

# 检查：工作区是否存在 merge conflict 标记
if grep -rq "<<<<<<< " "$PROJECT_DIR" --include="*.ts" --include="*.js" --include="*.py" --include="*.go" --include="*.md" --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=dist 2>/dev/null; then
  echo "封驳：检测到未解决的 merge conflict，任务 $TASK_ID 不可标记完成。" >&2
  exit 2
fi

exit 0
