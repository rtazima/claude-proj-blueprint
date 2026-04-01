# [SPEC] Project Name

## Project
[SPEC] Describe the project in 2-3 lines.
See `docs/product/vision.md` for the full product vision.

## Tech Stack
[SPEC] List the actual stack. Example:
- Backend: [language + framework]
- Frontend: [language + framework]
- Database: [database]
- Tests: [test frameworks]
- Package manager: [manager]

## Architecture
- `/src` → production code
- `/docs` → Obsidian vault (PRDs, ADRs, specs, runbooks)
- `/.claude/` → skills, commands, agents, hooks

### Documentation directories
- `/docs/product/` → PRDs, personas, roadmap
- `/docs/architecture/` → ADRs (Architecture Decision Records)
- `/docs/specs/` → modular project specifications
- `/docs/runbooks/` → deploy, debug, onboarding, post-mortems

## Code Conventions
[SPEC] Define your team's conventions. Example:
- Style: [linter, formatter, rules]
- Types: [typing policy]
- Commits: Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`)
- Branches: `feature/`, `fix/`, `docs/`, `refactor/`
- PRs: always with description, reference PRD/ADR when applicable

## Commands
[SPEC] Day-to-day commands. Example:
- `[dev command]` → dev server
- `[test command]` → tests
- `[lint command]` → lint

## Workflow Rules
[SPEC] Workflow rules. Example:
- Always run tests before committing
- Never commit secrets
- Every UI component follows the design system

### Documentation Rules
Every change that affects the product MUST be documented back to the Obsidian vault (`docs/`).
PRDs come from Obsidian, implementation flows through code, and decisions go back to Obsidian.

| What changed | What to update |
|---|---|
| New feature or module | CLAUDE.md module map + README project structure |
| New env vars | `.env.example` with defaults and comments |
| Architectural decision | ADR in `docs/architecture/` (next sequential number) |
| Production bug | Post-mortem in `docs/runbooks/post-mortems/` |
| Business insight during implementation | Note in the relevant PRD (`docs/product/`) |
| API/integration change | Runbook in `docs/runbooks/` |
| Gotcha discovered | CLAUDE.md Gotchas section |

The `/implement` skill enforces this checklist before committing.
The `docs-check` hook warns if `src/` changed without `docs/` in the same commit.

### Code Review Gates (L3+)
Every `git commit` triggers automated review via `scripts/pre-commit-review.sh`:
- Compilation, tests, secrets, quality, error handling, test coverage
- MUST FIX = commit blocked | SHOULD FIX = warning | CONSIDER = info
- Add project-specific checks in the `[SPEC]` section of the script
- See `docs/specs/code-review-gates.md` for details and ADR-004

## Design
[SPEC] Choose your design flow (Figma is optional):

### Option A — Figma flow (team has a designer)
- Design system: [FIGMA LINK]
- Use the Figma MCP server for visual context
- `/implement` reads Figma link from PRD → extracts design → generates code

### Option B — Agent flow (no designer / dev-only team)
- Design tokens: `docs/specs/design-system/README.md`
- Component library: [SPEC] [shadcn / Radix / MUI / custom]
- `/implement` reads PRD + tokens → frontend agent generates UI
- Skill: `.claude/skills/frontend-agent/SKILL.md`

### Option C — Hybrid
- Use Figma for complex/custom screens
- Use agent flow for standard CRUD, forms, dashboards
- Both flows coexist — detected automatically per PRD

## Modular Specifications
The project adopts the following spec modules (see `docs/specs/`):

### Enabled
[SPEC] List the modules enabled for this project:
- [ ] `compliance/` → Laws, regulations, ISOs
- [ ] `security/` → Information security
- [ ] `observability/` → Monitoring, logging, tracing
- [ ] `scalability/` → Performance, caching, queues
- [ ] `versioning/` → API versioning, DB migrations, semver
- [ ] `design-system/` → Design tokens, component patterns, UI strategy
- [ ] `accessibility/` → a11y, WCAG
- [ ] `i18n/` → Internationalization, localization
- [ ] `testing-strategy/` → Test pyramid, QA
- [ ] `devops/` → CI/CD, IaC, environments
- [ ] `data-architecture/` → Modeling, pipelines, analytics
- [ ] `ai-ml/` → Models, prompts, evals, guardrails
- [ ] `long-term-memory/` → Vector DB, semantic search (L4)

## Model Presets (L4)
Agents use different models based on task complexity and cost:

| Agent | Model | Why |
|---|---|---|
| Lead (you) | opus | Complex reasoning, coding, architecture |
| `security-auditor` | opus | Deep vulnerability analysis, subtle patterns |
| `compliance-auditor` | opus | Legal/regulatory interpretation |
| `quality-guardian` | sonnet | Objective checklists, fast feedback |
| [SPEC] `domain-auditor` | sonnet | Project-specific business rules |
| [SPEC] `monitoring-agent` | haiku | Health checks, simple metrics |

Configure via `model:` in agent frontmatter (`.claude/agents/*.md`).
Switch session model: `/model opus` or `claude --model sonnet`.

## Gotchas
[SPEC] List known edge cases and pitfalls:
- [Gotcha 1]
- [Gotcha 2]

## Memory (L4)
Long-term semantic search via vector DB. See `docs/specs/long-term-memory/`.
- Index: `python memory/index.py`
- Search: `python memory/query.py "query"`
- Incremental: `python memory/index.py --incremental`
- Config: `memory/config.yaml`
- Skill auto-activated when referencing past decisions or historical context
