# FEAT13-person-picker-checkbox-redesign — The Orang/Utang checkbox moves outside the dropdown and gates creation entirely

**Status:** DONE 2026-08-24. Owner's direct request (manual-testing feedback,
round six), correcting FEAT11 D7's shipped design after seeing it live: the checkbox
was nested inside the autocomplete's suggestion overlay (only visible once typing a
non-matching name); the owner wants it as a persistent control above the field
instead, and — the real behavioral change — **inline creation is only possible at all
when the checkbox is checked**, and it can only ever create a `PERSON` account. No UC
owns this, same class as FEAT01-12.

**Depends on:** `FEAT11-person-account-type` — DONE (this issue revises `_PersonAccountField`,
which FEAT11 introduced).

## Decisions

**D1 — The checkbox becomes a persistent widget above the field, not part of the
suggestion overlay.** `_PersonAccountField` gains its own visible `Row(Checkbox,
Text(checkboxLabel))` rendered directly above the `RawAutocomplete`, always present
(not conditional on typed text) — replacing the current `CheckboxListTile` that only
appeared inside `optionsViewBuilder`'s "create new" row.

**D2 — Unchecked: select-only, no creation possible at all.** Confirmed with the
owner directly: *"if not checked cant create new account."* When unchecked,
`optionsBuilder` never adds the `isCreateNew` entry, regardless of whether the typed
text matches nothing — the field behaves exactly like a plain autocomplete over
existing accounts, with no path to creating a new one. Existing accounts (any group —
`RECEIVABLE`/`PAYABLE`/`PERSON`, per `personDebtChoices`) stay selectable the whole
time, checked or not — confirmed with the owner (*"still shows existing accounts
too"*): checking the box only **adds** the create option, it never hides or replaces
the normal picker.

**D3 — Checked: creation is always `PERSON`, unconditionally.** *"Create new account
is only for orang meaning only checkbox"* — there is no other type creatable from this
field anymore. This **replaces FEAT11 D7's `defaultGroupWhenUnchecked` entirely**:
`Lend`'s old unchecked→`RECEIVABLE` and `Borrow`'s old unchecked→`PAYABLE` behavior is
gone, because unchecked can no longer create anything (D2). The `_PersonAccountField`
constructor loses `showCheckbox`/`defaultGroupWhenUnchecked` (no longer meaningful
distinctions) — every call site now behaves identically: a checkbox, gating creation,
always producing `PERSON`.

**D4 — Repay's field now matches Lend/Borrow exactly — no more special-casing.**
FEAT11 D7 gave `Repay` no checkbox at all (always-create-`PERSON`, since it had no
sensible unchecked default). Under D2/D3 that asymmetry disappears on its own: every
flow's field is now "unchecked = can't create, checked = creates `PERSON`," which is
already exactly what `Repay` needs — so `Repay` gets the same persistent checkbox as
the other two, not a bespoke no-checkbox variant. One shape, three call sites.

**D5 — `openingAmount: 0` for an inline-created account is unchanged** — still
established by FEAT11, not revisited here.

## Out of scope

- Any change to what happens after creation (resolution via `_pendingCreateName` /
  `didUpdateWidget` / `addPostFrameCallback` — FEAT05's pattern — is untouched).
- The Repay direction toggle (FEAT11 D8) — unrelated control, unaffected by this issue.
- Any change to `personDebtChoices()` or which groups are selectable.

## Definition of done

Four commands green. Widget tests: unchecked, typing a name matching nothing shows
**no** "Create" option anywhere in the suggestion list, for all three flows
(Lend/Borrow/Repay); unchecked, an existing account is still selectable; checked,
typing a new name shows "Create '...'" and creating it always writes `AccountGroup.PERSON`
in all three flows (replacing the three separate FEAT11 D7 tests that asserted
`RECEIVABLE`/`PAYABLE` defaults — those defaults no longer exist); checked, an existing
account is still selectable too (the checkbox never hides the normal picker). The
checkbox itself is asserted as a persistent widget (`find.byType(Checkbox)` present
before any text is typed), not only inside an options overlay. `git diff --stat
app/drift_schemas/` empty — no schema change, presentation only.
