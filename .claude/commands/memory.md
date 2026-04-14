Long-term memory operations for the project.

Arguments: $ARGUMENTS (subcommand: index | search <query> | stats)

Flags:
  --global     Search/show global cross-project memory instead of project memory
  --both       Search both project and global memory, merge results by relevance

Workflow:
1. If "index": run `python memory/index.py --incremental` to re-index changes
   (ADRs, post-mortems, and learner reports auto-promote to global memory if enabled)
2. If "search <query>": run `python memory/query.py "<query>" --agent-format` and use as context
3. If "search --global <query>": run `python memory/query.py "<query>" --global --agent-format`
4. If "search --both <query>": run `python memory/query.py "<query>" --both --agent-format`
5. If "stats": run `python memory/query.py --stats` to see chunk counts
6. If "stats --global": run `python memory/query.py --stats --global` to see global memory

After searching, use the results as context for responding to the user.
Always cite the source (file and excerpt) when using information from memory.

If the memory module is not installed, instruct:
  pip install -r memory/requirements.txt
  python memory/index.py
