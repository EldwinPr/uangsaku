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
  flutter_riverpod: ^3.4.2
  riverpod_annotation: ^4.0.6
dev_dependencies:
  build_runner: ^2.16.0
  riverpod_generator: ^4.0.8
```

**Verified 2026-08-21, `FEAT01-foundation`** — resolved with `dart pub add` against the real
pub.dev index, alongside `drift: ^2.34.3`, `drift_flutter: ^0.3.1`, `drift_dev: ^2.34.5`. Note
`riverpod_annotation` and `riverpod_generator` are already at major version 4, not 3 as this
file previously guessed.

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

**One more exception, verified `FEAT01`:** `appDatabaseProvider` is neither shape — it is
plumbing (ISSUE-001 D5), a plain hand-written `Provider<AppDatabase>`, not `@riverpod`. A
manual `Provider` is inherently kept alive (only `.autoDispose` variants dispose), which is
exactly what "outlives every screen" needs, and it sidesteps a real generator conflict:
`riverpod_generator` and `drift_dev` both target `part '<file>.g.dart'`, and `AppDatabase`
already owns that part via `@DriftDatabase`. Putting `@riverpod` on a function in the same
file did not error in testing — `source_gen`'s combining builder merges both generators'
output into one `.g.dart` — but the plain `Provider` is simpler and was the actual choice
made in `app_database.dart`.

**A second, broader exception, verified `UC13`, 2026-08-21:** `riverpod_generator` cannot
build a provider whose signature (parameter *or* return type) mentions a drift-generated row
class — `Category`, `Subcategory`, or any other class declared in `app_database.g.dart` (a
`part of 'app_database.dart'`). It fails with `InvalidTypeException: The type is invalid and
cannot be converted to code`, isolated by swapping only the type: a `Stream<int>` provider
builds, the identical provider retyped `Stream<Category>` fails. This is not the
`categoriesProvider`-naming contingency below — it applies even to a bare top-level
`@riverpod` **function**, and it means `categoryTreeProvider` (`StreamProvider<Map<Category,
List<Subcategory>>>`) has to be hand-written too, not only `CategoriesNotifier`. Hand-write
any provider whose type touches a drift-generated row class; codegen remains the default for
everything else.

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

## Combining more than one stream: `Notifier` with hand-opened subscriptions, not `StreamNotifier`

**Corrected `UC11`, 2026-08-22.** `BudgetNotifier`'s state is one query derived from three
drift streams (`BudgetDao.watchGroups()` plus `watchPeriods()` for this month and last —
`class-budgeting.drawio`'s D3). The first attempt built it as a `StreamNotifier`, with
`build()` returning a hand-rolled `combineLatest3` (a `StreamController` fed by three
`.listen()` calls, cancelled from the controller's `onCancel`) — the shape this file
previously recommended as the fallback's alternative.

**Verified against the real toolchain: that shape's cancellation does not run.** A widget
test that mounted `SetBudgetScreen`, unmounted it, and flushed the usual drift-cancellation
timer (`testing.md`) then hung indefinitely on `AppDatabase.close()` — the three drift
`.listen()` subscriptions inside the combining `StreamController` were still open, because
nothing ever called the controller's `onCancel`. An isolated `ProviderContainer`
reproduction (no widget involved) confirmed the same live subscriptions as a *"Timer is
still pending"* failure rather than a clean close. Isolating the cause required checking
each layer separately:

- A **minimal** `StreamNotifierProvider.autoDispose` wrapping one drift stream directly
  (no combining layer) closed cleanly — so the fault is not `StreamNotifier` itself, and
  not `autoDispose` in general (`categoryTreeProvider` is also `autoDispose` and closes
  cleanly).
- The same three-stream merge, watched through a bare `ProviderContainer` with
  `container.listen()` and no widget, **emitted the correct combined value immediately and
  every time** — so the combining logic itself is correct.
- Only the combination of *both* — a `StreamController`-wrapped `Stream` returned from a
  `StreamNotifier.build()`, under `flutter_riverpod: ^3.4.2` — leaves the controller's
  `onCancel` uninvoked when the provider's own `autoDispose` fires.

**The fix:** a plain `Notifier<AsyncValue<T>>`, opening every subscription by hand inside
`build()` and cancelling them from `ref.onDispose` — tying cancellation directly to the
provider element's own disposal, with no `StreamController` layer in between:

```dart
class BudgetNotifier extends Notifier<AsyncValue<List<BudgetRow>>> {
  @override
  AsyncValue<List<BudgetRow>> build() {
    final dao = BudgetDao(ref.watch(appDatabaseProvider));
    // ...open one .listen() per source stream, update `state` from each...
    ref.onDispose(() {
      // ...cancel every subscription opened above...
    });
    return const AsyncValue.loading();
  }
}
```

This is the fallback this file already named before verification (*"if the real toolchain
fights that, the fallback is `Notifier` holding the same derived state with a subscription
opened in `build()`"*) — it turned out to be the only shape that actually closes, not
merely an alternative. **Any provider combining more than one stream should use this
shape from the start**, rather than trying `StreamNotifier` first.

## No refusals

NFR-4's fit criterion is **zero refused user actions**. In this layer that means a notifier
method does not have an early return that silently declines to do the thing, and a screen does
not disable a control to prevent an action. Where the owner is about to do something with a
consequence — changing the currency, deleting an account with transactions against it — the
app **warns and proceeds**. The warning is a dialog that continues, never a block.

This is the requirement most likely to be violated by accident, because disabling a button
feels like good UI. `testing.md` carries the check for it.
