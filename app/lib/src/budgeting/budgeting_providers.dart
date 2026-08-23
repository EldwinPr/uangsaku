import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'budget_dao.dart';

/// One row of `SetBudgetScreen`'s view — a budget group with the amount it
/// should show and, when one already exists, the current month's period id
/// (D4). A record, not a class: no query-result class for UC-11 is on
/// `class-budgeting.drawio` (`BudgetConsumption` is annotated UC-12 only),
/// and the outranking rule (`coding-conventions/README.md`) is that code may
/// not invent a class the diagrams don't have.
///
/// - [amount] is the current month's amount if a row exists for it;
///   otherwise the previous month's amount as FR-15's pre-fill; otherwise
///   `null` (blank).
/// - [periodId] is set only when a **current**-month row exists — it is
///   what `BudgetNotifier.delete()` needs, and its absence is why the
///   screen renders no delete control for a group with nothing to delete.
typedef BudgetRow = ({int groupId, String name, int? amount, int? periodId});

/// `BudgetNotifier` — the screen's single source for both reading and
/// writing (D3): `class-budgeting.drawio` gives Budgeting exactly one
/// provider (`budgetConsumptionProvider` is UC-12 only), unlike
/// `categoryTreeProvider`/`categoriesProvider`'s split in
/// `class-transactions.drawio`.
///
/// State is the current month's view **derived from a live drift query**,
/// not a cached copy — produced by combining `BudgetDao.watchGroups()` with
/// `BudgetDao.watchPeriods()` for this month and last (D3), so a write here
/// simply lets drift re-emit and the screen rebuild. No write method returns
/// anything the screen renders (`riverpod.md`).
///
/// **A plain `Notifier<AsyncValue<...>>`, not a `StreamNotifier`, with the
/// three subscriptions opened by hand in `build()` and cancelled by
/// `ref.onDispose`.** D3's own contingency for this: `StreamNotifier` was
/// tried first, combining the three drift streams behind a hand-rolled
/// `combineLatest3` (`dart:async` only, no new package) returned from
/// `build()`. Verified against the real toolchain while building this
/// issue — the combined stream's own subscriptions were never cancelled
/// when the provider's own auto-dispose fired: `AppDatabase.close()` hung
/// indefinitely in a widget test after unmounting `SetBudgetScreen` and
/// flushing the drift-cancellation timer the usual way (`testing.md`), and
/// an isolated `ProviderContainer` reproduction showed the same live
/// subscriptions still present as a "Timer is still pending" failure rather
/// than a clean close. A minimal `StreamNotifierProvider` wrapping a single
/// drift stream directly (no combining layer) closed cleanly, isolating the
/// cause to `StreamController`-wrapped-`Stream` cancellation under
/// `flutter_riverpod: ^3.4.2`'s `StreamNotifier`, not to `Notifier` itself,
/// not to auto-dispose in general (`categoryTreeProvider`, also
/// `autoDispose`, closes cleanly), and not to the combining logic's
/// correctness (the same three-stream merge, watched through a
/// `ProviderContainer` with no widget involved, emitted the right value
/// immediately every time). `ref.onDispose` ties cancellation directly to
/// the provider element's own disposal instead, with no controller layer
/// in between, and that closes cleanly. Recorded in `riverpod.md` per D3's
/// own instruction: *"anything that fights the real toolchain loses."*
///
/// Hand-written either way, not `@riverpod`: `riverpod_generator` throws
/// `InvalidTypeException` on any provider whose signature mentions a
/// drift-generated row class, and would also name the provider
/// `budgetNotifierProvider` rather than the class diagram's `budgetProvider`
/// (verified `UC13`, the identical `categoriesProvider` precedent).
class BudgetNotifier extends Notifier<AsyncValue<List<BudgetRow>>> {
  late BudgetDao _dao;

  @override
  AsyncValue<List<BudgetRow>> build() {
    _dao = BudgetDao(ref.watch(appDatabaseProvider));

    List<BudgetGroup>? groups;
    List<BudgetPeriod>? currentPeriods;
    List<BudgetPeriod>? previousPeriods;

    void emit() {
      if (groups != null && currentPeriods != null && previousPeriods != null) {
        state = AsyncData(_toRows(groups!, currentPeriods!, previousPeriods!));
      }
    }

    final groupsSubscription = _dao.watchGroups().listen((value) {
      groups = value;
      emit();
    });
    final currentPeriodsSubscription = _dao.watchPeriods().listen((value) {
      currentPeriods = value;
      emit();
    });
    final previousPeriodsSubscription = _dao.watchPeriods(monthsAgo: 1).listen((
      value,
    ) {
      previousPeriods = value;
      emit();
    });

    ref.onDispose(() {
      groupsSubscription.cancel();
      currentPeriodsSubscription.cancel();
      previousPeriodsSubscription.cancel();
    });

    return const AsyncValue.loading();
  }

  /// Message 10: sets this month's amount for [groupId] (FR-12, FR-16 — no
  /// lock, proceeds at any point in the month).
  Future<void> setAmount({required int groupId, required int amount}) {
    return _dao.upsert(groupId: groupId, amount: amount);
  }

  /// Message 15: deletes the month's period for a group (FR-18, no lock).
  Future<void> delete({required int periodId}) {
    return _dao.delete(periodId: periodId);
  }

  /// Message 20: adds a budget group (moved from UC-13 step 3).
  Future<void> addGroup({required String name}) {
    return _dao.insertGroup(name: name);
  }

  /// Message 26: renames a budget group (FR-18).
  Future<void> renameGroup({required int groupId, required String newName}) {
    return _dao.updateGroup(groupId: groupId, name: newName);
  }

  /// Message 32: deletes a budget group (FR-18, D7 — zero refusals).
  Future<void> deleteGroup({required int groupId}) {
    return _dao.deleteGroup(groupId: groupId);
  }

  /// D4's merge: a current-month row wins over the previous month's
  /// pre-fill, forced by FR-16 (a saved change must be visible and
  /// re-editable).
  List<BudgetRow> _toRows(
    List<BudgetGroup> groups,
    List<BudgetPeriod> currentPeriods,
    List<BudgetPeriod> previousPeriods,
  ) {
    final currentByGroup = {
      for (final period in currentPeriods) period.budgetGroupId: period,
    };
    final previousByGroup = {
      for (final period in previousPeriods) period.budgetGroupId: period,
    };

    return [
      for (final group in groups)
        (
          groupId: group.budgetGroupId,
          name: group.name,
          amount:
              currentByGroup[group.budgetGroupId]?.amount ??
              previousByGroup[group.budgetGroupId]?.amount,
          periodId: currentByGroup[group.budgetGroupId]?.budgetPeriodId,
        ),
    ];
  }
}

final budgetProvider =
    NotifierProvider.autoDispose<BudgetNotifier, AsyncValue<List<BudgetRow>>>(
      BudgetNotifier.new,
    );

/// UC-12's per-group figures (FR-13, FR-17), messages 2–6 on
/// `seq-uc12-budget-consumption.drawio`: wraps exactly one drift stream —
/// `BudgetDao.watchConsumption()`'s — and nothing else. Screen passes no
/// argument, so it always shows the current month (`monthsAgo: 0`); no month
/// picker is drawn (plan Out of scope).
///
/// Hand-written single-stream `StreamProvider.autoDispose`, not `@riverpod`,
/// for the two recorded reasons (`riverpod.md`, verified UC-13/UC-14):
/// `riverpod_generator` throws `InvalidTypeException` on any provider typed
/// over a drift row class, and codegen would rename this away from the class
/// diagram's spelling (*StreamProvider · UC-12*). Not a combining notifier
/// either — the UC-11 ruling (`context/index/decisions.md` 2026-08-22) bans
/// multi-stream merging shapes only when a screen reads more than one
/// stream; this screen reads one, matching `financialPositionProvider` /
/// `accountBalancesProvider`'s shape.
final budgetConsumptionProvider =
    StreamProvider.autoDispose<List<BudgetConsumption>>((ref) {
      final database = ref.watch(appDatabaseProvider);
      return BudgetDao(database).watchConsumption();
    });
