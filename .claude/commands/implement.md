Implement a feature from a PRD.

Arguments: $ARGUMENTS (PRD path, e.g. docs/product/feat-auth.md)

Workflow:
1. Read the PRD at $ARGUMENTS
2. Enter Plan Mode — create a detailed plan before coding
3. Check related ADRs in docs/architecture/
4. Check applicable specs in docs/specs/
5. **Detect design flow:**
   - If the PRD contains a Figma link → use Figma MCP to extract design context, then implement
   - If no Figma link → activate the `frontend-agent` skill:
     a. Load design tokens from docs/specs/design-system/README.md
     b. Scan existing UI components for consistency
     c. Generate UI from PRD requirements + tokens + component library
6. Implement following CLAUDE.md and the implement-prd skill
7. Create tests following the testing skill
8. Commit with Conventional Commits format message

Always ask for plan confirmation before starting implementation.
