#!/bin/bash
# Bootstrap script for Claude Code Project Template
# Usage: ./scripts/bootstrap.sh --level [1|2|3|4] [--design figma|agent|hybrid]

set -e

LEVEL=2  # default
DESIGN_FLOW=""
REVIEW_LEVEL=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --level) LEVEL="$2"; shift 2 ;;
    --design) DESIGN_FLOW="$2"; shift 2 ;;
    --review) REVIEW_LEVEL="$2"; shift 2 ;;
    *) echo "Usage: ./scripts/bootstrap.sh --level [1|2|3|4] [--design figma|agent|hybrid] [--review simple|hybrid|deep]"; exit 1 ;;
  esac
done

echo "🚀 Bootstrapping project at Level $LEVEL"
echo ""

# ============================================================
# L1: CLAUDE.md + settings + docs structure
# ============================================================
echo "📋 L1: Setting up CLAUDE.md and basic structure..."

if [ ! -f "CLAUDE.md" ]; then
  echo "   ⚠️  CLAUDE.md not found — make sure you're in the project root"
  exit 1
fi

# Ensure basic dirs exist
mkdir -p src docs/{product,architecture,specs,runbooks/post-mortems}

echo "   ✅ Basic structure ready"
echo "   📝 TODO: Fill in [SPEC] markers in CLAUDE.md"
echo "   📝 TODO: Fill in docs/product/vision.md"
echo ""

# ============================================================
# Design flow — ask if not provided via --design flag
# ============================================================
if [ -z "$DESIGN_FLOW" ]; then
  echo "🎨 Design flow — how will UI be built?"
  echo "   See docs/design-flow-guide.md for detailed guidance."
  echo ""
  echo "   1) Figma    — PRD + Figma link → code (team has a designer)"
  echo "   2) Agent    — PRD + design tokens → frontend agent generates UI (no designer)"
  echo "   3) Hybrid   — Figma for complex screens, agent for the rest"
  echo "   4) None     — no UI in this project (backend/CLI/agent only)"
  echo ""
  read -p "   Choose [1-4] (default: 2): " design_choice

  case "$design_choice" in
    1) DESIGN_FLOW="figma" ;;
    3) DESIGN_FLOW="hybrid" ;;
    4) DESIGN_FLOW="none" ;;
    *) DESIGN_FLOW="agent" ;;
  esac
fi

echo ""

# Configure design flow
configure_design_flow() {
  local flow="$1"

  case "$flow" in
    figma)
      echo "   🎨 Design flow: Figma"
      echo "   ✅ Figma MCP reference enabled"
      echo "   ✅ design-system/ spec module enabled"
      mkdir -p docs/specs/design-system
      # Update CLAUDE.md Design section — mark Figma as active
      if grep -q "\[SPEC\] Choose your design flow" CLAUDE.md 2>/dev/null; then
        sed -i.bak 's/\[SPEC\] Choose your design flow (Figma is optional):/Design flow: **Figma** (configured by bootstrap)/' CLAUDE.md && rm -f CLAUDE.md.bak
      fi
      echo "   📝 TODO: Add Figma file link in docs/specs/design-system/README.md"
      echo "   📝 TODO: Configure Figma MCP server in .claude/settings.json"
      echo "   📝 TODO: Fill in design tokens in docs/specs/design-system/README.md"
      ;;
    agent)
      echo "   🤖 Design flow: Agent (no Figma required)"
      echo "   ✅ frontend-agent skill enabled"
      echo "   ✅ design-system/ spec module enabled"
      mkdir -p docs/specs/design-system .claude/skills/frontend-agent
      if grep -q "\[SPEC\] Choose your design flow" CLAUDE.md 2>/dev/null; then
        sed -i.bak 's/\[SPEC\] Choose your design flow (Figma is optional):/Design flow: **Agent** (configured by bootstrap)/' CLAUDE.md && rm -f CLAUDE.md.bak
      fi
      echo "   📝 TODO: Define design tokens in docs/specs/design-system/README.md"
      echo "   📝 TODO: Choose a component library (shadcn, Radix, MUI, etc.)"
      echo "   📝 TODO: Review .claude/skills/frontend-agent/SKILL.md"
      ;;
    hybrid)
      echo "   🎨🤖 Design flow: Hybrid (Figma + Agent)"
      echo "   ✅ Figma MCP reference enabled"
      echo "   ✅ frontend-agent skill enabled"
      echo "   ✅ design-system/ spec module enabled"
      mkdir -p docs/specs/design-system .claude/skills/frontend-agent
      if grep -q "\[SPEC\] Choose your design flow" CLAUDE.md 2>/dev/null; then
        sed -i.bak 's/\[SPEC\] Choose your design flow (Figma is optional):/Design flow: **Hybrid** (configured by bootstrap)/' CLAUDE.md && rm -f CLAUDE.md.bak
      fi
      echo "   📝 TODO: Define design tokens in docs/specs/design-system/README.md"
      echo "   📝 TODO: Configure Figma MCP server in .claude/settings.json"
      echo "   📝 TODO: Document which screens go through Figma vs Agent in PRDs"
      ;;
    none)
      echo "   ⏭️  Design flow: None (no UI)"
      echo "   Skipping design system setup"
      ;;
  esac
  echo ""
}

configure_design_flow "$DESIGN_FLOW"

if [ "$LEVEL" -lt 2 ]; then
  echo "✅ Level 1 setup complete!"
  echo ""
  echo "Daily workflow:"
  echo "  cd $(basename $PWD) && claude"
  echo "  → Describe what you need"
  echo "  → Claude reads CLAUDE.md automatically"
  exit 0
fi

# ============================================================
# L2: Skills + Commands
# ============================================================
echo "🧠 L2: Setting up skills and commands..."

mkdir -p .claude/{skills,commands}

# Count skills
SKILL_COUNT=$(find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
echo "   📦 $SKILL_COUNT skills found"

# Count commands
CMD_COUNT=$(find .claude/commands -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
echo "   ⚡ $CMD_COUNT commands found"

echo "   📝 TODO: Create project-specific skills in .claude/skills/"
echo "   📝 TODO: Use .claude/skills/_template-skill/SKILL.md as template"
echo ""

if [ "$LEVEL" -lt 3 ]; then
  echo "✅ Level 2 setup complete!"
  echo ""
  echo "Daily workflow:"
  echo "  cd $(basename $PWD) && claude"
  echo "  → Shift+Tab+Tab: Plan Mode"
  echo "  → Describe feature intent"
  echo "  → Shift+Tab: Auto Accept"
  echo "  → /compact to compress context"
  echo "  → Commit frequently, new session per feature"
  exit 0
fi

# ============================================================
# L3: Hooks
# ============================================================
echo "🔒 L3: Setting up hooks..."

if [ -f ".claude/hooks.json" ]; then
  echo "   ✅ hooks.json found"
else
  echo "   ⚠️  hooks.json not found — create it in .claude/"
fi

# Make scripts executable
chmod +x scripts/*.sh 2>/dev/null || true
echo "   ✅ Scripts made executable"

# ─── Code Review Level ───────────────────────────────────────
if [ -z "$REVIEW_LEVEL" ]; then
  echo ""
  echo "🔍 Code review level — how thorough should pre-commit review be?"
  echo ""
  echo "   1) Simple  — bash only (grep, compile, tests) — fast, free"
  echo "   2) Hybrid  — bash + Sonnet AI review — balanced [recommended]"
  echo "   3) Deep    — bash + Opus AI review — thorough, higher cost"
  echo ""
  echo "   All levels run the same bash checks (compilation, secrets, quality)."
  echo "   Hybrid/Deep add an AI pass that catches logic bugs and edge cases."
  echo "   AI review adds warnings only — never blocks commits."
  echo ""
  read -p "   Choose [1-3] (default: 1): " review_choice

  case "$review_choice" in
    2) REVIEW_LEVEL="hybrid" ;;
    3) REVIEW_LEVEL="deep" ;;
    *) REVIEW_LEVEL="simple" ;;
  esac
fi

echo ""
echo "   🔍 Review level: $REVIEW_LEVEL"

# Configure review level in pre-commit-review.sh
if [ -f "scripts/pre-commit-review.sh" ]; then
  sed -i.bak "s/^REVIEW_LEVEL=\"\${REVIEW_LEVEL:-simple}\"/REVIEW_LEVEL=\"\${REVIEW_LEVEL:-${REVIEW_LEVEL}}\"/" scripts/pre-commit-review.sh && rm -f scripts/pre-commit-review.sh.bak
  echo "   ✅ Pre-commit review configured (level: $REVIEW_LEVEL)"

  if [ "$REVIEW_LEVEL" = "hybrid" ] || [ "$REVIEW_LEVEL" = "deep" ]; then
    if [ -f "scripts/ai-review.sh" ]; then
      echo "   ✅ AI review script ready"
    else
      echo "   ⚠️  scripts/ai-review.sh not found — AI review won't work"
    fi
    echo "   📝 TODO: Set ANTHROPIC_API_KEY in .env or ~/.env for AI review"
  fi

  echo "   📝 TODO: Configure stack settings at top of scripts/pre-commit-review.sh"
  echo "   📝 TODO: Add project-specific checks in the [SPEC] section"
else
  echo "   ⚠️  scripts/pre-commit-review.sh not found"
fi

echo "   📝 TODO: Test hooks with a sample file write"
echo "   📝 TODO: Customize lint-check.sh for your stack"
echo "   📝 TODO: See docs/specs/code-review-gates.md for review gate philosophy"
echo "   ✅ docs-check.sh hook active — warns if src/ changes without docs/ update"
echo ""

if [ "$LEVEL" -lt 4 ]; then
  echo "✅ Level 3 setup complete!"
  echo ""
  echo "Daily workflow:"
  echo "  cd $(basename $PWD) && claude"
  echo "  → Same as L2, plus:"
  echo "  → Hooks run automatically on file write and bash"
  echo "  → /spec-review src/ to run agent review"
  exit 0
fi

# ============================================================
# L4: Agents + Agent Teams + Long-term Memory
# ============================================================
echo "🤖 L4: Setting up agents, memory, and autonomous capabilities..."

mkdir -p .claude/agents

AGENT_COUNT=$(find .claude/agents -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
echo "   🕵️ $AGENT_COUNT agents found"

# Memory layer
echo ""
echo "🧠 L4: Setting up long-term memory..."
if [ -f "memory/index.py" ]; then
  echo "   ✅ Memory module found"

  # Create virtual environment if it doesn't exist
  if [ ! -d "memory/.venv" ]; then
    echo "   📦 Creating Python virtual environment..."
    if python3 -m venv memory/.venv 2>/dev/null; then
      echo "   ✅ Virtual environment created at memory/.venv"
    else
      echo "   ⚠️  Failed to create venv — install python3-venv or use: python3 -m venv memory/.venv"
    fi
  else
    echo "   ✅ Virtual environment exists (memory/.venv/)"
  fi

  # Install dependencies in venv
  MEMORY_PIP="memory/.venv/bin/pip"
  MEMORY_PYTHON="memory/.venv/bin/python"

  if [ -f "$MEMORY_PIP" ]; then
    if "$MEMORY_PYTHON" -c "import chromadb" 2>/dev/null; then
      echo "   ✅ Dependencies installed"
    else
      echo "   📦 Installing memory dependencies..."
      "$MEMORY_PIP" install -q -r memory/requirements.txt 2>/dev/null \
        && echo "   ✅ Dependencies installed" \
        || echo "   ⚠️  Install failed — run manually: source memory/.venv/bin/activate && pip install -r memory/requirements.txt"
    fi

    # Auto-index if not already done
    if [ ! -d "memory/.chroma" ]; then
      echo "   📦 Running initial index..."
      "$MEMORY_PYTHON" memory/index.py 2>/dev/null \
        && echo "   ✅ Initial index complete" \
        || echo "   ⚠️  Index failed — run manually: source memory/.venv/bin/activate && python memory/index.py"
    else
      echo "   ✅ Vector DB exists (memory/.chroma/)"
    fi
  fi

  # Install post-commit hook
  if [ -d ".git" ] && [ -f "scripts/post-commit-index.sh" ]; then
    cp scripts/post-commit-index.sh .git/hooks/post-commit
    chmod +x .git/hooks/post-commit
    echo "   ✅ Post-commit hook installed (auto-index)"
  fi

  # Add venv to .gitignore if not already there
  if [ -f ".gitignore" ]; then
    if ! grep -q "memory/.venv" .gitignore 2>/dev/null; then
      echo "memory/.venv/" >> .gitignore
      echo "   ✅ memory/.venv/ added to .gitignore"
    fi
  fi
else
  echo "   ⚠️  memory/ module not found"
fi
# Configure agent teams in settings.json
SETTINGS_FILE=".claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
  if ! grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$SETTINGS_FILE" 2>/dev/null; then
    # Add env block with agent teams flag
    if grep -q '"env"' "$SETTINGS_FILE" 2>/dev/null; then
      # env block exists — add the key
      sed -i.bak 's/"env"\s*:\s*{/"env": {\n    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",/' "$SETTINGS_FILE" && rm -f "$SETTINGS_FILE.bak"
    else
      # No env block — add it after opening brace
      sed -i.bak 's/^{/{\'$'\n  "env": {\n    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"\n  },/' "$SETTINGS_FILE" && rm -f "$SETTINGS_FILE.bak"
    fi
    echo "   ✅ Agent teams enabled in $SETTINGS_FILE"
  else
    echo "   ✅ Agent teams already configured"
  fi
else
  echo "   ⚠️  $SETTINGS_FILE not found — creating with agent teams config"
  cat > "$SETTINGS_FILE" << 'SETTINGS_EOF'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
SETTINGS_EOF
  echo "   ✅ Agent teams enabled in $SETTINGS_FILE"
fi

echo ""
echo "   📝 TODO: Customize agents in .claude/agents/"
echo "   📝 TODO: Set up self-healing CI pipeline"
echo ""

echo "✅ Level 4 setup complete!"
echo ""
echo "Daily workflow:"
echo "  cd $(basename $PWD) && claude"
echo "  → Same as L3, plus:"
echo "  → python memory/query.py 'how did we handle X' — semantic search"
echo "  → python memory/index.py --incremental — re-index after changes"
echo "  → 'Create an agent team for [task]'"
echo "  → Author-Critic loop runs automatically"

echo ""
echo "================================================"
echo "📊 Summary"
echo "================================================"
echo "Level:    $LEVEL"
echo "Design:   $DESIGN_FLOW"
echo "Review:   ${REVIEW_LEVEL:-n/a}"
echo "Skills:   $SKILL_COUNT"
echo "Commands: $CMD_COUNT"
echo "Agents:   $AGENT_COUNT"
echo "Hooks:    $([ -f '.claude/hooks.json' ] && echo 'Active' || echo 'Not configured')"
echo "Memory:   $([ -d 'memory/.chroma' ] && echo 'Indexed' || echo 'Not indexed')"
echo ""
echo "Next: Search for [SPEC] markers and fill them in:"
echo "  grep -r '\[SPEC\]' CLAUDE.md docs/ .claude/ | head -20"
if [ "$DESIGN_FLOW" != "none" ]; then
  echo ""
  echo "Design system setup:"
  echo "  See docs/design-flow-guide.md for detailed guidance"
  echo "  Fill in tokens: docs/specs/design-system/README.md"
fi
