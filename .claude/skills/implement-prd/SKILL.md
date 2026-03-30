---
name: implement-prd
description: Implement a feature from a PRD. Activated when the user asks to implement, build, or construct from a product document.
allowed tools: Read, Write, Edit, Grep, Glob, Bash
---

# Implement from PRD

## Workflow
1. **Read the PRD** completely in `docs/product/`
2. **Check related ADRs** in `docs/architecture/`
3. **Check applicable specs** in `docs/specs/` (design, compliance, etc.)
4. **Detect design flow** — determine how UI will be built:
   - **Figma flow:** PRD contains a Figma link → use Figma MCP server to extract design context (components, spacing, colors, layout) → implement matching the design
   - **Agent flow:** PRD has no Figma link → activate `.claude/skills/frontend-agent/SKILL.md` → load design tokens from `docs/specs/design-system/README.md` → scan existing components → generate UI from tokens + component library + PRD requirements
5. **Plan Mode** — create implementation plan before coding
6. **Implement** following `CLAUDE.md` conventions
7. **Tests** — create tests following `.claude/skills/testing/SKILL.md`
8. **Spec checks** — verify compliance with active modules
9. **Document** — update docs if needed

## Design flow detection
Check the PRD for these patterns to determine the flow:
- Contains `figma.com` URL or `## Design` section with link → **Figma flow**
- Contains `## Design` with "see design-system tokens" or no link → **Agent flow**
- No design section at all → **Agent flow** (use tokens + existing patterns)

## Rules
- Never implement without reading the full PRD first
- If the PRD is ambiguous, ask before assuming
- Always check if an ADR already exists for the technical decision
- Atomic commits per feature/sub-feature
- Never hardcode UI values — always use design tokens or Figma specs
