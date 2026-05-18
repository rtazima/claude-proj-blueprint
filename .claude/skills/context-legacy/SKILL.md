---
name: context-legacy
description: "Legacy code archaeology — multi-phase discovery that reads the codebase, git history, and optionally Jira to reconstruct WHY code exists. Produces discovery notes, ADR candidates, and PRD candidates for human review. Activated when user says 'descobrir módulo', 'arqueologia de código', 'entender legado', 'contexto do módulo', 'por que esse código', 'legacy context', '/discover', or when starting work on an unfamiliar legacy module."
allowed tools: Read, Bash, Write, Glob
---

# Context Legacy Skill

Multi-phase discovery for legacy code. Reads code, git, and optionally Jira to reconstruct intent.
Never modifies source files. All output goes to `memory/discoveries/` and `docs/`.

## Phases

```
Phase 0 → Memory query          (check what's already indexed — avoid redoing work)
Phase 1 → Code archaeology      (static analysis — always)
Phase 2 → Git history           (always)
Phase 3 → Jira enrichment       (only if JIRA_* env vars present in .env)
Phase 4 → Cross-reference       (synthesize all signals)
Phase 5 → Output generation     (notes + candidates + re-index)
```

---

## Phase 0 — Memory query

Before reading any code, check if the module was already discovered.

```bash
memory/.venv/bin/python -m memory.query "<module_name>" 2>/dev/null | head -30
```

If results show prior discovery notes for this module:
- Read `memory/discoveries/<module-slug>-survey.md` if it exists
- Note what's already known — skip re-deriving it in Phases 1–2
- Focus new work on gaps or on Jira context not yet captured

If no prior results, proceed to Phase 1 fresh.

---

## Phase 1 — Code archaeology

**Goal:** understand what the module does, not how it works.

```bash
# Map the target
find <module_path> -type f | sort
wc -l <module_path>/**/* 2>/dev/null | sort -rn | head -20

# Hot files: most commits in last 2 years
git log --since="2 years ago" --pretty=format: --name-only -- <module_path> \
  | sort | uniq -c | sort -rn | head -10

# Cold files: untouched 3+ years, still present
git log --before="3 years ago" --name-only --pretty=format: -- <module_path> \
  | sort -u > /tmp/cold-all.txt
git log --since="3 years ago" --name-only --pretty=format: -- <module_path> \
  | sort -u > /tmp/cold-recent.txt
comm -23 /tmp/cold-all.txt /tmp/cold-recent.txt
```

Read hot and cold files first. For each, note:
- Public interface (classes, functions exported, iface.hh for C++)
- Non-obvious dependencies (`#include`, imports, `deps` file)
- Surprising patterns — magic numbers, global state, platform ifdefs
- Existing comments that hint WHY (not what)
- Markers already present (`:HACK:`, `:UNSAFE:`, `TODO`, `FIXME`, `XXX`)

**Output:** bullet list of `[CODE]` notes. Write survey to `memory/discoveries/<module-slug>-survey.md`.

---

## Phase 2 — Git history

**Goal:** find churn, authors, regressions, and commit messages that explain decisions.

```bash
git log --oneline -- <module_path> | head -40
git log --name-only --pretty=format: -- <module_path> | sort | uniq -c | sort -rn | head -15
git shortlog -sn -- <module_path> | head -10
git log --format="%H %ad %an%n%s%n%b%n---" --date=short -20 -- <module_path>
```

Flag commits containing: `fix`, `revert`, `hack`, `workaround`, `urgent`, `regression`, `broke`, `undo`.

Look for:
- Files changed > 5 times — instability signal
- Commits that revert previous commits — regression cycle
- Long commit bodies — usually explain a hard decision
- Single-author files — knowledge silo risk

**Output:** bullet list of `[GIT]` notes.

---

## Phase 3 — Jira enrichment (optional)

**Check first — skip entirely if not configured:**

```bash
[ -f .env ] && source .env 2>/dev/null
if [ -z "$JIRA_BASE_URL" ] || [ -z "$JIRA_API_TOKEN" ]; then
  echo "[JIRA] Not configured — skipping Phase 3"
  echo "       To enable: add JIRA_BASE_URL, JIRA_EMAIL, JIRA_API_TOKEN, JIRA_PROJECT_KEY to .env"
fi
```

If configured:

```bash
bash scripts/jira-context-fetch.sh \
  --term "<module_name>" \
  --term "<key_class_or_file_stem>" \
  --output memory/discoveries/<module-slug>-jira.md
```

From the output extract `[JIRA]` notes:
- Recurring bugs → instability confirmation
- Decision-type comments → `:HACK:` candidate
- Epic description → business reason this module exists
- Linked issues → coupling map

If 0 results, broaden terms (drop extension, try directory name, try acronym only).

**Output:** bullet list of `[JIRA]` notes. Raw output already written to `memory/discoveries/<module-slug>-jira.md`.

---

## Phase 4 — Cross-reference and synthesis

**Goal:** correlate signals from CODE, GIT, and JIRA to find the real story.

| Signal combination | Interpretation |
|---|---|
| High churn + recurring Jira bugs | Fragile area — refactor candidate |
| Complex code + no git explanation + no Jira | Undocumented decision — ADR candidate |
| Workaround in code + Jira bug comment | `:HACK:` marker confirmed |
| Single author in git + no spec docs | Knowledge silo — PRD candidate |
| Epic describes X + code implements Y | Spec drift — PRD candidate |
| Commit refs a ticket not in Jira results | Missing history — note it |

Produce a synthesis table: Area | Signals | Interpretation.

---

## Phase 5 — Output generation

### 5a — Per-file discovery notes

For each hot and cold file, write `memory/discoveries/<module-slug>/<file-slug>.md`:

```markdown
## <filename>

**Purpose:** one paragraph, code-derived, no speculation
**Apparent decisions:** embedded choices not explained anywhere
**Critical dependencies:** other files, modules, env vars this file relies on
**Risks:** accidental coupling, dead code, partial migrations
```

### 5b — Main context document

Write `docs/architecture/legacy-context-<module-slug>-<YYYY-MM-DD>.md`:

```markdown
# Legacy Context: <Module>

**Target:** <path>
**Date:** <YYYY-MM-DD>
**Jira:** configured | not configured | skipped

---

## What this module does

{2–4 sentences. Code-derived. No speculation.}

## Discovery notes

| # | Source | Area | Finding |
|---|--------|------|---------|
| 1 | CODE | <file:line> | <what was found> |
| 2 | GIT  | <file> | <commit pattern> |
| 3 | JIRA | <KEY-123> | <ticket excerpt> |

## Synthesis

{3–6 sentences connecting the signals.}

## Knowledge silos

| Author | Area | Last commit | Risk |
|--------|------|-------------|------|

## Next steps

- [ ] Review ADR candidates in docs/architecture/_candidates/
- [ ] Review PRD candidates in docs/product/_candidates/
- [ ] Apply intent markers from memory/discoveries/<module-slug>/markers.patch
- [ ] Share this doc before modifying the module
```

### 5c — ADR candidates (one file per candidate)

For each undocumented decision found, write `docs/architecture/_candidates/adr-candidate-<topic>.md`:

```markdown
# ADR Candidate: <Decision title>

**Status:** candidate — needs human review
**Source:** <CODE | GIT | JIRA — where the decision was found>
**Evidence:** <specific file, line, commit, or ticket>

## Reconstructed context

<Why this decision was likely made, as inferred from signals>

## Why this needs an ADR

<What breaks or becomes risky if someone changes this without knowing the decision>

## Suggested action

- [ ] Validate reconstruction with original authors if available
- [ ] Formalize with `/adr` if confirmed
- [ ] Delete this file if the decision was accidental (not intentional)
```

Only create a candidate if at least 2 independent signals point to the same decision.

### 5d — PRD candidates (one file per candidate)

For each behavior found in Jira/git but absent from `docs/product/`, write `docs/product/_candidates/prd-candidate-<topic>.md`:

```markdown
# PRD Candidate: <Feature or behavior>

**Status:** candidate — needs human review
**Source:** <JIRA ticket | git commit | code comment>
**Evidence:** <specific ticket key, commit hash, or file>

## What was found

<Description of the behavior or feature, as found in the source>

## Why it may need a PRD

<Is this a feature users depend on? A compliance requirement? A business rule?>

## Suggested action

- [ ] Confirm this is intentional and still active
- [ ] Draft full PRD with `/prd` if confirmed
- [ ] Delete this file if the behavior is obsolete
```

### 5e — Intent marker patch

Write `memory/discoveries/<module-slug>/markers.patch` with suggested markers.
Each suggestion must have a one-line justification. Patch is never auto-applied.

```
# Suggested intent markers for <module> — review before applying
#
# <file>:<line-area> — <justification>
+ // :HACK: <reason>
+ // :UNSAFE: <reason>
+ // :FLAKY: <reason>
```

### 5f — Re-index memory

After all files are written:

```bash
memory/.venv/bin/python -m memory.index --incremental
```

If the venv doesn't exist, document the skip:
```
[MEMORY] Skipping re-index — memory/.venv not found.
         Run: python3 -m venv memory/.venv && memory/.venv/bin/pip install -r memory/requirements.txt
         Then: memory/.venv/bin/python -m memory.index
```

---

## Final summary to user

After Phase 5:
1. Print path to the main context doc
2. List ADR candidates created (paths)
3. List PRD candidates created (paths)
4. State memory index result (indexed N chunks / skipped)
5. Offer: "Run `/adr` on any candidate to formalize it, or open the file and delete it if it's not a real decision."

---

## Rules

- Never modify source files. Read-only on code.
- If a file exceeds 2000 lines, treat as sub-module — read interface + hot sections only
- If git history is empty, skip Phase 2 and note it
- If Jira returns 0 results, try broader terms before giving up
- Only create an ADR candidate when 2+ independent signals confirm the same decision
- Only create a PRD candidate when the behavior is non-obvious and not in docs/product/
- Produce output even if some phases are empty — partial context is still useful
