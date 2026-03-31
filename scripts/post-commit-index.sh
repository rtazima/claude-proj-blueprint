#!/bin/bash
# L4 hook: auto-index project into vector DB on commit
# Install: cp scripts/post-commit-index.sh .git/hooks/post-commit && chmod +x .git/hooks/post-commit

# Only run if memory module exists
if [ ! -f "memory/index.py" ]; then
  exit 0
fi

# Use venv python if available, fallback to system python
if [ -f "memory/.venv/bin/python" ]; then
  PYTHON="memory/.venv/bin/python"
elif command -v python3 &>/dev/null; then
  PYTHON="python3"
else
  exit 0
fi

# Only run if dependencies are installed
if ! "$PYTHON" -c "import chromadb" 2>/dev/null; then
  exit 0
fi

# Run incremental index in background (don't block commit)
"$PYTHON" memory/index.py --incremental &>/dev/null &

echo "🧠 Memory index updated (background)"
