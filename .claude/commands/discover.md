Legacy code archaeology and context bootstrap.

Arguments: $ARGUMENTS (module path, directory, or file to discover)

Workflow:
1. Activate the `legacy-context` skill
2. Phase 1 — Survey: map the territory with git log and filesystem inventory. Identify hot files (top commits last 12 months) and cold files (untouched 6+ months). Compute LOC, test ratio, and first-pass risk indicators. Write to `memory/discoveries/<module-slug>-survey.md`.
3. Phase 2 — Discovery: for hot and cold files (skip the middle), capture purpose, apparent decisions, critical dependencies, and risks. Use `git blame` and naming patterns as entry points, not linear reading. Suggest intent markers as a patch.
4. Phase 3 — Promote: detect patterns appearing 3+ times across files, draft ADR candidates in `docs/architecture/_candidates/`, run `python memory/index.py --incremental` to populate semantic memory.

Read-only for source code. Source is never modified. Marker patch and ADR candidates require human review before application.

Output paths:
- Survey: `memory/discoveries/<module-slug>-survey.md`
- Discovery notes: `memory/discoveries/<module-slug>/<file-slug>.md`
- Intent marker patch: `memory/discoveries/<module-slug>/markers.patch`
- ADR candidates: `docs/architecture/_candidates/adr-XXX-<topic>.md`

Use this before `/implement` or `/refactor` on modules where memory and docs are empty.
