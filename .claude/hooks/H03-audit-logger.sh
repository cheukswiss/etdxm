#!/usr/bin/env bash
# H03 - 操作审计日志
# 事件：PostToolUse (所有工具)
# 功能：异步记录所有工具调用，供事后追溯审查
# 日志位置：.claude/audit.log
#
# 注意：不使用 set -e，审计日志写入失败不应阻断主流程
# 注意：Agent 工具的 tool_result 可能包含巨量文本，
#       使用 head -c 限制输入大小防止超时

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_DIR="$PROJECT_DIR/.claude"
LOG_FILE="$LOG_DIR/audit.log"

# 确保审计日志目录存在
mkdir -p "$LOG_DIR"

# 限制输入大小，防止 Agent 工具的巨量 tool_result 导致超时
INPUT=$(head -c 10000)

# 一次性 jq 提取所有字段，避免多次 echo|jq 管道操作
# 兼容标准工具调用（tool_name）和 Agent Teams 系统事件（type/event_type）
FIELDS=$(echo "$INPUT" | jq -r '[
  (.tool_name // .type // .event_type // "unknown"),
  (if .tool_name == "Bash" then (.tool_input.command // "" | .[0:120])
   elif (.tool_name == "Edit" or .tool_name == "Write" or .tool_name == "Read") then (.tool_input.file_path // "")
   elif .tool_name == "Grep" then (.tool_input.pattern // "")
   elif .tool_name == "SendMessage" then ("to=" + (.tool_input.recipient // "unknown"))
   elif .tool_name == "Agent" then ("name=" + (.tool_input.name // "unknown"))
   elif .type then (.message // .from // "")
   else ((.tool_input | keys[0:2] | join(",")) // "")
   end)
] | @tsv' 2>/dev/null || echo "unknown	")

TOOL_NAME=$(echo "$FIELDS" | cut -f1)
DETAIL=$(echo "$FIELDS" | cut -f2)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "$TIMESTAMP | $TOOL_NAME | $DETAIL" >> "$LOG_FILE" 2>/dev/null || true

exit 0
