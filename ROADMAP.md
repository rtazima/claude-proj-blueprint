# Roadmap

Living document. Tracks future considerations across the blueprint that
are intentionally not in the current release. Reviewed every few months.

Contributions welcome via PR. To propose a new item, open an issue first
to discuss scope and fit.

---

## legacy-context skill

### Stack-specific heuristics

The current skill is intentionally stack-agnostic. Field validation has
been on .NET C# + Azure DevOps + PostgreSQL only. Adding stack-specific
heuristics (ASP.NET controller idioms, EF Core repository patterns,
Spring/Java conventions, Ruby on Rails resource controllers, etc.)
would improve survey precision and discovery note quality. Deferred
until at least three different stacks have been validated in the field;
generalizing from one stack is premature.

### GitLab and Bitbucket providers

Phase 3 currently supports GitHub (via `gh`) and Azure DevOps (via `az`
plus REST). GitLab (`glab` CLI) and Bitbucket (`bb` CLI, less mature)
follow the same architectural pattern. Adding them is mechanical work
once an active user has a concrete use case. Not adding speculatively.

### Self-hosted instance support

GitHub Enterprise Server, Azure DevOps Server (on-premise), and
self-hosted GitLab work in theory with the current implementation but
have not been validated. The remote URL detection in Phase 1 currently
matches public hostnames only. Self-hosted typically requires URL
pattern config and PAT scoping changes that vary per deployment.

### Plugin-based Phase 3 architecture

With two concrete providers (GitHub, Azure DevOps), the polymorphism is
shallow. A third or fourth provider may justify extracting a provider
interface and loading implementations dynamically. Premature with the
current count.

### Wiki, Confluence, Jira, Slack integration

Remote discovery currently scopes to PRs/MRs, issues/work-items, and
releases/tags. Wikis and ticketing systems outside the code host
(Confluence, Jira) often carry decision context, but integration is
non-trivial: each has different APIs, auth models, and content
structures. Field demand will drive priority.

### Incremental discovery

Current `/discover <path>` is full-scan every time. For long-lived
projects where discovery runs periodically (quarterly review of
context), an incremental mode would skip files unchanged since the
previous run and only re-discover changed paths. Storage of "last
discovered SHA per file" is straightforward; integration with the
existing memory infrastructure is the design question.

### Discovery quality metrics

The current Phase 5 summary reports counts (PRs captured, ADR
candidates proposed, etc.) but not quality. Future versions could
report on coverage (% of priority files with non-trivial findings),
density of insights per file, or freshness of context (how recent the
referenced decisions are). Useful for users running the skill
repeatedly on the same module.

### Cross-project discovery

Currently scoped to one repo at a time. Some legacy systems span
multiple repos (API + web + worker + shared library). A "discovery
session" that traverses related repos and produces a consolidated
context would help, but raises hard questions about cross-repo PR
linking, shared work items, and how to scope the survey.

---

## Other skills and infrastructure

### Context governance and `/context stats`

Planned for a future release dedicated to context observability.
Measuring context consumption per session, per skill, per task type.
Distinct from legacy-context (which bootstraps context) but
complementary (which would measure if the bootstrap is paying off).

### Source-driven Development maturation

The `source-driven-development` skill is currently focused on greenfield
patterns. Adapting it to legacy environments (where the source is the
contract because nothing else exists) is a parallel track to
legacy-context.

### Skill quality assurance

A meta-skill or harness for validating other skills against known
fixtures. Would catch regressions as skills evolve.

---

## How to contribute to this roadmap

If you implemented or rejected one of these items, update this file in
the same PR. Items that get rejected should be removed with a brief
note in the CHANGELOG explaining why ("explored, found that X, decided
not to pursue").
