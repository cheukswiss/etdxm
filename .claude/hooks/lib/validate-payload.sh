#!/usr/bin/env bash
# validate-payload.sh — 三省六部消息载荷结构校验（jq 实现，零外部依赖）
#
# 用法：  echo "$JSON" | bash validate-payload.sh <ticket|report|plan>
# 退出码：0 = 通过；1 = 不合规（原因输出至 stderr）
#
# 规约来源（canonical）：.claude/schemas/{ticket,report,plan}.schema.json
# 本脚本是上述 schema 的运行时强制实现，供 H08 消息网关调用。
# 设计取舍：用 jq 做结构 + 枚举 + 闭环验收检查，不引入 ajv/python-jsonschema，
#           与项目既有「纯 jq」hook 风格一致，避免运行环境依赖。
set -uo pipefail

TYPE="${1:-}"
JSON="$(cat)"

ROLES='["gongbu","xingbu","hubu","bingbu","libu","libu_hr"]'
TSTATUS='["pending","assigned","in_progress","blocked","done","auditing","rejected","partial_done"]'

fail() { echo "[schema:${TYPE:-?}] $1" >&2; exit 1; }
chk()  { echo "$JSON" | jq -e "$1" >/dev/null 2>&1; }

# 必须是合法 JSON
echo "$JSON" | jq -e . >/dev/null 2>&1 || fail "载荷非合法 JSON"

case "$TYPE" in
  ticket)
    chk '.task' || fail "缺少 task 对象"
    chk '.task.id and .task.title and .task.assigned_to and .task.status and (.task.acceptance_criteria != null)' \
      || fail "task 必填字段缺失（id/title/assigned_to/status/acceptance_criteria）"
    chk '(.task.acceptance_criteria | type) == "array"' || fail "acceptance_criteria 必须为数组"
    echo "$JSON" | jq -e --argjson r "$ROLES" '.task.assigned_to as $a | ($r | index($a)) != null' >/dev/null 2>&1 \
      || fail "assigned_to 非法部门：$(echo "$JSON" | jq -r '.task.assigned_to')"
    echo "$JSON" | jq -e --argjson s "$TSTATUS" '.task.status as $v | ($s | index($v)) != null' >/dev/null 2>&1 \
      || fail "status 非法状态：$(echo "$JSON" | jq -r '.task.status')"
    ;;

  report)
    chk '.report' || fail "缺少 report 对象"
    chk '.report.plan_id and .report.status' || fail "report.plan_id / status 缺失"
    chk '(.report.subtask_results | type) == "array"' || fail "subtask_results 必须为数组"
    # 闭环验收：delivered 状态必须逐条验收且全部 pass + 附证据
    if chk '.report.status == "delivered"'; then
      chk '(.report.criteria_verification | type) == "array" and (.report.criteria_verification | length > 0)' \
        || fail "status=delivered 必须附 criteria_verification（逐条验收）"
      chk '.report.criteria_verification | all(.result == "pass")' \
        || fail "存在未通过(result!=pass)的验收项，不得标记 delivered"
      chk '.report.criteria_verification | all(.evidence != null and .evidence != "")' \
        || fail "每条验收项必须附 evidence 证据"
    fi
    ;;

  plan)
    chk '.plan_id and .objective and .subtasks' || fail "plan 必填字段缺失（plan_id/objective/subtasks）"
    chk '(.subtasks | type) == "array" and (.subtasks | length > 0)' || fail "subtasks 必须为非空数组"
    chk '.subtasks | all(.id and .assigned_to and .description)' || fail "每个 subtask 必须含 id/assigned_to/description"
    echo "$JSON" | jq -e --argjson r "$ROLES" '.subtasks | all(.assigned_to as $a | ($r | index($a)) != null)' >/dev/null 2>&1 \
      || fail "subtask.assigned_to 含非法部门"
    ;;

  *)
    fail "未知载荷类型：$TYPE（应为 ticket|report|plan）"
    ;;
esac

exit 0
