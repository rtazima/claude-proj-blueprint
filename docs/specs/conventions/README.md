# Convention Registry

The `REGISTRY.yaml` file maps which conventions each agent role receives, per phase.

## Why

Each agent (security-auditor, quality-guardian, etc.) only needs a subset of project
conventions. Loading everything into every agent wastes context and dilutes focus.

## How it works

- **`roles`** defines what each agent receives. `always` entries load in every phase;
  `phases` entries load only during that specific phase.
- **`conventions`** defines each convention key, linking it to its source file and
  providing a short description.

## Adding a convention

1. Add the key under the appropriate role(s) and phase(s) in `roles`.
2. Add the key's definition (source + description) in `conventions`.
3. Ensure the source file exists in the project.

## Extending with new roles

Add a new entry under `roles` following the same `always` / `phases` structure.
Reference it from agent definitions in `.claude/agents/`.
