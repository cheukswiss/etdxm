#!/usr/bin/env bash
# H10 - ticket-adapter：派工工单 canonical 适配与 schema 强制
# 事件：PreToolUse (TaskCreate)
#
# ── 背景（M3 诊断）──
# ticket.schema 要求 canonical {task:{...}}，但平台 TaskCreate 工单实为扁平
# tool_input {subject, description, activeForm?, metadata?}，无 .task 包裹层；
# 故 H08（SendMessage 网关）的 `jq -e '.task'` 闸门对派工从不触发、ticket schema
# 校验形同虚设。H10 在 TaskCreate 的 PreToolUse 处把派工载荷映射为 canonical
# {task:{...}} 再交 lib/validate-payload.sh 校 ticket.schema，使「工单合规」由劝谕入律令。
#
# ── 派工约定（尚书须遵）──
# 派工时把 canonical 工单字段置于 TaskCreate.tool_input.metadata.task，即
#   metadata.task = {id, title?, assigned_to, status, acceptance_criteria, ...}
# H10 以 tool_input.subject 补 title（title 为 null/缺失/空串时；补后仍空则封驳），
# 包成 {task:...} 后交校验器。
#
# ── 辨别 + dead-letter 观察（皇上 2026-05-26 裁：监测非强制）──
# 仅当 tool_input.metadata.task 存在（＝派工按约定填）才映射并强制 ticket.schema。
# 无 metadata.task 的 TaskCreate（含未遵约定的真实派工、普通会话待办）→ 记 dead-letter
# 观察日志（公示）后【放行不阻断】——皇上裁定不强制真实流量、不改派工、不动 SKILL，
# 仅诚实暴露未遵 metadata.task 约定者、监测采纳率。镜像 H08「检测到结构化载荷才校验」。
#
# ── superset 取舍（太子 2026-05-26 裁甲·接受·纯标注、不改逻辑）──
# 因无可靠启发式区分「似派工」与「普通会话待办」，H10 对【所有】无 metadata.task 的 TaskCreate
# 一律记 dead_letter——是 honest superset，为「似派工」措辞在无启发式现实下的忠实退路、非违旨。
# 边界与代价（诚实标注）：
#   · 约定未推行期间，每次建任务各记一条 dead_letter；
#   · 故「采纳率量化」须俟 metadata.task 约定推行后方有信息量（此前 dead_letter 占比≈全量、无判别力）；
#   · audit.log/metrics.jsonl 噪音可后续加启发式（按 subject 模式/来源辨别派工）优化降噪。
#
# ── 开关 ──
# GOVERNANCE_ENFORCE=1 硬拦截(exit 2)；=0 仅观察告警(exit 0)。
#
# ── ⚠️ 诚实标注·残余两条（皇上 2026-05-26 裁定）──
# 【残余一·在体强制未验】「PreToolUse 对 TaskCreate 触发并 honor exit 2 阻断」未做在体
#   端到端实测——唯一隔离验证机制（嵌套 headless `claude --settings` 子进程）被平台安全
#   分类器判为「创建不安全 agent」而禁止，连人在环（太子授权）亦被挡（见 M-A1 阶段1）。
#   现据三支撑判定该机制【高置信成立】，据以落地 H10：
#     ① M-00 四证据链：可阻断 hook 活跃(ENFORCE=1，H01/H08/H09 实接线)；TaskCreate
#        已证在 hook 管道内(H03 PostToolUse 对 12 次 TaskCreate 触发为证)；PreToolUse
#        matcher 已证可匹配编排类工具(SendMessage/Agent)；适配器脚本侧沙箱实证可读载荷+exit2。
#     ② Claude Code Pre/Post hook 对称性：PostToolUse 既对 TaskCreate 触发，
#        PreToolUse 同名 matcher 应同样匹配同一 tool_name。
#     ③ 编排工具 matcher 先例：生产 settings.json 已有 SendMessage/Agent 的 PreToolUse 实活。
# 【残余二·真实流量为监测非强制】皇上裁定不采 metadata.task 强制约定、不改派工。故对未携
#   metadata.task 的真实扁平派工，H10 仅记 dead-letter 观察日志、放行不阻断——即【监测而非
#   强制】。当前真强制仅及「已按约定填 metadata.task」之工单；待派工方采约定后方对真实流量真强制。
#
# ── 复议条件（任一满足即应重验/收紧对应残余）──
#   · [残余一] 平台放开嵌套沙箱 agent，或提供官方 hook dry-run / 录制能力 → 即补在体冒烟实测；
#   · [残余一] audit.log 出现 H10 的 violation / ticket_ok 行（H10 在体已对真实派工触发）→ 自然清零；
#   · [残余一] Claude Code 官方文档明确 TaskCreate 的 PreToolUse 行为 → 据文档确认后移除标注；
#   · [残余二] dead_letter 观察日志显示派工已普遍采 metadata.task（采纳率达标）→ 可评估升为强制。
set -uo pipefail

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LIB="$PROJECT_DIR/.claude/hooks/lib"
LOG_FILE="$PROJECT_DIR/.claude/audit.log"
METRICS="$PROJECT_DIR/.claude/metrics.jsonl"
ENFORCE="${GOVERNANCE_ENFORCE:-1}"
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_ID=$(cat "$PROJECT_DIR/.claude/session.id" 2>/dev/null || echo "default")

j() { echo "$INPUT" | jq -r "$1" 2>/dev/null; }

# 仅管 TaskCreate，其余工具放行
TOOL=$(j '.tool_name // empty')
[ "$TOOL" = "TaskCreate" ] || exit 0

emit() { # $1=event $2=detail
  local d
  d=$(printf '%s' "${2:-}" | tr '\n' ' ')
  echo "$TS | H10 | $1 | $d" >> "$LOG_FILE" 2>/dev/null || true
  # 用 jq 构造，保证异常字段值被正确转义，避免污染 metrics.jsonl
  jq -nc --arg ts "$TS" --arg session "$SESSION_ID" --arg event "$1" --arg detail "$d" \
    '{ts:$ts,session:$session,event:$event,hook:"H10",detail:$detail}' >> "$METRICS" 2>/dev/null || true
}

deny() { # $1=message
  emit "violation" "$1"
  if [ "$ENFORCE" = "1" ]; then
    echo "封驳[H10]：$1" >&2
    exit 2
  fi
  echo "提醒[H10 观察模式]：$1" >&2
  exit 0
}

# ── 辨别 + dead-letter 观察（皇上裁：监测非强制，放行不阻断）──
# 无 metadata.task → 无法校 schema。皇上裁定不强制真实流量、不改派工，改记 dead-letter
# 观察日志（公示）后放行，诚实暴露未遵约定者、供监测采纳率。
if ! echo "$INPUT" | jq -e '.tool_input.metadata.task' >/dev/null 2>&1; then
  SUBJ=$(j '.tool_input.subject // ""')
  emit "dead_letter" "TaskCreate 无 metadata.task：H10 未强制 schema（监测/公示，放行不阻断）；subject=${SUBJ:0:60}"
  exit 0
fi

# ── 适配：扁平派工 → canonical {task:{...}}；title 为 null/缺失/空串时以 subject 补 ──
# 注意：jq `//=` 仅替换 null/false，不替换空串("")；故显式用 (== "") 判定，
#       覆盖 title="" 显式空的情形（刑部 M-A3 缺口修复）。
SUBJECT=$(j '.tool_input.subject // empty')
CANON=$(echo "$INPUT" | jq -c --arg subj "$SUBJECT" \
  '{task: (.tool_input.metadata.task | .title = (if ((.title // "") | tostring) == "" then $subj else .title end))}' 2>/dev/null)

if [ -z "$CANON" ] || [ "$CANON" = "null" ]; then
  deny "派工载荷映射 canonical 失败（metadata.task 非对象或非法）"
fi

# ── 空串健壮性：title 经 subject 补后仍空（subject 亦空/缺失）→ 视为缺失，封驳 ──
# validate-payload 的 `jq -e '.task.title'` 对空串判真会漏过，故 H10 层先行兜住。
TITLE=$(printf '%s' "$CANON" | jq -r '.task.title // ""' 2>/dev/null)
if [ -z "$TITLE" ]; then
  deny "工单缺 title：metadata.task.title 为空且 subject 亦空，无法补全"
fi

# ── 校 ticket.schema（复用既有运行时强制实现）──
if ! ERR=$(printf '%s' "$CANON" | bash "$LIB/validate-payload.sh" ticket 2>&1); then
  deny "工单 schema 校验失败：$ERR"
fi

emit "ticket_ok" "派工工单 canonical 校验通过：id=$(printf '%s' "$CANON" | jq -r '.task.id // "?"') assigned_to=$(printf '%s' "$CANON" | jq -r '.task.assigned_to // "?"')"
exit 0
