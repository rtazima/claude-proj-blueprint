---
name: slop-cleaner
description: AI slop cleaner. Activated when the user says "clean up", "remove slop", "polish code", "review for slop", "AI artifacts", "deslop", or wants to clean LLM-generated code patterns. Also auto-activated after /implement as a final pass.
allowed tools: Read, Write, Edit, Grep, Glob
---

# AI Slop Cleaner

Remove patterns that LLMs typically introduce: unnecessary comments, over-abstraction,
verbose code, dead code, and "AI verbal tics." The writer and the reviewer MUST be
different passes — never self-approve a cleanup.

## Rules

1. **Scope first**: identify which files to clean (args, or `git diff --name-only HEAD~3`)
2. **Read before editing**: always read the full file before making changes
3. **One category at a time**: go through the checklist in order, not all at once
4. **Preserve behavior**: cleaning must NOT change functionality — only remove noise
5. **Run tests after**: if tests exist, run them after cleanup to confirm nothing broke
6. **Report**: list every change made with before/after snippets

## Slop Patterns Checklist

### 1. Unnecessary comments
- [ ] Comment restates the function/variable name: `// Get the user` above `getUser()`
- [ ] Section headers in small files: `// --- Imports ---`, `// Constructor`
- [ ] Obvious explanations: `// Increment counter` above `counter++`
- [ ] JSDoc/docstrings that only restate the signature with no added insight
- [ ] `// TODO` without context or assignee (either add context or remove)

### 2. Over-abstraction
- [ ] Single-use interfaces/types that could be inline
- [ ] Wrapper functions that only call one thing with no added logic
- [ ] Abstract factory / Strategy / Builder for something with one implementation
- [ ] Config objects for values that will never change
- [ ] Event emitters with a single listener

### 3. Redundant type assertions
- [ ] `as Type` where the type is already inferred by the compiler
- [ ] `!` non-null assertions where the value is guaranteed non-null
- [ ] Explicit return types that match the inferred type and add no clarity
- [ ] `String(x)` or `Number(x)` where x is already that type

### 4. Excessive logging
- [ ] `console.log` / `logger.debug` on every function entry/exit
- [ ] Logging the same data that is already in the request/response
- [ ] Logging inside tight loops (performance hazard)
- [ ] Debug logs left from development (not guarded by env/level)

### 5. Dead code
- [ ] Commented-out code blocks (not TODOs — actual dead code)
- [ ] Unused imports
- [ ] Unreachable branches (`if (false)`, `return` before code)
- [ ] Unused variables or parameters
- [ ] Functions that are never called

### 6. Over-engineering
- [ ] Error handling that catches and re-throws with no added context
- [ ] Premature optimization (caching something used once)
- [ ] Utility classes/files for a single helper function
- [ ] Enum where a union type or simple constant suffices
- [ ] Layer of indirection that adds no value (service calls repository that calls database — if service only forwards)

### 7. LLM verbal tics (in comments, docs, commit messages)
- [ ] "Robust", "comprehensive", "seamless", "leverage", "utilize", "facilitate"
- [ ] "This function/method/class does X" (redundant with the name)
- [ ] "For security purposes" / "for performance reasons" without specifics
- [ ] Excessively polite code comments: "Please note that..."

### 8. Temporal contamination
Comments should describe what the code does NOW, not why it was changed.
Code is read in a timeless present — change history belongs in git, not in source.

- [ ] Past tense verbs in comments: "Added", "Fixed", "Changed", "Refactored", "Updated", "Removed", "Moved", "Replaced", "Converted"
- [ ] Change-tracking language: "now uses", "no longer", "instead of", "was previously", "used to be"
- [ ] PR/commit language in code: "as per review", "per discussion", "as requested"
- [ ] Comments that explain the diff rather than the current state

**BAD** (temporal contamination):
```
// Added mutex to fix race condition in user cache
// Refactored to use factory pattern for better testability
// Changed from array to Set for O(1) lookup performance
// Fixed bug where null users caused crash
```

**GOOD** (timeless present):
```
// Mutex serializes concurrent cache access
// Factory pattern decouples creation from usage
// Set provides O(1) membership checks
// Guard clause rejects null users before processing
```

## Language-specific patterns
[SPEC] Add patterns for your stack:

### TypeScript / JavaScript
- `any` type used as shortcut instead of proper typing
- `@ts-ignore` / `@ts-expect-error` without explanation
- `== null` mixed with `=== undefined` inconsistently

### Python
- `pass` in exception handlers without comment
- Bare `except:` catching everything
- `# type: ignore` without reason

### Go
- `_ = err` (silently swallowing errors)
- Unused `ctx` parameter

## Output format
For each file cleaned:
```
## file.ts
- Removed 3 unnecessary comments (lines 12, 45, 78)
- Inlined single-use interface `UserProps` (line 5)
- Removed 2 dead imports (line 1-2)
```

## References
- Karpathy's guidelines on clean code
- See `CLAUDE.md` for project conventions
