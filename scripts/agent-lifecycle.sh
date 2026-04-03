#!/bin/bash
# Hook: emit events when agents start or stop.
# Runs on SubagentStart and SubagentStop to feed the agent monitor dashboard.
#
# Reads agent info from stdin (JSON with agent_name, etc.)
# Level: L4

set -euo pipefail

# Source event emitter
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/agent-events.sh"

# Read hook input from stdin
INPUT=$(cat)

# Extract event type from first argument or detect from context
EVENT_TYPE="${1:-start}"

# Extract agent name from stdin JSON
AGENT_NAME=""
if echo "$INPUT" | grep -q '"agent_name"'; then
  AGENT_NAME=$(echo "$INPUT" | sed -n 's/.*"agent_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

# Fallback: try "name" field
if [ -z "$AGENT_NAME" ]; then
  if echo "$INPUT" | grep -q '"name"'; then
    AGENT_NAME=$(echo "$INPUT" | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  fi
fi

# Skip if no agent name found
if [ -z "$AGENT_NAME" ]; then
  exit 0
fi

# Extract task/description if available
TASK=""
if echo "$INPUT" | grep -q '"task"'; then
  TASK=$(echo "$INPUT" | sed -n 's/.*"task"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi
if [ -z "$TASK" ] && echo "$INPUT" | grep -q '"description"'; then
  TASK=$(echo "$INPUT" | sed -n 's/.*"description"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

if [ "$EVENT_TYPE" = "start" ]; then
  emit_agent_start "$AGENT_NAME" "${TASK:-running}"
elif [ "$EVENT_TYPE" = "stop" ]; then
  # Extract status if available
  AGENT_STATUS="ok"
  if echo "$INPUT" | grep -q '"error"'; then
    AGENT_STATUS="error"
  fi
  emit_agent_complete "$AGENT_NAME" "$AGENT_STATUS" "${TASK:-completed}"
fi

exit 0
