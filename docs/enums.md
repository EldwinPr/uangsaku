# Enums

Canonical list of legal **enum values** per column — the vocabulary of what a thing
*is*.

The counterpart to [`statuses.md`](statuses.md), and the line between them is worth
stating because it decides where a new value belongs:

> **A status says what an entity may do next. An enum says what an entity is.**

A status gates behaviour, so it needs a state diagram showing which moves between values
are legal. An enum classifies, so it needs none — every value is reachable from every
other by editing the record. If a proposed value forbids something, it is a status and
belongs in `statuses.md`; if it only labels, it belongs here.

As of 2026-08-24 `statuses.md` lists **no** values for any entity, and this file lists
**seventeen** across five columns. That asymmetry is the expected shape for an app built
on NFR-4 ("the app assists; it does not police") — such an app accumulates
classifications freely and statuses not at all.

---

## `Account.group` — 3 values

Which of FR-1's three kinds of money an account holds. Required; every account has
exactly one.

| Value | Meaning | Example |
|---|---|---|
| `HOLDING` | Money I hold and can actually spend | Cash, bank account, e-wallet (FR-2, FR-3) |
| `RECEIVABLE` | Money owed to me | What Budi owes me (FR-5) |
| `PAYABLE` | Money I owe | Credit card, loan (FR-4) |

**Why three and not two.** FR-1 refuses to merge spendable with owed-to-me: *"money
sitting with Budi is mine, but it cannot buy lunch."* `HOLDING` and `RECEIVABLE` are
both positive and both the owner's; only `HOLDING` is reachable. The balance sheet's
four figures (UC-01) are three sums over this column plus their net.

**The naming was closed by constraint, not preference** — worth knowing before anyone
proposes "renaming these to something more standard." NFR-1's fit criterion forbids a
debit/credit column outright, so those words were never available to choose. Decided
2026-08-19 with the schema (ISSUE-001 D2, `context/index/decisions.md`); it also closed
the `fr-nfr.md` §4 "credit/debit account" naming collision.

**One table, not subtypes.** FR-4 and FR-5 make a credit card and a person ordinary
accounts, so this is a discriminator on `Account` — there are no subtype tables and no
separate `Debt` entity. The owner re-confirmed that a debt is an account.

---

## `Transaction.kind` — 7 values

What sort of movement a transaction records. Required; every transaction has exactly
one. All seven live in one ledger table (ISSUE-001 D1), so this column is the
discriminator that distinguishes them.

The values only make sense alongside which account each side touches, so that table
lives here rather than in the issue plan it was decided in:

| Value | `from_account_id` | `to_account_id` | Traces to |
|---|---|---|---|
| `expense` | the wallet | *null* | FR-6, UC-04 |
| `income` | *null* | the wallet | FR-7, UC-05 |
| `transfer` | wallet A | wallet B | FR-8, UC-06 |
| `lend` | the wallet | the person's `RECEIVABLE` account | FR-9, UC-07 |
| `borrow` | the `PAYABLE` account | the wallet | FR-9, UC-08 |
| `repayment` | either side | the other | FR-9, UC-07/UC-08 |
| `adjustment` | *null*, always | the corrected account, always | FR-18, UC-03 |

**Resolved 2026-08-23** (`pm/questions.md` Q4, `context/index/decisions.md`): the row
above no longer hedges. `adjustment` is the ledger's **only kind whose `amount` may be
negative** — direction is the sign of the diff, not which side is filled, because
`to_account_id` never varies. An upward correction stores a positive `amount`; a downward
one stores a negative `amount`. Every other kind's `amount` stays a non-negative
magnitude.

**The property that makes this shape worth keeping: "is this spending?" is
`to_account_id IS NULL`.** FR-8's "a transfer is not an expense" and FR-9's "lending is
not spending" are therefore enforced by the shape of the data, not by a rule every
future query has to remember — and `adjustment`'s fixed `to_account_id` means a balance
correction is never spending either, in either direction, by the same predicate. A
balance is likewise one expression over one table (NFR-2), and that expression already
tolerates a signed `amount` correctly: a negative contribution on the `to` side
subtracts, exactly as an equivalent `from`-side magnitude would.

**Why the column exists at all**, given it is largely derivable from the two accounts'
groups: reporting and UC-09's list both want to filter on it directly, and
`erd-conventions.md` endorses a type discriminator on a ledger table.

**This is internal double-entry without the name**, which NFR-1 explicitly permits —
accounting structure may be used internally where it makes the numbers correct for
free, but it may not surface. The owner still sees one amount and one form (FR-6) and
is never asked to pick two sides of an entry.

---

## `Settings.currency` — 2 values

The currency every amount in the app is recorded in. **App-level: one value for the
whole database.** There is no per-account and no per-transaction currency, no exchange
rate, and no conversion anywhere (FR-19, ISSUE-007 D1).

| Value | Exponent | Minor unit | `1999` stored means |
|---|---|---|---|
| `IDR` | 0 | none in practice | Rp 1.999 |
| `USD` | 2 | cent | $19.99 |

**The exponent is the point of this enum, not decoration.** Every amount column —
`Account.opening_amount`, `Transaction.amount`, `Budget_Period.amount` — is an `int`
counting minor units, never a floating-point number. The exponent is what turns that
integer back into a displayable figure, and display is the only place a decimal point
exists.

**Why `int` and not `double`.** NFR-2 requires the numbers to agree with each other.
Binary floating point cannot represent 0.1 exactly, so error accumulates across sums;
a balance sheet whose net stops matching the sum of its parts by a cent cannot be fixed
by a better query, because the error is in storage. Proposed as `double` by the owner
2026-08-20 and changed to `int` on this argument.

**Adding a third value** (`CNY` was asked about) is an enum value plus a migration —
deliberately a code change rather than a user-editable table, since the owner is also
the developer and a settings table would be ceremony. Note what it is *not*: adding a
value here still means one currency for the whole app, not multi-currency. Per-account
currency is a schema change, weighed and withdrawn on 2026-08-20.

**Changing the value re-labels, it does not convert.** 50,000 recorded as `IDR` becomes
50,000 read as `USD`. The app warns and proceeds — under NFR-4 it refuses nothing, and
the fit criterion is zero refusals.

---

## `Settings.locale` — 2 values

The app's UI language (FEAT03, no FR/UC — a preference, not a domain classification).
**A real toggle, not a one-way rewrite**: both values have a complete translation via
Flutter's `AppLocalizations` (`app/lib/l10n/app_en.arb`, `app_id.arb`).

| Value | Meaning |
|---|---|
| `en` | English. |
| `id` | Bahasa Indonesia — the default (the app's home market). |

Unlike `Settings.currency`, changing this re-derives nothing and needs no warning
dialog — no recorded amount depends on which language renders it.

## `Settings.themeMode` — 3 values

The app's light/dark preference. A project-owned enum, never Flutter's own `ThemeMode`
in the table layer (`settings_table.dart` imports only `package:drift/drift.dart`) —
mapped to `ThemeMode` in the widget layer (`app.dart`) only.

| Value | Meaning |
|---|---|
| `system` | Follows the platform brightness. |
| `light` | Always light. |
| `dark` | Always dark. |

## Stated non-members

Things that look like enum values and are not. Recorded because each one has a
plausible-sounding wrong version, and the wrong version costs a migration.

- **`Account.settled` is a boolean, not an enum.** FR-11's "just tick" (ISSUE-001 D8).
  Two values, one move, no intermediate stage — a flag. `statuses.md` excludes it for
  the same reason. If a third value is ever wanted ("partially settled"), note that
  FR-11's "show how much is paid" is already answered by summing transactions against
  the account, so the third value would be a stored duplicate of a derivable number,
  which NFR-2 forbids.

- **"Others" is not a `Budget_Group` value.** It is `budget_group_id IS NULL`
  (FR-17, ISSUE-001 D5). It appears in the budget view as though it were a group, but
  it is deliberately not a row — a row could be renamed, deleted, or have a budget set
  against it, and none of those make sense for "everything untagged."

- **`Budget_Period` has no status values at all.** It had `open` / `locked` / `closed`
  for one day; removing FR-16's lock collapsed the lifecycle. See `statuses.md`, which
  records why in full. Its `starts_on` / `ends_on` dates remain load-bearing.

- **A category is not an enum.** FR-10's categories and subcategories are user-created
  rows in two tables (ISSUE-001 D6), not a fixed vocabulary. The two-level depth is
  structural — enforced by there being exactly two tables — rather than by a value.

---

## Adding a value here

1. Ask what it **forbids**. If the answer is anything, it is a status, not an enum —
   it belongs in `statuses.md` and needs a state diagram, and under NFR-4 it needs an
   argument in `docs/fr-nfr.md` first.
2. Ask whether it is **derivable** from data already recorded. If it is, it is a query,
   not a column (NFR-2).
3. If it survives both, add it here **with the requirement it traces to**, and update
   the ERD and the owning module's class diagram in the same pass — the diagrams name
   these enums, and a value list that exists in only one of the three places is the
   drift this file was created to end.

*Currency landed here on 2026-08-20*, which is what this line used to predict. The
free-text note this line used to name as the next candidate was **decided 2026-08-21 and
did not land here** — it is a nullable column on `Transaction`, not a vocabulary, and it
is in the schema as of `FEAT01`. The one `fr-nfr.md` §4 item still open is where the data
lives, which has no enum in it either.
