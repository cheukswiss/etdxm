#!/usr/bin/env bash
# metrics-report.sh — 聚合 .claude/metrics.jsonl，按 session 输出旨意执行度量
#
# 用法：bash .claude/scripts/metrics-report.sh [--json]
# 默认输出人类可读表；--json 输出结构化结果供 eval 套件消费。
set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
M="$PROJECT_DIR/.claude/metrics.jsonl"
MODE="${1:-table}"

[ -f "$M" ] || { echo "暂无 metrics.jsonl（尚未产生可观测数据）"; exit 0; }

AGG=$(jq -s '
  [ group_by(.session // "default")[] | {
      session:      (.[0].session // "default"),
      tool_calls:   ([.[] | select(.event=="tool_call")] | length),
      tokens_est:   ([.[] | (.tokens_est // 0)] | add),
      payloads_ok:  ([.[] | select(.event=="payload_ok")] | length),
      violations:   ([.[] | select(.event=="violation")] | length),
      topo_unverified: ([.[] | select(.event=="topology_unverified")] | length),
      task_done:    ([.[] | select(.event=="task_done")] | length),
      rejected:     ([.[] | select(.event=="rejected")] | length),
      first_ts:     ([.[] | .ts] | min),
      last_ts:      ([.[] | .ts] | max)
  } ]
' "$M" 2>/dev/null || echo '[]')

if [ "$MODE" = "--json" ]; then
  echo "$AGG"
  exit 0
fi

echo "════════ etdxm 度量报告 ════════"
echo "$AGG" | jq -r '.[] |
  "● session \(.session)\n" +
  "  工具调用      : \(.tool_calls)\n" +
  "  token 估算(下界): \(.tokens_est)\n" +
  "  合规载荷      : \(.payloads_ok)\n" +
  "  通信越权拦截  : \(.violations)\n" +
  "  拓扑未验证放行: \(.topo_unverified)\n" +
  "  任务完成      : \(.task_done)\n" +
  "  驳回          : \(.rejected)\n" +
  "  起止          : \(.first_ts) → \(.last_ts)"
'
echo "════════════════════════════════"
echo "提示：token 为按调用字节估算的下界代理值，用于相对趋势与失控检测，非精确计费（见 HARNESS.md）。"
