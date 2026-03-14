---
usage: "由太子在创建任何 Teammate 前执行防重检查时读取"
---

# 创建前检查清单

太子在创建 Teammate 前，须确认：

- [ ] Team 已通过 TeamCreate 创建（仅首次）
- [ ] **防重检查已通过**（读 config.json → 无同名成员 / 同名已探活确认失活）
- [ ] prompt 中包含该 Agent 的核心身份定义（三省见 governance-core，六部见 `architecture-overview/roles-liubu.md`）
- [ ] prompt 中包含通信权限约束（六部定义中已自带）
- [ ] prompt 中包含当前任务上下文（旨意/工单）
- [ ] name 参数与 architecture-overview 角色总览中的 agent_id 一致
