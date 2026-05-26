#!/usr/bin/env bash
# H08 - 消息网关：通信拓扑校验 + 载荷 schema 校验
# 事件：PreToolUse (SendMessage)
# 把 governance-core 通信权限矩阵 + ticket/report/plan schema 从「软规则」下沉为「硬约束」。
#
# 开关：GOVERNANCE_ENFORCE=1 硬拦截(exit 2)；=0 仅观察告警(exit 0)
# 渐进式强制（observe → enforce）：
#   拓扑校验在「发送方身份不可判定」时 fail-open（记录后放行）——
#   Agent Teams 为实验功能，SendMessage 载荷形态需经 audit.log 观察确认后再收紧。
#   一旦确认发送方字段，本 hook 即对越权通信全量硬拦截。
set -uo pipefail

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LIB="$PROJECT_DIR/.claude/hooks/lib"
LOG_FILE="$PROJECT_DIR/.claude/audit.log"
METRICS="$PROJECT_DIR/.claude/metrics.jsonl"
ENFORCE="${GOVERNANCE_ENFORCE:-1}"
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

j() { echo "$INPUT" | jq -r "$1" 2>/dev/null; }

RECIPIENT=$(j '.tool_input.recipient // .tool_input.to // .tool_input.teammate // .tool_input.recipient_name // empty')
SENDER="${CLAUDE_TEAMMATE_NAME:-${CLAUDE_AGENT_NAME:-}}"
[ -z "$SENDER" ] && SENDER=$(j '.sender // .from // .teammate_name // empty')
BODY=$(j '.tool_input.message // .tool_input.content // .tool_input.body // .tool_input.text // empty')

emit() { # $1=event $2=detail
  local d s r
  d=$(printf '%s' "${2:-}" | tr '\n' ' ')
  # sender/recipient 来自外部输入（tool_input.to / env），换行/回车须剥除，
  # 否则恶意 recipient 可向纯文本 audit.log 注入伪造行（log forging）。
  s=$(printf '%s' "${SENDER:-?}" | tr -d '\n\r')
  r=$(printf '%s' "${RECIPIENT:-?}" | tr -d '\n\r')
  echo "$TS | GATEWAY | $1 | sender=$s recipient=$r | $d" >> "$LOG_FILE" 2>/dev/null || true
  # 用 jq 构造，保证字段值（含异常 teammate 名中的引号/反斜杠）被正确转义，避免污染 metrics.jsonl
  jq -nc --arg ts "$TS" --arg event "$1" --arg sender "${SENDER:-}" --arg recipient "${RECIPIENT:-}" --arg detail "$d" \
    '{ts:$ts,event:$event,sender:$sender,recipient:$recipient,detail:$detail}' >> "$METRICS" 2>/dev/null || true
}

deny() { # $1=message
  emit "violation" "$1"
  if [ "$ENFORCE" = "1" ]; then
    echo "封驳[H08]：$1" >&2
    exit 2
  fi
  echo "提醒[H08 观察模式]：$1" >&2
  exit 0
}

# ---- 通信拓扑校验（governance-core 三、通信权限速查）----
is_allowed() {
  local s="$1" r="$2"
  # 员外郎 worker-* 作为收件方：任意六部(堂官)或尚书可下发
  case "$r" in
    worker-*) case "$s" in gongbu|xingbu|hubu|bingbu|libu|libu_hr|shangshu) return 0 ;; *) return 1 ;; esac ;;
  esac
  # 员外郎 worker-* 作为发件方：仅可回报六部(堂官)
  case "$s" in
    worker-*) case "$r" in gongbu|xingbu|hubu|bingbu|libu|libu_hr) return 0 ;; *) return 1 ;; esac ;;
  esac
  case "$s" in
    taizi)    [[ " zhongshu menxia shangshu " == *" $r "* ]] && return 0 ;;
    zhongshu) [[ " taizi menxia " == *" $r "* ]] && return 0 ;;
    menxia)   [[ " taizi zhongshu shangshu " == *" $r "* ]] && return 0 ;;
    shangshu) [[ " taizi zhongshu menxia gongbu xingbu hubu bingbu libu libu_hr " == *" $r "* ]] && return 0 ;;
    gongbu|xingbu|hubu|bingbu|libu|libu_hr) [[ " shangshu taizi " == *" $r "* ]] && return 0 ;;  # taizi 仅 P0 例外
  esac
  return 1
}

if [ -n "$RECIPIENT" ] && [ -n "$SENDER" ]; then
  is_allowed "$SENDER" "$RECIPIENT" || deny "通信越权：$SENDER → $RECIPIENT 不在权限矩阵内（R10 红线）"
elif [ -n "$RECIPIENT" ] && [ -z "$SENDER" ]; then
  emit "topology_unverified" "发送方身份不可判定，拓扑校验 fail-open 放行（待 audit 确认字段后收紧）"
fi

# ---- 载荷 schema 校验（ticket / report / plan）----
if [ -n "$BODY" ] && echo "$BODY" | jq -e . >/dev/null 2>&1; then
  PTYPE=""
  if   echo "$BODY" | jq -e '.task' >/dev/null 2>&1; then PTYPE="ticket"
  elif echo "$BODY" | jq -e '.report' >/dev/null 2>&1; then PTYPE="report"
  elif echo "$BODY" | jq -e '.plan_id and .subtasks' >/dev/null 2>&1; then PTYPE="plan"
  fi
  if [ -n "$PTYPE" ]; then
    if ! ERR=$(echo "$BODY" | bash "$LIB/validate-payload.sh" "$PTYPE" 2>&1); then
      deny "载荷校验失败（$PTYPE）：$ERR"
    fi
    emit "payload_ok" "$PTYPE"
  fi
fi

exit 0
