## [2026-05-26] — 编年史·律令纪（劝谕→律令硬化）

> 三纲由「markdown 软规则」下沉为「代码硬约束」：凡需保证之事，写进 hook，而非 prompt。详见 `.claude/HARNESS.md`。

### 📜 新旨意
- 立强制之制，使通信·预算·验收三纲由劝谕入律令——新增 H08 消息网关（通信拓扑校验 + ticket/report/plan 三 schema 校验）、H09 预算熔断（Token 累计 80% 预警 / 100% 熔断）、`hooks/lib/validate-payload.sh` 三 schema 运行时强制；增设 `eval/` 评测套件与 `HARNESS.md` (`7ddc7f3`)
- 立 H10 适配之制，使派工工单 schema 校验由摆设入律令——新增 H10 工单适配（`TaskCreate` 派工载荷映射 canonical 后校 `ticket.schema`，无 metadata.task 者记 dead-letter 监测放行）(`edb1fee`)

### 🔧 修缮
- 增强 H03（结构化 metrics + token 累计）、H04（deliverables 闭环检查）、H07（初始化 session.id 与 budget.json）
- 收紧 `validate-payload.sh` ticket 校验——`title` 不可为空字符串（`length > 0`，同惠 H08/H10）

---

## [2026-03-14] — 编年史·立制纪

### 📜 新旨意
- 立起居注制——会话事件记录，追踪跨会话历史，tuichao 写入，morning-court 读取 (`1bfb121`)
- 立三省六部一键安装脚本——`install.sh` / `uninstall.sh`，支持 `--minimal`/`--full`/`--dry-run`/`--force` 诸制 (`07822b1`)
- 立英文命名之制，禁中文 Teammate 名以防通信失败——governance-core 纪律 #8 + team-bootstrap + bootstrap-prompts 接线 (`35be254`)

### 🔧 修缮
- 行三层渐进披露之制——6 个 Skill 升级 L2+L3，新增 10 个 L3 文件，governance-core 整体加载，立 CLAUDE.md 三层架构约定 (`45f6282`)
- 修缮安装脚本——修复 sed 注入、settings.json 静默覆盖、Skill 复制吞错诸缺陷

---

## [2026-03-13] — 编年史·开国纪

> 此为开国快照，所记「七道 Hook、十八 Skill」为彼时实况；后续增补见上方各纪（现状为 10 Hook / 26 Skill）。

### 📜 新旨意
- 取法唐制，立三省六部以治 Agent — 创建治理框架、三省分权、六部职责、七道 Hook、十八 Skill、太子为 Lead (`34d3d38`)
- 立编年史 Skill——扫描 git log 按三省六部语境自动归档变更，记开国以来诸事于册 (`a7e045f`)

### 🔧 修缮
- 修缮五部法典 — 细化容错分级、并行策略、覆奏计数、建制自主、工单流转诸制 (`093da4c`)
