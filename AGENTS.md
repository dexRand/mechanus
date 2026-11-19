# MECHANUS — Project Index

This file is the **map**. It lists each project and where its own `AGENTS.md` lives.

**Rule**: read only the `AGENTS.md` of the project you are working on. Never load the
others into context — load them on demand, when you enter that project.

**Deploy**: the official deployment is **bare-metal** — OpenCode 2 run by systemd
(`/etc/systemd/system/opencode-web.service`, port 4096, published at
`ai.yourdomain.com`). The Docker files are legacy. Provider keys are **never
committed**: they are supplied through the environment (`*_API_KEY`, e.g.
`DEEPSEEK_API_KEY`) or the global config/auth store.

| Repo | Path | AGENTS.md | What it is |
|------|------|-----------|------------|
| example-project | `/workspace/example-project` | `/workspace/example-project/AGENTS.md` | Your first project |

> Replace the example row with your real projects. Adjust paths to your checkout
> layout. Add a new row when you add a project; keep it one line per project
> (pointers only, no content duplication).

**Each project's own `AGENTS.md`** should state its check levels, so the swarm never runs a
long gate by mistake:

```markdown
## Checks
- L0 (seconds): <lint / types / build>
- L1 (minutes): <tests of what you touch, e.g. pytest tests/billing, jest --findRelatedTests>
- L2 (gate, may take hours): <full suite> — CI only, agents never run it
- Worktree setup: <deps to copy, env to link, test locks if a single test DB>
```
