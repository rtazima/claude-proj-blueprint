---
name: context-legacy
description: "Legacy code archaeology — multi-phase discovery that reads the codebase, git history, and optionally Jira to reconstruct WHY code exists, producing a context document that seeds ADR candidates and PRD notes for review. Activated when user says 'descobrir módulo', 'arqueologia de código', 'entender legado', 'contexto do módulo', 'por que esse código', 'legacy context', '/discover', or when starting work on an unfamiliar legacy module."
allowed tools: Read, Bash, Write, Edit, Glob
---

# Context Legacy Skill

Multi-phase discovery for legacy code. Reads code, git, and optionally Jira to reconstruct intent. Output seeds ADR and PRD review — never modifies source.

## Phases

```
Phase 1 → Code archaeology      (static analysis, always)
Phase 2 → Git history           (always)
Phase 3 → Jira enrichment       (only if JIRA_* env vars present)
Phase 4 → Cross-reference       (synthesize all signals)
Phase 5 → Output generation     (context doc + ADR candidates + PRD notes)
```

---

## Phase 1 — Code archaeology

**Goal:** understand what the module does, not how it works.

```bash
# Map the target
find <module_path> -type f | sort
wc -l <module_path>/**/* 2>/dev/null | sort -rn | head -20
```

Read the main files. For each, note:
- Public interface (classes, functions exported)
- Non-obvious dependencies (`#include`, imports)
- Areas that look complex, fragile, or surprising
- Any existing comments that hint at WHY (not just what)
- Markers already present (`:HACK:`, `:UNSAFE:`, `TODO`, `FIXME`, `XXX`)

Look specifically for:
- Constants or magic numbers without explanation
- Code paths with no apparent caller (dead code candidates)
- Unusual patterns — global state, platform ifdefs, retry loops

**Output:** a bullet list of `[FOUND]` notes carried into Phase 4.

---

## Phase 2 — Git history

**Goal:** find churn, authors, regressions, and the commit messages that explain decisions.

```bash
# High-level history for the module
git log --oneline --follow -- <file_or_dir> | head -40

# Churn: files changed most often
git log --name-only --pretty=format: -- <module_path> | sort | uniq -c | sort -rn | head -15

# Authors
git shortlog -sn -- <module_path> | head -10

# Last time each file was touched
git log -1 --pretty=format:"%ad %an" --date=short -- <file> for each file

# Full messages of the most recent 10 commits
git log --format="%H %ad %an%n%s%n%b%n---" --date=short -10 -- <module_path>
```

Flag commits that contain keywords: `fix`, `revert`, `hack`, `workaround`, `urgent`, `critical`, `regression`, `broke`, `undo`.

Look for:
- Files with high churn (changed > 5 times) — instability signal
- Commits that revert previous commits — regression cycle
- Long commit bodies — usually explain a hard decision
- Single-author files — knowledge silo risk

**Output:** a bullet list of `[GIT]` notes carried into Phase 4.

---

## Phase 3 — Jira enrichment (optional)

**Check first — skip if not configured:**

```bash
# Check if Jira is configured
if [ -f .env ]; then source .env 2>/dev/null; fi
if [ -z "$JIRA_BASE_URL" ] || [ -z "$JIRA_API_TOKEN" ]; then
  echo "JIRA not configured — skipping Phase 3"
  echo "To enable: add JIRA_BASE_URL, JIRA_EMAIL, JIRA_API_TOKEN, JIRA_PROJECT_KEY to .env"
  exit 0
fi
```

If configured, run `scripts/jira-context-fetch.sh`:

```bash
bash scripts/jira-context-fetch.sh \
  --term "<module_name_or_key_terms>" \
  --project "$JIRA_PROJECT_KEY" \
  --output /tmp/jira-raw.md
```

The script fetches and structures:
1. All tickets mentioning the module (JQL: `text ~ "term"`)
2. Bug-type tickets specifically (pattern: what broke and how it was fixed)
3. Comments with decision keywords (`decided`, `because`, `workaround`, `intentional`)
4. Parent epics — one level up for business context
5. Linked issues — lateral coupling map

From the script output, extract `[JIRA]` notes:
- Recurring bugs in the same area → instability confirmation
- Comments explaining a workaround → `:HACK:` candidate
- Epic description → business reason this module exists
- Linked modules → coupling map for architecture review

**Output:** a bullet list of `[JIRA]` notes carried into Phase 4. If Phase 3 was skipped, note it.

---

## Phase 4 — Cross-reference and synthesis

**Goal:** correlate signals across all three phases to find the real story.

Cross-reference patterns to look for:

| Signal combination | Interpretation |
|---|---|
| High git churn + recurring Jira bugs | Fragile area, likely needs refactor |
| Complex code + no git explanation + no Jira | Undocumented decision — ADR candidate |
| Workaround comment in code + Jira bug comment | `:HACK:` marker confirmed |
| Single author in git + no spec docs | Knowledge silo — needs PRD for review |
| Epic describes feature X + code implements Y differently | Spec drift — PRD note |
| Commit message references ticket not found in Jira | Missing history — note it |

Produce a **synthesis table** with three columns: Area | Signals | Interpretation.

---

## Phase 5 — Output generation

Write one document to `docs/architecture/legacy-context-{module-slug}-{YYYY-MM-DD}.md`.

Use this structure exactly:

```markdown
# Legacy Context: {Module}

**Target:** {file or directory}
**Date:** {YYYY-MM-DD}
**Jira:** {configured / not configured / skipped}

---

## What this module does

{2–4 sentences. Code-derived. No speculation.}

## Discovery notes

| # | Source | Area | Finding |
|---|--------|------|---------|
| 1 | CODE | {file:line} | {what was found} |
| 2 | GIT | {file} | {commit pattern or message} |
| 3 | JIRA | {KEY-123} | {ticket or comment excerpt} |
| ... | | | |

## Synthesis

{3–6 sentences connecting the signals. What is the real picture?}

## ADR candidates

For each decision found that is not formalized:

### ADR-?: {Decision title}
- **Evidence:** {where the decision appears — code, git, jira}
- **Context:** {why it was made, as reconstructed}
- **Status:** Proposed — needs review
- **Action:** run `/adr` to formalize

## PRD notes for review

For each behavior or feature found in Jira/git that is not in `docs/product/`:

- **{Feature or behavior}** — found in {source}, not in product docs. Review whether it needs a PRD.

## Intent markers to add

Suggested annotations to add to source code based on discoveries:

| File | Line area | Marker | Reason |
|------|-----------|--------|--------|
| {file} | {function or block} | `:HACK:` | {evidence} |
| {file} | {function or block} | `:UNSAFE:` | {evidence} |
| {file} | {function or block} | `:FLAKY:` | {evidence} |

## Knowledge silos

Authors who are sole contributors to critical areas:

| Author | Area | Last commit | Risk |
|--------|------|-------------|------|

## Next steps

- [ ] Review ADR candidates above — run `/adr` for each
- [ ] Check PRD notes — decide which need formal specs
- [ ] Add intent markers to source files
- [ ] Share context doc with team before modifying this module
- [ ] If Jira was not configured: add JIRA_* to .env and re-run for richer history
```

After writing the document:
1. Tell the user the path and a one-sentence summary of what was found
2. List the ADR candidates by title
3. Offer: "Run `/adr` for any of these to formalize them, or `/prd` to draft a PRD from the PRD notes."

---

## Notes

- Never modify source files. This skill is read-only on code.
- If a file is too large to read fully, prioritize: public interface → areas flagged in git/Jira → constructor/init code → teardown/cleanup
- If git history is empty (no git repo), note it and proceed with Phases 1 and 3 only
- If Jira returns 0 results, try broader terms (drop file extension, try class name only, try directory name)
- Produce the document even if Phases 2 and 3 are empty — partial context is still useful
