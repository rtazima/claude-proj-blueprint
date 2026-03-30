# Module: Design System

> Visual design tokens, component patterns, and UI implementation strategy.
> This module makes Figma **optional** — teams choose between design tool integration or agent-driven UI generation.

## How to enable
1. Fill in the sections below
2. Choose your design flow: **Figma** or **Agent-driven**
3. Create a skill in `.claude/skills/frontend-agent/SKILL.md` if using agent-driven flow

## Design flow

[SPEC] Choose your primary flow:
- [ ] **Figma flow** → PRD + Figma link → code (requires Figma MCP server)
- [ ] **Agent flow** → PRD + design tokens → frontend agent generates UI
- [ ] **Hybrid** → Figma for complex screens, agent for standard CRUD/forms

## Design tokens

[SPEC] Define your tokens (or link to external source):

### Colors
```
[SPEC] Example:
--color-primary: #2563eb
--color-primary-hover: #1d4ed8
--color-surface: #ffffff
--color-surface-alt: #f8fafc
--color-text: #0f172a
--color-text-muted: #64748b
--color-border: #e2e8f0
--color-error: #dc2626
--color-success: #16a34a
--color-warning: #d97706
```

### Typography
```
[SPEC] Example:
--font-sans: "Inter", system-ui, sans-serif
--font-mono: "JetBrains Mono", monospace
--text-xs: 0.75rem / 1rem
--text-sm: 0.875rem / 1.25rem
--text-base: 1rem / 1.5rem
--text-lg: 1.125rem / 1.75rem
--text-xl: 1.25rem / 1.75rem
--text-2xl: 1.5rem / 2rem
```

### Spacing
```
[SPEC] Example:
--space-1: 0.25rem (4px)
--space-2: 0.5rem (8px)
--space-3: 0.75rem (12px)
--space-4: 1rem (16px)
--space-6: 1.5rem (24px)
--space-8: 2rem (32px)
```

### Radii & Shadows
```
[SPEC] Example:
--radius-sm: 0.25rem
--radius-md: 0.375rem
--radius-lg: 0.5rem
--shadow-sm: 0 1px 2px rgba(0,0,0,0.05)
--shadow-md: 0 4px 6px rgba(0,0,0,0.07)
```

## Component library

[SPEC] Choose:
- [ ] Custom components from scratch
- [ ] shadcn/ui
- [ ] Radix UI
- [ ] Material UI
- [ ] Ant Design
- [ ] Chakra UI
- [ ] Other: ___

## Figma flow (if enabled)

[SPEC] Fill if using Figma:
- Figma file: [LINK]
- Figma MCP server: enabled/disabled
- Component mapping: `docs/specs/design-system/figma-component-map.md`
- Handoff process: designer publishes → dev runs `/implement` with Figma link

## Agent flow (if enabled)

When no Figma link is provided, the frontend agent generates UI from:
1. **Design tokens** defined above
2. **Component library** selected above
3. **PRD requirements** (functional specs, user stories)
4. **Reference patterns** — existing screens in the project for consistency

### Agent rules
- Always use design tokens — never hardcode colors, spacing, or typography
- Follow component library conventions and patterns
- Match the visual style of existing screens in the project
- Generate responsive layouts (mobile-first)
- Include loading, empty, and error states
- Follow accessibility standards (see `docs/specs/accessibility/`)

## Layout patterns

[SPEC] Define standard layouts:
- [ ] Sidebar + content
- [ ] Top nav + content
- [ ] Dashboard grid
- [ ] Form layouts (single column / two column)
- [ ] Card grid / list view toggle
- [ ] Modal / drawer patterns

## Responsive breakpoints

[SPEC] Define:
```
sm: 640px
md: 768px
lg: 1024px
xl: 1280px
2xl: 1536px
```

## Dark mode

[SPEC] Choose:
- [ ] Not supported
- [ ] Light only with dark-ready tokens
- [ ] Full dark mode with toggle
- [ ] System preference auto-detect
