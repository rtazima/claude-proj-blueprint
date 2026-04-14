# Module: Long-Term Memory

> Persistent vector memory for Level 4 agents. Allows the system to "remember" decisions, solutions, and context from months ago.

## Why

CLAUDE.md lasts a single session. Obsidian lasts forever, but needs to be read in full. Vector memory solves the middle ground: instant semantic search over the entire project history.

```
"How did we solve rate limiting last time?"
→ Vector DB finds: ADR-012, PR #47, March post-mortem
→ Agent receives precise context without reading 200 files
```

## Memory architecture (4 layers)

| Layer | Storage | Duration | What it stores | Search |
|-------|---------|----------|---------------|--------|
| Short-term | CLAUDE.md | Session | Stack, conventions, gotchas | Claude reads it whole |
| Mid-term | docs/ (Obsidian) | Permanent (Git) | PRDs, ADRs, specs, runbooks | Grep, links |
| Long-term | Vector DB (project) | Permanent | Embeddings of project files | Semantic |
| Cross-project | Vector DB (global) | Permanent | ADRs, post-mortems, learner reports from ALL projects | Semantic (`--global`) |

### Cross-project memory
Decisions made in one project often apply to others. The global memory layer stores
ADRs, post-mortems, and learner reports from every project that has it enabled.
Lives at `~/.claude/memory/global/` (shared across all projects on the machine).

**What gets promoted to global** (configurable in `config.yaml`):
- ADRs — architectural decisions transfer across projects
- Post-mortems — lessons learned are universal
- Learner reports — extracted patterns benefit all projects

**What stays project-only**:
- Code — too project-specific to be useful elsewhere
- PRDs — product requirements are project-scoped
- Git commits — too granular for cross-project value

**Usage**:
```bash
python memory/query.py "rate limiting" --global --agent-format   # global only
python memory/query.py "rate limiting" --both --agent-format     # merged results
```

## Recommended stack

### Option A: Chroma (blueprint default)
- **When to use**: most projects, quick setup, no extra infrastructure
- **How it works**: embedded vector DB, runs locally, persists to disk
- **Embedding**: `all-MiniLM-L6-v2` via sentence-transformers (local, free)
- **Storage**: `memory/.chroma/` (gitignored — each dev indexes locally)

### Option B: pgvector (shared, team-wide)
- **When to use**: teams with 2+ devs that need shared memory
- **How it works**: PostgreSQL extension, SQL queries with vector similarity
- **Advantage**: everyone points to the same DB — what one dev indexes, everyone searches
- **Embedding**: same local model or via API (OpenAI, Voyage, Cohere)

**pgvector setup:**
```bash
# 1. On PostgreSQL (15+), enable the extension
psql -U postgres -c "CREATE DATABASE project_memory;"
psql -U postgres -d project_memory -c "CREATE EXTENSION vector;"

# 2. Create a dedicated user
psql -U postgres -d project_memory -c "
  CREATE USER memory_user WITH PASSWORD 'your-secure-password';
  GRANT ALL PRIVILEGES ON DATABASE project_memory TO memory_user;
  GRANT ALL ON SCHEMA public TO memory_user;
"

# 3. In the project, edit memory/config.yaml:
#    Comment out backend: chroma
#    Uncomment backend: pgvector and fill in credentials

# 4. Each dev exports the password as an env var (never hardcode)
export PGVECTOR_PASSWORD="your-secure-password"

# 5. Install extra dependencies
pip install psycopg2-binary pgvector

# 6. Index (schema is created automatically)
python memory/index.py
```

**Docker (quick alternative):**
```bash
docker run -d --name pgvector \
  -e POSTGRES_DB=project_memory \
  -e POSTGRES_USER=memory_user \
  -e POSTGRES_PASSWORD=your-secure-password \
  -p 5432:5432 \
  pgvector/pgvector:pg16
```

### Option C: Cloud (at scale)
- **When to use**: large teams, lots of data, need a hosted solution
- **Options**: Pinecone, Weaviate Cloud, Qdrant Cloud
- **Trade-off**: monthly cost, but zero ops

## What to index

| Source | Type | Chunking | Frequency |
|--------|------|----------|-----------|
| `docs/architecture/` | ADRs | 1 ADR = 1 chunk | On every commit |
| `docs/product/` | PRDs | Sections (## heading) | On every commit |
| `docs/runbooks/post-mortems/` | Post-mortems | 1 post-mortem = 1 chunk | On every commit |
| `docs/specs/` | Spec modules | Sections (## heading) | On every commit |
| `src/` | Code | 1 file = 1 chunk (with path as metadata) | On every commit |
| Git log | Commits | 1 commit message = 1 chunk | On every commit |

## Metadata

Each chunk stores:
```json
{
  "source": "docs/architecture/adr-012-rate-limiting.md",
  "type": "adr",
  "title": "ADR-012: Rate Limiting Strategy",
  "last_modified": "2026-03-15",
  "tags": ["rate-limiting", "redis", "architecture"]
}
```

## Usage

### Index
```bash
# Index the entire project
python memory/index.py

# Index only changes since last run
python memory/index.py --incremental
```

### Search
```bash
# Semantic search
python memory/query.py "how did we solve authentication"

# Filtered by type
python memory/query.py "rate limiting" --type docs

# Top 5 results
python memory/query.py "deploy failure" --top 5
```

### In Claude Code (via skill)
The `memory` skill is auto-invoked when the agent needs historical context. The Lead agent queries it before planning.

## Setup

```bash
# Install dependencies
pip install -r memory/requirements.txt

# First index
python memory/index.py

# Test
python memory/query.py "test query"
```

## Configuration

Edit `memory/config.yaml` — see the file for all available options.
