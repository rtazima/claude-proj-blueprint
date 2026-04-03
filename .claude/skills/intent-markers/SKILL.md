---
name: "intent-markers"
description: "Recognize and apply intent markers — inline code annotations (:PERF:, :UNSAFE:, :SCHEMA:, :SECURITY:, :HACK:, :FLAKY:) that flag areas needing special attention during review. Activated when writing or reviewing performance-sensitive, security-critical, or schema-dependent code."
allowed tools: Read, Grep, Glob, Edit, Write, Bash
---

# Intent Markers

Inline annotations that flag code areas needing special attention during review. Grep-able: `grep -rn ':PERF:' src/`

## Marker Reference

| Marker | Meaning | Reviewer action |
|---|---|---|
| `:PERF:` | Performance-sensitive | Check complexity, allocation, hot paths |
| `:UNSAFE:` | Safety-critical | Verify justification for bypassing type system, raw pointers, disabled checks |
| `:SCHEMA:` | Schema-dependent | Check backward compatibility, migration needed? |
| `:SECURITY:` | Security-sensitive | Auth, encryption, validation, secrets — requires security-auditor review |
| `:HACK:` | Intentional shortcut | Must have expiration date or issue link. Tracked as tech debt |
| `:FLAKY:` | Known unreliable | Tests may be flaky, external deps may timeout. Document workaround |

## When to ADD markers (writing code)

Add a marker when:
- Code has non-obvious performance implications
- You bypass safety checks or type systems for a reason
- Code depends on a specific DB schema or external contract
- Code handles auth, secrets, encryption, or user input
- You take a deliberate shortcut (always include issue link or date)
- Code depends on unreliable external services or has known flaky behavior

## When to CHECK markers (reviewing code)

During code review, search for markers in changed files:
```bash
grep -rn ':\(PERF\|UNSAFE\|SCHEMA\|SECURITY\|HACK\|FLAKY\):' src/
```
Every marker in a diff MUST have a corresponding review comment.

## Examples

### TypeScript
```typescript
// :PERF: O(n^2) — acceptable for n < 100 items, refactor if list grows
function findDuplicates(items: Item[]): Item[] {
  return items.filter((item, i) => items.findIndex(x => x.id === item.id) !== i);
}

// :SECURITY: Input sanitized before SQL interpolation — parameterized query preferred
const query = `SELECT * FROM users WHERE email = ${sanitize(email)}`;

// :HACK: Workaround for library bug #1234 — remove after v3.0 upgrade
(window as any).__forceRerender = true;
```

### Python
```python
# :UNSAFE: Disabling type check — external API returns untyped dict
result: Any = external_api.fetch()  # type: ignore

# :SCHEMA: Depends on users.preferences JSONB column added in migration 042
def get_theme(user: User) -> str:
    return user.preferences.get("theme", "light")

# :FLAKY: Stripe webhook delivery is eventually consistent, retry 3x
@retry(max_attempts=3, backoff=2)
def handle_payment_webhook(payload: dict) -> None:
    ...
```

### Go
```go
// :PERF: Hot path — called per request. Avoid allocations.
func (s *Server) authenticate(ctx context.Context, token string) (*User, error) { ... }
```

## References
- `docs/specs/documentation-standards.md` — token budgets for docs
- `docs/specs/code-review-gates.md` — automated review checks
