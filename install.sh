#!/usr/bin/env bash
# ============================================================
# etdxm 三省六部 Agent Teams — 一键安装脚本
#
# 用法:
#   ./install.sh [选项] <目标工程目录>
#
# 选项:
#   -y, --force      跳过所有交互确认
#   --dry-run        只列出将执行的操作，不实际执行
#   --minimal        仅安装核心模块（governance-core + 6 个基础 Skill + Hooks）
#   --full           安装全部模块（默认）
#   -h, --help       显示帮助
#
# 示例:
#   ./install.sh ~/work/my-project
#   ./install.sh --minimal --force ~/work/my-project
#   ./install.sh --dry-run ~/work/my-project
# ============================================================

set -euo pipefail

# ── 颜色 ──────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ── 脚本自身所在目录（即 etdxm 源目录）──────────
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 默认参数 ─────────────────────────────────────
FORCE=false
DRY_RUN=false
INSTALL_MODE="full"
TARGET_DIR=""

# ── 最小安装集（核心 Skill）─────────────────────
MINIMAL_SKILLS=(
    governance-core
    team-bootstrap
    architecture-overview
    intent-classification
    morning-court
    tuichao
    communication-protocols
)

# ── 参数解析 ─────────────────────────────────────
show_help() {
    sed -n '2,16p' "$0" | sed 's/^# \?//'
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--force)   FORCE=true; shift ;;
        --dry-run)    DRY_RUN=true; shift ;;
        --minimal)    INSTALL_MODE="minimal"; shift ;;
        --full)       INSTALL_MODE="full"; shift ;;
        -h|--help)    show_help ;;
        -*)           echo -e "${RED}未知选项: $1${NC}"; show_help ;;
        *)            TARGET_DIR="$1"; shift ;;
    esac
done

if [[ -z "$TARGET_DIR" ]]; then
    echo -e "${RED}错误：请指定目标工程目录${NC}"
    echo ""
    echo "用法: $0 [选项] <目标工程目录>"
    echo "运行 $0 --help 查看完整帮助"
    exit 1
fi

TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$TARGET_DIR")"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "${RED}错误：目标目录不存在: $TARGET_DIR${NC}"
    echo "请先创建目录，或指定一个已存在的目录。"
    exit 1
fi

# 防止安装到源目录自身
if [[ "$TARGET_DIR" == "$SOURCE_DIR" ]]; then
    echo -e "${YELLOW}目标目录与源目录相同，无需安装。${NC}"
    exit 0
fi

# ── 辅助函数 ─────────────────────────────────────
# 安全确认：--force 时自动同意
confirm_action() {
    local prompt="$1" default="${2:-n}"
    if $FORCE; then return 0; fi
    read -rp "$prompt" answer
    answer="${answer:-$default}"
    [[ "$answer" == "y" || "$answer" == "Y" ]]
}

# dry-run 感知的操作包装
run_cmd() {
    if $DRY_RUN; then
        echo -e "      ${CYAN}[dry-run]${NC} $1"
    else
        eval "$2"
        echo "      $1"
    fi
}

# 检查 skill 是否在最小安装集中
is_minimal_skill() {
    local name="$1"
    for s in "${MINIMAL_SKILLS[@]}"; do
        [[ "$s" == "$name" ]] && return 0
    done
    return 1
}

# sed 安全替换项目名（转义特殊字符）
safe_sed_replace() {
    local project_name="$1" source_file="$2"
    # 转义 sed 替换串中的特殊字符: & \ /
    local escaped
    escaped=$(printf '%s' "$project_name" | sed 's/[&/\]/\\&/g')
    sed "s/^# etdxm — 三省六部 Agent Teams/# ${escaped} — 三省六部 Agent Teams/" "$source_file"
}

# ── 版本信息 ─────────────────────────────────────
SOURCE_VERSION="$(cd "$SOURCE_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")"
SOURCE_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ── 开始安装 ─────────────────────────────────────
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   三省六部 Agent Teams · 安装程序       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "源目录:   ${GREEN}$SOURCE_DIR${NC}"
echo -e "目标工程: ${GREEN}$TARGET_DIR${NC}"
echo -e "安装模式: ${GREEN}$INSTALL_MODE${NC}"
echo -e "源版本:   ${GREEN}$SOURCE_VERSION${NC}"
$DRY_RUN && echo -e "运行模式: ${YELLOW}dry-run（仅预览，不实际执行）${NC}"
echo ""

# ── 检测目标工程是否已安装 ────────────────────────
if [[ -d "$TARGET_DIR/.claude/skills/governance-core" ]]; then
    echo -e "${YELLOW}⚠ 检测到目标工程已安装三省六部框架。${NC}"
    if ! confirm_action "是否覆盖安装？(y/N) " "n"; then
        echo "已取消。"
        exit 0
    fi
    echo ""
fi

# ── [1/6] 创建目录结构 ───────────────────────────
echo -e "${CYAN}[1/6] 创建目录结构...${NC}"
run_cmd "✓ .claude/hooks/"   'mkdir -p "$TARGET_DIR/.claude/hooks"'
run_cmd "✓ .claude/skills/"  'mkdir -p "$TARGET_DIR/.claude/skills"'
run_cmd "✓ .claude/qijuzhu/" 'mkdir -p "$TARGET_DIR/.claude/qijuzhu"'

# H2: 生成 .gitkeep 确保空目录可被 Git 追踪
if ! $DRY_RUN; then
    touch "$TARGET_DIR/.claude/qijuzhu/.gitkeep" 2>/dev/null || true
fi

# ── [2/6] 复制 Hooks ────────────────────────────
echo -e "${CYAN}[2/6] 安装治理钩子 (Hooks)...${NC}"
for hook in "$SOURCE_DIR"/.claude/hooks/H*.sh; do
    hookname="$(basename "$hook")"
    run_cmd "✓ $hookname" 'cp "$SOURCE_DIR/.claude/hooks/'"$hookname"'" "$TARGET_DIR/.claude/hooks/'"$hookname"'" && chmod +x "$TARGET_DIR/.claude/hooks/'"$hookname"'"'
done

# ── [3/6] 复制 Skills ───────────────────────────
echo -e "${CYAN}[3/6] 安装技能模块 (Skills)...${NC}"
shopt -s nullglob
skill_count=0
skipped_count=0
for skill_dir in "$SOURCE_DIR"/.claude/skills/*/; do
    skill_name="$(basename "$skill_dir")"

    # --minimal 模式：跳过非核心 Skill
    if [[ "$INSTALL_MODE" == "minimal" ]] && ! is_minimal_skill "$skill_name"; then
        skipped_count=$((skipped_count + 1))
        continue
    fi

    # D3: 使用 nullglob，不静默吞错
    md_files=("$skill_dir"*.md)
    if [[ ${#md_files[@]} -eq 0 ]]; then
        echo -e "      ${YELLOW}⚠ $skill_name/ 无 .md 文件，跳过${NC}"
        continue
    fi

    if $DRY_RUN; then
        echo -e "      ${CYAN}[dry-run]${NC} ✓ $skill_name/ (${#md_files[@]} 个文件)"
    else
        mkdir -p "$TARGET_DIR/.claude/skills/$skill_name"
        cp "${md_files[@]}" "$TARGET_DIR/.claude/skills/$skill_name/"
    fi
    skill_count=$((skill_count + 1))
done
shopt -u nullglob
echo "      ✓ 已安装 $skill_count 个 Skill 模块"
if [[ $skipped_count -gt 0 ]]; then
    echo -e "      ${YELLOW}⊘ 跳过 $skipped_count 个非核心模块（--minimal 模式）${NC}"
fi

# ── [4/6] 安装 settings.json ────────────────────
echo -e "${CYAN}[4/6] 安装配置文件...${NC}"

if [[ -f "$TARGET_DIR/.claude/settings.json" ]]; then
    # D2: 检测已有 hooks，提供合并/覆盖/跳过选择
    existing_has_hooks=false
    if command -v jq &>/dev/null && jq -e '.hooks' "$TARGET_DIR/.claude/settings.json" &>/dev/null; then
        existing_has_hooks=true
    fi

    if $existing_has_hooks; then
        echo -e "      ${YELLOW}⚠ 目标已有 settings.json 且包含 hooks 配置${NC}"
        echo -e "      ${YELLOW}  覆盖将丢失目标工程已有的 hooks！${NC}"
    else
        echo -e "      ${YELLOW}⚠ 目标已有 settings.json${NC}"
    fi

    if $FORCE; then
        settings_action="o"
    else
        echo "      处理方式："
        echo "        (m) 合并 — 保留目标已有 hooks，追加三省六部 hooks（需要 jq）"
        echo "        (o) 覆盖 — 备份原文件后替换"
        echo "        (s) 跳过 — 不修改 settings.json"
        read -rp "      请选择 [m/o/s]: " settings_action
        settings_action="${settings_action:-s}"
    fi

    case "$settings_action" in
        m|M)
            if ! command -v jq &>/dev/null; then
                echo -e "      ${RED}✗ 合并需要 jq，但未安装。回退为覆盖模式。${NC}"
                settings_action="o"
            else
                if ! $DRY_RUN; then
                    cp "$TARGET_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.json.bak"
                    # 深度合并：三省六部的 hooks 追加到已有 hooks 数组，env 合并
                    jq -s '
                        def merge_hooks:
                            . as [$a, $b] |
                            ($a.hooks // {}) as $ah |
                            ($b.hooks // {}) as $bh |
                            ($ah | keys) + ($bh | keys) | unique | map(
                                . as $k | {($k): (($ah[$k] // []) + ($bh[$k] // []) | unique)}
                            ) | add // {};
                        {
                            hooks: ([$.[0], $.[1]] | merge_hooks),
                            env: ($.[0].env // {} | . * ($.[1].env // {}))
                        } + ($.[0] | del(.hooks, .env)) * ($.[1] | del(.hooks, .env))
                    ' "$TARGET_DIR/.claude/settings.json" "$SOURCE_DIR/.claude/settings.json" \
                        > "$TARGET_DIR/.claude/settings.json.tmp" \
                        && mv "$TARGET_DIR/.claude/settings.json.tmp" "$TARGET_DIR/.claude/settings.json"
                fi
                echo "      ✓ settings.json 已合并（原文件备份为 .bak）"
            fi
            ;;&
        o|O)
            if [[ "$settings_action" == "o" || "$settings_action" == "O" ]]; then
                run_cmd "✓ settings.json 已覆盖（原文件备份为 .bak）" \
                    'cp "$TARGET_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.json.bak" && cp "$SOURCE_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.json"'
            fi
            ;;
        *)
            echo "      ⊘ 跳过 settings.json"
            ;;
    esac
else
    run_cmd "✓ settings.json" 'cp "$SOURCE_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.json"'
fi

echo "      ⊘ settings.local.json 跳过（含源工程硬编码路径）"

# ── [5/6] 安装 CLAUDE.md ────────────────────────
echo -e "${CYAN}[5/6] 安装 CLAUDE.md...${NC}"
project_name="$(basename "$TARGET_DIR")"

if [[ -f "$TARGET_DIR/CLAUDE.md" ]]; then
    echo -e "      ${YELLOW}⚠ 目标已有 CLAUDE.md${NC}"
    if $FORCE; then
        claude_action="a"
    else
        read -rp "      如何处理？(a)追加到末尾 / (r)替换 / (s)跳过 [a/r/s]: " claude_action
        claude_action="${claude_action:-s}"
    fi
else
    claude_action="r"
fi

case "$claude_action" in
    a|A)
        if $DRY_RUN; then
            echo -e "      ${CYAN}[dry-run]${NC} ✓ 追加到现有 CLAUDE.md 末尾"
        else
            { echo ""; echo "---"; echo ""; safe_sed_replace "$project_name" "$SOURCE_DIR/CLAUDE.md"; } >> "$TARGET_DIR/CLAUDE.md"
            echo "      ✓ 已追加到现有 CLAUDE.md 末尾"
        fi
        ;;
    r|R)
        if $DRY_RUN; then
            echo -e "      ${CYAN}[dry-run]${NC} ✓ 写入 CLAUDE.md（项目名: $project_name）"
        else
            safe_sed_replace "$project_name" "$SOURCE_DIR/CLAUDE.md" > "$TARGET_DIR/CLAUDE.md"
            echo "      ✓ 已写入 CLAUDE.md（项目名: $project_name）"
        fi
        ;;
    *)
        echo "      ⊘ 跳过 CLAUDE.md"
        ;;
esac

# ── [6/6] 写入版本标记 ──────────────────────────
echo -e "${CYAN}[6/6] 写入版本标记...${NC}"
if $DRY_RUN; then
    echo -e "      ${CYAN}[dry-run]${NC} ✓ .claude/.etdxm-version"
else
    cat > "$TARGET_DIR/.claude/.etdxm-version" <<EOF
source_commit: $SOURCE_VERSION
install_date: $SOURCE_DATE
install_mode: $INSTALL_MODE
source_dir: $SOURCE_DIR
EOF
    echo "      ✓ .claude/.etdxm-version（$SOURCE_VERSION @ $SOURCE_DATE）"
fi

# ── 验证（dry-run 时跳过）───────────────────────
if ! $DRY_RUN; then
    echo ""
    echo -e "${CYAN}验证安装...${NC}"
    errors=0

    # 检查核心文件
    for f in governance-core/SKILL.md team-bootstrap/SKILL.md architecture-overview/SKILL.md; do
        if [[ ! -f "$TARGET_DIR/.claude/skills/$f" ]]; then
            echo -e "  ${RED}✗ 缺失: .claude/skills/$f${NC}"
            errors=$((errors + 1))
        fi
    done

    # 检查 hooks 可执行 + 语法
    for hook in "$TARGET_DIR"/.claude/hooks/H*.sh; do
        hookname="$(basename "$hook")"
        if [[ ! -x "$hook" ]]; then
            echo -e "  ${RED}✗ 不可执行: $hookname${NC}"
            errors=$((errors + 1))
        fi
        if ! bash -n "$hook" 2>/dev/null; then
            echo -e "  ${RED}✗ 语法错误: $hookname${NC}"
            errors=$((errors + 1))
        fi
    done

    # 检查版本标记
    if [[ ! -f "$TARGET_DIR/.claude/.etdxm-version" ]]; then
        echo -e "  ${RED}✗ 缺失: .claude/.etdxm-version${NC}"
        errors=$((errors + 1))
    fi

    if [[ $errors -eq 0 ]]; then
        echo -e "  ${GREEN}✓ 全部检查通过${NC}"
    else
        echo -e "  ${RED}发现 $errors 个问题${NC}"
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
    echo -e "${GREEN}║   安装完成！                             ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo "下一步："
    echo "  1. cd $TARGET_DIR"
    echo "  2. 启动 Claude Code，太子将自动加载 governance-core"
    echo "  3. 使用 /morning-court 召开早朝"
    echo -e "  4. ${CYAN}建议首次运行 /keju 验证系统一致性${NC}"
    echo ""
    echo -e "${YELLOW}提示：如需将治理文件纳入版本控制，请执行：${NC}"
    echo "  cd $TARGET_DIR && git add .claude/ CLAUDE.md"
fi
echo ""
