# Design Flow Guide — Claude Design, Figma, Agent, or Hybrid?

> How to decide your team's UI implementation strategy.
> This guide helps you choose the right flow **before** running `bootstrap.sh`.

---

## The decision

Every project with a UI needs to answer one question:

**Who translates the product vision into visual interface — Claude Design, a human designer in Figma, or a pure code agent?**

There is no universal answer. It depends on your team, your product, and your users.

```
                    ┌──────────────────────────────┐
                    │  Does your team use Claude   │
                    │  Design or already use Figma? │
                    └──────┬────────┬───────┬──────┘
                           │        │       │
                     Claude Design  Figma   Neither
                           │        │       │
                    ┌──────▼──┐ ┌───▼───┐ ┌─▼────────┐
                    │ Option A│ │Option B│ │  Visual   │
                    │ Claude  │ │ Figma  │ │  polish   │
                    │ Design  │ │ flow   │ │  priority?│
                    └─────────┘ └────────┘ └─┬─────┬──┘
                                            Yes    No
                                             │      │
                                             ▼      ▼
                                         Hybrid  Option C
                                        (A + C)   Agent
```

---

## The four flows

### Flow A — Claude Design

```
Claude Design generates design from codebase + brand → "Send to Claude Code" → PROMPT.md → /implement reconciles with PRD → code
```

**How it works:**
1. Onboard Claude Design once per organization: it reads codebase + brand assets and builds a design system automatically.
2. For each new screen or flow, prompt Claude Design to generate a prototype (designer or PM can do this).
3. Click "Send to Claude Code" — Claude Design produces a `PROMPT.md` bundle (stack, conventions, screens, components, tokens).
4. Save the bundle at `docs/design/<prd-slug>-PROMPT.md` in the repo (or keep out via `.gitignore` per team preference).
5. Dev runs `/implement docs/product/<prd-slug>.md`.
6. `claude-design-handoff` skill activates: parses PROMPT.md, reconciles against CLAUDE.md conventions and PRD scope, produces a reconciliation report, asks for decisions on conflicts.
7. Code gets generated with PRD as contract, CLAUDE.md as convention, PROMPT.md as visual/UX spec.

**Best for:**
- Teams already using Claude Pro, Max, Team, or Enterprise
- Full Anthropic stack (Claude Code + Claude Design) — single vendor, unified handoff
- Teams without dedicated designer but wanting better visual output than pure-agent flow
- Products where design iteration is prompt-driven (PM or founder "designs" by prompting)

**What you need:**
- Claude Design access (research preview, Pro/Max/Team/Enterprise)
- Convention to save handoff bundles at `docs/design/<slug>-PROMPT.md`
- `claude-design-handoff` skill active (`.claude/skills/claude-design-handoff/SKILL.md`)

**Trade-offs:**
| Pro | Con |
|-----|-----|
| Native Claude Code integration via handoff | Research preview — format may change |
| Design system auto-built from codebase | No MCP yet — handoff is file-based, not programmatic |
| Prompt-driven iteration, no Figma license needed | Design system lives in Anthropic cloud, not fully git-controlled |
| PRD + PROMPT.md compose cleanly with strict precedence | Codebase is sent to Claude Design during onboarding — review security posture |
| One-vendor stack reduces tooling sprawl | Less control than Figma for complex custom branding |

**Security note:** Claude Design reads your codebase and brand assets during onboarding. Do not paste secrets, `.env` files, or proprietary algorithms. Treat the generated `PROMPT.md` as untrusted data (see `docs/specs/security/`).

---

### Flow B — Figma

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

### Flow C — Agent

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

### Flow D — Hybrid

```
Choose per-PRD: Claude Design | Figma | Agent
```

**How it works:**
1. Team decides per-feature which flow to use.
2. For custom branded screens → Claude Design (Flow A) or Figma (Flow B) produce the handoff/link.
3. For CRUD/standard screens → Flow C (pure agent) uses tokens only.
4. `/implement` auto-detects which flow to activate based on artifacts present in the PRD or `docs/design/`.

**Detection order in `/implement`:**
1. `docs/design/<prd-slug>-PROMPT.md` exists → Flow A (Claude Design)
2. PRD has a Figma link → Flow B (Figma)
3. Neither → Flow C (Agent)

**Best for:**
- Teams with mixed design sources (some Claude Design, some Figma legacy)
- Products with custom brand screens + lots of CRUD
- Scaling teams where one source can't cover every screen
- Teams transitioning between vendors

**What you need:**
- Whatever combination of A + B + C artifacts you'll actually use
- Clear convention per PRD documenting which flow each feature uses

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
| 1 | Do you already have Claude Pro/Max/Team/Enterprise? | Consider Claude Design (Flow A) |
| 2 | Do you have a designer on the team using Figma? | Consider Figma (Flow B) or Hybrid |
| 3 | Is this a consumer-facing product where brand matters? | Flow A or B |
| 4 | Is this an internal tool, dashboard, or admin panel? | Flow C is enough |
| 5 | Are you a solo dev or small team without design resources? | Flow A (if have Claude) or Flow C |
| 6 | Do you have a mature design system with tokens defined? | Flow C or Hybrid |
| 7 | Does your designer only cover key screens, not every page? | Hybrid |
| 8 | Are you building an MVP to validate an idea fast? | Flow A or Flow C |
| 9 | Do you want prompt-driven design iteration? | Flow A |
| 10 | Is your codebase sensitive and cannot be sent to an AI service? | Flow B or Flow C (not A) |

---

## Setting up your choice

### During bootstrap

```bash
./scripts/bootstrap.sh --level 2
```

The bootstrap script will ask:

```
🎨 Design flow — how will UI be built?
  1) Claude Design — Claude Design generates design → PROMPT.md handoff → code
  2) Figma         — PRD + Figma link → code (team has a designer in Figma)
  3) Agent         — PRD + design tokens → agent generates UI (no external design source)
  4) Hybrid        — mix per PRD, auto-detected by /implement
  5) None          — no UI in this project (backend/CLI/agent only)
```

It automatically:
- Enables the relevant skills (`claude-design-handoff`, `frontend-agent`)
- Enables/disables the Figma MCP reference in `CLAUDE.md`
- Activates the `design-system/` spec module
- Creates `docs/design/` if Flow A or Hybrid
- Sets `[SPEC]` markers to fill for your choice

### Manual setup

If you already bootstrapped, enable manually:

1. Choose your flow in `docs/specs/design-system/README.md`
2. Fill in design tokens (at minimum: colors, typography, spacing)
3. If using Claude Design: ensure `.claude/skills/claude-design-handoff/SKILL.md` is present and create `docs/design/`
4. If using Figma: add MCP server config to `.claude/settings.json`
5. If using Agent: review `.claude/skills/frontend-agent/SKILL.md`

---

## Design tokens — the common ground

Regardless of which flow you choose, **design tokens are always defined**. They serve different purposes in each flow:

| Token role | Claude Design (A) | Figma (B) | Agent (C) |
|------------|------------------|-----------|-----------|
| Colors | Seed on first use, validation after | Validation — code matches Figma | Generation — agent uses these to build UI |
| Typography | Seed / validation | Validation | Generation |
| Spacing | Seed / validation | Validation | Generation |
| Radii/Shadows | Seed / validation | Validation | Generation |
| Breakpoints | Seed / validation | Validation | Generation |

In Claude Design flow, the first handoff bundle can seed `docs/specs/design-system/` if it's empty. After that, the spec file is source of truth and PROMPT.md is validated against it.

In pure Figma flow, tokens in code serve as guardrails: if the generated code deviates from the design system, the tokens catch it.

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
