Persistence mode: implement from PRD and don't stop until all acceptance criteria pass.

Arguments: $ARGUMENTS (PRD path, e.g. docs/product/feat-auth.md)

Workflow:
1. Activate the `persistence` skill
2. Read the PRD at $ARGUMENTS
3. Extract all acceptance criteria into a checklist
4. Read CLAUDE.md for test/build commands
5. Enter the persistence loop:
   - Implement changes to address failing criteria
   - Run tests/build after each change
   - Report which criteria pass/fail
   - Continue until ALL pass or max iterations (default: 5) reached
6. After loop completes, run slop-cleaner on changed files
7. Run documentation checklist from /implement (step 8)
8. Commit with Conventional Commits format

Do NOT ask for confirmation between iterations. The boulder never stops.
