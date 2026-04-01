#!/bin/bash
# Magic keywords — detects intent from natural language and injects context.
# Reads the user prompt from stdin and outputs a JSON message if a keyword matches.
#
# Hook: UserPromptSubmit
# Level: L3+

# Read the user prompt from stdin (hook receives JSON with user_prompt field)
INPUT=$(cat)

# Extract the user prompt text
# Try jq first, fall back to grep/sed
if command -v jq &>/dev/null; then
  PROMPT=$(echo "$INPUT" | jq -r '.user_prompt // .prompt // empty' 2>/dev/null)
else
  PROMPT=$(echo "$INPUT" | grep -o '"user_prompt"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"user_prompt"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')
fi

# Lowercase for matching
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# ─── Keyword matching ───────────────────────────────────────
# Priority order: more specific matches first

# Persistence mode
if echo "$PROMPT_LOWER" | grep -qE "(don.?t stop|keep going|ralph|persistence mode|until (it|all|every).*(work|pass)|nao pare|nao para)"; then
  echo '{"result":"add_context","context":"[PERSISTENCE MODE ACTIVATED] Use the persistence skill. Do NOT ask for confirmation between iterations. Read the PRD, extract acceptance criteria, implement iteratively until ALL criteria pass or max iterations reached. The boulder never stops."}'
  exit 0
fi

# Slop cleaner
if echo "$PROMPT_LOWER" | grep -qE "(clean up|remove slop|polish|deslop|anti.?slop|limpa|limpeza)"; then
  echo '{"result":"add_context","context":"[SLOP CLEANER ACTIVATED] Use the slop-cleaner skill. Scan recently changed files for AI-generated patterns: unnecessary comments, over-abstraction, redundant types, excessive logging, dead code, over-engineering, LLM verbal tics."}'
  exit 0
fi

# Implement from PRD
if echo "$PROMPT_LOWER" | grep -qE "(build me|implement|create feature|construa|implemente|desenvolva)"; then
  # Only trigger if there seems to be a feature request, not a generic command
  if echo "$PROMPT_LOWER" | grep -qE "(feature|funcionalidade|from prd|da prd|do prd)"; then
    echo '{"result":"add_context","context":"[IMPLEMENT MODE] Use the /implement workflow. Read the PRD first, enter Plan Mode, check ADRs and specs, implement, test, document."}'
    exit 0
  fi
fi

# Review / audit
if echo "$PROMPT_LOWER" | grep -qE "(security audit|compliance audit|spec review|full review|auditoria|revisao completa)"; then
  echo '{"result":"add_context","context":"[AUDIT MODE] Use /spec-review workflow. Invoke security-auditor, compliance-auditor, and quality-guardian agents. Consolidate findings by severity."}'
  exit 0
fi

# Learn from session
if echo "$PROMPT_LOWER" | grep -qE "(learn from|what patterns|improve skills|retrospective|session review|o que aprendemos)"; then
  echo '{"result":"add_context","context":"[LEARNER MODE] Use the learner skill. Analyze recent git history, identify recurring patterns, compare against existing skills, suggest improvements."}'
  exit 0
fi

# [SPEC] Add project-specific keywords:
# if echo "$PROMPT_LOWER" | grep -qE "(your keyword)"; then
#   echo '{"result":"add_context","context":"[YOUR MODE] Instructions here."}'
#   exit 0
# fi

# No match — passthrough
exit 0
