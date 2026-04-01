#!/bin/bash
# Context guard — monitors session length and warns when context is getting large.
# Uses tool call count as a proxy for context consumption.
#
# Hook: PostToolUse (runs on every tool use)
# Level: L3+

# ─── Configuration ───────────────────────────────────────────
WARN_THRESHOLD=${CONTEXT_GUARD_WARN:-50}       # Tool calls before first warning
CRITICAL_THRESHOLD=${CONTEXT_GUARD_CRITICAL:-80} # Tool calls before critical warning
COUNTER_DIR="${TMPDIR:-/tmp}"

# ─── Session-unique counter ──────────────────────────────────
# Use the Claude Code session start time (approximated by the first invocation)
SESSION_ID=$(date +%Y%m%d)
COUNTER_FILE="${COUNTER_DIR}/claude-context-guard-${SESSION_ID}-$$"

# Find any existing counter for today (different PID each hook call, so use glob)
EXISTING_COUNTER=$(ls "${COUNTER_DIR}"/claude-context-guard-"${SESSION_ID}"-* 2>/dev/null | head -1)

if [ -n "$EXISTING_COUNTER" ]; then
  COUNTER_FILE="$EXISTING_COUNTER"
  COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
else
  COUNT=0
fi

# Increment
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

# ─── Check thresholds ───────────────────────────────────────
if [ "$COUNT" -ge "$CRITICAL_THRESHOLD" ]; then
  cat << 'EOF'
🔴 CONTEXT CRITICAL — conversation is very long.
   Strongly recommend:
   1. Run /compact to compress context
   2. Or start a new session for the next task

   If memory/compact-context.md exists, critical context will be preserved.
   If memory/session-notes.md exists, append your current task status before compacting.
EOF
elif [ "$COUNT" -ge "$WARN_THRESHOLD" ]; then
  # Only warn once every 10 calls after threshold
  REMAINDER=$((COUNT % 10))
  if [ "$REMAINDER" -eq 0 ]; then
    cat << 'EOF'
⚠️  CONTEXT WARNING — conversation is getting long.
   Consider running /compact soon to preserve context window.
   Tip: append important context to memory/session-notes.md before compacting.
EOF
  fi
fi

# Never block
exit 0
