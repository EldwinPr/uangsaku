# FEAT05-category-picker — Category/subcategory pickers become autocomplete-with-inline-create

**Status:** DONE 2026-08-24. Was CONFIRMED — owner's direct request, third item from the same
manual-testing feedback round. No UC owns this, same class as FEAT01-04.

**Depends on:** `FEAT04-nav-redesign` — DONE.

## Scope, settled explicitly (owner's answer when asked)

**UI only. No schema change.** `Category` and `Subcategory` stay two separate drift
tables (ERD D6, FR-10's exactly-two-levels decision) — this issue replaces the picker
*widget*, not the data model. `CategoryDao`/`CategoriesNotifier` are unchanged; this
issue is a pure consumer of the existing `categoryTreeProvider` (read) and
`categoriesProvider.notifier.add()` (write, already exists — `add({int? categoryId,
required String name})`, category when `categoryId` is null, subcategory under it
otherwise, per its existing doc comment).

## Decisions

**D1 — Two screens, two pickers each, four autocomplete fields total.**
`RecordTransactionScreen` (category + subcategory, expense/income flows only — the
existing field visibility rule is unchanged) and `TransactionListScreen`'s `_EditSheet`
(category + subcategory, all kinds). Same widget shape in both places; a shared private
widget in whichever file makes sense, or duplicated if that's cleaner — coder's call, not
worth a shared public class for four call sites.

**D2 — The interaction: pick existing, or type a name that doesn't match to create it.**
Use Flutter's `Autocomplete<T>` (or `RawAutocomplete` if `Autocomplete` doesn't give
enough control over the "create new" affordance):

- Typed text matching an existing category/subcategory (case-insensitive) — selecting it
  from the suggestion list sets the id, same as the dropdown did.
- Typed text matching **nothing** existing — the suggestion list's last entry is a
  distinct "create '<text>'" option (visually distinguished, e.g. a leading `+` icon).
  Selecting it calls `ref.read(categoriesProvider.notifier).add(name: text)` (or
  `add(categoryId: selectedCategoryId, name: text)` for a subcategory), then the field
  resolves to the newly created row once it appears in `categoryTreeProvider`'s next
  emission (match by name — the DAO returns no id from `add()`, so this is how the field
  learns which row it just created; same read/write-asymmetry shape every write in this
  app already has).
- Clearing the field / leaving it blank stays legal (optional field, unchanged).

**D3 — Subcategory narrowing is picker-specific, matching each screen's existing rule —
do not unify them.** `RecordTransactionScreen`'s subcategory suggestions are narrowed to
children of the selected category (current dropdown behavior, unchanged) — selecting a
different category clears the subcategory selection, same as today. `TransactionList
Screen`'s edit sheet shows **all** subcategories regardless of category, per its own
documented rule (UC-09 D6: *"unlike the record form's narrowed pool: a stored
subcategory must stay visible even if its parent was cleared"*) — keep that flattened
list for *browsing existing* subcategories. **Creating a new subcategory still requires
a category to be selected first in both screens** (a subcategory's `categoryId` is
`NOT NULL` at the schema level) — if no category is selected, the "create new" option is
simply unavailable, not a refusal (there is nothing to refuse; the field has no parent to
create against, same as the current dropdown rendering zero items when nothing is
selected).

**D4 — Nothing about NFR-4 changes.** The field is always editable; there is no
disabled/blocked state for "no matches" — that state is exactly what triggers the
create-new affordance, not an error.

**D5 — Every new label goes through `AppLocalizations`.** A "create new" affordance
needs at least one new string (e.g. "Create "{name}"", ICU placeholder) in both
`app_en.arb`/`app_id.arb`.

## Out of scope

- Any change to `CategoryDao`, `CategoriesNotifier`, or the `Categories`/`Subcategories`
  tables.
- `CategoryManagerScreen` (the dedicated category-management screen) — unchanged, still
  the place to rename/delete.
- Save-flow UX, account-name uniqueness — next issue.

## Definition of done

Four commands green. Widget tests: typing an existing category's name and selecting it
sets the same id the dropdown would have; typing a new name and selecting "create"
writes it via `categoriesProvider` and the field ends up showing/selected on the newly
created row; `RecordTransactionScreen`'s subcategory suggestions are still narrowed by
category, `TransactionListScreen`'s are not (for browsing); the "create new" affordance
is absent when no category is selected for a subcategory field. `git diff --stat
app/drift_schemas/` empty.
