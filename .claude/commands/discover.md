Legacy code archaeology for a module or file. Reconstructs intent using static analysis, git history, and Jira (when configured). Produces context docs that seed ADR candidates and PRD notes.

Arguments: $ARGUMENTS (module path, file path, or multiple paths separated by spaces)

Workflow:
1. Activate the `context-legacy` skill
2. Run the 5 phases for each target in $ARGUMENTS:
   - Phase 1: Code archaeology — map files, read public interfaces, find surprising patterns
   - Phase 2: Git history — churn, authors, regression commits, decision messages
   - Phase 3: Jira enrichment — if JIRA_* present in .env, search for related tickets, bugs, comments, epics
   - Phase 4: Cross-reference — correlate signals from code, git, and Jira
   - Phase 5: Output — write docs/architecture/legacy-context-{module}-{date}.md
3. When multiple paths are given, run phases 1–3 for each, then synthesize phase 4–5 together
4. After writing the context doc, list ADR candidates and offer to run /adr for any of them

Output: docs/architecture/legacy-context-{module}-{YYYY-MM-DD}.md
Never modify source files.
