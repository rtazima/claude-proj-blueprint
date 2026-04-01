---
name: persistence
description: "Persistence mode (Ralph). Activated when the user says \"don't stop\", \"keep going\", \"Ralph mode\", \"persistence mode\", \"until it works\", \"until all tests pass\", or wants iterative implementation until all acceptance criteria pass. The boulder never stops."
allowed tools: Read, Write, Edit, Grep, Glob, Bash
---

# Persistence Mode (Ralph)

Iterative implementation loop that does NOT stop until all acceptance criteria from the
PRD pass — or max iterations are reached. Named after Sisyphus: the boulder never stops.

## Rules

1. **Never ask for confirmation between iterations** — just keep going
2. **Never claim "done" without evidence** — run the actual test/build commands
3. **Track iteration count** — stop at max iterations even if not all criteria pass
4. **Report status after each iteration** — which criteria pass, which fail, what you'll try next
5. **Each iteration must make progress** — if the same criterion fails 3 times with the same approach, try a different strategy
6. **Preserve working code** — never break passing criteria to fix a failing one

## Configuration
- Max iterations: [SPEC] (default: 5)
- Test command: [SPEC] (from CLAUDE.md Commands section)
- Build command: [SPEC] (from CLAUDE.md Commands section)

## Workflow

### Phase 1: Extract criteria
1. Read the PRD at the given path
2. Extract ALL acceptance criteria into a numbered checklist
3. Print the checklist: `[ ] Criterion 1`, `[ ] Criterion 2`, etc.
4. Identify the test/build command from CLAUDE.md or project config

### Phase 2: Implement (loop)
For each iteration (1 to max_iterations):

```
── Iteration {N}/{max} ──────────────────────
```

1. **Assess**: which criteria are NOT yet passing?
2. **Plan**: what specific changes will address the next failing criterion?
3. **Implement**: make the changes
4. **Verify**: run tests/build to check ALL criteria (not just the one you worked on)
5. **Report**:
   ```
   ✅ Criterion 1: passing
   ✅ Criterion 2: passing
   ❌ Criterion 3: failing — [reason]
   ── {passed}/{total} criteria passing ──
   ```
6. If ALL criteria pass → go to Phase 3
7. If not all pass → continue to next iteration

### Phase 3: Finalize
1. Run full test suite one final time
2. Run slop-cleaner skill on changed files (if available)
3. Print final status:
   ```
   ── Ralph Complete ──────────────────────
   Iterations: {N}/{max}
   Criteria: {passed}/{total} passing
   Files changed: [list]
   ────────────────────────────────────────
   ```
4. If max iterations reached with failures, clearly state which criteria still fail

## Escape conditions
- All criteria pass → success, stop
- Max iterations reached → stop, report remaining failures
- Build/compilation completely broken with no path forward → stop, explain

## Anti-patterns (do NOT do these)
- Do NOT ask "should I continue?" — the answer is always yes until done
- Do NOT skip verification — always run the actual commands
- Do NOT count a criterion as passing based on "it should work" — verify with evidence
- Do NOT make multiple unrelated changes per iteration — focus on one failing criterion

## References
- Inspired by oh-my-claudecode's Ralph mode
- See `/implement` for the standard implementation workflow
- See `slop-cleaner` skill for post-implementation cleanup
