# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project uses date-based releases (YYYY-MM-DD), not semver.

---

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
