# Documentation Standards: Token Budgets

## Why token budgets matter

Every documentation file that loads into context consumes tokens from the context window. Unbounded docs degrade AI assistant performance and increase costs. These budgets enforce discipline: write less, say more.

## Token budgets by file type

| File | Budget | Loads | Purpose |
|---|---|---|---|
| `CLAUDE.md` (per directory) | ≤200 tokens (~150 words) | Automatically | Navigation index. Tables with "What" and "When to read" columns. |
| `README.md` (per directory) | ≤500 tokens (~375 words) | On demand | Invisible knowledge — architecture, decisions, invariants. |
| Root `CLAUDE.md` | ≤400 lines | Automatically | Project hub. Exception to per-directory budget. |
| Root `README.md` | No strict limit | On demand | Public-facing. Favor brevity. |
| ADRs | ≤300 words | On demand | Context + Decision + Consequences. No essays. |
| PRDs | ≤800 words (main body) | On demand | Structured sections: problem, solution, acceptance criteria. |
| Runbooks | No word limit | On demand | Step-by-step, no prose. Every command must be copy-pasteable. |

## CLAUDE.md format (per directory)

Keep it as a pure navigation index. Example:

```markdown
| What | When to read |
|---|---|
| `auth/` | Adding or modifying authentication |
| `api/routes.ts` | Adding new API endpoints |
| `middleware/` | Changing request pipeline |
```

No explanations, no architecture, no decisions. Those go in README.md.

## The invisible knowledge test

Documentation should contain ONLY what cannot be learned by reading the source code.

Before writing any documentation, apply this test:

1. **Could a developer learn this by reading the source files?** If yes, it does not belong in documentation. The code is the source of truth.
2. **Is this a decision or trade-off that is not obvious from the code?** If yes, document it (ADR or README).
3. **Is this a cross-cutting concern that spans multiple files?** If yes, document the connection (README).
4. **Is this operational knowledge (how to deploy, debug, recover)?** If yes, document it (runbook).

### What fails the test (do not document)

- Function signatures (read the code)
- Parameter types (read the types)
- What a module does (read the module)
- Import structure (read the imports)

### What passes the test (do document)

- WHY a module exists instead of using a library
- WHY a non-obvious pattern was chosen
- HOW modules interact at a system level
- WHAT to do when production breaks at 3am

## Enforcement

The `/implement` skill checks documentation budgets before committing. The `docs-check` hook warns when docs exceed their budget. The `/clean` skill flags bloated documentation as slop.
