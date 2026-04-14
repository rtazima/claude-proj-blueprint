---
name: context-engineering
description: "Context engineering — proactive context window management. Activated when working on large tasks, long sessions, multi-file changes, or when context is getting bloated. Keywords: \"context\", \"too much code\", \"split this task\", \"focus\", \"scope down\", \"token budget\", \"keep it small\". Complements the reactive context-guard hook with proactive techniques."
allowed tools: Read, Grep, Glob
---

# Context Engineering

Proactively manage what goes into the context window. More context is NOT better — 
the right context at the right time is better. This skill teaches techniques to keep
context lean, focused, and effective.

The reactive `context-guard` hook warns when context is bloated (50+ tool calls).
This skill prevents it from getting there in the first place.

## Rules

1. **Target <2,000 lines per task** — if a task requires reading more, split it
2. **Load on demand** — don't read files "just in case". Read when you need them
3. **Forget aggressively** — once a file is understood, stop re-reading it
4. **Prefer Grep over Read** — search for what you need instead of reading entire files
5. **One concern per session** — avoid mixing unrelated tasks in the same conversation
6. **Summarize, don't accumulate** — after analyzing multiple files, synthesize findings into a brief summary instead of carrying all raw content

## Context hierarchy

What to load first, in priority order:

| Priority | Source | Why |
|---|---|---|
| 1 | `CLAUDE.md` | Project rules, conventions, commands — always relevant |
| 2 | Spec modules (`docs/specs/`) | Only the ones active for this task |
| 3 | The specific files being changed | Direct context for the work |
| 4 | Test files for changed code | Verify behavior expectations |
| 5 | Error output / logs | Only when debugging |
| 6 | Conversation history | Degrades over time — prefer files as source of truth |

## Techniques

### 1. Task decomposition
Before starting a large task, split it into independent sub-tasks:
```
Task: "Implement user authentication"
→ Sub-task 1: Design auth API (read: PRD, API spec)
→ Sub-task 2: Implement auth middleware (read: framework docs, existing middleware)
→ Sub-task 3: Add auth tests (read: test patterns, middleware code)
→ Sub-task 4: Update docs (read: CLAUDE.md, existing docs)
```
Each sub-task has its own minimal context set.

### 2. Strategic file reading
```
BAD:  Read entire src/ to "understand the codebase"
GOOD: Grep for the function name, read only the relevant file + its test
```

### 3. Context checkpoints
At natural breakpoints (after implementing a sub-task, before starting the next):
- Summarize what was done in 2-3 sentences
- Note any decisions made and why
- List what the next sub-task needs to know

### 4. Progressive disclosure for skills
- Load only the skill description first (frontmatter)
- Load full SKILL.md only when activating it
- Load supporting files (examples, references) only when the skill workflow calls for them

### 5. Memory offloading
For long sessions:
- Write intermediate findings to `memory/session-notes.md`
- Reference the notes file instead of keeping everything in context
- The `pre-compact-save` hook auto-saves before compaction

### 6. Tiered lookup (query before reading)
Before reading raw source code, exhaust cheaper context sources first:

```
Layer 1: Memory (semantic search)
  python memory/query.py "your question" --agent-format
  → May have the answer from ADRs, post-mortems, past code
  → Cost: ~50 tokens for the query + results

Layer 2: Docs (specs, ADRs, runbooks)
  Grep docs/ for keywords
  → Structured knowledge, already summarized
  → Cost: ~200 tokens per relevant section

Layer 3: Code (src/)
  Read the specific file + its test
  → Raw context, highest fidelity but highest cost
  → Cost: ~500-2000 tokens per file

Layer 4: Global memory (cross-project, if enabled)
  python memory/query.py "your question" --global --agent-format
  → Decisions from OTHER projects that may apply here
  → Cost: ~50 tokens, but lower relevance
```

**Rule**: Only descend to the next layer if the previous one didn't answer the question.
Most implementation questions are answered at Layer 2 (docs). Only edge cases need Layer 3 (code).

## When to apply

| Signal | Action |
|---|---|
| Task touches 5+ files | Split into sub-tasks |
| Reading 3rd file without writing code | Stop. You have enough context to start. |
| Same file read twice | You forgot what it said. Summarize it. |
| Tool call count > 30 | Checkpoint. Summarize progress. Consider new session. |
| Error output > 50 lines | Extract the relevant line. Don't load the full trace. |

## Racionalizações comuns

| Racionalização | Realidade |
|---|---|
| "Preciso ler tudo pra entender o contexto" | Ler tudo polui o contexto. Leia o mínimo pra agir e expanda sob demanda. |
| "Vou ler esse arquivo caso precise depois" | "Caso precise" é desperdício. Leia quando precisar de fato. |
| "A task é grande mas consigo fazer tudo numa sessão" | Sessões longas degradam qualidade. Divida em sub-tasks com contexto limpo. |
| "Preciso ver todos os testes antes de implementar" | Veja os testes do módulo que está alterando. O resto é ruído. |

## Red Flags

- Leu mais de 5 arquivos sem produzir nenhuma mudança
- Releu o mesmo arquivo 3+ vezes na mesma sessão
- Tool call count > 50 sem checkpoint ou resumo
- Task que toca 10+ arquivos numa única sessão sem decomposição
- Carregou spec modules que não são relevantes para a task atual

## References
- Reactive complement: `scripts/context-guard.sh` (PostToolUse hook)
- Context save: `scripts/pre-compact-save.sh` (PreCompact hook)
- Session notes: `memory/session-notes.md`
- Padrão inspirado em addyosmani/agent-skills `context-engineering` skill
