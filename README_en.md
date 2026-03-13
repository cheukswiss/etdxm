<div align="center">

<h1>🏛️ etdxm · Three Departments & Six Ministries · Agent Teams</h1>

<p><em>Governing modern AI agents with ancient wisdom from the Tang Dynasty</em></p>

<p>A multi-agent collaboration governance framework built entirely with <code>.md</code> files<br>Designed exclusively for Claude Code Agent Teams</p>

<p>
<code>👑 Crown Prince triages</code> → <code>📜 Zhongshu plans</code> → <code>🔍 Menxia reviews</code> → <code>📮 Shangshu dispatches</code> → <code>⚔️ Six Ministries execute</code> → <code>📋 Report back</code>
</p>

<p><strong>Zero code · Near-zero deps · Zero infra<br>Claude Code is the runtime</strong></p>

<p>
<a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-22C55E?style=flat-square" alt="License: MIT"></a>
<img src="https://img.shields.io/badge/Claude_Code-Native_Runtime-E86C1D?style=flat-square" alt="Claude Code">
<img src="https://img.shields.io/badge/Agents-10_Dedicated-8B5CF6?style=flat-square" alt="Agents">
<img src="https://img.shields.io/badge/Deps-Near_Zero_(jq)-blue?style=flat-square" alt="Near Zero Deps">
</p>

</div>

---

## 🏮 Motivation — Origin Story

> *"When duties are divided, order prevails; when all power converges, chaos follows."*

### ⚡ Pain Points of Existing Approaches

Claude Code's Agent Teams mechanism makes multi-agent collaboration possible, but the out-of-the-box model is flat — all Teammates are equal peers, directly dispatched by a single Lead. As task complexity grows, this "one ruler governs all" model runs into several problems:

- **No review stage**: Plans go straight to execution with no checks and balances — like an emperor ruling without censors to advise
- **High coordination overhead**: The Lead must plan, dispatch, and summarize all at once — serving as both Secretary and Executor, stretched too thin
- **Hard to guarantee quality**: No independent review role — deliverables go unchecked, quality depends on luck alone

### 🏯 Why the Three Departments and Six Ministries

The Tang Dynasty's Three Departments and Six Ministries system solved analogous problems:

- **Veto mechanism = built-in quality gate**: Menxia holds veto power — proposals must pass review before dispatch, catching flawed designs before execution
- **Tier separation = separation of concerns**: Zhongshu decides, Menxia reviews, Shangshu executes — each with distinct responsibilities, no interference
- **Battle-tested governance wisdom**: This system ran the Tang Dynasty for nearly three centuries — its governance logic has stood the test of time

### 💡 Core Philosophy

- **Pure Markdown definitions**: All roles, processes, and rules defined in `.md` files — no programming language introduced
- **Zero code intrusion**: No modifications to your project code, no runtime dependencies added
- **Claude Code native runtime**: Built entirely on Claude Code's native mechanisms — Agent Teams, Skills, Hooks — no extra infrastructure needed

---

## ✨ Features

> *When every minister fulfills their duty, the realm prospers.*

- **Complete multi-agent governance pipeline**: 10 Agents across a three-tier architecture (Inner Court → Three Departments → Six Ministries), covering the full chain from planning to execution to review
- **Built-in quality assurance**: Veto (Menxia review and rejection) + Re-review (dual post-execution verification) — both proposals and deliverables get independent scrutiny
- **Parallel execution**: Non-conflicting tasks run simultaneously across ministries; within a ministry, Director-Deputy mode supports up to 3 Deputies working in parallel in isolated worktrees
- **24 on-demand Skills**: Like sealed imperial decrees — summoned when needed, filed away after use — zero context waste
- **7 automated governance Hooks**: File protection, dangerous command interception, operation audit — a permanent inspector general, ready out of the box
- **Fault tolerance and circuit breaking**: Timeout retry, failure reassignment, consecutive failures trigger breaker — timeout means dismissal, crash means replacement
- **Morning court system**: `/morning-court` to gather system status and pending tasks in one command, presenting a court report
- **Zero code, zero infrastructure, copy and use**: Drop the files into your project directory, start Claude Code, and begin governance

---

## 🚀 How to Embed in Your Project

> *Three steps to open court and begin governance.*

**Step 1** — Copy the following files to your project root:

```
your-project/
├── CLAUDE.md          ← System declaration, auto-loaded by Claude Code
└── .claude/
    ├── settings.json  ← Hooks registration + environment variables
    ├── hooks/         ← 7 governance Hook scripts
    └── skills/        ← 24 Skill modules (loaded on demand)
```

**Step 2** — Customize configuration in `CLAUDE.md` as needed

**Step 3** — Start Claude Code normally:

```bash
cd your-project
claude
```

Claude Code auto-loads `CLAUDE.md` → loads governance-core Skill → Crown Prince takes position. From then on, every message goes through the full governance pipeline.

---

## ⚙️ Requirements

> *Before opening court, ensure the ceremonial regalia is in order.*

This project is built on Claude Code's Agent Teams architecture and requires enabling the experimental feature:

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

Or add to `.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

### 📦 System Dependencies

Hook scripts (H01-H03) use `jq` to parse JSON input. Please ensure it is installed:

```bash
# macOS
brew install jq

# Ubuntu / Debian
sudo apt-get install jq

# Arch Linux
sudo pacman -S jq
```

> If jq is not installed, Hook scripts will silently degrade (audit logs may record as "unknown") without blocking normal usage.

---

## ⚠️ Considerations

### 💰 Token Consumption — Maintaining a Court Costs More Than Keeping a Single Advisor

> **Important**: The full Three Departments pipeline means multiple Agents are active simultaneously. Each edict passes through the complete chain of planning → review → dispatch → execution → audit → re-review, resulting in **significantly higher token consumption than single-agent usage**. Please fully understand this cost profile before using.

The full governance pipeline involves multiple rounds of multi-agent communication (Crown Prince → Zhongshu → Menxia → Shangshu → Six Ministries → Xingbu audit → Menxia re-review) — this is the price of governance quality.

Rough consumption estimates:

| Task Type | Estimated Token Usage | Notes |
|-----------|----------------------|-------|
| Direct handling / fast_track | Thousands ~ 10K | Simple tasks, skipping the full pipeline |
| Standard edict (single ministry) | 50K ~ 150K | Full pipeline + single ministry execution |
| Complex edict (multi-ministry parallel) | 150K ~ 400K+ | Full pipeline + multi-ministry + re-review |

> **Wise governance balances ambition with economy.** Don't mobilize the entire court to fix a typo — the Crown Prince can handle that directly. But for restructuring core architecture, the full Three Departments pipeline is the prudent path. Use `fast_track` and direct handling wisely to strike the right balance between quality and cost.

### ✅ When to Use — When to Open Court

- **Medium to large development tasks**: Tasks requiring requirements analysis, solution design, multi-module parallel development, and code review
- **Multi-role collaboration**: Tasks naturally involving planning, development, testing, and documentation — requiring division of labor
- **Quality-sensitive projects**: Projects that benefit from proposal review (veto) and post-execution verification (re-review)
- **Refactoring and architecture changes**: Systematic changes across multiple files and modules, requiring global planning and risk assessment

### 🚫 When NOT to Use — No Need to Mobilize the Entire Court

- **Single-file quick edits**: Changing one config line or fixing a typo — the Crown Prince handles it directly, no need to disturb the Three Departments
- **Simple Q&A and chat**: The Crown Prince auto-detects and responds directly, no governance pipeline needed
- **Token-constrained scenarios**: The full pipeline consumes significant tokens; use single-agent mode when budget is tight
- **Latency-critical scenarios**: The full pipeline adds multiple rounds of agent interaction, unsuitable for sub-second response requirements
- **Non-Claude Code environments**: This framework deeply depends on Claude Code's Agent Teams, Skills, and Hooks — it cannot be ported to other platforms

> **Tip**: For simple tasks, the Crown Prince automatically chooses direct handling or fast_track — it won't invoke the full pipeline every time. No need to worry about overkill — the Crown Prince decides for you.

### 🔒 Known Limitations

> **Claude Code's Agent Teams (multi-agent collaboration) is currently an experimental feature**

- Requires Claude Code **>= 2.1.40**
- As an experimental feature, behavior and APIs may change in future versions
- Agent Teams does not support per-teammate model specification (all Agents use the same model)
- This project's parallel execution (Director-Deputy mode) relies on Agent Teams' Teammate mechanism and `worktree` isolation
- Recommended for users with some Claude Code experience; newcomers should familiarize themselves with the basics first

---

## 🏗️ Architecture

> *Inner court triages, Three Departments deliberate, Six Ministries execute — clear hierarchy, each in their place.*

10 Agents across three tiers:

```
                        ┌────────────────────┐
                        │  You (the Emperor)  │
                        └─────────┬──────────┘
                                  │
                        ┌─────────▼──────────┐
                        │ Taizi (Crown Prince)│
                        │      Gateway        │
                        │ Chat / Route Edicts │
                        └─────────┬──────────┘
                                  │
              ┌───────────────────▼───────────────────┐
              │          Three Departments             │
              │                                       │
              │  Zhongshu      Plan & decompose tasks  │
              │       ↓                                │
              │  Menxia        Review & veto            │
              │       ↓              ↑ veto loop        │
              │  Shangshu      Dispatch & coordinate    │
              └───────┬───────┬───────┬───────┬───────┘
                      │       │       │       │
              ┌───────▼───────▼───────▼───────▼───────┐
              │          Six Ministries                │
              │                                       │
              │  Libu_HR Personnel  Hubu   Data       │
              │  Libu    Docs       Bingbu Ops        │
              │  Xingbu  Compliance Gongbu Dev        │
              └───────────────────────────────────────┘
```

**Full Pipeline:**

```
Edict → Taizi triages → Zhongshu drafts → Menxia reviews → Shangshu dispatches → Six Ministries execute
                                ↑                  │
                                └─── veto ─────────┘
                                                            ↓
              Report ← Menxia re-review ← Shangshu summarizes ← Xingbu audits
```

- **Veto** — Menxia can reject Zhongshu's proposals; three consecutive vetoes auto-escalate to you
- **Re-review** — After execution, Menxia verifies outputs match original requirements
- **Parallel** — Non-conflicting tasks execute simultaneously; within a ministry, Director-Deputy mode with isolated worktrees

---

## 👥 Role Overview

> *Ten ministers, each with their own expertise.*

| Tier | Department | Role | Team Role | Responsibility |
|------|-----------|------|-----------|----------------|
| Inner Court | Taizi (Crown Prince) | Gateway | **Lead** | Triage messages: chat directly, route edicts to Zhongshu, ask for clarification |
| Three Depts | Zhongshu (Central Secretariat) | Planner | Teammate | Receive edict → analyze requirements → decompose tasks → draft proposal |
| Three Depts | Menxia (Gate Department) | Reviewer | Teammate | Review proposal → approve / veto and return |
| Three Depts | Shangshu (Executive Department) | Coordinator | Teammate | Parse dependencies → dispatch to ministries → coordinate → summarize report |
| Six Ministries | Libu_HR (Personnel) | HR | Teammate | Agent management, permission assignment, evaluation |
| Six Ministries | Hubu (Revenue) | Data | Teammate | Data processing, resource accounting, reports |
| Six Ministries | Libu (Rites) | Docs | Teammate | Documentation, standards |
| Six Ministries | Bingbu (War) | Ops | Teammate | Deployment, ops, CI/CD, security hardening |
| Six Ministries | Xingbu (Justice) | QA | Teammate | Testing, code review, security scanning, redline enforcement |
| Six Ministries | Gongbu (Works) | Dev | Teammate | Feature development, architecture design, technical challenges |

---

## 🔗 Core Mechanisms

> *The beauty of governance lies in interlocking checks at every stage.*

**🚫 Veto — Menxia's Absolute Veto Power**
If Zhongshu's proposal doesn't pass muster, Menxia sends it back. Three consecutive vetoes on the same proposal auto-escalates to you for a decision. Every proposal must pass through Menxia, no exceptions.

**🔍 Re-review — Post-execution Verification**
After the Six Ministries complete their work, Xingbu performs a technical audit (Redlines R01-R10), then Menxia re-reviews to verify outputs match original requirements. One checks "was it done correctly", the other checks "was the right thing done".

**⚡ Director-Deputy Parallel — One Ministry, Multiple Tasks**
When a ministry receives multiple non-conflicting tasks, it auto-switches to Director mode: up to 3 Deputies work in parallel in isolated worktrees, with the Director merging outputs.

**🛡️ Fault Tolerance — Timeout Means Dismissal, Crash Means Replacement**
Faults are classified into three levels: F1 auto-retry, F2 reassign or redo, F3 escalate. Three consecutive failures within 5 minutes triggers a circuit breaker.

---

## 🎯 Quick Start

> *Morning court, imperial edicts, adjournment — each has its proper ritual.*

etdxm provides a set of `/` commands (Slash Commands) for interacting with the system through court protocol:

| Command | Function | Description |
|---------|----------|-------------|
| `/morning-court` | Morning Court | Crown Prince gathers system status and pending tasks, presents court report |
| `/shengzhi` | Imperial Edict | Structured guidance for issuing formal edicts with complete information |
| `/tuichao` | Adjourn Court | Gracefully shut down all Teammates, summarize session work |
| `/keju` | Imperial Exam | Check Skill configs, Hook syntax, governance-core consistency |
| `/biannian` | Annals | Scan git history, generate court-style CHANGELOG |

You can also issue edicts in natural language — the Crown Prince automatically classifies intent:

```
Help me refactor error handling in this module  # Classified as edict → full pipeline
What does this function do?                     # Classified as chat → direct answer
/shengzhi P0 Fix authentication vulnerability   # Quick edict → urgent pipeline
```

---

## 📜 Skill Modules

> *Twenty-four sealed decrees — summoned on demand, filed after use, claiming not a single seat in court.*

24 Skills loaded on demand, released after use, no context overhead:

| Category | Skill | Trigger |
|----------|-------|---------|
| Emperor Commands | `morning-court` | `/morning-court` — open morning court |
| | `shengzhi` | `/shengzhi` — issue imperial edict with structured guidance |
| | `tuichao` | `/tuichao` — adjourn court, graceful shutdown |
| | `keju` | `/keju` — imperial exam, system health check |
| | `biannian` | `/biannian` — annals, generate CHANGELOG |
| Crown Prince | `intent-classification` | Crown Prince classifies message intent |
| | `team-bootstrap` | First-time Teammate creation guidance |
| | `zouzhe` | Crown Prince presents formal memorial to Emperor |
| | `hanlin` | Web search Claude Code official docs & Issues |
| Three Depts Pipeline | `analysis-framework` | Zhongshu planning / Menxia review |
| | `veto-mechanism` | Menxia veto |
| | `review-coverage` | Menxia re-review |
| | `dispatch-rules` | Shangshu dispatches tasks |
| | `audit-boundaries` | Xingbu audit / Menxia re-review boundary |
| | `special-directives` | Urgent edicts / Emperor's direct orders |
| Format Standards | `ticket-format` | Shangshu work order format |
| | `report-format` | Shangshu report format |
| | `communication-protocols` | Cross-ministry collaboration / exception escalation |
| Rules & Redlines | `redline-reference` | Xingbu redlines R01-R10 |
| | `permission-matrix` | Permission change approval |
| System Operations | `fault-tolerance` | Timeout / failure / circuit breaker |
| | `token-optimization` | Token optimization & context management |
| | `architecture-overview` | Global architecture & ministry role reference |
| | `parallel-execution` | Director-Deputy parallelism |

---

## 🛡️ Hooks Governance Layer

> *The Inspector General stands permanent watch — seven checkpoints, silent guardians.*

7 Hook scripts (`.claude/hooks/`) provide automated governance:

| Hook | Event | Function |
|------|-------|----------|
| H01 Governance File Protection | PreToolUse | Prevent modification of core governance files — touch the throne, face impeachment |
| H02 Dangerous Command Interception | PreToolUse | Block `rm -rf` and other high-risk commands — stay the executioner's blade |
| H03 Operation Audit Log | PostToolUse | Log all tool invocations — the court diary, every action recorded |
| H04 Task Completion Verification | TaskCompleted | Verify delivery conditions |
| H05 Idle Quality Gate | TeammateIdle | Workspace check before going idle |
| H06 Config Change Sentinel | ConfigChange | Block unauthorized config changes |
| H07 Session Lifecycle | SessionStart | Initialize audit environment |

All audit logs are written to `.claude/audit.log` (included in `.gitignore`).

---

## 🤝 Contributing

> *Open the gates wide to talent, gather wisdom from all.*

Contributions welcome: new Skill modules · Agent role optimization · documentation improvements · issue reports. See [Contributing Guide](CONTRIBUTING.md) for details.

---

## 🙏 Acknowledgments

The Three Departments and Six Ministries concept in this project was inspired by [**Edict**](https://github.com/cft0808/edict) — a full-stack multi-agent governance system built on the OpenClaw platform. This project takes the same governance philosophy and deeply adapts it for Claude Code's native mechanisms.

> Thanks to the Edict project and its author for their pioneering work — same philosophy, different paths.

---

## 📄 License

[MIT](LICENSE)
