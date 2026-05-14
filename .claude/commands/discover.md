Legacy code archaeology and context bootstrap with multi-provider remote discovery.

Arguments: $ARGUMENTS (module path, directory, or file to discover)

Workflow:
1. Activate the `legacy-context` skill
2. Phase 1 — Pre-flight: detect remote provider from `git remote get-url origin`. Validate auth: `gh auth status` for GitHub, `$AZURE_DEVOPS_EXT_PAT` set plus `az repos list` smoke test for Azure DevOps. Parse repo identifiers (owner/repo for GitHub; org/project/repo for Azure). Estimate PR/issue volume. Sets flag for Phase 3.
3. Phase 2 — Survey: map the territory with git log and filesystem inventory. Identify recent hot files (top commits last 24 months), persistent hot files (top commits all-time), and cold-but-imported files (untouched 3+ years, still referenced). Compute LOC, test ratio, and risk indicators.
4. Phase 3 — Remote Discovery: skipped if provider is unknown or auth invalid. Polymorphic by provider: Phase 3a uses `gh` CLI for GitHub, Phase 3b uses `az` CLI plus REST for Azure DevOps. Both produce identical output structure. Iterates every file with PR history, fetches every attached PR, classifies as Cosmetic (skipped), Key (high-density discussion), Moderate, or Quiet. Writes per-file remote contexts plus aggregate files for module issues/work-items, releases/tags, and a remote summary.
5. Phase 4 — Local Discovery: for priority files from survey, capture purpose, apparent decisions, critical dependencies, risks, plus a Remote context section that cross-references Key PRs verbatim. Suggest intent markers as a patch with PR references in justification comments.
6. Phase 5 — Promote: detect patterns appearing 3+ times across local and remote findings, draft ADR candidates in `docs/architecture/_candidates/`, run `python memory/index.py --incremental` if available.

Read-only for source code. Source is never modified. Marker patch and ADR candidates require human review before application.

Output paths:
- Survey: `memory/discoveries/<module-slug>-survey.md`
- Per-file remote context: `memory/discoveries/<module-slug>/<file-slug>-remote.md`
- Per-file discovery notes: `memory/discoveries/<module-slug>/<file-slug>.md`
- Module issues / work items: `memory/discoveries/<module-slug>-issues.md`
- Module releases / tags: `memory/discoveries/<module-slug>-releases.md`
- Remote summary: `memory/discoveries/<module-slug>-remote-summary.md`
- Intent marker patch: `memory/discoveries/<module-slug>/markers.patch`
- ADR candidates: `docs/architecture/_candidates/adr-XXX-<topic>.md`

Supported providers:
- GitHub: detected by `github.com` in remote URL. Requires `gh auth login` completed.
- Azure DevOps: detected by `dev.azure.com` or `.visualstudio.com` in remote URL. Requires `AZURE_DEVOPS_EXT_PAT` exported in the shell that launched Claude Code. PAT needs Read scopes for Code, Pull Request Threads, and Work Items. `az login` is NOT required (PAT alone authenticates DevOps API access).
- Other providers (GitLab, Bitbucket, self-hosted): Phase 3 is skipped with warning. Phases 2, 4, 5 still run.

Use this before `/implement` or `/refactor` on modules where memory and docs are empty. Designed for codebases older than 5 years with no convention discipline.
