#!/usr/bin/env bash
# H07 - 会话生命周期
# 事件：SessionStart
# 功能：初始化审计环境，记录会话启动

set -euo pipefail

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_DIR="$PROJECT_DIR/.claude"
LOG_FILE="$LOG_DIR/audit.log"

# 确保审计日志目录存在
mkdir -p "$LOG_DIR"

SOURCE=$(echo "$INPUT" | jq -r '.source // "unknown"')
MODEL=$(echo "$INPUT" | jq -r '.model // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 记录会话启动
echo "========================================" >> "$LOG_FILE"
echo "$TIMESTAMP | SESSION_START | source=$SOURCE | model=$MODEL | session=$SESSION_ID" >> "$LOG_FILE"

exit 0
