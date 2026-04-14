---
name: memory
description: Long-term memory via vector DB. Activated when the user asks about past decisions, previous solutions, project history, "how did we do X", "last time", "we already solved", or when the agent needs historical context before planning an implementation.
allowed tools: Read, Bash
---

# Long-Term Memory

## When to use
- Before implementing: search for previous solutions to similar problems
- Before deciding: search for already-documented ADRs and trade-offs
- After incidents: search for post-mortems of similar issues
- When reviewing: search for project patterns and conventions

## How to search
```bash
# General semantic search (project memory)
python memory/query.py "your question here" --agent-format

# Search only in architectural decisions
python memory/query.py "rate limiting" --type docs --agent-format

# Search in code
python memory/query.py "authentication middleware" --type code --agent-format

# Search in commits
python memory/query.py "fix deploy" --type git_commit --agent-format

# Search global cross-project memory
python memory/query.py "how did we solve auth" --global --agent-format

# Search both project + global, merged by relevance
python memory/query.py "rate limiting strategy" --both --agent-format
```

Always use `--agent-format` to get structured markdown output.

## When to index
```bash
# After significant changes to docs/ or src/
python memory/index.py --incremental
# ADRs, post-mortems, and learner reports are auto-promoted to global memory
# if global_memory.enabled is true in config.yaml
```

## Rules
- ALWAYS check memory before creating an ADR (one may already exist on the topic)
- ALWAYS check before implementing a complex feature
- If memory returns relevant context, CITE the source in the implementation plan
- If no results, move on without mentioning memory

## Setup (if not configured)
```bash
pip install -r memory/requirements.txt
python memory/index.py
```
