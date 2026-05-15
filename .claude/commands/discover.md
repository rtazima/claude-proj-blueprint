Legacy code archaeology and context bootstrap with multi-provider remote discovery.

Arguments: $ARGUMENTS (module path, directory, or file to discover)

Workflow:
1. Activate the `legacy-context` skill
2. Phase 1 — Pre-flight: detect remote provider, validate auth (PAT for Azure DevOps, gh for GitHub), parse repo identifiers, estimate PR/issue volume, detect PR coverage to identify trunk-based-without-PRs cultures, detect memory infrastructure availability. Sets flags for downstream phases.
3. Phase 2 — Survey: map territory with git log and filesystem inventory. Identify recent hot files (top commits last 24 months), persistent hot files (top commits all-time), and cold-but-imported files (untouched 3+ years, still referenced).
4. Phase 3 — Remote Discovery: skipped if provider unknown or auth invalid. Polymorphic by provider (gh for GitHub, az + REST for Azure DevOps). Both produce identical output. Iterates every file with PR history, classifies as Cosmetic (skipped), Key, Moderate, or Quiet. Optional early-exit heuristic (default off) samples 5 recent PRs and runs in lean mode if no human review density is detected.
5. Phase 4 — Local Discovery: for priority files from survey, capture purpose, apparent decisions, critical dependencies, risks, plus Remote context section cross-referencing Key PRs. Commit message scan window auto-extends to 40 entries when trunk-based detected. Suggests intent markers as patch.
6. Phase 5 — Promote: detect patterns appearing 3+ times across local and remote findings, draft ADR candidates in `docs/architecture/_candidates/`. Auto-creates `adr-000-template.md` if missing. Runs `python memory/index.py --incremental` if available; documents skip and recovery instructions in summary if not.

Tunable flags (defaults in parentheses, override via env var):
- `LEGACY_CONTEXT_EARLY_EXIT` (false): if true, Phase 3 may run in lean mode on repos with no PR review culture
- `LEGACY_CONTEXT_TRUNK_THRESHOLD` (30): PR coverage % below which the repo is classified as trunk-based
- `LEGACY_CONTEXT_EARLY_EXIT_SAMPLE` (5): sample size for early-exit detection
- `LEGACY_CONTEXT_EARLY_EXIT_THRESHOLD` (2): minimum human review comments per PR to consider density present

Defaults bias toward completeness. Override for speed when you have validated the repo profile.

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
