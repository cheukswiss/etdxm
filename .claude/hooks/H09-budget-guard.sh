#!/usr/bin/env bash
# H09 - Token 预算熔断
# 事件：PreToolUse (Agent|SendMessage) —— 在「创建 Teammate / 发消息」等放大性操作前检查累计预算
#
# 开关：GOVERNANCE_ENFORCE=1 超额硬拦截(exit 2)；=0 仅告警。80% 预警。
# 数据来源：.claude/budget.json（由 H07 初始化、H03 累计）
# 说明：token 用量为按工具调用字节数估算的「下界代理值」（见 HARNESS.md），
#       用于捕捉失控的调用量与相对趋势，非精确计费。
set -uo pipefail

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
BUDGET_FILE="$PROJECT_DIR/.claude/budget.json"
ENFORCE="${GOVERNANCE_ENFORCE:-1}"

[ -f "$BUDGET_FILE" ] || exit 0

LIMIT=$(jq -r '.limit_tokens // 0' "$BUDGET_FILE" 2>/dev/null || echo 0)
USED=$(jq -r '.cumulative_tokens // 0' "$BUDGET_FILE" 2>/dev/null || echo 0)

# 防御：非整数或上限为 0 时跳过
case "$LIMIT$USED" in *[!0-9]*) exit 0 ;; esac
[ "$LIMIT" -le 0 ] && exit 0

PCT=$(( USED * 100 / LIMIT ))

if [ "$PCT" -ge 100 ]; then
  MSG="Token 预算耗尽：已用约 $USED / 上限 $LIMIT（${PCT}%）。如需追加请皇上裁决，或调高 GOVERNANCE_TOKEN_BUDGET。"
  if [ "$ENFORCE" = "1" ]; then
    echo "熔断[H09]：$MSG" >&2
    exit 2
  fi
  echo "提醒[H09 观察模式]：$MSG" >&2
elif [ "$PCT" -ge 80 ]; then
  echo "提醒[H09]：Token 预算已用约 ${PCT}%（$USED/$LIMIT），临近上限。" >&2
fi

exit 0
