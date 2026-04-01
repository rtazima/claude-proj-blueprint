# Code Review Gates

## Philosophy

> **Agents and skills are for on-demand tasks.
> Hooks are for guarantees that must never fail.**

A security-auditor agent is great for deep reviews, but it needs to be invoked.
A pre-commit hook runs **always**, without anyone needing to remember.

## How it works

Every `git commit` triggers `scripts/pre-commit-review.sh` via Claude Code hooks.
The script runs automated checks on staged source files and either:

- **Blocks** the commit (exit code 2) — for MUST FIX issues
- **Warns** but allows (exit code 0) — for SHOULD FIX issues
- **Passes clean** — all checks green

## Review Levels

Configured via `bootstrap.sh --review <level>` or `REVIEW_LEVEL` env var:

| Level | What runs | Time | Cost | Best for |
|---|---|---|---|---|
| **simple** | Bash only (grep, compile, tests) | ~5-15s | Free | Solo devs, open source, CI-heavy teams |
| **hybrid** | Bash + Sonnet AI review | ~20-30s | ~$0.01/commit | Most teams (recommended) |
| **deep** | Bash + Opus AI review | ~40-60s | ~$0.05/commit | Security-critical, fintech, healthcare |

### How AI review works (hybrid/deep)

1. Bash checks run first (deterministic, fast)
2. If no MUST FIX blockers, AI review runs on the staged diff
3. AI analyzes logic bugs, edge cases, security risks, business logic
4. AI adds **warnings only** — never blocks commits
5. Bash handles blocking; AI handles intelligence

### Requirements for hybrid/deep

- `claude` CLI installed (uses your Max/Pro plan — no API key needed), **OR**
- `ANTHROPIC_API_KEY` set in environment, `.env`, or `~/.env` (API fallback)
- `scripts/ai-review.sh` present in the project
- Python 3 available (only needed for API fallback)

## Check Categories

### Universal checks (built-in)

| # | Check | Severity | What it catches |
|---|---|---|---|
| 1 | Compilation / type check | MUST FIX | Broken builds |
| 2 | Tests passing | MUST FIX | Regressions |
| 3 | Hardcoded secrets | MUST FIX | API keys, passwords in code |
| 4 | Quality (console.log, any, ts-ignore) | SHOULD FIX | Debugging artifacts, weak typing |
| 5 | Error handling (fetch without try/catch) | SHOULD FIX | Unhandled exceptions, hung connections |
| 6 | Test coverage gaps | CONSIDER | Files without test counterparts |

### Project-specific checks (customize)

These are the checks that catch **your** bugs. Add them based on lessons learned:

```bash
# Example: block risky price calculations (real bug from production)
PRICE_CALC=$(grep -n 'deal.price.*coupon' "$f" || true)
if [ -n "$PRICE_CALC" ]; then
  echo "❌ MUST FIX: Price+coupon calculation — coupons have hidden caps"
  MUST_FIX=$((MUST_FIX + 1))
fi
```

The `[SPEC]` sections in `scripts/pre-commit-review.sh` mark where to add your project-specific checks.

## Configuration

### Stack configuration (top of script)

```bash
LANG_EXTENSIONS="ts"                      # File extensions to review
SOURCE_DIR="src"                          # Source directory
TEST_DIR="src/__tests__"                  # Test directory
TEST_SUFFIX=".test.ts"                    # Test file suffix
COMPILE_CMD="npx tsc --noEmit"            # Compile command
TEST_CMD="npm test -- --passWithNoTests"  # Test command
```

### Multi-language support

The script includes commented templates for Python and Go.
Uncomment the relevant sections in `scripts/pre-commit-review.sh`.

## Integration with other layers

| Layer | Tool | Purpose |
|---|---|---|
| L2 | `code-review` skill | On-demand deep review (invoked manually) |
| L3 | `pre-commit-review.sh` hook | Automated gate on every commit |
| L3 | `lint-check.sh` hook | Lint on every file write |
| L3 | `security-check.sh` hook | Block dangerous bash commands |
| L3 | `docs-check.sh` hook | Warn if source changed without docs update |
| L4 | `quality-guardian` agent | Deep quality audit with agent teams |
| L4 | `security-auditor` agent | OWASP/security audit with agent teams |

The pre-commit hook provides **fast, automated coverage**.
Agents provide **deep, context-aware analysis** for bigger changes.

## Adding new checks

When you find a bug in production, ask: "Could a pre-commit check have caught this?"

If yes, add it to the `PROJECT-SPECIFIC CHECKS` section:

```bash
# [Date] Bug: [description]
# Root cause: [what went wrong]
# Check: [what to look for]
for f in $STAGED_FILES; do
  MATCH=$(grep -n 'pattern' "$f" || true)
  if [ -n "$MATCH" ]; then
    echo "❌ MUST FIX [$f]: [description]"
    MUST_FIX=$((MUST_FIX + 1))
  fi
done
```

This turns production incidents into permanent guardrails.

## Origin

This spec was created from real-world validation on the `amaia-agent` project,
where automated code review caught pricing accuracy bugs before they reached users.
See ADR: `docs/architecture/adr-004-pre-commit-review.md`.
