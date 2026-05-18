#!/bin/bash
# jira-context-fetch.sh — fetch Jira tickets, comments, and epics for legacy context discovery
# Called by the context-legacy skill (Phase 3). Read-only: never creates or modifies Jira data.
#
# Usage:
#   bash scripts/jira-context-fetch.sh --term "ModuleName" [--term "AnotherTerm"] \
#       --project PROJECT_KEY [--max 20] [--output /tmp/jira-raw.md]
#
# Env vars required (load from .env):
#   JIRA_BASE_URL   — https://your-company.atlassian.net
#   JIRA_EMAIL      — your@email.com
#   JIRA_API_TOKEN  — token from id.atlassian.com/manage-profile/security/api-tokens
#   JIRA_PROJECT_KEY — default project key (overridden by --project)

set -euo pipefail

# ─── Args ─────────────────────────────────────────────────────────────────────
TERMS=()
PROJECT_KEY=""
MAX_RESULTS=25
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --term)     TERMS+=("$2");      shift 2 ;;
    --project)  PROJECT_KEY="$2";  shift 2 ;;
    --max)      MAX_RESULTS="$2";  shift 2 ;;
    --output)   OUTPUT_FILE="$2";  shift 2 ;;
    -h|--help)
      echo "Usage: $0 --term <term> [--term <term2>] --project <KEY> [--max N] [--output file.md]"
      exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [ ${#TERMS[@]} -eq 0 ]; then
  echo "Error: at least one --term is required" >&2; exit 1
fi

# ─── Env ──────────────────────────────────────────────────────────────────────
[ -f .env ] && set -a && source .env && set +a 2>/dev/null || true

: "${JIRA_BASE_URL:?'JIRA_BASE_URL not set — add to .env'}"
: "${JIRA_EMAIL:?'JIRA_EMAIL not set — add to .env'}"
: "${JIRA_API_TOKEN:?'JIRA_API_TOKEN not set — add to .env'}"
PROJECT_KEY="${PROJECT_KEY:-${JIRA_PROJECT_KEY:?'JIRA_PROJECT_KEY not set and --project not given'}}"

# ─── Deps ─────────────────────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install: brew install jq" >&2; exit 1
fi
if ! command -v curl &>/dev/null; then
  echo "Error: curl is required." >&2; exit 1
fi

# ─── Auth ─────────────────────────────────────────────────────────────────────
JIRA_AUTH=$(printf '%s:%s' "$JIRA_EMAIL" "$JIRA_API_TOKEN" | base64 | tr -d '\n')
BASE="${JIRA_BASE_URL%/}/rest/api/3"

# ─── Helpers ──────────────────────────────────────────────────────────────────
jira_get() {
  local path="$1"
  curl -sf \
    --user "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
    -H "Accept: application/json" \
    "${BASE}/${path}" 2>/dev/null || echo '{}'
}

jira_post() {
  local path="$1"
  local body="$2"
  curl -sf \
    --user "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "$body" \
    "${BASE}/${path}" 2>/dev/null || echo '{}'
}

# Extract plain text from Atlassian Document Format (ADF) or plain string
adf_to_text() {
  local raw="$1"
  if echo "$raw" | jq -e 'type == "object"' &>/dev/null; then
    echo "$raw" | jq -r '.. | .text? // empty' 2>/dev/null | grep -v '^$' | head -20 | tr '\n' ' '
  else
    echo "$raw" | head -c 500
  fi
}

jira_search() {
  local jql="$1"
  local fields="summary,issuetype,status,components,created,updated,parent,issuelinks,priority,resolution"
  local body
  body=$(jq -n --arg jql "$jql" --arg max "$MAX_RESULTS" --argjson fields '["summary","issuetype","status","components","created","updated","parent","issuelinks","priority","resolution"]' \
    '{jql: $jql, maxResults: ($max|tonumber), fields: $fields}')
  jira_post "search/jql" "$body"
}

# ─── Build JQL ────────────────────────────────────────────────────────────────
# Build OR clause from all terms
TERM_CLAUSE=""
for term in "${TERMS[@]}"; do
  [ -n "$TERM_CLAUSE" ] && TERM_CLAUSE="${TERM_CLAUSE} OR "
  TERM_CLAUSE="${TERM_CLAUSE}text ~ \"${term}\""
done

JQL_ALL="project = \"${PROJECT_KEY}\" AND (${TERM_CLAUSE}) ORDER BY updated DESC"
JQL_BUGS="project = \"${PROJECT_KEY}\" AND issuetype = Bug AND (${TERM_CLAUSE}) ORDER BY created DESC"

# ─── Run queries ──────────────────────────────────────────────────────────────
echo "  Jira: searching '${TERMS[*]}' in $PROJECT_KEY..." >&2

RAW_ALL=$(jira_search "$JQL_ALL")
RAW_BUGS=$(jira_search "$JQL_BUGS")

TOTAL=$(echo "$RAW_ALL" | jq '(.total // (.issues | length)) // 0')
TOTAL_BUGS=$(echo "$RAW_BUGS" | jq '(.total // (.issues | length)) // 0')

echo "  Jira: found $TOTAL tickets ($TOTAL_BUGS bugs)" >&2

# ─── Process issues ───────────────────────────────────────────────────────────
OUT=""
EPIC_CONTEXT=""

process_issues() {
  local raw="$1"
  local label="$2"

  local keys
  keys=$(echo "$raw" | jq -r '.issues[]?.key // empty')
  [ -z "$keys" ] && return

  while IFS= read -r KEY; do
    [ -z "$KEY" ] && continue
    echo "  Jira: fetching $KEY..." >&2

    local detail
    detail=$(jira_get "issue/${KEY}?fields=summary,description,comment,status,issuetype,components,labels,issuelinks,parent,priority,resolution,created")

    local summary issuetype status resolution created parent_key
    summary=$(echo "$detail"    | jq -r '.fields.summary // ""')
    issuetype=$(echo "$detail"  | jq -r '.fields.issuetype.name // ""')
    status=$(echo "$detail"     | jq -r '.fields.status.name // ""')
    resolution=$(echo "$detail" | jq -r '.fields.resolution.name // "Unresolved"')
    created=$(echo "$detail"    | jq -r '.fields.created // ""' | cut -c1-10)
    parent_key=$(echo "$detail" | jq -r '.fields.parent.key // ""')

    # Description excerpt
    local raw_desc desc=""
    raw_desc=$(echo "$detail" | jq '.fields.description // ""')
    if [ "$raw_desc" != '""' ] && [ "$raw_desc" != 'null' ]; then
      desc=$(adf_to_text "$raw_desc" | head -c 300)
    fi

    # Comments — filter for decision-type language
    local decision_comments=""
    local comment_count
    comment_count=$(echo "$detail" | jq '.fields.comment.comments | length // 0')
    if [ "$comment_count" -gt 0 ]; then
      while IFS= read -r comment_json; do
        local author body text
        author=$(echo "$comment_json" | jq -r '.author.displayName // "unknown"')
        body=$(echo "$comment_json"   | jq '.body // ""')
        text=$(adf_to_text "$body")
        if echo "$text" | grep -qi -E "decid|because|reason|workaround|hack|intentional|por que|porque|chose|alternative|instead|trade.?off"; then
          local date
          date=$(echo "$comment_json" | jq -r '.created // ""' | cut -c1-10)
          decision_comments="${decision_comments}\n  - **${author}** (${date}): $(echo "$text" | head -c 250)"
        fi
      done < <(echo "$detail" | jq -c '.fields.comment.comments[]?')
    fi

    # Linked issues
    local links=""
    links=$(echo "$detail" | jq -r '.fields.issuelinks[]? | "  - \(.type.name): \(.inwardIssue.key // .outwardIssue.key // "?") — \(.inwardIssue.fields.summary // .outwardIssue.fields.summary // "")"' 2>/dev/null || true)

    # Epic chain (one level)
    if [ -n "$parent_key" ] && [ -z "$EPIC_CONTEXT" ]; then
      local epic_detail epic_summary epic_desc_raw epic_desc
      echo "  Jira: fetching epic $parent_key..." >&2
      epic_detail=$(jira_get "issue/${parent_key}?fields=summary,description")
      epic_summary=$(echo "$epic_detail" | jq -r '.fields.summary // ""')
      epic_desc_raw=$(echo "$epic_detail" | jq '.fields.description // ""')
      epic_desc=$(adf_to_text "$epic_desc_raw" | head -c 400)
      EPIC_CONTEXT="**[${parent_key}](${JIRA_BASE_URL}/browse/${parent_key})**: ${epic_summary}\n\n${epic_desc}"
    fi

    # Append to output
    OUT="${OUT}
### [${KEY}](${JIRA_BASE_URL}/browse/${KEY}) — ${summary}

| Field | Value |
|-------|-------|
| Type | ${issuetype} |
| Status | ${status} / ${resolution} |
| Created | ${created} |
| Label | ${label} |
"

    [ -n "$desc" ] && OUT="${OUT}
**Description excerpt:**
> ${desc}
"

    if [ -n "$decision_comments" ]; then
      OUT="${OUT}
**Decision-type comments:**
$(echo -e "$decision_comments")
"
    fi

    if [ -n "$links" ]; then
      OUT="${OUT}
**Linked issues:**
${links}
"
    fi

    OUT="${OUT}
---
"
  done <<< "$keys"
}

process_issues "$RAW_ALL"  "all"

# ─── Compose output document ──────────────────────────────────────────────────
DATE=$(date +%Y-%m-%d)
TERMS_STR=$(printf '"%s" ' "${TERMS[@]}")

DOCUMENT="## Jira context (Phase 3)

**Fetched:** ${DATE}
**Project:** ${PROJECT_KEY}
**Terms searched:** ${TERMS_STR}
**Total tickets:** ${TOTAL} (${TOTAL_BUGS} bugs, showing first ${MAX_RESULTS})

### Epic / business context

$([ -n "$EPIC_CONTEXT" ] && echo -e "$EPIC_CONTEXT" || echo "_No parent epic found for these tickets._")

### Tickets

${OUT:-_No tickets found. Try broader search terms._}
"

# ─── Write or print ───────────────────────────────────────────────────────────
if [ -n "$OUTPUT_FILE" ]; then
  echo -e "$DOCUMENT" > "$OUTPUT_FILE"
  echo "  Jira: written to $OUTPUT_FILE" >&2
else
  echo -e "$DOCUMENT"
fi
