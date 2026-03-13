#!/usr/bin/env bash
# H02 - 危险命令拦截
# 事件：PreToolUse (Bash)
# 功能：拦截高危 shell 命令，防止误操作造成不可逆损害

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# ==============================
# 第一层：关键词模式拦截
# ==============================
BLOCKED_PATTERNS=(
  # --- 文件系统 ---
  "rm -rf /"
  "rm -rf ~"
  "rm -rf \\\$HOME"
  # --- Git 高危操作 ---
  "git push.*--force.*main"
  "git push.*--force.*master"
  "git reset --hard.*origin/(main|master)(\\s|$)"
  # --- 数据库高危操作 ---
  "DROP TABLE"
  "DROP DATABASE"
  "TRUNCATE TABLE"
  "DELETE FROM.*WHERE 1"
  # --- Shell 炸弹与磁盘破坏 ---
  ":(){ :|:& };:"
  "mkfs\."
  "> /dev/sda"
  # --- 基础设施高危操作 ---
  "kubectl delete namespace"
  "kubectl delete ns "
  "iptables -F"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "斩杀：检测到高危命令（匹配: $pattern），已拦截。如确需执行请经皇上直令。" >&2
    exit 2
  fi
done

# ==============================
# 第二层：裸 DELETE / UPDATE 两步判定
# 判定逻辑：先检测是否含 DELETE FROM 或 UPDATE...SET，
#           再检测是否含 WHERE 子句，无 WHERE 则拦截
# ==============================

# 检查裸 DELETE（含 DELETE FROM 但不含 WHERE）
if echo "$COMMAND" | grep -qiE "DELETE[[:space:]]+FROM[[:space:]]"; then
  if ! echo "$COMMAND" | grep -qiE "WHERE[[:space:]]"; then
    echo "斩杀：检测到无 WHERE 子句的 DELETE 语句，已拦截。如确需执行请经皇上直令。" >&2
    exit 2
  fi
fi

# 检查裸 UPDATE（含 UPDATE...SET 但不含 WHERE）
if echo "$COMMAND" | grep -qiE "UPDATE[[:space:]].*SET[[:space:]]"; then
  if ! echo "$COMMAND" | grep -qiE "WHERE[[:space:]]"; then
    echo "斩杀：检测到无 WHERE 子句的 UPDATE 语句，已拦截。如确需执行请经皇上直令。" >&2
    exit 2
  fi
fi

exit 0
