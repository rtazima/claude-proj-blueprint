---
name: learner
description: "Pattern learner. Activated when the user says \"learn from this\", \"what patterns\", \"improve skills\", \"retrospective\", \"session review\", or wants to extract reusable patterns from recent work to improve the project's skills and conventions."
allowed tools: Read, Grep, Glob, Bash, Write
---

# Learner

Analyze completed work and extract patterns to improve existing skills, suggest new ones,
and refine project conventions. This is a meta-skill: it makes other skills better.

## Rules

1. **Read-only analysis first** — understand patterns before suggesting changes
2. **Evidence-based** — every suggestion must reference specific commits, files, or patterns
3. **Conservative** — suggest changes, don't auto-apply. The human decides what to adopt
4. **Quality gate** — only suggest patterns that appear 3+ times (not one-offs)
5. **Output to docs** — write the report to `docs/architecture/learner-report-{date}.md`

## Workflow

### Phase 1: Gather data
1. Run `git log --oneline -N` (N from args, default 20) to see recent commits
2. Run `git log --stat -N` to see which files changed most
3. Read the diffs of significant commits: `git show --stat <sha>`
4. Read existing skills in `.claude/skills/*/SKILL.md`
5. Read existing commands in `.claude/commands/*.md`
6. Read `CLAUDE.md` for current conventions

### Phase 2: Analyze patterns
Look for:

#### A. Skill gaps
- Recurring manual steps that no skill covers
- Patterns Claude keeps explaining/doing that could be codified
- Workarounds or repeated code patterns across files

#### B. Skill improvements
- Skill rules that were violated in practice (maybe they're wrong)
- Skill checklists that are consistently skipped (maybe too strict)
- Skill triggers that didn't fire when they should have (description needs updating)
- Missing examples in skills that would have helped

#### C. Convention drift
- CLAUDE.md rules that don't match actual practice
- Commit message style drift from Conventional Commits
- File naming patterns that evolved beyond what CLAUDE.md documents

#### D. Hook gaps
- Errors that hooks should have caught but didn't
- Repetitive manual checks that could be automated
- New file types/patterns not covered by existing hooks

### Phase 3: Report
Write a structured report:

```markdown
# Learner Report — {date}

## Analyzed
- Commits: {N} (from {oldest_sha} to {newest_sha})
- Files changed: {count}
- Period: {date_range}

## Suggested new skills
### 1. [skill-name]
- **Pattern observed**: [what was done manually 3+ times]
- **Evidence**: commits {sha1}, {sha2}, {sha3}
- **Proposed trigger**: "[keywords]"
- **Proposed rules**: [list]

## Suggested skill improvements
### 1. [existing-skill-name]
- **Current rule**: [what the skill says]
- **Observed practice**: [what actually happened]
- **Suggestion**: [specific change]
- **Evidence**: [commits/files]

## Convention updates for CLAUDE.md
- [Specific addition or correction]

## Hook suggestions
- [New hook idea with trigger and behavior]
```

### Phase 4: Present
1. Summarize findings (not the full report — just counts and highlights)
2. Ask which suggestions to adopt
3. If approved, create/modify the relevant skills, CLAUDE.md, or hooks

## Configuration
- Analysis scope: [SPEC] `--since "2 weeks ago"` or `--commits 20`
- Minimum pattern frequency: 3 (to suggest as a skill)
- Output: `docs/architecture/learner-report-{date}.md`

## References
- Inspired by oh-my-claudecode's Learner skill (level 7)
- See `.claude/skills/_template-skill/SKILL.md` for new skill format
- See `CLAUDE.md` for current conventions
