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

# jq 提取均补守护：免畸形/空输入经 set -e 透传，在写 session.id/budget.json
# 前意外中止（致 H09 预算 fail-open）。
SOURCE=$(echo "$INPUT" | jq -r '.source // "unknown"' 2>/dev/null || echo "unknown")
MODEL=$(echo "$INPUT" | jq -r '.model // "unknown"' 2>/dev/null || echo "unknown")
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 记录会话启动
echo "========================================" >> "$LOG_FILE"
echo "$TIMESTAMP | SESSION_START | source=$SOURCE | model=$MODEL | session=$SESSION_ID" >> "$LOG_FILE"

# ---- 可观测性 + 预算：初始化 session 标识与 Token 预算 ----
# session.id 供 H03/H08 标注度量归属；budget.json 供 H03 累计、H09 熔断。
echo "$SESSION_ID" > "$LOG_DIR/session.id" 2>/dev/null || true
LIMIT="${GOVERNANCE_TOKEN_BUDGET:-400000}"
case "$LIMIT" in *[!0-9]*) LIMIT=400000 ;; esac
# 仅在「真新会话」才把累计预算清零（cumulative_tokens=0）——budget.json 不存在，
#   或既有 session_id 与当前不一致。resume/compact 属同一会话（session_id 不变），
# 保留既有 budget.json 与累计，否则 H09 熔断会被无谓清零、对最该保护的长会话失效。
BUDGET_FILE="$LOG_DIR/budget.json"
PREV_SID=$(jq -r '.session_id // empty' "$BUDGET_FILE" 2>/dev/null || echo "")
if [[ ! -f "$BUDGET_FILE" || "$PREV_SID" != "$SESSION_ID" ]]; then
  jq -n --arg sid "$SESSION_ID" --arg ts "$TIMESTAMP" --argjson lim "$LIMIT" \
    '{session_id:$sid, started_at:$ts, limit_tokens:$lim, cumulative_tokens:0}' \
    > "$BUDGET_FILE" 2>/dev/null || true
fi
jq -nc --arg ts "$TIMESTAMP" --arg session "$SESSION_ID" --arg detail "budget=$LIMIT" \
  '{ts:$ts,session:$session,event:"session_start",tokens_est:0,detail:$detail}' \
  >> "$LOG_DIR/metrics.jsonl" 2>/dev/null || true

exit 0
