---
name: legacy-context
description: "Legacy code archaeology and context bootstrap. Activated when the user mentions \"legacy code\", \"código legado\", \"sistema antigo\", \"código sem documentação\", \"discover module\", \"entender módulo\", \"arqueologia de código\", \"código que ninguém entende\", or runs /discover. Populates the empty upper layers of tiered lookup (memory and docs) before context-engineering techniques can be effective. Read-only for source code: outputs discovery notes, ADR candidates, and suggested intent markers. Remote discovery supports GitHub (via gh CLI) and Azure DevOps (via az CLI plus REST)."
allowed tools: Read, Grep, Glob, Bash, Write
---

# Legacy Context

Most context-engineering techniques assume layers 1 and 2 of tiered lookup
(semantic memory and structured docs) already contain useful information.
In consolidated codebases this assumption breaks. There are no ADRs, no
post-mortems indexed, no runbooks, no skill memory. Tiered lookup collapses
to layer 3 (raw code) and every session pays the full reading cost again.

This skill runs **before** context-engineering becomes useful. It does code
archaeology and writes discovery notes, ADR candidates, and intent marker
suggestions into the empty layers, so that the next sessions can use the
cheaper layers as designed.

The skill is read-only for source code. It never edits source files. It
writes only to `memory/discoveries/`, `docs/architecture/_candidates/`,
and emits intent marker patches for human review.

## Operating principle

Bias toward completeness. When in doubt, capture more, not less. In
consolidated codebases, the contextual gem is usually the comment buried
in a 6-year-old PR review or the issue closed as "wontfix" with three
paragraphs of reasoning. Missing those is a worse failure than producing
verbose discovery notes.

## Supported remote providers

| Provider | Detection | Auth | Notes |
|---|---|---|---|
| GitHub | URL contains `github.com` | `gh auth status` | Full feature parity |
| Azure DevOps | URL contains `dev.azure.com` or `.visualstudio.com` | `AZURE_DEVOPS_EXT_PAT` env var (no `az login` needed) | No reactions on comments; releases mapped to git tags |
| Other (GitLab, Bitbucket, self-hosted) | Anything else | n/a | Phase 3 skipped with warning |

## Rules

1. **Read source, write context.** Never modify source files. All output
   goes to discovery notes, ADR candidates, or marker patches for review.
2. **Discovery before implementation.** This skill does not implement
   features. If implementation is needed, hand off to `/implement` after
   discovery completes.
3. **Why, not what.** Source code already shows what runs. Discovery
   captures why it exists, what depends on it, and what breaks if changed.
4. **Cover the path entirely on remote.** Remote discovery iterates every
   file in the path, not just the priority ones from the survey. A "warm"
   file with no commit pattern may still have a critical PR discussion
   attached to it.
5. **Cap source-code reading depth, not remote breadth.** If a single
   source file exceeds 2,000 lines, treat it as a sub-module and recurse.
   On remote, do not cap by top-N. Stratify by discussion density instead.
6. **Outputs go to predictable paths.** Other skills (memory, incoherence
   detector, ADR) consume the discovery output. Keep file naming consistent
   across providers.
7. **Same output across providers.** Phase 3 produces identical file
   structure whether running on GitHub or Azure DevOps. Downstream phases
   should not need to know which provider generated the data.

## Workflow

### Phase 1: Pre-flight checks

Detect the remote provider, validate authentication, and estimate volume
before committing to a long run.

1. Detect provider:
   ```bash
   git remote get-url origin
   ```
   Match the URL:
   - Contains `github.com` → provider=github
   - Contains `dev.azure.com` or `.visualstudio.com` → provider=azure_devops
   - Anything else → provider=unknown

2. Parse repo identifiers:

   GitHub URLs (`git@github.com:OWNER/REPO.git` or `https://github.com/OWNER/REPO`):
   ```bash
   gh repo view --json owner,name,nameWithOwner
   ```

   Azure DevOps URLs:
   - HTTPS form: `https://ORG@dev.azure.com/ORG/PROJECT/_git/REPO`
   - SSH form: `git@ssh.dev.azure.com:v3/ORG/PROJECT/REPO`

   Extract ORG, PROJECT, REPO. URL-decode the PROJECT name (Azure allows
   spaces in project names, encoded as `%20`).

3. Validate authentication:

   For provider=github:
   ```bash
   gh auth status
   ```

   For provider=azure_devops:
   ```bash
   # PAT must be exported in the shell that launched Claude Code.
   # az login is NOT required for Azure DevOps with PAT auth. Many
   # users have DevOps access without an Azure Cloud subscription;
   # `az account show` will fail for them but DevOps API access works.
   test -n "$AZURE_DEVOPS_EXT_PAT" || { echo "AZURE_DEVOPS_EXT_PAT not set"; }
   # Validate by listing one PR from the target repo. If this returns
   # JSON (even an empty array), authentication is valid.
   az repos pr list --repository "$REPO" --status all --top 1 --output json >/dev/null
   ```

   If any check fails for the detected provider, OR provider=unknown:
   - Set internal flag `remote_discovery=false`
   - Phase 3 will skip with visible warning
   - Phases 2, 4, 5 still run

4. Estimate volume:

   For github:
   ```bash
   gh search prs --repo "$NAMEWITHOWNER" --limit 1 --json totalCount --jq '.[].totalCount'
   ```

   For azure_devops:
   ```bash
   # No direct totalCount; sample to estimate
   az repos pr list --repository "$REPO" --status all --top 1000 --output json | jq 'length'
   ```
   If the sample returns exactly 1000, total may be much higher. Adjust
   pagination strategy in Phase 3b accordingly.

5. If estimated PR count exceeds 5000, print warning that Phase 3 will be
   slow but proceed. If exceeds 20000, ask for confirmation before
   continuing.

6. Print a one-line pre-flight summary: `provider`, repo identifier
   (`owner/repo` or `org/project/repo`), estimated PR count, estimated
   issue/work-item count, `remote_discovery` flag.

### Phase 2: Survey

Map the territory before reading anything in depth. Window widened for
codebases older than 5 years.

1. Define the target scope from the user input. Examples: a directory
   (`src/billing/`), a single file (`src/Auth/AuthController.cs`), or a
   logical module (`Billing module`).
2. Inventory the files:
   ```bash
   find <path> -type f \( -name '*.cs' -o -name '*.py' -o -name '*.ts' \
     -o -name '*.js' -o -name '*.java' -o -name '*.rb' -o -name '*.go' \) \
     | xargs wc -l | sort -rn | head -50
   ```
3. Detect hot files. Use two windows in a codebase older than 5 years:
   ```bash
   # Recent hot: commits in last 24 months
   git log --since="2 years ago" --pretty=format: --name-only -- <path> \
     | sort | uniq -c | sort -rn | head -20

   # Persistent hot: commits all-time
   git log --pretty=format: --name-only -- <path> \
     | sort | uniq -c | sort -rn | head -20
   ```
   The intersection (files in both lists) are structurally central.
   Files only in "persistent hot" but not "recent hot" are usually stable
   foundations. Files only in "recent hot" are active work areas.

4. Detect cold files. In an old codebase, the threshold for cold extends:
   ```bash
   git log --before="3 years ago" --name-only --pretty=format: -- <path> \
     | sort -u > /tmp/all-files.txt
   git log --since="3 years ago" --name-only --pretty=format: -- <path> \
     | sort -u > /tmp/recent-files.txt
   comm -23 /tmp/all-files.txt /tmp/recent-files.txt
   ```
   Files untouched for 3+ years that are still imported elsewhere are
   high-context: ancient decisions still load-bearing.

5. Check test coverage proxy: count test files alongside source files in
   the same module. Low or zero test count is a discovery signal.

6. Write the survey to `memory/discoveries/<module-slug>-survey.md`:
   - Total LOC, file count, language breakdown
   - Recent hot files (top 20, with commit counts)
   - Persistent hot files (top 20, with all-time commit counts)
   - Cold-but-imported files
   - Test ratio (test files / source files)
   - First-pass risk indicators (zero tests on hot files, files older
     than 5 years still being modified, single-author files with author
     no longer in `git shortlog`, etc.)

Do not read file contents in depth during this phase. The survey is the
map, not the territory.

### Phase 3: Remote Discovery

Skip this phase entirely if Phase 1 set `remote_discovery=false`. Print
warning and proceed to Phase 4.

This phase iterates every file in the path that has any commit history,
not just the priority ones from the survey.

Branch by provider. Both branches produce the same output structure
(per-file remote contexts plus three module aggregates).

#### Phase 3a: GitHub provider

1. Build PR inventory once, used by all per-file lookups:
   ```bash
   gh pr list --state all --limit 1000 \
     --json number,title,body,state,createdAt,mergedAt,closedAt,\
   author,files,labels,reactions \
     > /tmp/pr-inventory.json
   ```
   Paginate with `--search "is:pr created:<date>..<date>"` if total
   exceeds 1000 across the repo lifetime.

2. For each file under the path:
   - Get SHAs that touched the file: `git log --format="%H" -- <file>`
   - Resolve each SHA to PR number(s) by querying the inventory or
     calling `gh api /repos/{owner}/{repo}/commits/<sha>/pulls`
   - Collect unique PR numbers for the file

3. For each unique PR, fetch full context once and cache it. Detail
   needed: title, body, author, merge state, merge date, files touched,
   review comments (both summary review and inline), reactions on the
   PR and on each comment.
   ```bash
   # PR body and metadata
   gh pr view <num> --json title,body,author,state,mergedAt,closedAt,\
   files,reviews,comments,reactions,labels

   # Inline review comments (per-line)
   gh api /repos/{owner}/{repo}/pulls/<num>/comments
   ```

4. Classify each PR by density:
   - **Cosmetic**: only touches `.md`, `.txt`, `.gitignore`,
     `.editorconfig`, files in `docs/` or `__tests__/`, OR diff smaller
     than 20 lines AND zero review comments.
   - **Key**: 5+ review comments (summary + inline combined) OR
     mentioned in a release note OR has 2+ reactions on review comments
     OR has the word "decision", "architecture", "breaking" anywhere in
     body or any comment.
   - **Moderate**: 2-4 review comments and not Key.
   - **Quiet**: 0-1 review comments, not Cosmetic, not Key.

5. Write to `memory/discoveries/<module-slug>/<file-slug>-remote.md`,
   one file per source file that has any PR history. Skip Cosmetic PRs
   entirely. See "Per-file remote context format" section below.

6. Generate three aggregate files for the module (see "Module aggregate
   files format" section below).

7. If rate limit is approached, pause and warn. The user can resume by
   re-running the phase, which will skip already-cached PRs.

#### Phase 3b: Azure DevOps provider

Mirror of Phase 3a using Azure DevOps APIs. Produces identical output
structure with provider-specific data sourcing. Assumes
`AZURE_DEVOPS_EXT_PAT` is exported in the calling shell.

1. Build PR inventory once:
   ```bash
   # ORG, PROJECT, REPO from Phase 1
   az repos pr list --repository "$REPO" --status all --top 1000 \
     --output json > /tmp/pr-inventory.json
   ```
   If `jq 'length' /tmp/pr-inventory.json` returns exactly 1000, paginate
   using `--skip` until empty results:
   ```bash
   skip=1000
   while true; do
     batch=$(az repos pr list --repository "$REPO" --status all \
       --top 1000 --skip $skip --output json)
     count=$(echo "$batch" | jq 'length')
     [ "$count" -eq 0 ] && break
     echo "$batch" | jq '.[]' >> /tmp/pr-inventory.json
     skip=$((skip + 1000))
   done
   ```

2. For each file under the path:
   - Get SHAs that touched the file: `git log --format="%H" -- <file>`
   - For each SHA, resolve to PR id(s) via the REST API:
     ```bash
     curl -s -u ":$AZURE_DEVOPS_EXT_PAT" \
       "https://dev.azure.com/$ORG/$PROJECT_ENCODED/_apis/git/repositories/$REPO/commits/$SHA/pullRequests?api-version=7.0" \
       | jq '.value[].pullRequestId'
     ```
     `$PROJECT_ENCODED` is the URL-encoded project name from Phase 1.
   - Collect unique PR ids for the file.

3. For each unique PR, fetch:
   - Basic info and metadata:
     ```bash
     az repos pr show --id "$PR_ID" --output json
     ```
   - Threads (which contain both general comments and inline review
     comments in Azure DevOps):
     ```bash
     curl -s -u ":$AZURE_DEVOPS_EXT_PAT" \
       "https://dev.azure.com/$ORG/$PROJECT_ENCODED/_apis/git/repositories/$REPO/pullRequests/$PR_ID/threads?api-version=7.0"
     ```
     Each thread has `comments[]` and optional `threadContext` indicating
     file path and line numbers. Inline review comments have
     `threadContext` set; general PR comments do not.
   - Linked work items:
     ```bash
     az repos pr show-work-items --id "$PR_ID" --output json
     ```

4. Classify each PR by density. Same rules as Phase 3a, with two
   provider-specific adaptations:
   - **Cosmetic** and **Moderate** and **Quiet**: same thresholds as 3a,
     counting all comments across all threads (excluding system-generated
     threads where `properties.CodeReviewThreadType` indicates auto-events
     like "auto complete enabled").
   - **Key**: 5+ thread comments OR linked to a work item whose
     description has 200+ characters OR has the word "decision",
     "architecture", "breaking" anywhere in PR body or comments.
   - Azure DevOps has no reactions feature. The reaction-based criterion
     from Phase 3a is dropped here.

5. Write to `memory/discoveries/<module-slug>/<file-slug>-remote.md`
   using the same format as Phase 3a. Author display uses Azure DevOps
   `displayName` from the API (which is typically the person's name, not
   a handle).

6. Generate the three aggregate files. See "Module aggregate files format"
   below. Azure-specific notes:
   - Issues file uses work items. Query via WIQL:
     ```bash
     az boards work-item query --wiql \
       "SELECT [System.Id], [System.Title], [System.State], [System.Tags] FROM workitems WHERE [System.Title] CONTAINS '<module-keyword>' OR [System.Tags] CONTAINS '<module-keyword>' ORDER BY [System.ChangedDate] DESC" \
       --output json
     ```
     For each returned work item, fetch detail with
     `az boards work-item show --id "$WI_ID" --output json`. Capture
     description, comments, links, and state transitions.
   - Releases file falls back to git tags (Azure DevOps Releases is a
     Pipelines concept, not used for release notes in most repos):
     ```bash
     git tag --sort=-creatordate
     ```
     For each tag, list commits in the path between the tag and its
     predecessor, and include any matching work item titles. Flag this
     limitation explicitly in the file header.

7. Rate limit handling: Azure DevOps allows ~200 req/sec/user under
   typical PAT scopes. If a 429 is returned, pause for 60 seconds and
   retry. If 429 repeats more than 3 times, abort the phase and write
   what was captured so far.

#### Per-file remote context format

Both Phase 3a and Phase 3b write the same structure per source file:

```markdown
# Remote context: <file>

Provider: github | azure_devops
Generated: <date>

## Key PRs (high discussion density)

### PR #<num>: <title>
- Author: @username | Merged: 2024-03-15 | State: merged
- Files touched: <files>
- Linked items: #<issue-or-wi-id> (if any)
- Body: <full body, no truncation>
- Top review comments:
  - @reviewer1: "<comment text>"
  - @reviewer2: "<comment text>"
- Inline comments on critical lines:
  - Line 142: @reviewer1: "<comment>"

### PR #<num>: ...
...

## Moderate PRs

### PR #<num>: <title>
- Author: @username | Merged: 2023-06-12 | State: merged
- Files touched: <files>
- Body: <full body>
- Review comments:
  - @reviewer: "<comment>"

## Quiet PRs (low discussion, full inventory)

- PR #<num> | 2020-04-22 | @author | <title>
- PR #<num> | 2019-11-03 | @author | <title>
```

#### Module aggregate files format

`memory/discoveries/<module-slug>-issues.md` — every issue (GitHub) or
work item (Azure DevOps) that mentions any file path in the module, any
keyword in the module name, or is linked from any PR captured above.
Same three-tier classification by comment count. Note in the file header
which provider produced it.

`memory/discoveries/<module-slug>-releases.md` — every release where
release notes mention a file path or module identifier. For GitHub, uses
`gh release list` and `gh release view`. For Azure DevOps, uses git tags
as a fallback and notes the limitation explicitly.

`memory/discoveries/<module-slug>-remote-summary.md` — meta overview:
provider used, total PRs captured, total Key/Moderate/Quiet counts, top
authors, most-referenced issues or work items, period covered, gaps
detected (files in the path with zero PR history is a strong tell of
either dead code or pre-Git-era code).

### Phase 4: Local Discovery

For each priority file from the survey (recent hot, persistent hot, and
cold-but-imported), produce a discovery note. This phase reads the file
in depth and cross-references with remote findings from Phase 3.

1. Read the file in full once.
2. Run `git blame --line-porcelain <file> | grep '^author ' | sort | uniq -c | sort -rn`
   to identify implicit owners (recurring authors). Flag authors who are
   no longer in `git shortlog -sn --since="6 months ago"` — that
   contextual knowledge has left the building.
3. Read the last 20 commit messages that touched the file:
   ```bash
   git log -20 --pretty=format:"%h %ad %an %s" --date=short -- <file>
   ```
4. Load `memory/discoveries/<module-slug>/<file-slug>-remote.md` if it
   exists. The Key PRs section is required reading; Moderate is
   recommended; Quiet is reference-only.
5. Capture five things in `memory/discoveries/<module-slug>/<file-slug>.md`:
   - **Purpose** — one paragraph on what the file does today
   - **Apparent decisions** — embedded decisions visible in the code but
     not explained anywhere (naming patterns, control flow choices,
     hardcoded thresholds, library choices that look deliberate)
   - **Critical dependencies** — what other files, services, env vars,
     DB tables, or external systems this file relies on
   - **Risks and gotchas** — observed signs of accidental coupling, dead
     code, partial migrations, half-applied patterns
   - **Remote context** — summary of Key PRs from `<file-slug>-remote.md`
     with explicit cross-references (e.g., "PR #234 in 2022 made this
     temporary, see work item #1045 for full reasoning"). Pull verbatim
     quotes from review comments when they capture decision rationale
     that the code does not.
6. Suggest intent markers as a patch file at
   `memory/discoveries/<module-slug>/markers.patch`. Use markers from
   the `intent-markers` skill: `:PERF:`, `:UNSAFE:`, `:SCHEMA:`,
   `:SECURITY:`, `:HACK:`, `:FLAKY:`. Each suggestion includes a one-line
   justification referencing the PR or issue/work-item that revealed it
   (e.g., `// :HACK: temporary per PR #234`).

Anti-pattern: do not read files linearly trying to understand every line.
Use `git blame`, naming patterns, and remote PR context to find anchor
points first, then read around them.

### Phase 5: Promote

Move discovery output into the layers that tiered lookup queries.

1. Scan all discovery notes (local and remote) for patterns that appear
   three or more times across files. Each such pattern is an ADR
   candidate. Sources include: same workaround applied in multiple
   places, same external dependency assumption made in multiple files,
   recurring topic across PR discussions (cross-check the
   `<module-slug>-remote-summary.md`).
2. For each candidate, write a draft to
   `docs/architecture/_candidates/adr-XXX-<topic>.md` using the template
   in `docs/architecture/adr-000-template.md`. Mark it explicitly as
   `Status: candidate — needs human review`. Reference the source PRs
   and files that supported the pattern detection.
3. Run `python memory/index.py --incremental` to index discovery notes
   and ADR candidates into semantic memory. If `memory/index.py` is not
   available in the target project, skip with a visible warning and
   continue. The text files in `memory/discoveries/` are still useful
   without semantic indexing.
4. Print a final summary to the user:
   - Provider used (github | azure_devops | skipped)
   - Files explored in depth
   - PRs captured (Key / Moderate / Quiet counts)
   - Issues or work items captured
   - Releases or tags referenced
   - Implicit decisions detected
   - ADR candidates proposed (with paths)
   - Intent marker patch path
   - Memory indexing result (or skip notice)

The patch file is never applied automatically. The user reviews it,
applies what makes sense, and discards the rest.

## Output paths

| Artifact | Path |
|---|---|
| Survey | `memory/discoveries/<module-slug>-survey.md` |
| Per-file remote context | `memory/discoveries/<module-slug>/<file-slug>-remote.md` |
| Per-file discovery notes | `memory/discoveries/<module-slug>/<file-slug>.md` |
| Module issues / work items | `memory/discoveries/<module-slug>-issues.md` |
| Module releases / tags | `memory/discoveries/<module-slug>-releases.md` |
| Remote discovery summary | `memory/discoveries/<module-slug>-remote-summary.md` |
| Intent marker patch | `memory/discoveries/<module-slug>/markers.patch` |
| ADR candidates | `docs/architecture/_candidates/adr-XXX-<topic>.md` |

## Racionalizações comuns

| Racionalização | Realidade |
|---|---|
| "Preciso ler todos os arquivos do módulo pra entender" | Hot e cold cobrem o esqueleto. Os arquivos do meio aparecem sob demanda quando vc trabalhar em features específicas. |
| "O código tá ruim, vou refatorar antes de documentar" | Refactor sem entender por que o código tá assim apaga contexto. Discovery primeiro, refactor é outra task. |
| "Vou ler do começo ao fim, sequencial" | Leitura linear é cara e cega. Blame, naming e commit history apontam os pontos que carregam contexto. |
| "ADR pode ser gerado direto, sem revisão humana" | Skill sugere candidato baseado em padrão observado. Humano decide se o padrão foi decisão consciente ou acidente histórico que precisa ser consertado. |
| "Vou aplicar os intent markers direto no código" | Skill não tem permissão pra editar source. Patch fica em `memory/discoveries/` pra revisão. |
| "Remote discovery é overkill, git log já dá o contexto" | Em código de 5+ anos, metade do contexto mora nos PRs (review comments, decisões discutidas). git log mostra que mudou, não por quê. |
| "Posso pular o Phase 1 e ir direto pro discovery" | Phase 1 evita rate limit na Phase 3 e te avisa de volume excessivo antes da skill consumir tempo. |
| "Vou capturar só os top 10 PRs pra economizar" | Em legacy, a discussão crítica frequentemente está num PR antigo aparentemente trivial. Estratifica por densidade, não por contagem. |
| "GitHub e Azure DevOps são iguais, posso reusar a Phase 3a" | API e modelo de dados diferem. Threads em Azure ≠ inline comments em GitHub. Work items ≠ issues. A Phase 3b traduz isso pro mesmo output. |
| "PAT do Azure funciona se eu colocar no .zshrc" | Funciona, mas vaza o token em arquivo de config. Exporta na sessão e fecha. Trabalho de cliente, segurança importa. |
| "Preciso de `az login` antes de rodar a skill em Azure DevOps" | Não. O PAT exportado em `AZURE_DEVOPS_EXT_PAT` basta. Muito usuário tem acesso ao DevOps sem subscription Azure Cloud, então `az login` nem completa. A skill valida acesso real via `az repos pr list`. |

## Red Flags

- Mais de 10 arquivos source explorados em profundidade numa única sessão
- Discovery note maior que 500 linhas por arquivo (provavelmente está reproduzindo o código em vez de capturar contexto)
- ADR candidato proposto com menos de 3 ocorrências do padrão
- Intent marker sugerido sem justificativa concreta acima da linha
- Tentativa de editar arquivos em `src/` (skill não tem Edit, deve falhar limpo)
- Survey omitido e pulou direto pra discovery (perde os ganchos de hot/cold)
- Phase 3 rodando sem Phase 1 (pode estourar rate limit sem aviso)
- PR classificado como Key sem nenhum dos critérios objetivos atendidos
- Quiet PRs sem listagem (estrutura de output incompleta, pode estar perdendo inventário)
- Phase 3b sem `AZURE_DEVOPS_EXT_PAT` exportado (smoke test deve pegar antes, mas se passar é red flag)
- Output em provider github e azure_devops com estruturas diferentes (regressão da abstração)

## When to hand off

| Situation | Hand off to |
|---|---|
| Discovery feita, hora de implementar mudança | `/implement` ou `implement-prd` skill |
| Pattern detectado parece dívida, não decisão consciente | `tech-debt` skill |
| Quer verificar se docs antigas estão consistentes com discovery | `incoherence-detector` skill |
| Quer aplicar os markers sugeridos | `intent-markers` skill |
| Sessão acabou, hora de consultar discovery em sessão nova | `memory` skill (consulta tiered lookup já populado) |

## References

- Complementary skill: `.claude/skills/context-engineering/SKILL.md` (techniques that work *after* bootstrap)
- Complementary skill: `.claude/skills/intent-markers/SKILL.md` (markers vocabulary)
- Complementary skill: `.claude/skills/adr/SKILL.md` (ADR format)
- Complementary skill: `.claude/skills/incoherence-detector/SKILL.md` (post-bootstrap drift check)
- Memory infrastructure: `memory/index.py`, `memory/query.py`
- Hook: `scripts/context-guard.sh` (reactive context monitoring during work)
- External: GitHub CLI (`gh`) docs at https://cli.github.com/manual/
- External: Azure DevOps CLI (`az devops`) docs at https://learn.microsoft.com/en-us/azure/devops/cli/
- External: Azure DevOps REST API at https://learn.microsoft.com/en-us/rest/api/azure/devops/
