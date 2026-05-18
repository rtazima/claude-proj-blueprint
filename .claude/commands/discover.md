Legacy code archaeology. Reads code, git history, and Jira (when configured) to reconstruct WHY a module exists. Produces discovery notes in memory/, ADR candidates and PRD candidates in docs/ for human review, then re-indexes memory.

Arguments: $ARGUMENTS (one or more module paths or file paths, space-separated)

Workflow:
1. Activate the `context-legacy` skill
2. For each target in $ARGUMENTS, run all phases in order
3. Never modify source files — read-only on code

Output paths:
- Survey:            memory/discoveries/<module-slug>-survey.md
- Per-file notes:    memory/discoveries/<module-slug>/<file-slug>.md
- Jira notes:        memory/discoveries/<module-slug>-jira.md
- Main context doc:  docs/architecture/legacy-context-<module-slug>-<date>.md
- ADR candidates:    docs/architecture/_candidates/adr-candidate-<topic>.md
- PRD candidates:    docs/product/_candidates/prd-candidate-<topic>.md
- Marker patch:      memory/discoveries/<module-slug>/markers.patch

After all targets are processed, run:
  memory/.venv/bin/python -m memory.index --incremental
