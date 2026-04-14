"""
Query the project's long-term memory via semantic search.

Usage:
    python memory/query.py "how did we solve rate limiting"
    python memory/query.py "authentication" --type adr
    python memory/query.py "deploy failure" --type post_mortem --top 3
    python memory/query.py "login component" --type code
    python memory/query.py --stats
"""

import argparse
import sys
from pathlib import Path

import yaml
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.text import Text

from memory.backends import create_backend

console = Console()


def load_config() -> dict:
    config_path = Path(__file__).parent / "config.yaml"
    with open(config_path) as f:
        return yaml.safe_load(f)


def make_global_config(config: dict) -> dict:
    """Create a config dict that points to the global memory store."""
    global_cfg = config.get("global_memory", {})
    persist_dir = global_cfg.get("persist_dir", "~/.claude/memory/global")
    persist_dir = str(Path(persist_dir).expanduser())
    return {
        **config,
        "backend": "chroma",
        "persist_dir": persist_dir,
        "collection_name": global_cfg.get("collection_name", "global_memory"),
    }


def get_store(config: dict):
    try:
        return create_backend(config)
    except Exception as e:
        console.print(f"[red]Could not connect to vector DB: {e}[/red]")
        console.print("[yellow]Run 'python memory/index.py' first.[/yellow]")
        sys.exit(1)


def show_stats(config: dict):
    """Show statistics about the indexed knowledge base."""
    store = get_store(config)
    total = store.count()

    # Get type distribution
    all_metadatas = store.get_all_metadatas()
    type_counts: dict[str, int] = {}
    source_counts: dict[str, int] = {}

    for meta in all_metadatas:
        doc_type = meta.get("type", "unknown")
        type_counts[doc_type] = type_counts.get(doc_type, 0) + 1

        source = meta.get("source", "unknown")
        top_dir = source.split("/")[0] if "/" in source else source
        source_counts[top_dir] = source_counts.get(top_dir, 0) + 1

    table = Table(title=f"Knowledge Base — {total} chunks")
    table.add_column("Type", style="bold")
    table.add_column("Chunks", justify="right")

    for doc_type, count in sorted(type_counts.items(), key=lambda x: -x[1]):
        table.add_row(doc_type, str(count))

    console.print(table)

    source_table = Table(title="By source directory")
    source_table.add_column("Directory", style="bold")
    source_table.add_column("Chunks", justify="right")

    for source, count in sorted(source_counts.items(), key=lambda x: -x[1]):
        source_table.add_row(source, str(count))

    console.print(source_table)


def search(
    query: str,
    config: dict,
    top_k: int = 5,
    type_filter: str | None = None,
    min_similarity: float = 0.3,
) -> list[dict]:
    """Semantic search over the knowledge base."""
    store = get_store(config)

    # Load embedding model
    from sentence_transformers import SentenceTransformer
    model = SentenceTransformer(config["embedding_model"])

    query_embedding = model.encode(query).tolist()

    # Build where filter
    where = None
    if type_filter:
        where = {"type": type_filter}

    results = store.query(query_embedding, top_k=top_k, where=where)

    hits = []
    for i in range(len(results["ids"][0])):
        distance = results["distances"][0][i]
        similarity = 1 - distance  # cosine distance → similarity

        if similarity < min_similarity:
            continue

        hits.append({
            "id": results["ids"][0][i],
            "text": results["documents"][0][i],
            "metadata": results["metadatas"][0][i],
            "similarity": round(similarity, 3),
        })

    return hits


def display_results(hits: list[dict], query: str):
    """Pretty-print search results."""
    if not hits:
        console.print(f"\n[yellow]No results found for:[/yellow] {query}\n")
        return

    console.print(f"\n[bold]Results for:[/bold] {query}\n")

    for i, hit in enumerate(hits, 1):
        meta = hit["metadata"]
        sim = hit["similarity"]

        # Color by similarity
        if sim >= 0.7:
            sim_color = "green"
        elif sim >= 0.5:
            sim_color = "yellow"
        else:
            sim_color = "red"

        title = f"[bold]{i}. {meta.get('title', 'Untitled')}[/bold]"
        subtitle = (
            f"[dim]{meta.get('source', '?')}[/dim] · "
            f"[dim]{meta.get('type', '?')}[/dim] · "
            f"[{sim_color}]{sim:.0%} match[/{sim_color}]"
        )

        # Truncate text preview
        preview = hit["text"][:300]
        if len(hit["text"]) > 300:
            preview += "..."

        console.print(Panel(
            f"{subtitle}\n\n{preview}",
            title=title,
            title_align="left",
            border_style="dim",
            padding=(0, 1),
        ))


def format_for_agent(hits: list[dict], scope: str = "project") -> str:
    """Format results as context for Claude Code agent consumption."""
    if not hits:
        return f"No relevant context found in {scope} memory."

    parts = [f"## Relevant context from {scope} memory\n"]

    for hit in hits:
        meta = hit["metadata"]
        parts.append(f"### {meta.get('title', 'Untitled')}")
        parts.append(f"Source: `{meta.get('source', '?')}` | "
                      f"Type: {meta.get('type', '?')} | "
                      f"Similarity: {hit['similarity']:.0%}")
        parts.append(f"\n{hit['text'][:1000]}\n")

    return "\n".join(parts)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Search project long-term memory")
    parser.add_argument("query", nargs="?", help="Search query")
    parser.add_argument("--type", type=str, default=None,
                        help="Filter by type: docs, code, adr, git_commit")
    parser.add_argument("--top", type=int, default=5,
                        help="Number of results (default: 5)")
    parser.add_argument("--min-sim", type=float, default=0.3,
                        help="Minimum similarity threshold (default: 0.3)")
    parser.add_argument("--stats", action="store_true",
                        help="Show knowledge base statistics")
    parser.add_argument("--agent-format", action="store_true",
                        help="Output as markdown for agent consumption")
    parser.add_argument("--global", dest="use_global", action="store_true",
                        help="Search global cross-project memory instead of project memory")
    parser.add_argument("--both", action="store_true",
                        help="Search both project and global memory, merge results")
    args = parser.parse_args()

    config = load_config()

    if args.stats:
        if args.use_global or args.both:
            global_config = make_global_config(config)
            console.print("[bold]Global Memory[/bold]")
            show_stats(global_config)
            if args.both:
                console.print("\n[bold]Project Memory[/bold]")
                show_stats(config)
        else:
            show_stats(config)
        sys.exit(0)

    if not args.query:
        parser.print_help()
        sys.exit(1)

    search_kwargs = dict(
        query=args.query,
        top_k=args.top,
        type_filter=args.type,
        min_similarity=args.min_sim,
    )

    if args.both:
        # Search both project and global, merge by similarity
        project_hits = search(config=config, **search_kwargs)
        global_config = make_global_config(config)
        global_hits = search(config=global_config, **search_kwargs)
        for h in project_hits:
            h["_scope"] = "project"
        for h in global_hits:
            h["_scope"] = "global"
        all_hits = sorted(
            project_hits + global_hits,
            key=lambda h: h["similarity"],
            reverse=True,
        )[:args.top]
        if args.agent_format:
            print(format_for_agent(all_hits, scope="project + global"))
        else:
            display_results(all_hits, args.query)
    elif args.use_global:
        global_config = make_global_config(config)
        hits = search(config=global_config, **search_kwargs)
        if args.agent_format:
            print(format_for_agent(hits, scope="global"))
        else:
            display_results(hits, args.query)
    else:
        hits = search(config=config, **search_kwargs)
        if args.agent_format:
            print(format_for_agent(hits))
        else:
            display_results(hits, args.query)
