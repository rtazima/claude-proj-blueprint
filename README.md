# Claude Proj Blueprint

A modular, level-based project template for teams building software with **Claude Code**, **Obsidian**, and **Figma**.

Pick your maturity level. Plug in your specs. Ship.

---

## Why

Every team reinvents project structure from scratch. This blueprint gives you an opinionated skeleton that scales from solo MVP to autonomous multi-agent systems — without locking you into a specific stack.

```
Level 1 → You and Claude as copilot on a weekend project
Level 4 → Agent teams with self-healing CI and compliance auditors
```

## Maturity Levels

| Level | What | Who it's for | What you get |
|-------|------|-------------|-------------|
| **L1** | ReAct loop | Solo devs, MVPs | `CLAUDE.md` + docs structure + Obsidian vault |
| **L2** | Planner + Executor | Small teams | + Skills (auto-invoked knowledge) + Slash commands |
| **L3** | Multi-agent with critique | Teams in production | + Hooks (automated gates) + Spec review pipeline |
| **L4** | Autonomous system | Mature teams | + Specialized agents + Agent teams + Self-healing |

Each level includes everything from the levels below it.

> **Where do these levels come from?** This framework is a practical synthesis — not invented from scratch. It combines industry frameworks, published research, and hands-on experience building with these tools. See [Influences & Attribution](#influences--attribution) for the full picture.

## Quick Start

```bash
# Clone
git clone https://github.com/rtazima/claude-proj-blueprint.git my-project
cd my-project

# Remove the template's git history and start fresh
rm -rf .git && git init

# Bootstrap at your level
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh --level 2

# Fill in your project specifics
grep -r '\[SPEC\]' CLAUDE.md docs/ .claude/ | head -20

# Open docs/ as an Obsidian vault (optional but recommended)
# In Obsidian: Open folder as vault → select docs/

# Start working
claude
```

## Project Structure

```
your-project/
├── CLAUDE.md                    ← L1+  Hub — Claude reads this first
├── .claude/
│   ├── settings.json            ← L1+  Permissions & safety
│   ├── skills/                  ← L2+  Auto-invoked knowledge packs
│   │   ├── code-review/
│   │   ├── testing/
│   │   ├── implement-prd/
│   │   ├── frontend-agent/      ←      UI generation without Figma
│   │   ├── adr/
│   │   ├── memory/              ←      L4 long-term memory retrieval
│   │   └── _template-skill/     ←      Create your own
│   ├── commands/                ← L2+  Slash commands
│   │   ├── implement.md         ←      /implement <prd-path>
│   │   ├── deploy.md            ←      /deploy
│   │   └── spec-review.md       ←      /spec-review <path>
│   ├── hooks.json               ← L3+  Automated gates
│   └── agents/                  ← L4+  Specialized sub-agents
│       ├── compliance-auditor.md
│       ├── security-auditor.md
│       └── quality-guardian.md
├── docs/                        ← L1+  Obsidian vault
│   ├── product/                 ←      PRDs, vision, roadmap
│   ├── architecture/            ←      ADRs (decision records)
│   ├── specs/                   ←      Modular spec modules
│   ├── design-flow-guide.md     ←      Figma vs Agent vs Hybrid decision
│   └── runbooks/                ←      Deploy, debug, post-mortems
├── src/                         ←      Your code
├── memory/                      ← L4+  Long-term vector memory
│   ├── index.py                 ←      Index project into vector DB
│   ├── query.py                 ←      Semantic search CLI
│   ├── config.yaml              ←      Configuration
│   └── requirements.txt         ←      pip install -r memory/requirements.txt
└── scripts/
    ├── bootstrap.sh             ←      Level-based setup
    ├── lint-check.sh            ←      L3+ post-write hook
    ├── security-check.sh        ←      L3+ pre-bash hook
    └── post-commit-index.sh     ←      L4 auto-index on commit
```

## Spec Modules

Specs are **plug-and-play** knowledge modules in `docs/specs/`. Enable only what your project needs.

| Module | What it covers | When to enable |
|--------|---------------|----------------|
| `compliance/` | Laws, regulations, ISOs | Regulated data, certifications |
| `security/` | OWASP, access control, crypto | Every production project |
| `observability/` | Logs, metrics, traces, alerts | Every production project |
| `scalability/` | Caching, queues, performance | When scale matters |
| `versioning/` | API versions, migrations, semver | Public APIs, multiple clients |
| `design-system/` | Design tokens, component patterns, UI strategy | Projects with UI — makes Figma optional |
| `accessibility/` | WCAG, a11y | User-facing products |
| `i18n/` | Multi-language, localization | International products |
| `testing-strategy/` | Test pyramid, QA process | Teams with 3+ devs |
| `devops/` | CI/CD, IaC, environments | Every production project |
| `data-architecture/` | Modeling, pipelines, analytics | Data-intensive products |
| `ai-ml/` | Models, prompts, evals, guardrails | AI/ML products |
| `long-term-memory/` | Vector DB, semantic search | L4 autonomous systems |

### Adding a custom module

```bash
mkdir docs/specs/my-module
# Use any existing module as reference
# Optionally create .claude/skills/my-module/SKILL.md for auto-invocation
```

## The `[SPEC]` Convention

Every `[SPEC]` marker is an extension point. The blueprint tells you **where** things go; you fill in **what** goes there.

```markdown
## Tech Stack
[SPEC] List the actual project stack:
- Backend: [linguagem + framework]
```

Becomes:

```markdown
## Tech Stack
- Backend: Python + FastAPI
- Frontend: React + TypeScript
- Database: PostgreSQL
```

## How the 4 Layers Work

**L1 — CLAUDE.md** — Claude reads this automatically at every session. Your stack, architecture, conventions, gotchas. Keep it under 200 lines.

**L2 — Skills** — Markdown files that Claude loads based on natural language triggers. Say "write tests" and the testing skill activates automatically.

**L3 — Hooks** — Scripts that run before/after Claude uses tools. Lint on every file write. Security check before every bash command. Exit 0 = allow, exit 2 = block.

**L4 — Agents** — Sub-agents with their own context. Run individually or as a coordinated team with the author-critic loop.

**L4 — Memory** — Vector database indexes `docs/` and `src/` for semantic search. Ask "how did we handle rate limiting?" and get the relevant ADR, code, and PRD. Supports Chroma (local, default) or pgvector (shared, team-wide).

```bash
pip install -r memory/requirements.txt
python memory/index.py              # Index everything
python memory/query.py "auth"       # Semantic search
python memory/query.py --stats      # What's indexed
```

## Daily Workflow

```bash
cd your-project && claude

# L2+
# Shift+Tab+Tab → Plan Mode
# Describe feature intent
# Shift+Tab → Auto Accept
# /compact to compress context
# Commit frequently, new session per feature

# L3+
# /spec-review src/ → run compliance + security + quality audit

# L4+
# /memory search "how did we handle rate limiting"
# "Create an agent team to implement auth with OAuth2"
```

## Integrations

**Obsidian** — Open `docs/` as a vault. PRDs, ADRs, specs are interconnected with `[[wiki-links]]`.

**Figma** (optional) — For teams with a designer. Add Figma links to PRDs, use the Figma MCP server for design-to-code. See the [Design Flow Guide](docs/design-flow-guide.md) to decide if you need it.

**Frontend Agent** (alternative to Figma) — For dev-only teams. Define design tokens in `docs/specs/design-system/`, choose a component library, and the `/implement` command generates UI from PRD requirements. No designer needed.

**GitHub** — Issue templates and CI workflow included.

## Influences & Attribution

The 4 maturity levels in this blueprint are a practical synthesis. They weren't invented in isolation — they combine industry frameworks, published research, and direct experience building products and technology with AI at the center.

### What's original

- The integration of **Obsidian + Claude Code + Figma Make** as a unified workflow
- The specific mapping of Claude Code features (CLAUDE.md, skills, hooks, agent teams) to maturity levels
- The `[SPEC]` convention and modular spec system
- The blueprint structure itself — opinionated on where things go, flexible on what goes there

### What came from the industry

| Source | What it contributed | How it shaped the blueprint |
|--------|--------------------|-----------------------------|
| **Rushika Rai** — AI Agent vs Agentic AI framework | 5 technical maturity levels (Level 0→4) measuring what the agent can do alone | Inspired the level-based structure, but we reframed it: our levels measure how the *human* changes their way of working, not just the agent's capability |
| **OpenAI — Harness Engineering** | The concept that engineers should design environments, constraints, and feedback loops — not write code. AGENTS.md as a map to deeper docs. Architectural guardrails as agent multipliers | Directly influenced L3 (hooks as automated gates) and the CLAUDE.md → docs/ structure. Our Obsidian vault is the equivalent of their structured `docs/` directory |
| **DX Research — Q4/2025 Impact Report** | Data from 135k+ developers across 435 companies on AI adoption, time savings, and quality impact | Validated the progression: most teams are at L1 (copilot). Structured enablement is what moves teams forward, not just tool access |
| **Steven Choi** | Execution vs judgment distinction. Data showing Staff Engineers gain disproportionately more from AI agents. The "agentic context problem" warning | Reinforced why L3 and L4 exist: without governance and memory, L2 generates invisible tech debt at scale |
| **Anthropic — Claude Code architecture** | Skills, hooks, agent teams, CLAUDE.md convention, context compaction | The 4 levels map directly to Claude Code's feature progression: CLAUDE.md (L1) → skills + commands (L2) → hooks (L3) → agent teams + memory (L4) |
| **Mitchell Hashimoto** | The "harness" metaphor — every time an agent makes a mistake, engineer a solution so it never happens again | Shaped the L3 philosophy: hooks and gates aren't bureaucracy, they're compounding improvements |
| **Ruben Hassid** | Playbook for team adoption of Claude in 5 days using Projects and shared context | Informed how we think about L1→L2 transition for teams: adoption is an enablement problem, not a technology problem |

### The synthesis

The key insight that ties it all together: **most frameworks measure what AI can do. This one measures what humans need to change.** An autonomous agent (L4) without the right human governance is just a faster way to generate tech debt. The levels exist to ensure that as AI capability increases, human oversight and context-keeping scale with it.

This is a living framework. As tools evolve and the community contributes, the levels will too. If you've found patterns that should be here, open an issue or PR.

## Recommended Learning

This blueprint gives you the structure, but you need the fundamentals to use it well. All links below come directly from Anthropic's official documentation.

### Start here (all levels)

| What | Link | Why |
|------|------|-----|
| Claude Code overview | [code.claude.com/docs/en/overview](https://code.claude.com/docs/en/overview) | Understand what Claude Code is and choose your environment (CLI, VS Code, Desktop, Web) |
| Quickstart | [code.claude.com/docs/en/quickstart](https://code.claude.com/docs/en/quickstart) | Walk through your first real task: explore a codebase, make changes, commit |
| Best practices | [code.claude.com/docs/en/best-practices](https://code.claude.com/docs/en/best-practices) | Patterns that work, anti-patterns that don't. Read this before writing your first CLAUDE.md |

### Level 1 — Copilot

| What | Link | Why |
|------|------|-----|
| CLAUDE.md and memory | [code.claude.com/docs/en/memory](https://code.claude.com/docs/en/memory) | How to give Claude persistent instructions. The foundation of everything else |
| Common workflows | [code.claude.com/docs/en/common-workflows](https://code.claude.com/docs/en/common-workflows) | Plan mode, auto-accept, /compact, commit patterns |
| Settings | [code.claude.com/docs/en/settings](https://code.claude.com/docs/en/settings) | Permissions, safety, environment variables |

### Level 2 — Planner + Executor

| What | Link | Why |
|------|------|-----|
| Skills | [code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills) | Auto-invoked knowledge packs. How to create, trigger, and scope them |
| Extend Claude Code | [code.claude.com/docs/en/features-overview](https://code.claude.com/docs/en/features-overview) | Map of all extension points: skills, subagents, hooks, MCP, plugins. Know when to use what |
| MCP servers | [code.claude.com/docs/en/mcp](https://code.claude.com/docs/en/mcp) | Connect Claude to external tools (Figma, GitHub, databases). Essential for the Figma Make flow |

### Level 3 — Governance + Quality

| What | Link | Why |
|------|------|-----|
| Hooks guide | [code.claude.com/docs/en/hooks-guide](https://code.claude.com/docs/en/hooks-guide) | Automate gates: lint on write, security check on bash, audit on completion |
| Hooks reference | [code.claude.com/docs/en/hooks](https://code.claude.com/docs/en/hooks) | Full event schemas, JSON input/output, PreToolUse decision control |
| Plugins | [code.claude.com/docs/en/plugins](https://code.claude.com/docs/en/plugins) | Package skills + hooks + agents into shareable, installable units |

### Level 4 — Autonomous System

| What | Link | Why |
|------|------|-----|
| Subagents | [code.claude.com/docs/en/sub-agents](https://code.claude.com/docs/en/sub-agents) | Create specialized agents with custom prompts, tools, permissions, and persistent memory |
| Agent teams | [code.claude.com/docs/en/agent-teams](https://code.claude.com/docs/en/agent-teams) | Multi-agent coordination: lead + teammates, shared tasks, peer-to-peer messaging. Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` |
| Claude Code SDK | [code.claude.com/docs/en/sdk](https://code.claude.com/docs/en/sdk) | Run Claude Code programmatically for CI/CD, automation, and custom orchestration |
| L4 Setup Guide | [docs/l4-setup-guide.md](docs/l4-setup-guide.md) | Step-by-step setup for Agent Teams, memory, and L4 hooks in this blueprint |

### Going deeper

| What | Link | Why |
|------|------|-----|
| How Claude Code works | [code.claude.com/docs/en/how-it-works](https://code.claude.com/docs/en/how-it-works) | Understand the agentic loop under the hood |
| Claude Code changelog | [code.claude.com/docs/en/changelog](https://code.claude.com/docs/en/changelog) | Stay current. Features evolve fast |
| Anthropic Academy | [docs.claude.com/en/docs/anthropic-academy](https://docs.claude.com/en/docs/anthropic-academy) | Free interactive courses from Anthropic |

> **Note:** Claude Code evolves fast. These links were verified against Claude Code v2.1.79 (March 2026). If a link breaks, check the [Claude Code docs homepage](https://code.claude.com/docs/en/overview) for the updated path.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)

## Author

Created by [@rtazima](https://github.com/rtazima).

---

> *"Opinionated on structure, flexible on content."*
