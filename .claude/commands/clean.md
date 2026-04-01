Clean AI-generated slop from code.

Arguments: $ARGUMENTS (file, directory, or empty for recent changes)

Workflow:
1. Determine scope:
   - If $ARGUMENTS is a file → clean that file
   - If $ARGUMENTS is a directory → clean all source files in it
   - If empty → use `git diff --name-only HEAD~3` to find recently changed files
2. Activate the `slop-cleaner` skill
3. Read each file and scan against the slop patterns checklist
4. Apply fixes one category at a time (comments → abstraction → types → logging → dead code → over-engineering → verbal tics)
5. Run tests after all changes to verify nothing broke
6. Report summary: files cleaned, patterns removed, lines saved
