# Riverpod

State management, chosen 2026-08-20 (`decisions.md`) because drift's DAOs already return
reactive streams and Riverpod's `StreamProvider` consumes a stream with no adapter layer.
Source: [riverpod.dev](https://riverpod.dev/).

## Code generation: yes, `@riverpod`

Riverpod's own documentation recommends code generation, and
[`riverpod_generator`](https://pub.dev/packages/riverpod_generator) is the current idiomatic
path: annotate a function or class with `@riverpod` and the generator emits the correctly
typed provider.

**The usual objection does not apply here.** Codegen's cost is that it drags in `build_runner`
and produces `.g.dart` files. This project pays that cost already — `drift_dev` is a builder,
so `build_runner` is non-negotiable from the first commit. Adding Riverpod's generator to a
build that must run anyway is nearly free, and it removes the hand-written provider
boilerplate that would otherwise be the most-edited, least-interesting code in the repo.

```yaml
dependencies:
  flutter_riverpod: ^3.0.0
  riverpod_annotation: ^3.0.0
dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^3.0.0
```

Pin real versions when `FEAT01` runs — the numbers above are shape, not verified fact, since
no `pub get` has ever been run for this project.

`invalid_annotation_target: ignore` in `analysis_options.yaml` is required by the generator;
it is in the analyzer block for that reason and no other.

**Providers are `autoDispose` by default under code generation.** That is the right default
here — screens come and go — but it means a provider whose state must outlive its screen has
to say so explicitly (`@Riverpod(keepAlive: true)`). Expect to need that for the currency
setting and almost nothing else.

## The two shapes, and only these two

The class diagrams draw exactly two kinds of thing in the provider band, and code should not
invent a third:

- **`StreamProvider` for reads.** Wraps a drift `watch…()` query. Named for what it exposes:
  `accountBalancesProvider`, `budgetConsumptionProvider`, `transactionListProvider`.
- **`Notifier` for writes.** One per module, exposing the verbs: `AccountsNotifier` with
  `addAccount` / `adjustAccount` / `markSettled`. Exposed as `accountsProvider`.

Use `.family` when a read is keyed — `debtProgressProvider` is a
`StreamProvider.family` keyed by account, as `class-accounts.drawio` shows.

## The rule that is easiest to get wrong

**A write does not return the result to the screen.** This is the same asymmetry
`sequence-conventions.md` makes a drawing rule, and it exists in code first:

```dart
// Right: the screen fires a write and forgets it. The list it is watching updates
// because drift pushes the changed row into the stream.
await ref.read(accountsProvider.notifier).addAccount(name: name, group: group);

// Wrong: treating the write as a request/response and rendering what it returns.
final account = await ref.read(accountsProvider.notifier).addAccount(...);
setState(() => _accounts.add(account));   // now there are two sources for one number
```

The second form is wrong for a reason bigger than style: it creates a second source of truth
for something NFR-2 says must have exactly one. The screen's list and the database would then
be two things that can disagree.

A notifier method may still return something the *caller* needs and the UI does not render —
a new row's id to navigate to, for instance. Returning a value is not banned; rendering the
returned value instead of the watched stream is.

## What may hold state

Almost nothing. Balances, totals, budget consumption and debt progress are all **derived by
query** (NFR-2, ERD D7 — no stored balance anywhere). A notifier holds what is genuinely
transient: form input in progress, a selected filter, a loading flag.

If you find yourself caching a computed total in a provider so a screen renders faster, stop:
that is a stored balance with extra steps, and the ERD deliberately has no column for it.
Fix the query.

## No refusals

NFR-4's fit criterion is **zero refused user actions**. In this layer that means a notifier
method does not have an early return that silently declines to do the thing, and a screen does
not disable a control to prevent an action. Where the owner is about to do something with a
consequence — changing the currency, deleting an account with transactions against it — the
app **warns and proceeds**. The warning is a dialog that continues, never a block.

This is the requirement most likely to be violated by accident, because disabling a button
feels like good UI. `testing.md` carries the check for it.
