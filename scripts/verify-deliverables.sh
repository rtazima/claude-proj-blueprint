#!/bin/bash
# Deliverables verification — validates agent output against expected schema.
# Checks that agents produce output with all required fields/sections.
#
# Hook: SubagentStop
# Level: L4

SCHEMA_DIR="docs/specs/deliverables"

# Read the agent event from stdin
INPUT=$(cat)

# Extract agent name from the event
if command -v jq &>/dev/null; then
  AGENT_NAME=$(echo "$INPUT" | jq -r '.agent_name // .name // empty' 2>/dev/null)
  AGENT_OUTPUT=$(echo "$INPUT" | jq -r '.output // .result // empty' 2>/dev/null)
else
  AGENT_NAME=$(echo "$INPUT" | grep -o '"agent_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"agent_name"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')
  AGENT_OUTPUT=$(echo "$INPUT" | grep -o '"output"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"output"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')
fi

# If we can't identify the agent, passthrough
if [ -z "$AGENT_NAME" ]; then
  exit 0
fi

# Look for schema file
SCHEMA_FILE="${SCHEMA_DIR}/${AGENT_NAME}.schema"

if [ ! -f "$SCHEMA_FILE" ]; then
  # No schema defined for this agent — passthrough
  exit 0
fi

# ─── Validate output against schema ─────────────────────────
MISSING=""
TOTAL=0
FOUND=0

while IFS= read -r field; do
  # Skip empty lines and comments
  [[ -z "$field" || "$field" =~ ^# ]] && continue

  TOTAL=$((TOTAL + 1))

  if echo "$AGENT_OUTPUT" | grep -qi "$field"; then
    FOUND=$((FOUND + 1))
  else
    if [ -z "$MISSING" ]; then
      MISSING="$field"
    else
      MISSING="$MISSING, $field"
    fi
  fi
done < "$SCHEMA_FILE"

# ─── Report ──────────────────────────────────────────────────
if [ "$TOTAL" -eq 0 ]; then
  exit 0
fi

if [ -n "$MISSING" ]; then
  MISSING_COUNT=$((TOTAL - FOUND))
  cat << EOF
⚠️  DELIVERABLES CHECK: ${AGENT_NAME} output is missing ${MISSING_COUNT}/${TOTAL} required fields.
   Missing: ${MISSING}

   Expected fields are defined in: ${SCHEMA_FILE}
   The agent should re-run or complete its output with the missing sections.
EOF
fi

# Never block — only warn
exit 0
