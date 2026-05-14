---
name: legacy-context
description: "Legacy code archaeology and context bootstrap. Activated when the user mentions \"legacy code\", \"código legado\", \"sistema antigo\", \"código sem documentação\", \"discover module\", \"entender módulo\", \"arqueologia de código\", \"código que ninguém entende\", or runs /discover. Populates the empty upper layers of tiered lookup (memory and docs) before context-engineering techniques can be effective. Read-only for source code: outputs discovery notes, ADR candidates, and suggested intent markers."
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

## Rules

1. **Read source, write context.** Never modify source files. All output
   goes to discovery notes, ADR candidates, or marker patches for review.
2. **Discovery before implementation.** This skill does not implement
   features. If implementation is needed, hand off to `/implement` after
   discovery completes.
3. **Why, not what.** Source code already shows what runs. Discovery
   captures why it exists, what depends on it, and what breaks if changed.
4. **Hot and cold first, ignore middle.** Files with many recent commits
   (hot) and files untouched for months (cold) carry the most context.
   Files with steady moderate activity are usually mature and self-evident.
5. **Cap depth.** If a single file exceeds 2,000 lines, treat it as a
   sub-module and recurse. Do not try to read it linearly.
6. **Outputs go to predictable paths.** Other skills (memory, incoherence
   detector, ADR) consume the discovery output. Keep file naming consistent.

## Workflow

### Phase 1: Survey

Map the territory before reading anything in depth.

1. Define the target scope from the user input. Examples: a directory
   (`src/billing/`), a single file (`src/Auth/AuthController.cs`), or a
   logical module (`Billing module`).
2. Inventory the files:
   ```bash
   find <path> -type f \( -name '*.cs' -o -name '*.py' -o -name '*.ts' \) \
     | xargs wc -l | sort -rn | head -20
   ```
3. Detect hot files (most commits in the last 12 months):
   ```bash
   git log --since="1 year ago" --pretty=format: --name-only -- <path> \
     | sort | uniq -c | sort -rn | head -10
   ```
4. Detect cold files (untouched for 6+ months but still in active modules):
   ```bash
   git log --before="6 months ago" --name-only --pretty=format: -- <path> \
     | sort -u > /tmp/all-files.txt
   git log --since="6 months ago" --name-only --pretty=format: -- <path> \
     | sort -u > /tmp/recent-files.txt
   comm -23 /tmp/all-files.txt /tmp/recent-files.txt
   ```
5. Check test coverage proxy: count test files alongside source files in
   the same module. Low or zero test count is a discovery signal.
6. Write the survey to `memory/discoveries/<module-slug>-survey.md`:
   - Total LOC, file count, language breakdown
   - Top 10 hot files with commit counts
   - Cold files list
   - Test ratio (test files / source files)
   - First-pass risk indicators (zero tests on hot files, files older
     than 5 years still being modified, etc.)

Do not read file contents in depth during this phase. The survey is the
map, not the territory.

### Phase 2: Discovery

For each priority file from the survey (hot list plus cold list, not the
middle), produce a discovery note.

1. Read the file in full once.
2. Run `git blame --line-porcelain <file> | grep '^author ' | sort | uniq -c | sort -rn`
   to identify implicit owners (recurring authors).
3. Read the last 10 commit messages that touched the file:
   ```bash
   git log -10 --pretty=format:"%h %ad %s" --date=short -- <file>
   ```
4. Capture four things in `memory/discoveries/<module-slug>/<file-slug>.md`:
   - **Purpose** — one paragraph on what the file does today
   - **Apparent decisions** — embedded decisions visible in the code but
     not explained anywhere (naming patterns, control flow choices,
     hardcoded thresholds, library choices that look deliberate)
   - **Critical dependencies** — what other files, services, env vars,
     DB tables, or external systems this file relies on
   - **Risks and gotchas** — observed signs of accidental coupling, dead
     code, partial migrations, half-applied patterns
5. Suggest intent markers as a patch file at
   `memory/discoveries/<module-slug>/markers.patch`. Use the markers from
   the `intent-markers` skill: `:PERF:`, `:UNSAFE:`, `:SCHEMA:`,
   `:SECURITY:`, `:HACK:`, `:FLAKY:`. Each suggestion must have a one-line
   justification in a comment above the marker line.

Anti-pattern: do not read files linearly trying to understand every line.
Use `git blame` and naming patterns to find anchor points first, then read
around them.

### Phase 3: Promote

Move discovery output into the layers that tiered lookup queries.

1. Scan all discovery notes for patterns that appear three or more times
   across files (e.g., same workaround applied in five places, same
   external dependency assumption made in four files). Each such pattern
   is an ADR candidate.
2. For each candidate, write a draft to
   `docs/architecture/_candidates/adr-XXX-<topic>.md` using the template
   in `docs/architecture/adr-000-template.md`. Mark it explicitly as
   `Status: candidate — needs human review`.
3. Run `python memory/index.py --incremental` to index discovery notes
   and ADR candidates into semantic memory.
4. Print a final summary to the user:
   - Files explored in depth
   - Implicit decisions detected
   - ADR candidates proposed (with paths)
   - Intent marker patch path
   - Memory indexing result

The patch file is never applied automatically. The user reviews it,
applies what makes sense, and discards the rest.

## Output paths

| Artifact | Path |
|---|---|
| Survey | `memory/discoveries/<module-slug>-survey.md` |
| Discovery notes | `memory/discoveries/<module-slug>/<file-slug>.md` |
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

## Red Flags

- Mais de 10 arquivos explorados em profundidade numa única sessão
- Discovery note maior que 200 linhas por arquivo (provavelmente está reproduzindo o código em vez de capturar contexto)
- ADR candidato proposto com menos de 3 ocorrências do padrão
- Intent marker sugerido sem justificativa concreta acima da linha
- Tentativa de editar arquivos em `src/` (skill não tem Edit, deve falhar limpo)
- Survey omitido e pulou direto pra discovery (perde os ganchos de hot/cold)

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
