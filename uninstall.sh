#!/usr/bin/env bash
# ============================================================
# etdxm 三省六部 Agent Teams — 卸载脚本
#
# 用法:
#   ./uninstall.sh [选项] <目标工程目录>
#
# 选项:
#   -y, --force      跳过确认提示
#   --dry-run        只列出将删除的内容，不实际执行
#   --keep-hooks     保留 hooks 目录
#   --keep-claude-md 保留 CLAUDE.md
#   -h, --help       显示帮助
#
# 示例:
#   ./uninstall.sh ~/work/my-project
#   ./uninstall.sh --dry-run ~/work/my-project
# ============================================================

set -euo pipefail

# ── 颜色 ──────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── 参数 ─────────────────────────────────────────
FORCE=false
DRY_RUN=false
KEEP_HOOKS=false
KEEP_CLAUDE_MD=false
TARGET_DIR=""

show_help() {
    sed -n '2,16p' "$0" | sed 's/^# \?//'
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--force)        FORCE=true; shift ;;
        --dry-run)         DRY_RUN=true; shift ;;
        --keep-hooks)      KEEP_HOOKS=true; shift ;;
        --keep-claude-md)  KEEP_CLAUDE_MD=true; shift ;;
        -h|--help)         show_help ;;
        -*)                echo -e "${RED}未知选项: $1${NC}"; show_help ;;
        *)                 TARGET_DIR="$1"; shift ;;
    esac
done

if [[ -z "$TARGET_DIR" ]]; then
    echo -e "${RED}错误：请指定目标工程目录${NC}"
    echo "用法: $0 [选项] <目标工程目录>"
    exit 1
fi

TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$TARGET_DIR")"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "${RED}错误：目录不存在: $TARGET_DIR${NC}"
    exit 1
fi

# ── 检测是否安装了三省六部 ───────────────────────
if [[ ! -f "$TARGET_DIR/.claude/.etdxm-version" ]] && [[ ! -d "$TARGET_DIR/.claude/skills/governance-core" ]]; then
    echo -e "${YELLOW}未检测到三省六部框架安装痕迹。${NC}"
    exit 0
fi

echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   三省六部 Agent Teams · 卸载程序       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "目标工程: ${GREEN}$TARGET_DIR${NC}"
$DRY_RUN && echo -e "运行模式: ${YELLOW}dry-run（仅预览）${NC}"
echo ""

# ── 显示版本信息 ─────────────────────────────────
if [[ -f "$TARGET_DIR/.claude/.etdxm-version" ]]; then
    echo -e "${CYAN}已安装版本信息：${NC}"
    sed 's/^/  /' "$TARGET_DIR/.claude/.etdxm-version"
    echo ""
fi

# ── 确认 ─────────────────────────────────────────
if ! $FORCE; then
    echo -e "${RED}⚠ 此操作将删除三省六部治理框架的全部文件。${NC}"
    read -rp "确认卸载？(y/N) " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "已取消。"
        exit 0
    fi
    echo ""
fi

# ── 辅助函数 ─────────────────────────────────────
remove_item() {
    local path="$1" label="$2"
    if [[ -e "$path" ]]; then
        if $DRY_RUN; then
            echo -e "  ${CYAN}[dry-run]${NC} 将删除: $label"
        else
            rm -rf "$path"
            echo -e "  ${GREEN}✓${NC} 已删除: $label"
        fi
    fi
}

# ── 执行卸载 ─────────────────────────────────────
echo -e "${CYAN}正在卸载...${NC}"

# 1. 删除 Skills
remove_item "$TARGET_DIR/.claude/skills" ".claude/skills/"

# 2. 删除 Hooks（除非 --keep-hooks）
if $KEEP_HOOKS; then
    echo -e "  ${YELLOW}⊘${NC} 保留: .claude/hooks/（--keep-hooks）"
else
    remove_item "$TARGET_DIR/.claude/hooks" ".claude/hooks/"
fi

# 3. 删除起居注
remove_item "$TARGET_DIR/.claude/qijuzhu" ".claude/qijuzhu/"

# 4. 删除版本标记
remove_item "$TARGET_DIR/.claude/.etdxm-version" ".claude/.etdxm-version"

# 5. 删除审计日志（运行时生成）
remove_item "$TARGET_DIR/.claude/audit.log" ".claude/audit.log"

# 6. 删除 settings.json（恢复备份如果存在）
if [[ -f "$TARGET_DIR/.claude/settings.json.bak" ]]; then
    if $DRY_RUN; then
        echo -e "  ${CYAN}[dry-run]${NC} 将恢复: settings.json.bak → settings.json"
    else
        mv "$TARGET_DIR/.claude/settings.json.bak" "$TARGET_DIR/.claude/settings.json"
        echo -e "  ${GREEN}✓${NC} 已恢复: settings.json（从 .bak 备份）"
    fi
else
    remove_item "$TARGET_DIR/.claude/settings.json" ".claude/settings.json"
fi

# 7. CLAUDE.md（除非 --keep-claude-md）
if $KEEP_CLAUDE_MD; then
    echo -e "  ${YELLOW}⊘${NC} 保留: CLAUDE.md（--keep-claude-md）"
else
    # 只在 CLAUDE.md 包含三省六部标记时删除
    if [[ -f "$TARGET_DIR/CLAUDE.md" ]] && grep -q "三省六部" "$TARGET_DIR/CLAUDE.md"; then
        remove_item "$TARGET_DIR/CLAUDE.md" "CLAUDE.md"
    else
        echo -e "  ${YELLOW}⊘${NC} 保留: CLAUDE.md（未检测到三省六部内容）"
    fi
fi

# 8. 清理空的 .claude/ 目录
if ! $DRY_RUN && [[ -d "$TARGET_DIR/.claude" ]]; then
    remaining=$(find "$TARGET_DIR/.claude" -type f 2>/dev/null | wc -l)
    if [[ "$remaining" -eq 0 ]]; then
        rm -rf "$TARGET_DIR/.claude"
        echo -e "  ${GREEN}✓${NC} 已删除: .claude/（空目录）"
    else
        echo -e "  ${YELLOW}⊘${NC} 保留: .claude/（仍有 $remaining 个非三省六部文件）"
    fi
fi

# ── 完成 ─────────────────────────────────────────
echo ""
if $DRY_RUN; then
    echo -e "${YELLOW}╔══════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║   预览完成（dry-run，未实际执行）        ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════╝${NC}"
else
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   卸载完成！                             ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
fi
echo ""
