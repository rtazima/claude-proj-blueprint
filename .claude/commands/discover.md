Legacy code archaeology and context bootstrap. Reads code, git history, Jira (when configured), and remote PRs/issues to reconstruct WHY a module exists. Produces discovery notes in memory/, ADR candidates and PRD candidates in docs/ for human review, then re-indexes memory.

Arguments: $ARGUMENTS (one or more module paths or file paths, space-separated)

Workflow:
1. Activate the `context-legacy` skill
2. For each target in $ARGUMENTS, run all phases in order:
   - Phase 0 — Memory query: check if already discovered, avoid redo
   - Phase 1 — Code archaeology: static analysis, hot/cold files, public interface, surprising patterns
   - Phase 2 — Git history: churn, authors, regression commits, decision messages, git blame (targeted on hot files), dead PRs (closed without merge)
   - Phase 3 — Jira enrichment: ticket history, bug patterns, decision comments, epic chain (skipped if `JIRA_*` not set in `.env`)
   - Phase 4 — Cross-reference: correlate all signals, produce synthesis table
   - Phase 5 — Output: discovery notes, main context doc, ADR candidates, PRD candidates, marker patch, re-index
3. Never modify source files — read-only on code

Tunable flags (defaults in parentheses, override via env var):
- `LEGACY_CONTEXT_EARLY_EXIT` (false): if true, Phase 2 dead PR scan may run in lean mode on repos with no PR review culture
- `LEGACY_CONTEXT_TRUNK_THRESHOLD` (30): PR coverage % below which the repo is classified as trunk-based

Defaults bias toward completeness. Override for speed when you have validated the repo profile.

Output paths:
- Survey:            memory/discoveries/<module-slug>-survey.md
- Per-file notes:    memory/discoveries/<module-slug>/<file-slug>.md
- Dead PR notes:     memory/discoveries/<module-slug>-dead-prs.md
- Jira notes:        memory/discoveries/<module-slug>-jira.md
- Main context doc:  docs/architecture/legacy-context-<module-slug>-<date>.md
- ADR candidates:    docs/architecture/_candidates/adr-candidate-<topic>.md
- PRD candidates:    docs/product/_candidates/prd-candidate-<topic>.md
- Marker patch:      memory/discoveries/<module-slug>/markers.patch

After all targets are processed, run:
  memory/.venv/bin/python -m memory.index --incremental

Supported remote providers (Phase 2 dead PR scan):
- GitHub: detected by `github.com` in remote URL. Requires `gh auth login` completed.
- Azure DevOps: detected by `dev.azure.com` or `.visualstudio.com`. Requires `AZURE_DEVOPS_EXT_PAT` in shell.
- Other providers (GitLab, Bitbucket, self-hosted): dead PR scan skipped with warning.

Use this before `/implement` or `/refactor` on modules where memory and docs are empty. Designed for codebases older than 5 years with no convention discipline.
