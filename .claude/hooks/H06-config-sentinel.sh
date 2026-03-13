#!/usr/bin/env bash
# H06 - 配置变更哨兵
# 事件：ConfigChange
# 功能：审计所有配置变更，阻止对 project_settings 的未授权修改

set -euo pipefail

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_FILE="$PROJECT_DIR/.claude/audit.log"

SOURCE=$(echo "$INPUT" | jq -r '.source // "unknown"')
FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 确保审计日志目录存在
mkdir -p "$(dirname "$LOG_FILE")"

# 记录配置变更事件
echo "$TIMESTAMP | CONFIG_CHANGE | source=$SOURCE | $FILE_PATH" >> "$LOG_FILE" 2>/dev/null || true

# 阻止对项目级设置的直接修改（需经皇上裁决）
if [[ "$SOURCE" == "project_settings" ]]; then
  echo "封驳：项目配置变更（$FILE_PATH）需经皇上裁决，不可自行修改。" >&2
  exit 2
fi

# skills 变更仅审计记录，不阻止（Skill 按需加载属正常行为）
exit 0
