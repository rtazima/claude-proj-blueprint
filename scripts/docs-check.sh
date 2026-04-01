#!/bin/bash
# Hook: check if source changes have corresponding documentation updates.
# Runs on PreToolUse for "git commit" — warns but never blocks.
#
# Philosophy: PRDs come from Obsidian, code gets implemented,
# decisions and changes flow BACK to Obsidian. This hook ensures
# the loop closes on every commit.

set -euo pipefail

# ─── Configuration ──────────────────────────────────────────
# [SPEC] Adjust for your project
SOURCE_DIR="src"                    # Source code directory
DOCS_DIR="docs"                     # Obsidian vault directory
ENV_EXAMPLE=".env.example"          # Env example file
CLAUDE_MD="CLAUDE.md"               # Project hub

# ─── Detect staged files ───────────────────────────────────
STAGED_SRC=$(git diff --cached --name-only --diff-filter=ACMR -- "${SOURCE_DIR}/" 2>/dev/null || true)
STAGED_DOCS=$(git diff --cached --name-only --diff-filter=ACMR -- "${DOCS_DIR}/" "${CLAUDE_MD}" "README.md" "${ENV_EXAMPLE}" 2>/dev/null || true)
STAGED_ALL=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)

# Skip if no source files staged
if [ -z "$STAGED_SRC" ]; then
  exit 0
fi

SRC_COUNT=$(echo "$STAGED_SRC" | wc -l | tr -d ' ')
WARNINGS=0

echo ""
echo "── Docs Check ──"

# ─── Check 1: Source changed but no docs updated ───────────
if [ -z "$STAGED_DOCS" ]; then
  echo "⚠️  CONSIDER: ${SRC_COUNT} source file(s) changed but no documentation updated"
  echo "   Checklist: CLAUDE.md module map | .env.example | README | ADR | Gotchas"
  WARNINGS=$((WARNINGS + 1))
fi

# ─── Check 2: New files without CLAUDE.md module map update ─
NEW_SRC_FILES=$(git diff --cached --name-only --diff-filter=A -- "${SOURCE_DIR}/" 2>/dev/null || true)
if [ -n "$NEW_SRC_FILES" ]; then
  CLAUDE_STAGED=$(echo "$STAGED_ALL" | grep -c "${CLAUDE_MD}" || true)
  if [ "$CLAUDE_STAGED" -eq 0 ]; then
    NEW_COUNT=$(echo "$NEW_SRC_FILES" | wc -l | tr -d ' ')
    echo "⚠️  CONSIDER: ${NEW_COUNT} new source file(s) — update CLAUDE.md module map"
    for f in $NEW_SRC_FILES; do
      echo "   + $f"
    done
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# ─── Check 3: Config changes without .env.example update ───
CONFIG_CHANGED=$(echo "$STAGED_SRC" | grep -i 'config' || true)
if [ -n "$CONFIG_CHANGED" ]; then
  # Check if new env vars were added
  NEW_ENV_VARS=$(git diff --cached -- ${SOURCE_DIR}/ | grep '^+.*process\.env\.\|^+.*os\.environ\.\|^+.*os\.Getenv\(' | grep -v '^+++' || true)
  if [ -n "$NEW_ENV_VARS" ]; then
    ENV_STAGED=$(echo "$STAGED_ALL" | grep -c "${ENV_EXAMPLE}" || true)
    if [ "$ENV_STAGED" -eq 0 ]; then
      echo "⚠️  CONSIDER: New environment variables detected — update ${ENV_EXAMPLE}"
      echo "$NEW_ENV_VARS" | head -5 | sed 's/^/   /'
      WARNINGS=$((WARNINGS + 1))
    fi
  fi
fi

# ─── Summary ───────────────────────────────────────────────
if [ $WARNINGS -eq 0 ]; then
  echo "✅ Documentation in sync"
else
  echo ""
  echo "   📝 ${WARNINGS} documentation reminder(s)"
  echo "   Run: grep -rE '\\[SPEC\\]|TODO' CLAUDE.md docs/ .env.example | head -10"
fi

# Never block — only warn
exit 0
