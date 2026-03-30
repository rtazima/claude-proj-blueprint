# Design Flow Guide — Figma, Agent, or Hybrid?

> How to decide your team's UI implementation strategy.
> This guide helps you choose the right flow **before** running `bootstrap.sh`.

---

## The decision

Every project with a UI needs to answer one question:

**Who translates the product vision into visual interface — a human designer or an AI agent?**

There is no universal answer. It depends on your team, your product, and your users.

```
                    ┌─────────────────────────┐
                    │    Does your team have   │
                    │    a dedicated designer?  │
                    └────────┬────────┬────────┘
                             │        │
                            Yes       No
                             │        │
                    ┌────────▼──┐  ┌──▼────────┐
                    │  Do they   │  │  Is visual │
                    │  use Figma?│  │  polish a  │
                    │            │  │  priority? │
                    └──┬─────┬──┘  └──┬─────┬──┘
                      Yes    No      Yes    No
                       │      │       │      │
                       ▼      ▼       ▼      ▼
                    Figma  Hybrid  Hybrid  Agent
                    flow    flow    flow   flow
```

---

## The three flows

### Flow A — Figma

```
Designer creates in Figma → Dev Mode → /implement reads via MCP → code
```

**How it works:**
1. Designer creates screens in Figma
2. Marks components as "Ready for Dev" in Dev Mode
3. Adds Figma link to the PRD in `docs/product/`
4. Dev runs `/implement docs/product/feat-x.md`
5. Claude reads Figma via MCP server, extracts design specs
6. Code matches the design pixel-for-pixel

**Best for:**
- Teams with a dedicated designer (full-time or contract)
- Consumer products where brand and visual identity matter
- Products with complex, custom UI patterns
- Stakeholder-facing deliverables that need visual approval before dev

**What you need:**
- Figma account (free tier works for small teams)
- Figma MCP server configured in `.claude/settings.json`
- Designer-dev handoff process defined

**Trade-offs:**
| Pro | Con |
|-----|-----|
| Pixel-perfect output | Requires a designer in the loop |
| Design reviews before code | Slower iteration (design → review → code) |
| Brand consistency guaranteed | Figma MCP can be flaky on complex files |
| Stakeholder alignment on visuals | Designer becomes a bottleneck if solo |

---

### Flow B — Agent

```
PRD + design tokens → frontend agent → code
```

**How it works:**
1. You define design tokens in `docs/specs/design-system/README.md` (colors, typography, spacing, etc.)
2. You choose a component library (shadcn, Radix, MUI, etc.)
3. You write a PRD describing what the screen should do
4. Dev runs `/implement docs/product/feat-x.md`
5. No Figma link found → frontend agent skill activates
6. Agent loads tokens + scans existing UI + generates code

**Best for:**
- Dev-only teams (no designer)
- Internal tools, dashboards, admin panels
- MVPs and prototypes where speed beats polish
- Solo founders and indie hackers
- Backend-heavy projects with minimal UI

**What you need:**
- Design tokens defined (at minimum: colors, typography, spacing)
- A component library chosen (strongly recommended — gives the agent a vocabulary)
- At least one existing screen for the agent to reference patterns from

**Trade-offs:**
| Pro | Con |
|-----|-----|
| No designer dependency | Visual output is "good enough", not custom |
| Fastest time-to-UI | Consistency depends on token discipline |
| Works for any maturity level | Complex layouts may need multiple iterations |
| Agent improves as codebase grows | No stakeholder visual preview before code |

---

### Flow C — Hybrid

```
Complex/custom screens → Figma
Standard screens → Agent
```

**How it works:**
1. Team decides per-feature: does this need custom design?
2. If yes → designer creates in Figma, link goes in PRD
3. If no → PRD describes requirements, agent generates from tokens
4. `/implement` auto-detects the flow based on Figma link presence

**Best for:**
- Teams with a part-time or shared designer
- Products with a strong design system but lots of CRUD screens
- Scaling teams where the designer can't cover every screen
- Teams transitioning from Figma-heavy to agent-driven

**What you need:**
- Everything from Flow A (Figma setup) + Flow B (tokens + component library)
- A clear convention for which screens go through Figma
- Documented in the PRD: "Design: see Figma" or "Design: use design system tokens"

**Trade-offs:**
| Pro | Con |
|-----|-----|
| Designer focuses on high-impact screens | Two flows to maintain |
| Standard screens ship fast | Team needs to align on when to use which |
| Best of both worlds | Tokens must stay in sync with Figma file |

---

## How to choose — quick checklist

Answer these questions:

| # | Question | If yes → |
|---|----------|----------|
| 1 | Do you have a designer on the team? | Consider Figma or Hybrid |
| 2 | Is this a consumer-facing product where brand matters? | Lean toward Figma |
| 3 | Is this an internal tool, dashboard, or admin panel? | Agent flow is enough |
| 4 | Are you a solo dev or small team without design resources? | Agent flow |
| 5 | Do you have a mature design system with tokens defined? | Agent or Hybrid |
| 6 | Does your designer only cover key screens, not every page? | Hybrid |
| 7 | Are you building an MVP to validate an idea fast? | Agent flow |
| 8 | Do stakeholders need to approve visuals before dev starts? | Figma flow |

---

## Setting up your choice

### During bootstrap

```bash
./scripts/bootstrap.sh --level 2
```

The bootstrap script will ask:

```
🎨 Design flow — how will UI be built?
  1) Figma    — PRD + Figma link → code (team has a designer)
  2) Agent    — PRD + design tokens → agent generates UI (no designer)
  3) Hybrid   — Figma for complex screens, agent for the rest
```

It automatically:
- Enables/disables the Figma MCP reference in `CLAUDE.md`
- Activates the `design-system/` spec module
- Configures the `frontend-agent` skill
- Sets `[SPEC]` markers to fill for your choice

### Manual setup

If you already bootstrapped, enable manually:

1. Choose your flow in `docs/specs/design-system/README.md`
2. Fill in design tokens (at minimum: colors, typography, spacing)
3. If using Figma: add MCP server config to `.claude/settings.json`
4. If using Agent: review `.claude/skills/frontend-agent/SKILL.md`

---

## Design tokens — the common ground

Regardless of which flow you choose, **design tokens are always defined**. They serve different purposes in each flow:

| Token role | Figma flow | Agent flow |
|------------|-----------|-----------|
| Colors | Validation — code matches Figma colors | Generation — agent uses these to build UI |
| Typography | Validation | Generation |
| Spacing | Validation | Generation |
| Radii/Shadows | Validation | Generation |
| Breakpoints | Validation | Generation |

Even in pure Figma flow, tokens in code serve as guardrails: if the generated code deviates from the design system, the tokens catch it.

---

## Frequently asked questions

**Can I switch flows later?**
Yes. The flows are per-PRD, not per-project. You can start with Agent flow for your MVP and add Figma later when you hire a designer. The `/implement` command auto-detects based on each PRD.

**Do I need a component library for Agent flow?**
Strongly recommended. Without one, the agent generates raw HTML/CSS, which is harder to maintain. With shadcn, Radix, or similar, the agent has a design vocabulary and produces consistent, accessible components.

**Can the agent generate from a screenshot instead of Figma?**
Not in this flow. If you have a screenshot or mockup, describe it in the PRD textually. The agent works from written requirements + tokens, not images.

**What if my Figma file is huge and MCP is slow?**
Use Hybrid: send only the specific screen's Figma link in the PRD, not the entire file. For simpler pages, skip Figma entirely.

**Does this work at all maturity levels?**
Yes. The design flow choice is independent of your maturity level (L1-L4). A solo dev at L1 can use Agent flow. A mature team at L4 can use Hybrid. The bootstrap script asks at any level.
