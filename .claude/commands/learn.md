Analyze recent work and extract patterns to improve skills and conventions.

Arguments: $ARGUMENTS (optional flags, can combine):
  --since "2 weeks ago"    Analyze commits since date (default: last 20 commits)
  --commits 20             Analyze last N commits
  --conversations 5        Mine last N Claude session transcripts for undocumented decisions

Workflow:
1. Activate the `learner` skill
2. Analyze recent git history (commits, diffs, file changes)
3. Compare patterns against existing skills in .claude/skills/
4. Identify: skill gaps, skill improvements, convention drift, hook gaps
5. If --conversations: also mine session transcripts from ~/.claude/projects/ for:
   - Decisions made but not documented in ADRs
   - Recurring corrections (human corrected agent 3+ times)
   - Knowledge gaps the agent didn't have
   - Workarounds that should be formalized as skills
6. Write report to docs/architecture/learner-report-{date}.md
7. Present summary and ask which suggestions to adopt
8. If approved, apply changes to skills, CLAUDE.md, or hooks
