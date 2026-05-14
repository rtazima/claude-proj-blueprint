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

# Debugger
if echo "$PROMPT_LOWER" | grep -qE "(debug|why is.*(fail|break|crash)|root cause|broken|investigate|trace error|not working|nao funciona|quebrou)"; then
  echo '{"result":"add_context","context":"[DEBUGGER ACTIVATED] Use the debugger skill. Systematic workflow: reproduce → isolate → hypothesize (2+ causes) → fix → verify → document. Never guess — gather evidence first."}'
  exit 0
fi

# Refactoring
if echo "$PROMPT_LOWER" | grep -qE "(refactor|extract (function|method|class|module)|split module|restructure|decouple|simplify architecture)"; then
  echo '{"result":"add_context","context":"[REFACTOR MODE] Use the refactor skill. Tests must pass before AND after. One refactoring at a time, commit between each. ADR if architecture changes."}'
  exit 0
fi

# Legacy context discovery
if echo "$PROMPT_LOWER" | grep -qE "(legacy code|c[oó]digo legado|sistema legado|sistema antigo|discover module|entender m[oó]dulo|arqueologia|c[oó]digo sem documenta[cç][aã]o|c[oó]digo que ningu[eé]m entende)"; then
  echo '{"result":"add_context","context":"[LEGACY CONTEXT] Use the legacy-context skill. Read-only for source code. Three phases: survey (map hot/cold files via git log), discovery (extract purpose/decisions/dependencies/risks from priority files), promote (draft ADR candidates and index discovery notes in semantic memory). Outputs to memory/discoveries/ and docs/architecture/_candidates/. Run this before context-engineering techniques on legacy modules where memory and docs are empty."}'
  exit 0
fi

# Tech debt
if echo "$PROMPT_LOWER" | grep -qE "(tech.?debt|technical debt|cleanup backlog|what needs fix|code health|debt audit|divida tecnica)"; then
  echo '{"result":"add_context","context":"[TECH DEBT SCAN] Use the tech-debt skill. Scan for TODOs, type suppressions, high-churn files, outdated deps, test gaps. Produce prioritized report in docs/architecture/."}'
  exit 0
fi

# PRD writing
if echo "$PROMPT_LOWER" | grep -qE "(write prd|draft prd|break down feature|scope this|requirements for|define feature|escrever prd|definir feature)"; then
  echo '{"result":"add_context","context":"[PRD WRITER] Use the prd-writer skill. Read the template at docs/product/_template-prd.md. Clarify ambiguities (max 5 questions), then draft a structured PRD with user stories, acceptance criteria, and spec impact."}'
  exit 0
fi

# API design
if echo "$PROMPT_LOWER" | grep -qE "(design api|new endpoint|api contract|rest api|graphql|openapi|swagger|api spec|definir api)"; then
  echo '{"result":"add_context","context":"[API DESIGNER] Use the api-designer skill. Contract first: define endpoints, schemas, error codes, pagination. Check versioning and security specs. Output API spec before implementation."}'
  exit 0
fi

# Migration
if echo "$PROMPT_LOWER" | grep -qE "(migration|schema change|add column|alter table|database change|create table|migrate|migracao)"; then
  echo '{"result":"add_context","context":"[MIGRATION MODE] Use the migration skill. Assess risk (green/yellow/red), generate up+down migration, test reversibility. ADR required for destructive changes (DROP, type change)."}'
  exit 0
fi

# Review / audit
if echo "$PROMPT_LOWER" | grep -qE "(security audit|compliance audit|spec review|full review|auditoria|revisao completa)"; then
  echo '{"result":"add_context","context":"[AUDIT MODE] Use /spec-review workflow. Invoke security-auditor, compliance-auditor, quality-guardian, and performance-auditor agents. Consolidate findings by severity."}'
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
