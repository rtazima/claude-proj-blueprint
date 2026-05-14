Legacy code archaeology and context bootstrap with remote discovery.

Arguments: $ARGUMENTS (module path, directory, or file to discover)

Workflow:
1. Activate the `legacy-context` skill
2. Phase 1 — Pre-flight: validate `gh` CLI availability, confirm repo is on GitHub, estimate PR/issue volume. Sets flag for Phase 3.
3. Phase 2 — Survey: map the territory with git log and filesystem inventory. Identify recent hot files (top commits last 24 months), persistent hot files (top commits all-time), and cold-but-imported files (untouched 3+ years, still referenced). Compute LOC, test ratio, and risk indicators. Write to `memory/discoveries/<module-slug>-survey.md`.
4. Phase 3 — Remote Discovery: skip if `gh` unavailable. Iterate every file in the path with PR history. Build PR inventory once, then per file fetch full context (body, review comments, inline comments, reactions). Classify each PR as Cosmetic (skipped), Key (high-density discussion), Moderate, or Quiet. Write per-file remote contexts plus aggregate files for module issues, releases, and a remote summary.
5. Phase 4 — Local Discovery: for priority files from survey, capture purpose, apparent decisions, critical dependencies, risks, plus a Remote context section that cross-references Key PRs. Suggest intent markers as a patch with PR references in justification comments.
6. Phase 5 — Promote: detect patterns appearing 3+ times across local and remote findings, draft ADR candidates in `docs/architecture/_candidates/`, run `python memory/index.py --incremental` if available.

Read-only for source code. Source is never modified. Marker patch and ADR candidates require human review before application.

Output paths:
- Survey: `memory/discoveries/<module-slug>-survey.md`
- Per-file remote context: `memory/discoveries/<module-slug>/<file-slug>-remote.md`
- Per-file discovery notes: `memory/discoveries/<module-slug>/<file-slug>.md`
- Module issues: `memory/discoveries/<module-slug>-issues.md`
- Module releases: `memory/discoveries/<module-slug>-releases.md`
- Remote summary: `memory/discoveries/<module-slug>-remote-summary.md`
- Intent marker patch: `memory/discoveries/<module-slug>/markers.patch`
- ADR candidates: `docs/architecture/_candidates/adr-XXX-<topic>.md`

Pre-requisites for full coverage:
- `gh auth login` completed (otherwise Phase 3 is skipped)
- Repo hosted on GitHub (otherwise Phase 3 is skipped)
- `git` history available locally

Use this before `/implement` or `/refactor` on modules where memory and docs are empty. Designed for codebases older than 5 years with no convention discipline.
