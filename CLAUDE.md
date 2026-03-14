# etdxm — 三省六部 Agent Teams

## 启动加载

- 会话初始化时**必须加载** `.claude/skills/governance-core/SKILL.md` 建立太子身份与治理规则
- 首次需要 Teammate 协作时，加载 `.claude/skills/team-bootstrap/SKILL.md` 完成团队创建
- 皇上可通过 `/morning-court` 召开早朝

## 交互模型

- 太子（Lead）是皇上唯一对话方，其余 Teammate 的产出经太子中转
- 术语：「Agent」= 逻辑角色，「Teammate」= 运行时实例

## 治理

- `.claude/hooks/` 提供自动化治理（文件保护、审计、质量门等）
- 通信拓扑遵守 governance-core 中的通信权限矩阵
- 详见 `.claude/skills/` 下各 Skill

## Skill 三层渐进式披露架构

Skill 采用三层渐进式披露（Progressive Disclosure）架构，按需加载以节省上下文窗口：

| 层级 | 载体 | 内容 | 加载时机 |
|------|------|------|---------|
| **L1** | frontmatter `description` | 一句话功能概述，供判断是否加载 | 常驻（所有会话） |
| **L2** | `SKILL.md` body | 流程框架、核心规则、决策树 | Skill 被触发时 |
| **L3** | 同目录下 `*.md` 引用文件 | 详细参考表格、清单、模板 | 执行具体操作时按需读取 |

### L3 文件规范

- **命名**：与所属 Skill 语义相关，使用 kebab-case（如 `fault-tolerance-tables.md`、`bootstrap-checklist.md`）
- **frontmatter 必须包含 `usage` 字段**，说明由谁在何场景读取：
  ```yaml
  ---
  usage: "由[Agent名]在[具体场景]时读取"
  ---
  ```
- **L2 引用 L3 的标准写法**：
  ```markdown
  > 📎 详细规则见 `文件名.md`
  ```

### 判定标准

- 体量小（≤50 行）且内容高度内聚的 Skill → 维持两层
- 含查阅型内容（数值表、检查清单、模板）且体量较大的 Skill → 升级为三层
- `governance-core` 等核心身份定义 → 绝对不拆分，整体加载
