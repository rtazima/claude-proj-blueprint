Analyze recent work and extract patterns to improve skills and conventions.

Arguments: $ARGUMENTS (optional: --since "2 weeks ago" or --commits 20, default: last 20 commits)

Workflow:
1. Activate the `learner` skill
2. Analyze recent git history (commits, diffs, file changes)
3. Compare patterns against existing skills in .claude/skills/
4. Identify: skill gaps, skill improvements, convention drift, hook gaps
5. Write report to docs/architecture/learner-report-{date}.md
6. Present summary and ask which suggestions to adopt
7. If approved, apply changes to skills, CLAUDE.md, or hooks
