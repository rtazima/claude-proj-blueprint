# Incoherence Detector

Activated when: "check consistency", "find mismatches", "incoherence", "specs match code", "docs outdated", "sync check", "drift".

## Purpose
Detect mismatches between three layers:
1. **Specs** — What we said we'd build (PRDs, API specs, schemas)
2. **Docs** — What we say it does (CLAUDE.md, README, ADRs, runbooks)
3. **Code** — What it actually does (source files, tests, config)

## Workflow

### Phase 1: Inventory (gather sources)
For the target module/feature, collect:
- [ ] PRD in `docs/product/`
- [ ] Relevant ADRs in `docs/architecture/`
- [ ] API spec in `docs/specs/api/` (if applicable)
- [ ] CLAUDE.md sections mentioning the module
- [ ] README.md sections mentioning the module
- [ ] Source files implementing the feature
- [ ] Test files covering the feature
- [ ] .env.example entries (if applicable)
- [ ] Runbooks referencing the feature

### Phase 2: Cross-reference (find mismatches)
Check each pair:

**Spec <> Code:**
- [ ] Features listed in PRD but not implemented
- [ ] Features implemented but not in any PRD
- [ ] API endpoints in spec but missing from code
- [ ] API endpoints in code but missing from spec
- [ ] Data models in spec vs actual schema/types
- [ ] Acceptance criteria in PRD vs test coverage

**Docs <> Code:**
- [ ] Commands documented but not working
- [ ] Commands working but not documented
- [ ] Env vars in code but missing from .env.example
- [ ] Env vars in .env.example but unused in code
- [ ] Module map in CLAUDE.md vs actual file structure
- [ ] Gotchas in CLAUDE.md vs actual behavior
- [ ] Architecture in ADRs vs current implementation

**Spec <> Docs:**
- [ ] PRD requirements not reflected in docs
- [ ] Docs describing features not in any PRD
- [ ] Version/status mismatches (PRD says "planned", docs say "done")
- [ ] Naming inconsistencies between PRD and docs

### Phase 3: Classify findings
For each mismatch found:
- **DRIFT** — Code evolved past the spec. Spec needs updating.
- **MISSING** — Spec/doc promises something not yet implemented.
- **STALE** — Documentation describes old behavior.
- **CONFLICT** — Two sources contradict each other.
- **ORPHAN** — Implementation exists with no spec or doc.

### Phase 4: Report
Output a structured report:

```
## Incoherence Report: [module/feature]

### Summary
- X mismatches found (Y drift, Z missing, W stale, V conflicts, U orphans)

### Findings
| # | Type | Source A | Source B | Description | Severity |
|---|------|---------|---------|-------------|----------|
| 1 | DRIFT | PRD feat-x.md | src/x.ts | PRD says 3 retries, code does 5 | SHOULD FIX |
| 2 | STALE | README.md | src/config.ts | README lists old env var name | MUST FIX |

### Recommended Actions
1. [action with specific file to update]
2. [action with specific file to update]
```

### Phase 5: Interactive resolution
For each finding, offer:
- **Fix docs** — Update documentation to match code (if code is correct)
- **Fix code** — Update code to match spec (if spec is correct)
- **Update spec** — Acknowledge drift and update spec
- **Defer** — Add to tech debt backlog

## Anti-patterns
- Don't flag every minor wording difference
- Don't flag TODOs/[SPEC] markers as mismatches (they're intentional placeholders)
- Don't compare across unrelated modules
- Focus on functional mismatches, not cosmetic ones

## Quality gate
Only report mismatches that would cause user confusion or bugs if left unfixed.
