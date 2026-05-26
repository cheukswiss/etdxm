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

# ---- 可观测性：结构化指标 + Token 估算 + 预算累计 ----
# token 为按调用字节数估算的「下界代理值」（INPUT 已被 head -c 截断，故为下界）——
# 用于相对趋势与失控调用量检测，非精确计费。详见 HARNESS.md。
SESSION_ID=$(cat "$LOG_DIR/session.id" 2>/dev/null || echo "default")
TOKENS_EST=$(( ${#INPUT} / 4 ))
SAFE_DETAIL=$(printf '%s' "$DETAIL" | tr '\n' ' ')
jq -nc --arg ts "$TIMESTAMP" --arg session "$SESSION_ID" --arg tool "$TOOL_NAME" --argjson tokens "$TOKENS_EST" --arg detail "$SAFE_DETAIL" \
  '{ts:$ts,session:$session,event:"tool_call",tool:$tool,tokens_est:$tokens,detail:$detail}' \
  >> "$LOG_DIR/metrics.jsonl" 2>/dev/null || true

BUDGET_FILE="$LOG_DIR/budget.json"
if [[ -f "$BUDGET_FILE" ]]; then
  (
    flock -w 2 9 2>/dev/null || exit 0
    CUR=$(jq -r '.cumulative_tokens // 0' "$BUDGET_FILE" 2>/dev/null || echo 0)
    case "$CUR" in *[!0-9]*) CUR=0 ;; esac
    NEW=$(( CUR + TOKENS_EST ))
    TMP=$(mktemp 2>/dev/null) || exit 0
    if jq --argjson n "$NEW" '.cumulative_tokens=$n' "$BUDGET_FILE" > "$TMP" 2>/dev/null; then
      mv "$TMP" "$BUDGET_FILE" 2>/dev/null || rm -f "$TMP"
    else
      rm -f "$TMP"
    fi
  ) 9>"$BUDGET_FILE.lock" 2>/dev/null || true
fi

exit 0
