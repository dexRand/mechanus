# Skills

MECHANUS uses a **curated subset** of agent skills — the ones that match the work,
not the whole catalog. Keep this list tight: every extra skill is fixed token cost
(its description) and routing noise.

## Curated set (~12)

Requirements & planning:
- `interview-me` (requirements interrogation, interactive phase only)
- `spec-driven-development`
- `planning-and-task-breakdown`

Build quality:
- `test-driven-development`
- `incremental-implementation`
- `api-and-interface-design`
- `code-simplification`

Frontend:
- `frontend-ui-engineering`
- `impeccable` (polish)

Review & debugging:
- `code-review-and-quality`
- `debugging-and-error-recovery`

Meta:
- `using-agent-skills`
- `mechanus` (this repo: the issue → builder → arbiter → PR method, `skills/mechanus/`)

## Install

These come from `addyosmani/agent-skills` + `impeccable`. Install per-project:

```bash
# inside a project repo
npx skills add addyosmani/agent-skills --skill test-driven-development
npx skills add addyosmani/agent-skills --skill code-review-and-quality
# ... (or copy the whole set once and trim)
```

The skills are installed **per project repo** (each repo has its own `.opencode/skills/`),
not globally — so a project carries the skills it actually needs.
