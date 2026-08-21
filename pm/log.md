# Log

Append-only. Newest entries at the bottom. Tag each: [STATUS] / [DECISION] /
[DISCOVERY] / [TODO].

**Read the header block below first — it is the current state of the project in one
screen.** Sessions 1-15 (2026-08-19 to 2026-08-21) are condensed into the timeline and
archived verbatim in [`pm/log-archive-2026-08.md`](log-archive-2026-08.md); the recurring
failure patterns extracted from them are in
[`context/index/lessons.md`](../context/index/lessons.md), which is the file worth reading
before starting work.

---

## Current state — 2026-08-21

**Phase.** Documentation complete; implementation not started. No Dart code exists.

**Active issue.** `FEAT01-foundation` — plan written and confirmed, not yet executed.
`app/` exists and is empty. Nothing is committed.

**Stack.** Flutter/Dart, `drift` over SQLite, Riverpod, no backend, local-first, single
user. **Settled, no longer provisional** — the choice hinged on iOS being a real target
and it was confirmed 2026-08-21.

**Targets.** Android and iOS. Neither is runnable on this machine: no Android SDK
(install before UC14, the first UI issue), and no Mac, so `app/ios/` is versioned but
never compiled. Web is not a fallback — `NativeDatabase.createInBackground` is
native-only. `flutter test` is headless and works, which is where `testing.md` puts the
correctness surface.

**Layout.** The Dart package is `app/`, not the repository root. Every Flutter command
needs `working-directory: app`.

**Toolchain.** Flutter 3.47.1 / Dart 3.13.1 at `C:/flutter`, matching the CI pin. Dart MCP
server 1.1.1. *A session started before the PATH edit cannot see `flutter` — restart the
process, do not re-edit PATH.*

**CI.** `.github/workflows/ci.yml`, two jobs. `docs` runs `audit.py` and works today.
`app` is guarded on `app/pubspec.yaml` and stays inert until FEAT01 lands one — **which
means the first push after FEAT01 is the first real CI run.** Get the four commands in
FEAT01 D7 green locally first.

**Audit.** `python audit.py` — green at 13 passed / 0 warnings / 0 failures. Proves the
artifacts agree with each other; proves nothing about whether they are right
(`lessons.md` §12).

**Open, needing an owner ruling — neither gates FEAT01, both are about screens:**
1. **UC-13 step 3, budget group CRUD, has no supporting class** on any class diagram.
   `seq-uc13` scopes it out with a note rather than inventing a participant, so UC-13 as
   drawn does not deliver what the workbook promises. Either a class diagram gains the
   classes or UC-13 is re-sliced.
2. **Does `note` appear on the transfer / lend-borrow / repayment screens?** `seq-uc04`
   and `seq-uc05` carry it; `seq-uc06/07/08` do not. The column exists on `Transaction`
   either way.

**Open, non-blocking:** one `fr-nfr.md` §4 item — where the data lives, narrowed to
phone-only but not closed.

**Standing caveat.** `context/coding-conventions/` is **provisional**. No `pub get` has run
for this project, so no version number in `riverpod.md` or `drift.md` is verified. FEAT01
is expected to correct them and say so here.

---

## Timeline — sessions 1-15 (2026-08-19 → 2026-08-21)

Full entries in [`pm/log-archive-2026-08.md`](log-archive-2026-08.md). Canonical homes for
anything durable are named; this is an index, not a record.

| When | What happened | Where it lives now |
|---|---|---|
| 08-19 s1 | Repo surveyed — framework complete, all project state empty. First `fr-nfr.md` **discarded**: invented rather than elicited. Real elicitation held; "balances" turned out to mean **balance sheet**. 18 FRs, 4 NFRs. | `docs/fr-nfr.md`, `input/2026-08-19-owner-scope-conversation/` |
| 08-19 s2 | FRs promoted to the workbook (UC-01..UC-13). Sheets renamed `UC FR`/`UC Non-FR`. Stack chosen **Kotlin**, then **reversed to Flutter the same day** when iOS moved from "polite maybe" to assumed. ISSUE-001 ERD done. | `docs/workbook.xlsx`, `decisions.md`, `docs/diagrams/erd.drawio` |
| 08-20 | Riverpod chosen, unblocking ISSUE-002 (three class diagrams). ISSUE-003 state diagram drawn, then **deleted** by ISSUE-004 when the owner removed FR-16's budget lock — "no more guardrails". `statuses.md` now lists no values for any entity. | `decisions.md`, `docs/statuses.md`, `class-*.drawio` |
| 08-20 | ISSUE-005 component diagram — the last Phase 1 artifact. D1: modules join each other's tables rather than calling another module's DAO. `audit.py` written. Two OMG spec stubs added, closing a `CLAUDE.md` gate that was being violated unnoticed. | `component-overview.drawio`, `audit.py`, `context/files/` |
| 08-20 | "A month" = calendar month. ISSUE-006 `enums.md` — the seven transaction kinds had existed **only in a closed issue's plan**. ISSUE-007 currency: one app-level setting, amounts as `int` minor units, `Settings` becomes a fourth module. | `docs/enums.md`, `decisions.md` |
| 08-20 | Backlog drafted, then **re-cut to one issue per use case** (`UC{NN}-{slug}`, `FEAT{NN}`). ISSUE-008 sequence conventions — sequence diagrams are the only type authored as **Mermaid** and converted. ISSUE-009 `coding-conventions/`. | `pm/tracker.yaml`, `sequence-conventions.md`, `context/coding-conventions/` |
| 08-21 | `Transaction.note` added; ERD re-opened. **All 14 sequence diagrams drawn**, every lifeline script-checked against the class diagrams. Renders moved to `pm/issues/<issue>/` and committed, with `renders.lock` guarding staleness. Toolchain installed; repo under git; CI written. | `docs/diagrams/seq-uc*.drawio`, `renders.lock`, `.github/` |
| 08-21 | **FEAT01 planned.** iOS confirmed → the Flutter decision stops being provisional. The app moves to `app/`, which silently broke CI's probe. Log distilled into this file plus `lessons.md`. | this file, `lessons.md`, `feat01-foundation/plan.md` |

---

## 2026-08-21 — Log restructured for subagent use

**[DECISION]** `pm/log.md` split three ways. It had reached 1,462 lines — a cost no
subagent can pay, and one no human was paying either. Now:

- **`pm/log.md`** (this file) — a current-state block, a timeline index, and new entries
  from here on.
- **`pm/log-archive-2026-08.md`** — sessions 1-15 verbatim, unedited.
- **`context/index/lessons.md`** — the recurring failure patterns, deduplicated with
  their evidence.

**[DISCOVERY]** Reading all fourteen sessions at once showed what no single session could:
**the same failures recur, and the log was the only place that fact was visible.** Four
registers left stale in one day; three instances of a value changing from stored to
derived and silently invalidating what was built on it; four checks that passed while
looking at the wrong set. Individually each reads as a slip. Together they are a pattern
worth a file — which is the argument for `lessons.md` existing at all.

**[DECISION]** The archive is preserved **verbatim, including terms that later changed**
(`UC Non-BPMN`, `ISSUE-015`, the superseded Kotlin stack). The log is append-only and
those entries were accurate when written; rewriting closed history to match a later
renumber is the tidy-up that makes a record untrustworthy. `audit.py` already carries the
stale paths in `ALLOWED_DANGLING` with that reason.

**[STATUS]** Two subagents added — `feat-planner` (writes and revises `plan.md` files) and
`flutter-coder` (executes a confirmed plan). Neither may cross into the other's job: the
planner writes no code, and the coder may not widen a plan's scope. Details in
`.claude/agents/`.
