# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project uses date-based releases (YYYY-MM-DD), not semver.

---

## [2026-05-14] — Legacy context discovery

Adds dedicated tooling for context bootstrap on consolidated codebases where
tiered lookup layers 1 (semantic memory) and 2 (structured docs) are empty.
The 6 techniques in `context-engineering` assume those layers contain useful
information. In legacy code with no ADRs, no post-mortems indexed, and
outdated or absent docs, tiered lookup collapses to layer 3 (raw code) and
the cost savings disappear. This release runs *before* `context-engineering`
becomes effective, populating the upper layers from the code itself.

### Added
- **`legacy-context` skill** (`.claude/skills/legacy-context/SKILL.md`) — three-phase archaeology workflow that maps a legacy module, extracts implicit decisions from priority files, and writes discovery notes, ADR candidates, and intent marker suggestions into the empty upper layers. Read-only for source code (`allowed tools: Read, Grep, Glob, Bash, Write`, no Edit). Phase 1 survey uses `git log` to find hot files (most commits in last 12 months) and cold files (untouched 6+ months). Phase 2 discovery captures purpose, apparent decisions, critical dependencies, and risks per priority file, suggests intent markers from the `intent-markers` vocabulary as a patch. Phase 3 promote detects patterns appearing 3+ times, drafts ADR candidates in `docs/architecture/_candidates/`, runs `memory/index.py --incremental`.
- **`/discover <path>` slash command** (`.claude/commands/discover.md`) — activates the `legacy-context` skill scoped to a module, directory, or file. Use before `/implement` or `/refactor` on legacy modules.
- **Magic keyword detection** in `scripts/magic-keywords.sh` — phrases "legacy code", "código legado", "sistema antigo", "discover module", "arqueologia", "código sem documentação" auto-activate the skill.
- **Output paths** for discovery artifacts: `memory/discoveries/<module-slug>-survey.md` (territory map), `memory/discoveries/<module-slug>/<file-slug>.md` (per-file notes), `memory/discoveries/<module-slug>/markers.patch` (intent marker suggestions for human review), `docs/architecture/_candidates/adr-XXX-<topic>.md` (ADR drafts).

### Changed
- `.claude/skills/context-engineering/SKILL.md` — added "When upper layers are empty" section between Red Flags and References. Names the assumption the 6 techniques make about tiered lookup, lists three signals that bootstrap is needed (memory query returns nothing, no ADRs cover the module, original authors left), points to `legacy-context` skill.
- `CLAUDE.md` — `/discover` added to slash commands list. Magic keywords list extended with legacy-context triggers.
- `README.md` — `legacy-context/` added to skills tree (after `incoherence-detector/`), `discover.md` added to commands tree, counts updated to 19 skills and 11 commands.

### Rationale
Most public Claude Code blueprints today address greenfield or modern codebases. The techniques work because layers 1 and 2 of tiered lookup are either populated as the project grows, or skipped without much loss. In consolidated companies with codebases older than 5 years, no ADRs, partial docs, and original authors gone, those layers are empty from day one. Context engineering as documented in the existing skill cannot operate. This release names that gap and provides the bootstrap step that makes the rest of the framework usable in that environment.

### Not yet done
- Stack-specific discovery heuristics (e.g., ASP.NET controllers, EF Core repository pattern, Spring services). The current skill is stack-agnostic.
- Diff comparison: measure context savings before/after running `/discover` on a module. Planned as separate skill.
- Promotion of discovery notes to global cross-project memory. Currently project-scoped only.

### v1.1 — Remote discovery via GitHub CLI

Adds **Phase 3: Remote Discovery** to the `legacy-context` skill. Phase numbering renumbered to 1–5 for explicit ordering (Pre-flight, Survey, Remote Discovery, Local Discovery, Promote). The original 3-phase v1 is fully subsumed.

Motivation: in repositories older than 5 years, a substantial portion of design context lives in PR review comments and closed issues, not in `git log`. Reviewers write things like "this is temporary, see issue #234" and the actual reasoning lives in the issue thread. Pure local archaeology (v1) cannot reach that content. This release adds GitHub CLI (`gh`) integration to capture it.

#### Added in v1.1
- **Phase 1: Pre-flight** — validates `gh auth status`, confirms repo is on GitHub, estimates PR/issue volume. Sets internal flag controlling Phase 3.
- **Phase 3: Remote Discovery** — iterates every file with PR history in the path (full coverage, no top-N cap). For each file, fetches every PR that touched it including title, body, review comments, inline comments, reactions. Classifies each PR by discussion density (Cosmetic, Key, Moderate, Quiet) and writes a per-file remote context document. Generates three aggregate files per module: `<module>-issues.md`, `<module>-releases.md`, `<module>-remote-summary.md`. Skipped gracefully if `gh` is unavailable or repo is not on GitHub.
- **Cross-reference in Phase 4** (Local Discovery) — each discovery note now includes a "Remote context" section that summarizes Key PRs and pulls verbatim review comments capturing decision rationale.
- **Pattern detection in Phase 5** (Promote) — ADR candidates now consult both local discovery notes and `<module>-remote-summary.md`. Patterns recurring across PR discussions are valid sources for candidates.
- **Intent marker references** — markers suggested in the patch now include PR/issue references in their justification comments (e.g., `// :HACK: temporary per PR #234`).

#### Changed in v1.1
- Survey window extended for old codebases: hot files use both 24-month and all-time windows; cold threshold raised from 6 months to 3 years; commit message scan increased from 10 to 20 entries per file.
- Workflow renumbered to 5 phases (was 3). Phase 1 of v1 → Phase 2 of v1.1; Phase 2 of v1 → Phase 4 of v1.1; Phase 3 of v1 → Phase 5 of v1.1.
- Discovery note structure adds a fifth section: "Remote context".

#### Stratification by density, not count
Remote Discovery does not cap PRs at top-N. Instead, every PR that touched the file is captured and classified:

| Tier | Criteria | Output |
|---|---|---|
| Cosmetic | Only docs/test files, OR diff < 20 lines with 0 review comments | Excluded entirely |
| Key | 5+ review comments (summary + inline), OR mentioned in a release note, OR 2+ reactions on review comments, OR contains "decision/architecture/breaking" | Full body + top comments + inline comments + reactions |
| Moderate | 2–4 review comments | Body + review comments listing |
| Quiet | 0–1 review comments, not Cosmetic, not Key | One-line entry in inventory |

#### Operating principle
Bias toward completeness. In consolidated codebases, the contextual gem is usually the comment buried in a 6-year-old PR review. Missing it is a worse failure than producing verbose discovery notes.

#### Not yet in v1.1
- GitLab and Bitbucket equivalents (currently GitHub-only via `gh`).
- Wiki/Confluence/Jira/Slack integration. Remote discovery is currently scoped to PRs, issues, and releases.
- Rate-limit-aware streaming (skill currently fetches inventory in bulk; in repos with 20k+ PRs this may approach `gh` quotas).
- Stack-specific heuristics (.NET, Java, Spring, EF Core, etc). Skill remains stack-agnostic.

### v1.2 — Azure DevOps support

Adds multi-provider remote discovery. Phase 3 becomes polymorphic, branching internally by provider while producing identical output structure regardless of which remote backs the repository.

Motivation: GitHub-only tooling for context engineering is a known gap in the enterprise space. Brazilian consolidated companies commonly host code on Azure DevOps and Bitbucket. The v1.1 release skipped Phase 3 gracefully for non-GitHub repos, but skipping cost the user the most valuable part of the skill (PR review discussions and issue threads). This release adds Azure DevOps as the second supported provider, using `az` CLI plus direct REST calls. The provider abstraction is the foundation; further providers (GitLab, Bitbucket) follow the same pattern.

#### Added in v1.2
- **Provider detection** in Phase 1 — parses `git remote get-url origin`, identifies github/azure_devops/unknown, sets `provider` for Phase 3 to branch on.
- **Phase 3b: Azure DevOps branch** — full mirror of Phase 3a using `az repos pr list/show`, `az repos pr show-work-items`, `az boards work-item query/show`, and direct REST calls for threads (Azure equivalent of inline review comments). Same Cosmetic/Key/Moderate/Quiet classification, same per-file and aggregate output files.
- **WIQL queries** for work item discovery in Phase 3b, mapped to the "issues" module aggregate.
- **Git tag fallback** for releases in Azure DevOps environments (Azure Pipelines Releases is a separate concept rarely used for release notes).
- **Pagination handling** for Azure DevOps `az repos pr list`, since it does not expose `totalCount` directly.
- **Rate limit handling** for Azure DevOps (~200 req/sec/user with typical PAT; pause-and-retry on 429, abort after 3 retries).
- **PAT precondition documentation** in the skill: `AZURE_DEVOPS_EXT_PAT` must be exported in the shell that launched Claude Code.

#### Changed in v1.2
- Phase 1 (Pre-flight) now detects and validates per provider. Output prints `provider` alongside repo identifier and volume estimate.
- Phase 3 is now polymorphic. Phase 3a (GitHub) keeps the v1.1 logic intact. Phase 3b (Azure DevOps) is new. Both produce the same downstream artifacts.
- Phase 5 summary now prints which provider was used (or `skipped` if Phase 3 was bypassed).
- Discovery notes (Phase 4) cross-reference work items in addition to GitHub issues, with consistent terminology in the output ("Issue" used as umbrella term).

#### Provider differences preserved in the design
| Aspect | GitHub | Azure DevOps |
|---|---|---|
| Inline review comments | PR comments with line context | Threads with `threadContext` |
| Issues equivalent | Issues | Work Items (Bug/User Story/Task/etc) |
| Reactions on comments | Yes (used as Key signal) | No (criterion dropped in 3b) |
| Release notes | `gh release list/view` | Git tags as fallback |
| Author identity | `@handle` | `displayName` |

#### Not yet in v1.2
- GitLab provider (next likely addition; uses `glab` CLI).
- Bitbucket provider.
- Self-hosted GitHub Enterprise or Azure DevOps Server (on-premise) — should mostly work but not validated.
- Stack-specific heuristics (.NET, Java, Spring, EF Core, etc). Skill remains stack-agnostic.
- Wiki/Confluence/Jira/Slack integration. Remote discovery is currently scoped to PRs/MRs, issues/work-items, and releases/tags.

### v1.3 — Hotfix: az login not required for Azure DevOps auth

Removes the dependency on `az account show` in Phase 1 auth validation for the Azure DevOps provider. The v1.2 check assumed an active Azure Cloud subscription, which many Azure DevOps users do not have. Phase 1 now validates DevOps access directly via `az repos pr list`, which reflects what the skill actually consumes.

#### Changed
- Phase 1 auth validation for `azure_devops` provider: replaced `az account show` + `az repos list` with a single `az repos pr list --repository "$REPO" --status all --top 1` call. PAT in `AZURE_DEVOPS_EXT_PAT` is the only auth requirement.
- "Supported remote providers" table updated: note that `az login` is not required for Azure DevOps.
- New racionalização added: "Preciso de `az login` antes de rodar a skill em Azure DevOps" → no, PAT alone suffices.
- `discover.md` command documentation updated to drop the `az login` precondition.

#### Why this matters
Discovered in field validation against a real Azure DevOps repo: in Brazilian consolidated companies, Azure DevOps is frequently adopted standalone, without an Azure Cloud subscription. For these users, `az login` completes the browser auth but `az account show` reports "Please run 'az login' to setup account" because there is no Azure subscription. Under v1.2, this would falsely set `remote_discovery=false` and skip Phase 3 entirely, defeating the v1.2 release for the most common Azure DevOps user profile.

#### Not changed
- All other Phase 3b logic remains intact.
- No changes to GitHub provider path.
- No changes to output structure.
- No changes to other phases.

### v1.4 — Field-informed adaptations

Incorporates four learnings from running v1.3 against a real Azure DevOps / .NET / PostgreSQL legacy at FaceSign. Three modules discovered (Core, Infra.Data, ExternalServices); all three exhibited patterns the v1.3 design did not anticipate. This release codifies the response without changing the core philosophy: defaults still bias toward completeness, but the skill is now smarter about detecting situations where completeness has low return.

#### Added in v1.4
- **Trunk-based culture detection** in Phase 1 — measures PR coverage of commits in the path. If `< 30%` of commits are linked to any PR, sets `trunk_based_detected=true`, which expands the Phase 4 commit message scan window from 20 to 40 entries. Field evidence: FaceSign has 3 years of commits with zero PRs (Jan 2023 – Mar 2026). When this is the case, decision history lives in commit messages, not in PR review threads, and the wider scan compensates for the absent remote layer.
- **Phase 3 early-exit heuristic** (disabled by default) — when enabled, samples the 5 most recent PRs touching the path and counts human review comments (filtering known bots: DeepSource, SonarCloud, GitHub Actions, Dependabot, Renovate, Codecov, Codacy, GitGuardian, Snyk, and others). If none have 2+ human comments, Phase 3 runs in "lean mode" capturing only PR titles, bodies, authors, dates, and linked work items, skipping the expensive thread fetching and per-file remote context generation. Reduces Phase 3 time from 6-15 min to 1-2 min on repos without PR review culture. **Disabled by default** to preserve the bias toward completeness. Field evidence: FaceSign Phase 3 took 6-15 min per module to conclude all PRs were Quiet.
- **Memory infrastructure detection** in Phase 1 — checks for `memory/index.py` and `memory/query.py` at the start, not at the end of Phase 5. Prints orientation message early ("not detected — discovery notes will be plain files, no semantic search across sessions"). Phase 5 still tries to index and now writes a "Memory indexing" section in the module summary documenting the status and recovery instructions.
- **Auto-creation of ADR template** in Phase 5 — if `docs/architecture/adr-000-template.md` does not exist, the skill creates a minimal Nygard-simplified template before writing candidates. Avoids inconsistent ADR formatting when the target project has no prior ADR practice.
- **`Tuning` section** in the skill documenting four configurable flags with rationale: `early_exit_enabled`, `trunk_based_threshold_pct`, `early_exit_sample_size`, `early_exit_comment_threshold`. Each can be overridden via env var (e.g., `LEGACY_CONTEXT_EARLY_EXIT=true claude`).
- **`ROADMAP.md`** at the repo root, documenting future considerations explicitly out of scope for v1.4 (stack-specific heuristics, GitLab/Bitbucket providers, self-hosted instances, plugin architecture, wiki/Jira integration, incremental discovery, quality metrics, cross-project discovery). Living document for the broader blueprint, not just legacy-context.

#### Changed in v1.4
- Operating principle section explicitly references the new tunable defaults.
- Phase 1 pre-flight summary now includes `trunk_based_detected`, `memory_infra`, `early_exit_enabled` alongside the existing fields.
- Phase 4 commit scan window is now conditional on `trunk_based_detected`.
- Phase 5 indexing failure now writes documentation to the module summary instead of just printing a warning.
- Four new racionalizações added covering the new flags and behaviors.
- `discover.md` command documentation updated with the new tunable env vars.

#### Field-observed behaviors that informed this release
Three modules of FaceSign (Core, Infra.Data, ExternalServices) were discovered with v1.3. Across all three:
- 48 PRs total in the repo, 0 classified as Key, 1 as Moderate (where the comments were a DeepSource bot), 47 as Quiet. Zero human review comments on any PR.
- 3 years of commit history (Jan 2023 – Mar 2026) with zero PRs.
- Memory infrastructure absent in the target project; warning was discrete in v1.3 and easy to miss.
- ADR template absent in the target project; v1.3 wrote candidates with inconsistent structure.
- Phase 3 consumed 6-15 minutes per module producing aggregate files showing "all Quiet."

These observations did not invalidate the skill — Phase 4 still surfaced critical security and architecture findings in all three modules. But they showed that the skill could be more aware of the environment it runs in. v1.4 codifies that awareness without changing the operating principle.

#### Not in v1.4 (see ROADMAP.md)
Stack-specific heuristics (deferred until 3+ stacks are validated). GitLab/Bitbucket providers (no concrete user yet). Self-hosted instance support (untested). Plugin architecture for Phase 3 (premature). Wiki/Confluence/Jira integration (different APIs per system, demand-driven). Incremental discovery (storage design open question). Cross-project discovery (hard scoping problem). Discovery quality metrics (planned for a future observability release alongside `/context stats`).

---

Anthropic launched Claude Design (research preview, Pro/Max/Team/Enterprise).
Its "Send to Claude Code" button produces a `PROMPT.md` bundle — a native
Claude-Code handoff that the Blueprint now reconciles against PRD + CLAUDE.md.

### Added
- **`claude-design-handoff` skill** (`.claude/skills/claude-design-handoff/SKILL.md`) — parses PROMPT.md from Claude Design, reconciles against PRD and CLAUDE.md, produces reconciliation report before coding. Strict precedence: PRD > CLAUDE.md > PROMPT.md (never silently adopt PROMPT.md conventions). Includes Racionalizações + Red Flags sections.
- **Option A — Claude Design flow** in design section of CLAUDE.md and `docs/design-flow-guide.md`. Existing Figma flow becomes Option B, Agent flow becomes Option C, Hybrid becomes Option D with auto-detection of artifact type per PRD.
- **`docs/design/` convention** — location for `<prd-slug>-PROMPT.md` bundles from Claude Design.
- **Security posture section** (`docs/specs/security/README.md`) — data review checklist before enabling Claude Design, treatment of PROMPT.md as untrusted data, policy recommendations on commit vs. gitignore.
- **Bootstrap option 1** — `./scripts/bootstrap.sh --design claude-design` scaffolds skill + directory + CLAUDE.md marker.

### Changed
- `.claude/commands/implement.md` — design flow detection reorders: PROMPT.md first, Figma link second, agent fallback last.
- `docs/design-flow-guide.md` — expanded from 3 to 4 flows, added Claude Design trade-offs table, decision checklist updated with Claude Design questions, manual setup instructions extended.
- `scripts/bootstrap.sh` — prompt expanded from 4 to 5 options (added Claude Design at position 1), hybrid flow now sets up all three sources.
- `CLAUDE.md` — Design section reorganized around 4 options with explicit precedence rule.

### Not decided yet (waiting on Anthropic)
- MCP server for Claude Design — roadmap but not shipped. Handoff is file-based until then.
- Programmatic API for CI/CD — design generation still manual via UI.

---

## [2026-04-13] — Cross-project memory, conversation mining, tiered lookup

Patterns extracted from analysis of [lucasrosati/claude-code-memory-setup](https://github.com/lucasrosati/claude-code-memory-setup).

### Added
- **Cross-project memory** — global memory layer at `~/.claude/memory/global/` shared across all projects. ADRs, post-mortems, and learner reports auto-promote from project to global memory on index. Search with `--global` or `--both` (merged by relevance). Config via `global_memory` section in `memory/config.yaml`. Enables "how did we solve X in project A?" from project B.
- **Conversation mining** — new Phase 5 in learner skill + `--conversations N` flag in `/learn` command. Mines past Claude session transcripts (`~/.claude/projects/`) for undocumented decisions, recurring corrections, knowledge gaps, and workarounds that should be formalized. Signal→Action table for what to look for in transcripts.
- **Tiered lookup** — new technique #6 in context-engineering skill. 4-layer hierarchy: memory (semantic search, ~50 tokens) → docs (grep, ~200 tokens) → code (read file, ~500-2000 tokens) → global memory (cross-project, ~50 tokens). Rule: only descend if previous layer didn't answer.

### Changed
- `memory/index.py` — added `promote_to_global()` function: after project indexing, copies ADR/post-mortem/learner chunks to global store with project name prefix for uniqueness.
- `memory/query.py` — added `--global` and `--both` CLI flags. `--both` merges project + global results sorted by similarity. `format_for_agent()` now includes scope label.
- `memory/config.yaml` — added `global_memory` section (enabled: false by default, configurable persist_dir and source types).
- `.claude/commands/memory.md` — documented `--global` and `--both` flags.
- `.claude/commands/learn.md` — documented `--conversations N` flag.
- `.claude/skills/memory/SKILL.md` — added global search examples.
- `docs/specs/long-term-memory/README.md` — expanded from 3-layer to 4-layer architecture. Added cross-project memory section with what promotes vs what stays project-only.
- `CLAUDE.md` — Memory section updated with global/both/conversations commands.

---

## [2026-04-11] — Agent discipline: anti-rationalization, boundaries, new skills

Patterns incorporated from analysis of [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills).

### Added
- **Source-driven development skill** (`.claude/skills/source-driven-development/`) — forces agents to verify framework-specific decisions against official docs, not training data. Rules: detect stack versions, fetch docs before coding, cite sources, mark UNVERIFIED when docs unavailable. Source hierarchy: official docs > source code > migration guides > examples > UNVERIFIED.
- **Context engineering skill** (`.claude/skills/context-engineering/`) — proactive context window management. Target <2,000 lines per task, load on demand, forget aggressively. 5 techniques: task decomposition, strategic reading, checkpoints, progressive disclosure, memory offloading. Complements the reactive `context-guard` hook.
- **"Not Doing" list in PRD writer** — new mandatory step 4 in PRD workflow: explicitly document what was chosen NOT to build and why. Added to quality checklist ("Not Doing list with at least 3 items and justifications"). Prevents scope creep by making exclusions visible.
- **Three-tier boundaries in agents** — all 4 agents (security-auditor, compliance-auditor, quality-guardian, performance-auditor) now have `## Boundaries` with Always Do / Ask First / Never Do sections. Defines clear guardrails for autonomous vs. human-gated decisions.
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
- **8 commands**: /implement, /deploy, /memory, /spec-review, /debug, /refactor, /debt, /clean
- **3 agents**: security-auditor, compliance-auditor, quality-guardian
- **3 hooks**: docs-check.sh, lint-check.sh, security-check.sh
- **Memory layer** with Chroma support for L4
- **Bootstrap script** with maturity level prompts
