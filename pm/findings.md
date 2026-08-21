# Findings

**The unattended run's output.** After the last issue closes, two `repo-qa` sweeps run —
one over the app, one over the paper trail — and write what they find here. **Then the run
stops.** Nothing is fixed, no issue is reopened.

That stop is deliberate. A cross-cutting finding often needs a decision only the owner can
make, and a run that starts reopening closed issues churns without converging. **This file
is what the owner reads when they come back** — a clear list beats a repo quietly edited
toward one agent's judgement.

Distinct from its neighbours: `pm/questions.md` holds questions that **blocked** work before
it happened; this holds problems found in work **already done**. An entry here never gates
anything — it is a report, not a queue.

## Format

```
## F{N} — {one-line finding}                    [OPEN | ACCEPTED | FIXED | WONTFIX]
**Scope:** APP | TRAIL          **Severity:** defect | risk | improvement
**Where:** file:line, or the artifact
**Violates:** the rule, decision or requirement — by name
**What it is:** what is wrong, and what it causes. Not how to fix it.
**Confidence:** certain | likely | worth checking
```

**Severity is whether it is wrong, not how hard it is to fix.**

- **defect** — breaks a stated requirement or a recorded decision. A `double` holding money,
  a disabled control against NFR-4's zero refusals, a diagram that no longer matches code.
- **risk** — not wrong today, but a trap. A duplicated query that will drift, a convention
  that slipped partway through.
- **improvement** — better if changed, wrong in no sense.

Keep the three separate. Forty style notes bury two real defects, and this list exists to
decide what happens next.

## Resolving

The owner reads, then either promotes a finding to a tracked issue in `pm/tracker.yaml`
(where it gets a plan like any other work) or marks it `WONTFIX` with a reason. **A defect
resolved by a decision rather than a change is still resolved** — record which.

`lessons.md` applies here too: if a finding is another occurrence of a pattern already in
that file, add it there as evidence. The pattern is worth more than the individual fix.

---

*Phase 2 has not run yet. The entry below was filed during phase 1, by `issue-qa` at an
issue close, under the third option in its brief: not certain enough to reject, not certain
enough to wave through silently.*

## F1 — the "all seven tables exist" test reads drift's declared tables, not the database   [OPEN]
**Scope:** APP          **Severity:** risk
**Where:** `app/test/database/app_database_test.dart`, the `FEAT01: all seven tables exist` test
**Violates:** nothing stated. It is the shape `lessons.md` §5 describes — a check whose subject
is not quite the thing it is named for.
**What it is:** the test asserts over `database.allTables`, which is generated from the
`@DriftDatabase(tables: [...])` annotation and never touches SQLite. It does catch the failure
that can realistically happen — a table declared but left out of the annotation — and a
sibling test does query real SQL, so the schema is proven to be created. But the assertion as
named ("the tables exist") would hold even if nothing had been created, and it is the pattern
that has produced four green-for-the-wrong-reason results on this project. `sqlite_master`
would answer the question the name asks.
**Confidence:** worth checking — whether this matters depends on what the rest of the suite
looks like once DAO tests exist, which is not visible from one issue's diff.
