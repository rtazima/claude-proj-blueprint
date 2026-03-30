# Workflow: Who Does What

> The Obsidian vault is where everything starts and where everything returns.
> Obsidian is the brain, Claude Code is the hand. Figma is optional — the eye when you need one.

## The tools

| Tool | Role | When to use | Required? |
|------|------|-------------|-----------|
| **Obsidian** | The brain | Think, decide, plan, criticize, review | Always |
| **Claude Code** | The hand | Build, test, deploy, automate | Always |
| **Figma Make** | The eye | See, shape, prototype, iterate on design | Optional — see [Design Flow Guide](design-flow-guide.md) |

## The flow

### 1. Start in Obsidian — always

Open the vault and write what you want. It can be a 3-line PRD ("I want the agent to do X") or a full ADR. The point is: before opening Claude Code, what you want needs to exist as text in Obsidian. Even if it's a rough draft.

This is where you think, decide, and record why you decided.

- Write PRDs in `docs/product/`
- Write ADRs in `docs/architecture/`
- Check specs in `docs/specs/`

### 2. If there's UI → choose your design flow

Your team's design flow determines what happens next. See [Design Flow Guide](design-flow-guide.md) for details.

**Figma flow** (team has a designer):
Take the PRD from Obsidian, open Figma Make, create the screen. Mark "Ready for dev" in Dev Mode. Add the Figma link to the PRD.

**Agent flow** (no designer):
Skip Figma entirely. The PRD describes the requirements. Design tokens in `docs/specs/design-system/` define the visual language. The frontend agent generates the UI.

**Hybrid flow** (designer covers key screens):
Use Figma for complex/custom screens. Let the agent handle standard CRUD, forms, and dashboards.

If there's no UI (backend, infra, pure agent work), skip to step 3.

### 3. Hand it to Claude Code — it executes

Open the terminal:

```bash
cd your-project && claude
```

Claude reads `CLAUDE.md` automatically — it already knows your stack, conventions, and skills. You say:

```
/implement docs/product/feat-auth.md
```

Claude auto-detects the design flow:
- **PRD has Figma link** → reads design specs from Figma via MCP, implements matching the design
- **PRD has no Figma link** → loads design tokens, scans existing UI for patterns, generates UI from requirements

Compliance, security, and quality skills activate on their own based on context.

### 4. Return to Obsidian — always

The output from Claude Code (code, tests, generated ADRs) goes to Git. But the critique goes back to Obsidian. This is where you:

- Review if what was built matches the PRD
- Record what went wrong in a post-mortem
- Update the ADR if the decision changed
- Write the next PRD for the next cycle

## Who does what — quick reference

| Question | Answer |
|----------|--------|
| Where do I start? | **Obsidian** — write what you want |
| Who do I talk to? | **Claude Code** — it executes, but reads from Obsidian |
| Where do I design? | **Figma** (if enabled) or **design tokens** (agent flow) |
| Where do I criticize? | **Obsidian** — reviews, post-mortems, next cycle |
| What connects everything? | **Git** — everything in the same repo, everything versioned |

## The cycle

### With Figma (Flow A or Hybrid)

```
You (human)
  │
  ▼
Obsidian (think, decide, plan)
  │                    │
  ▼                    ▼
Figma Make ──MCP──► Claude Code
(see, shape)         (build, test)
  │                    │
  └──── feedback ──────┘
            │
            ▼
     Obsidian (critique, review)
            │
            ▼
      Next iteration
```

### Without Figma (Flow B — Agent)

```
You (human)
  │
  ▼
Obsidian (think, decide, plan)
  │
  ▼
Claude Code + frontend agent
(load tokens → generate UI → build, test)
  │
  ▼
Obsidian (critique, review)
  │
  ▼
Next iteration
```

In both flows, Obsidian is the beginning and end of every cycle. The cycle repeats until the feature is done, the product ships, or the decision changes.

## By maturity level

### L1 — Solo
You write in Obsidian, talk to Claude Code directly. Choose Figma or Agent flow — both work at L1.

### L2 — Team
PRDs and ADRs in Obsidian are shared via Git. Skills auto-activate in Claude Code. If using Figma, design specs flow in via MCP. If using Agent flow, the frontend agent skill generates UI from tokens. The team reviews in Obsidian.

### L3 — Production
Same as L2, but hooks run automatically on every file write (lint, security). The `/spec-review` command triggers compliance, security, and quality agents. Post-mortems go to Obsidian after every incident.

### L4 — Autonomous
You describe the goal in Obsidian. Claude Code creates an agent team (planner, executor, critic). The author-critic loop runs without you. The memory layer searches past decisions. You review the final output in Obsidian and approve or send it back.

Even at L4, Obsidian stays the source of truth. The agents read from it and write back to it. You're the final reviewer.
