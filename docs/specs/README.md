# Modular Specifications

> Each module is independent and plug-and-play.
> Enable only those that make sense for your project.

## Available modules

| Module | Purpose | When to use |
|--------|---------|-------------|
| **compliance/** | Laws, regulations, ISOs | Personal data, regulated industries, certifications |
| **security/** | Technical controls | Every production project |
| **observability/** | Logs, metrics, traces | Every production project |
| **scalability/** | Performance, caching, queues | When scale matters |
| **versioning/** | API versions, migrations | Products with public APIs or multiple clients |
| **design-system/** | Design tokens, component patterns, UI strategy | Projects with UI — makes Figma optional |
| **accessibility/** | WCAG, a11y | Products with user interfaces |
| **i18n/** | Multi-language | International products |
| **testing-strategy/** | Test pyramid, QA | Teams with 3+ devs |
| **devops/** | CI/CD, IaC, environments | Every production project |
| **data-architecture/** | Modeling, pipelines | Data-intensive products |
| **ai-ml/** | Models, prompts, evals | AI/ML products |
| **long-term-memory/** | Vector DB, semantic search | L4 — autonomous systems |

## Adding a custom module
1. Create a folder at `docs/specs/your-module/`
2. Add a `README.md` with the module structure
3. Optionally create a skill at `.claude/skills/your-module/SKILL.md`
4. Reference it in `CLAUDE.md` under "Modular Specifications"

## Convention
- Each module has a `README.md` as its entry point
- `[SPEC]` markers indicate points that must be filled in for the project
- Supporting documents go inside the module folder
- Corresponding skills go in `.claude/skills/[module]/SKILL.md`
- Agents that audit the module go in `.claude/agents/`
