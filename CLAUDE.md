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
