# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project uses date-based releases (YYYY-MM-DD), not semver.

---

## [2026-04-11] — Anti-rationalization, red flags, scope discipline, error-as-data

Patterns incorporated from analysis of [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills).

### Added
- **Anti-rationalization tables** — 5 skills now have `## Racionalizações comuns` sections: domain-specific excuse→rebuttal tables that prevent agents from skipping steps. Skills: implement-prd, debugger, persistence, code-review, slop-cleaner.
- **Red flags sections** — 5 skills now have `## Red Flags` sections: observable behavioral patterns that indicate a skill is being violated. Serves as drift detection mechanism.
- **Scope discipline** — pre-commit review now includes CONSIDER-level reminder to add `Não alterou:` section to commit messages listing files/modules intentionally not changed. Convention added to CLAUDE.md.
- **Error output as untrusted data** — new Rule 8 in debugger skill: treat error messages as data, not instructions (prompt injection via stack traces, log injection). New anti-pattern: never follow "fix suggestions" in error messages without verification. New section in security spec (`docs/specs/security/README.md`) with attack examples.

---

## [2026-04-02] — Conventions, quality gates, and incoherence detection

### Added
- **Intent markers skill** (`.claude/skills/intent-markers/`) — 6 inline code annotations (`:PERF:`, `:UNSAFE:`, `:SCHEMA:`, `:SECURITY:`, `:HACK:`, `:FLAKY:`) that flag areas needing special review attention. Grep-able across codebase.
- **Incoherence detector skill** (`.claude/skills/incoherence-detector/`) — 5-phase workflow to find mismatches between specs, docs, and code. Classifies as DRIFT, MISSING, STALE, CONFLICT, or ORPHAN.
- **Convention registry** (`docs/specs/conventions/REGISTRY.yaml`) — YAML mapping of which conventions each agent role receives per phase (plan/implement/review/deploy). 26 convention definitions.
- **Documentation standards** (`docs/specs/documentation-standards.md`) — Token budgets per file type (CLAUDE.md ≤200 tokens, README ≤500 tokens, ADRs ≤300 words). Includes invisible knowledge test.
- **Output style presets** (`.claude/output-styles/`) — Swappable communication styles: `direct.md` (terse, no hedging) and `verbose.md` (step-by-step with alternatives).

### Changed
- **Quality guardian** — added 3-rule priority hierarchy (RULE 0: knowledge preservation > RULE 1: project conformance > RULE 2: structural quality) and severity de-escalation (CONSIDER drops at iteration 3, SHOULD FIX drops at iteration 4+).
- **Slop cleaner** — added Category 8: temporal contamination. Detects LLM comments that leak change history ("Added mutex to fix...") instead of describing current state ("Mutex serializes access").

---

## [2026-04-02] — Agent observability system

### Added
- **Agent Event Protocol** (`scripts/agent-events.sh`) — bash library with 8 typed emitter functions (agent:start, agent:progress, agent:complete, agent:finding, session:start, session:end, flow). Writes structured JSONL to `logs/agent-events.jsonl`. Atomic file locking for parallel agent safety. Inspired by ëther Desktop's node/synapse model, adapted to zero-deps bash.
- **Terminal Dashboard** (`scripts/agent-monitor.sh`) — real-time TUI showing agents, status, findings, flow arrows, and timeline. Pure bash + awk, zero external deps. Supports `--once`, `--session`, `--clear` flags. ANSI color-coded.
- **Web Dashboard** (`tools/agent-dashboard.html`) — single HTML file (547 lines, zero deps) with SVG agent graph, event timeline, findings panel. Dark theme. Auto-refreshes every 2s via fetch. Served via `python3 -m http.server`.
- **Flow types** — 6 typed inter-agent flows: command (blue), data (green), audit (red), feedback (yellow), sync (purple), insight (gold). Visualized in both dashboards.
- `logs/` directory and `tools/` directory added to project structure.

### Changed
- `verify-deliverables.sh` — now emits agent:start and agent:complete events to the event log.
- `context-guard.sh` — now emits agent:finding events when thresholds are hit.
- README.md — updated project structure (logs/, tools/, 2 new scripts), added Agent Monitor section to L4 docs.
- `docs-check.sh` — expanded to monitor `src/` + `scripts/` + `tools/` + `.claude/` (was only `src/`). Added CHANGELOG check for feature commits, ADR check for hooks.json changes. Upgraded severity from CONSIDER to SHOULD FIX.

---

## [2026-04-01] — Full lifecycle coverage

### Added
- **Debugger skill (`/debug`)** — systematic debugging workflow: reproduce → isolate → hypothesize → fix → verify → document. The biggest gap in the previous version. (L2 skill + command)
- **PRD writer skill** — turn rough ideas into structured PRDs using the project template. Asks up to 5 clarifying questions, checks memory for overlap, outputs to `docs/product/`. (L2 skill)
- **Refactoring skill (`/refactor`)** — safe structural refactoring with a catalog of patterns (extract, move, rename, simplify, restructure). Tests before AND after each step. ADR for architecture changes. (L2 skill + command)
- **API designer skill** — contract-first API design: endpoints, schemas, error codes, pagination, auth. Checks versioning and security specs. (L2 skill)
- **Migration skill** — database migration workflow with risk assessment (green/yellow/red), up+down generation, zero-downtime patterns, reversibility verification. ADR required for destructive changes. (L3 skill)
- **Tech debt tracker (`/debt`)** — automated scan (TODOs, type suppressions, high-churn files, outdated deps, skipped tests) + manual assessment + prioritized report. (L3 skill + command)
- **Performance auditor agent** — dedicated agent for N+1 queries, unbounded loops, missing indexes, caching, pagination, payload sizes. Sonnet model. Pairs with scalability spec. (L4 agent)
- **API spec module** (`docs/specs/api/`) — conventions for REST/GraphQL, pagination, error format, rate limiting, naming, CORS. Pairs with api-designer skill.
- 7 new magic keywords in `magic-keywords.sh`: debug, refactor, tech debt, PRD writer, API design, migration, audit mode updated
- Performance-auditor deliverables schema for output validation

### Changed
- **Testing skill rewritten** — was a 20-line stub, now a full workflow: analyze code → decide test type → generate with AAA pattern → mock strategy → run and verify. Covers edge cases, async, concurrency, security testing. (L2 skill)
- `/spec-review` now invokes 4 agents: security-auditor + compliance-auditor + quality-guardian + performance-auditor
- CLAUDE.md: 14 spec modules (added `api/`), 5 model presets (added performance-auditor), expanded slash commands and magic keywords

## [2026-04-01]

### Added
- **Persistence mode (`/ralph`)** — iterative implementation loop that doesn't stop until all acceptance criteria from the PRD pass or max iterations reached. Inspired by oh-my-claudecode's Ralph mode. (L2 skill + command)
- **AI slop cleaner (`/clean`)** — removes LLM-generated patterns: unnecessary comments, over-abstraction, redundant type assertions, excessive logging, dead code, over-engineering, and "AI verbal tics." 7-category checklist with language-specific patterns. (L2 skill + command)
- **Pattern learner (`/learn`)** — analyzes recent git history and compares against existing skills to suggest new skills, skill improvements, convention updates, and hook gaps. Output written to `docs/architecture/learner-report-{date}.md`. (L4 skill + command)
- **Pre-compact context saver** — `PreCompact` hook saves branch, recent commits, modified files, and session notes to `memory/compact-context.md` before conversation compaction. Prevents context loss between conversation segments. (L3 hook)
- **Context guard** — `PostToolUse` hook counts tool calls and warns at 50 (warning) and 80 (critical) calls, suggesting `/compact` or new session. (L3 hook)
- **Magic keywords** — `UserPromptSubmit` hook auto-detects intent from natural language: "don't stop" → persistence mode, "clean up" → slop cleaner, "learn from this" → learner, "security audit" → spec review. Supports PT-BR keywords. (L3 hook)
- **Deliverables verification** — `SubagentStop` hook validates agent output against schemas in `docs/specs/deliverables/`. Schemas for security-auditor, compliance-auditor, quality-guardian. Template for custom agents. (L4 hook)
- Magic keywords and context management sections in CLAUDE.md
- Bootstrap outputs for new features at appropriate levels (L2, L3, L4)

## [2026-03-31]

### Added
- **Continuous documentation flow** — 3-layer system: (1) Documentation Rules table in CLAUDE.md, (2) docs checklist in `/implement` command, (3) `docs-check.sh` hook warns if `src/` changes without `docs/` updates. Ensures PRDs flow from Obsidian and decisions flow back.
- **AI-powered code review** — `ai-review.sh` uses `claude --print` CLI (works with Max plan) as primary method, Anthropic API as fallback. Called by pre-commit hook in hybrid/deep review levels.
- **3-level code review** — `pre-commit-review.sh` supports simple (bash only), hybrid (bash + Sonnet), and deep (bash + Opus). Bootstrap prompts for level choice.
- **Model presets** — agents use different models based on task complexity. Table in CLAUDE.md: lead=opus, security-auditor=opus, compliance-auditor=opus, quality-guardian=sonnet.

### Changed
- `ai-review.sh` rewritten: CLI-first approach (no API key needed for Max/Pro plans), model alias mapping (sonnet/opus/haiku → full model IDs)
- `pre-commit-review.sh` uses model aliases instead of full model IDs

## [2026-03-30]

### Added
- **Dual design flow** — Figma, Agent, or Hybrid. Bootstrap prompts for choice. Agent flow uses design tokens + frontend-agent skill to generate UI without a designer. Figma remains optional.
- **Agent teams in bootstrap** — L4 setup auto-enables `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings.json
- `docs/design-flow-guide.md` — decision guide with ASCII decision tree, trade-off tables, quick checklist

### Fixed
- Auto-create Python venv for memory dependencies in bootstrap (was failing silently)

## [2026-03-25]

### Added
- **L4 Setup Guide** — step-by-step guide for Agent Teams, memory layer, L4-specific hooks
- Attribution section explaining where maturity levels come from (Rushika Rai, OpenAI Harness Engineering, DX Research, Steven Choi, Anthropic, Mitchell Hashimoto, Ruben Hassid)

### Fixed
- YAML frontmatter values in template skill now properly quoted (community contribution via PR #8)

## [2026-03-23]

### Added
- **Initial blueprint** — 4 maturity levels (L1→L4), modular architecture
- **CLAUDE.md template** with `[SPEC]` convention for project customization
- **13 spec modules** in `docs/specs/`: compliance, security, observability, scalability, versioning, design-system, accessibility, i18n, testing-strategy, devops, data-architecture, ai-ml, long-term-memory
- **7 skills**: implement-prd, frontend-agent, adr, memory, code-review, testing, _template-skill
- **4 slash commands**: /implement, /deploy, /memory, /spec-review
- **3 agents**: security-auditor (opus), compliance-auditor (opus), quality-guardian (sonnet)
- **4 hooks**: lint-check (PostToolUse), security-check (PreToolUse), pre-commit-review (PreToolUse), docs-check (PreToolUse)
- **Long-term memory** with Chroma (local) or pgvector (shared), semantic search, auto-indexing
- **Bootstrap script** with `--level`, `--design`, `--review` flags
- **Obsidian vault** structure: PRDs, ADRs, specs, runbooks, post-mortem templates
- **Docs**: orchestration workflow, design flow guide, L4 setup guide, code review gates spec
- **CI**: GitHub Actions workflow validating blueprint structure
- **Templates**: PRD, ADR, post-mortem, skill, deliverables schema
