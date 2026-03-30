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
