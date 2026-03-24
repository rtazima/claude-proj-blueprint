# Workflow: Who Does What

> The Obsidian vault is where everything starts and where everything returns.
> Obsidian is the brain, Figma is the eye, Claude Code is the hand.

## The three tools

| Tool | Role | What you do there |
|------|------|-------------------|
| **Obsidian** | The brain | Think, decide, plan, criticize, review |
| **Figma Make** | The eye | See, shape, prototype, iterate on design |
| **Claude Code** | The hand | Build, test, deploy, automate |

## The flow

### 1. Start in Obsidian — always

Open the vault and write what you want. It can be a 3-line PRD ("I want the agent to do X") or a full ADR. The point is: before opening Figma or Claude Code, what you want needs to exist as text in Obsidian. Even if it's a rough draft.

This is where you think, decide, and record why you decided.

- Write PRDs in `docs/product/`
- Write ADRs in `docs/architecture/`
- Check specs in `docs/specs/`

### 2. If there's UI → go through Figma Make

Take the PRD from Obsidian, open Figma Make, and describe what you want to see. Figma generates the prototype. Iterate there until the visual makes sense. When it does, mark it as "Ready for dev" in Dev Mode.

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

It reads the PRD from Obsidian, pulls design specs from Figma via MCP, and implements. Compliance, security, and quality skills activate on their own based on context.

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
| Where do I design? | **Figma Make** — prototypes and design system |
| Where do I criticize? | **Obsidian** — reviews, post-mortems, next cycle |
| What connects everything? | **Git** — everything in the same repo, everything versioned |

## The cycle

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

Obsidian is the beginning and the end of every cycle. Figma and Claude Code are tools that it feeds. The cycle repeats until the feature is done, the product ships, or the decision changes.

## By maturity level

### L1 — Solo
You write in Obsidian, talk to Claude Code directly. No Figma needed unless there's UI.

### L2 — Team
PRDs and ADRs in Obsidian are shared via Git. Skills auto-activate in Claude Code. Figma design specs flow in via MCP. The team reviews in Obsidian.

### L3 — Production
Same as L2, but hooks run automatically on every file write (lint, security). The `/spec-review` command triggers compliance, security, and quality agents. Post-mortems go to Obsidian after every incident.

### L4 — Autonomous
You describe the goal in Obsidian. Claude Code creates an agent team (planner, executor, critic). The author-critic loop runs without you. The memory layer searches past decisions. You review the final output in Obsidian and approve or send it back.

Even at L4, Obsidian stays the source of truth. The agents read from it and write back to it. You're the final reviewer.
