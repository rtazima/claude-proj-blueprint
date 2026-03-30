---
name: frontend-agent
description: Generate UI components from PRD + design tokens when no Figma design is provided. Activated when implementing frontend features without a Figma link.
allowed tools: Read, Write, Edit, Grep, Glob, Bash
---

# Frontend Agent — Design-to-Code without Figma

## When this skill activates
- User runs `/implement` on a PRD that has **no Figma link**
- User asks to build UI, create a page, or implement a component
- PRD contains frontend requirements but no design reference

## Workflow

1. **Load design tokens** from `docs/specs/design-system/README.md`
2. **Identify component library** — read which library the project uses
3. **Scan existing UI** — grep for existing pages/components to match visual patterns
4. **Read PRD requirements** — extract user stories, screens, interactions
5. **Generate UI** following the rules below
6. **Self-review** — verify tokens are used, no hardcoded values, responsive, accessible

## Generation rules

### Tokens first
- ALWAYS read `docs/specs/design-system/README.md` before generating any UI
- Use CSS variables / theme tokens — never hardcode `#hex`, `px` spacing, or font names
- If a token is missing, flag it and suggest adding to the design system

### Consistency
- Before creating a new component, search for similar existing ones
- Match the layout patterns, spacing rhythm, and interaction patterns of existing screens
- Reuse existing components — don't create duplicates

### Component structure
- One component per file
- Props interface defined (TypeScript)
- Default to the project's component library (shadcn, Radix, etc.)
- Include variants: default, loading, empty, error states
- Responsive by default (mobile-first)

### Accessibility
- Semantic HTML elements
- ARIA labels on interactive elements
- Keyboard navigable
- Color contrast meets WCAG AA (4.5:1 text, 3:1 large text)
- Focus indicators visible

### What NOT to do
- Never generate pixel-perfect mockup replicas without tokens
- Never hardcode colors, spacing, or typography
- Never skip empty/error/loading states
- Never create a component that duplicates an existing one
- Never ignore the project's component library choice

## Output format

When generating a new page or component:

```
1. Component file(s) created
2. Tokens used: [list which tokens were applied]
3. Existing components reused: [list]
4. States covered: [default, loading, empty, error]
5. Responsive: [breakpoints handled]
6. Accessibility: [checks passed]
```
