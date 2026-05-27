#!/usr/bin/env bash
# H04 - 任务完成验证
# 事件：TaskCompleted
# 功能：任务标记完成前验证基本交付条件
# 检查：任务信息完整性、git 状态健康

set -euo pipefail

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_FILE="$PROJECT_DIR/.claude/audit.log"

# jq 提取均补 `2>/dev/null || <安全默认>`：否则畸形/空输入时 jq 非零退出码经
# set -e 透传，会在写审计/度量前意外中止并误判为封驳；补守护后畸形输入走
# 既有「主题为空→封驳」确定路径并先落日志。
TASK_ID=$(echo "$INPUT" | jq -r '.task_id // "unknown"' 2>/dev/null || echo "unknown")
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // ""' 2>/dev/null || echo "")
TEAMMATE=$(echo "$INPUT" | jq -r '.teammate_name // "unknown"' 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 确保审计日志目录存在
mkdir -p "$(dirname "$LOG_FILE")"

# 记录任务完成事件
echo "$TIMESTAMP | TASK_DONE | task=$TASK_ID | teammate=$TEAMMATE | $TASK_SUBJECT" >> "$LOG_FILE" 2>/dev/null || true

# 可观测性：结构化指标
SESSION_ID=$(cat "$PROJECT_DIR/.claude/session.id" 2>/dev/null || echo "default")
jq -nc --arg ts "$TIMESTAMP" --arg session "$SESSION_ID" --arg detail "task=$TASK_ID teammate=$TEAMMATE" \
  '{ts:$ts,session:$session,event:"task_done",tokens_est:0,detail:$detail}' \
  >> "$PROJECT_DIR/.claude/metrics.jsonl" 2>/dev/null || true

ENFORCE="${GOVERNANCE_ENFORCE:-1}"

# 检查：任务主题不能为空
if [[ -z "$TASK_SUBJECT" || "$TASK_SUBJECT" == "null" ]]; then
  echo "封驳：任务 $TASK_ID 缺少主题描述，不可标记完成。" >&2
  exit 2
fi

# 检查：若事件携带 deliverables 字段且为空数组，视为无交付物（闭环验收第一道）
DELIV=$(echo "$INPUT" | jq -r '(.deliverables // .task_deliverables // empty) | if type=="array" then length else "n/a" end' 2>/dev/null || echo "n/a")
if [[ "$ENFORCE" == "1" && "$DELIV" == "0" ]]; then
  echo "封驳：任务 $TASK_ID 标记完成但 deliverables 为空，须附产出物/证据。" >&2
  exit 2
fi

# 检查：工作区是否存在 merge conflict 标记
if grep -rq "<<<<<<< " "$PROJECT_DIR" --include="*.ts" --include="*.js" --include="*.py" --include="*.go" --include="*.md" --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=dist 2>/dev/null; then
  echo "封驳：检测到未解决的 merge conflict，任务 $TASK_ID 不可标记完成。" >&2
  exit 2
fi

exit 0
