#!/usr/bin/env bash
# run-eval.sh — etdxm 评测驱动（半自动）
#
# 为什么是半自动：Agent Teams 无法被脚本自动驱动（需在活跃会话中由皇上下旨），
# 因此本脚本负责「框定评测窗口 + 抓取该窗口的度量 + 落盘结果」，
# 由人把 task 的 prompt 投喂给一个干净的 etdxm 会话，跑完后回到这里收口。
#
# 工作流：
#   1) bash run-eval.sh list                 列出全部评测任务
#   2) bash run-eval.sh start <task_id>       打印 prompt，并在 metrics 打 run-start 标记
#   3) （在 etdxm 会话中执行该旨意至回奏完成）
#   4) bash run-eval.sh finish <task_id>      计算窗口内度量增量，写入 eval/results/<task_id>.json
#   5) bash run-eval.sh report                汇总所有结果，与基线对比
#
# 基线对比：在 eval/baseline/ 下用同样的 prompt 跑「单 Agent（普通 Claude Code）」，
#           手工记录 token 与产出质量评分，run-eval.sh report 会并列展示差值。
set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
EVAL_DIR="$ROOT/eval"
TASKS="$EVAL_DIR/tasks.json"
RESULTS="$EVAL_DIR/results"
METRICS="$ROOT/.claude/metrics.jsonl"
MARK="$EVAL_DIR/.run-mark"
mkdir -p "$RESULTS"

metrics_count() { [ -f "$METRICS" ] && wc -l < "$METRICS" || echo 0; }
metrics_tokens() { [ -f "$METRICS" ] && jq -s '[.[]|(.tokens_est//0)]|add' "$METRICS" 2>/dev/null || echo 0; }

case "${1:-}" in
  list)
    jq -r '.tasks[] | "\(.id)\t[\(.tier)]\t\(.prompt)"' "$TASKS"
    ;;

  start)
    TID="${2:?用法: run-eval.sh start <task_id>}"
    P=$(jq -r --arg id "$TID" '.tasks[]|select(.id==$id)|.prompt' "$TASKS")
    [ -z "$P" ] && { echo "未找到任务 $TID"; exit 1; }
    echo "$TID|$(metrics_count)|$(metrics_tokens)|$(date -u +%s)" > "$MARK"
    echo "════════ 评测开始：$TID ════════"
    echo "请将以下旨意投喂给一个干净的 etdxm 会话，跑完整轮次至回奏："
    echo ""
    echo "    $P"
    echo ""
    echo "完成后运行：bash eval/run-eval.sh finish $TID"
    ;;

  finish)
    TID="${2:?用法: run-eval.sh finish <task_id>}"
    [ -f "$MARK" ] || { echo "未找到 run-start 标记，请先 start"; exit 1; }
    IFS='|' read -r MID MCOUNT MTOK MEPOCH < "$MARK"
    [ "$MID" = "$TID" ] || { echo "标记任务($MID)与 finish($TID)不一致"; exit 1; }
    DCOUNT=$(( $(metrics_count) - MCOUNT ))
    DTOK=$(( $(metrics_tokens) - MTOK ))
    DSEC=$(( $(date -u +%s) - MEPOCH ))
    TIER=$(jq -r --arg id "$TID" '.tasks[]|select(.id==$id)|.tier' "$TASKS")
    jq -n --arg id "$TID" --arg tier "$TIER" \
          --argjson events "$DCOUNT" --argjson tokens "$DTOK" --argjson secs "$DSEC" '{
      task_id:$id, tier:$tier, metric_events:$events, tokens_est:$tokens, wall_seconds:$secs,
      quality_score:null, notes:"请人工补充 quality_score(0-5) 与产出质量备注"
    }' > "$RESULTS/$TID.json"
    rm -f "$MARK"
    echo "已写入 $RESULTS/$TID.json（events=$DCOUNT tokens≈$DTOK secs=$DSEC）"
    echo "请补充 quality_score 后运行：bash eval/run-eval.sh report"
    ;;

  report)
    echo "════════ etdxm 评测汇总 ════════"
    if ! ls "$RESULTS"/*.json >/dev/null 2>&1; then echo "暂无结果"; exit 0; fi
    jq -s 'sort_by(.tier,.task_id)[] |
      "\(.task_id) [\(.tier)] tokens≈\(.tokens_est) events=\(.metric_events) secs=\(.wall_seconds) quality=\(.quality_score // "?")"' \
      "$RESULTS"/*.json -r
    echo "─ 基线对比：见 eval/baseline/（单 Agent 同任务的 token 与质量记录）"
    ;;

  *)
    echo "用法: run-eval.sh {list|start <id>|finish <id>|report}"
    exit 1
    ;;
esac
