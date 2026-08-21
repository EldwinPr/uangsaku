Entry point — read this first, every session.

Read these before doing anything else:

- `pm/active.json` — which issue/worktree this session is on right now.
- `pm/tracker.yaml` — the ticket board: what's TODO/OUTLINED/WRITTEN/REVIEWED/DONE/BLOCKED.
- `context/general-rules.md` — cross-stack conventions that apply regardless of task type.
- `context/index/lessons.md` — how this project has actually gone wrong, distilled from
  fifteen sessions. Short, and it is the cheapest thing here that prevents a repeat.
- `pm/log.md` — the current-state block at its head. The pre-2026-08-21 narrative is
  archived in `pm/log-archive-2026-08.md`; read that only when you need the evidence
  behind something, not routinely.
- `context/index/map.yaml` — UC/FEAT → code index, so you don't re-discover where something lives.
- The active issue's `pm/issues/{id}-{slug}/plan.md`, if `active.json` points to one.
- `pm/questions.md` — the unattended run's halt queue. If anything in it is OPEN, an issue
  is blocked on an owner ruling and the answer is not in the repo yet.

That's it — no procedure detail here. How to actually do the work lives in `CLAUDE.md` (root) and `context/guide/*.md`, loaded on demand per task type.
