import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../accounts/accounts_table.dart';
import '../database/app_database.dart';
import 'account_dao.dart';

/// `AccountsNotifier` — the write side of UC-02 (message 2 on
/// `seq-uc02-add-account.drawio`: `addAccount(name, group, openingAmount)`).
///
/// Forwards to `AccountDao` and returns nothing to the screen — message 6 is
/// `ok`, and no new account appears as this call's return value; it would
/// arrive on the read path instead (`riverpod.md`, the read/write
/// asymmetry). This screen reads **no** drift stream, so the UC-11
/// multi-stream `Notifier` shape has nothing to bite on here
/// (`context/index/decisions.md` 2026-08-22) — a plain `Notifier<void>` over
/// the DAO is the whole write side.
///
/// Hand-written `NotifierProvider`, not `@riverpod`, for the two reasons
/// recorded at UC-13/UC-14 (`context/index/decisions.md` 2026-08-21):
/// `riverpod_generator` throws `InvalidTypeException` around drift row
/// types, and it would name the provider `accountsNotifierProvider`, not the
/// class diagram's `accountsProvider`.
class AccountsNotifier extends Notifier<void> {
  late AccountDao _dao;

  @override
  void build() {
    _dao = AccountDao(ref.watch(appDatabaseProvider));
  }

  /// Message 2. The opening amount is stored exactly as entered, signed —
  /// the app applies no group-dependent negation (`plan.md` D6, FR-4) — and
  /// is an int in minor units of `Settings.currency`, never a double.
  Future<void> addAccount({
    required String name,
    required AccountGroup group,
    required int openingAmount,
  }) async {
    await _dao.insert(
      AccountsCompanion.insert(
        name: name,
        group: group,
        openingAmount: openingAmount,
      ),
    );
  }

  /// Message 9 on `seq-uc03-adjust-account.drawio`: `adjustAccount(accountId,
  /// targetAmount)`.
  ///
  /// Forwards to [AccountDao.insertAdjustment] and returns nothing to the
  /// screen — message 13 is `ok`; the corrected balance arrives on the read
  /// path once `accountBalancesProvider` re-emits (`riverpod.md`, the
  /// read/write asymmetry; UC-03 plan D5). No arithmetic happens here — the
  /// DAO derives the diff itself (D3).
  Future<void> adjustAccount({
    required int accountId,
    required int targetAmount,
  }) async {
    await _dao.insertAdjustment(
      accountId: accountId,
      targetAmount: targetAmount,
    );
  }

  /// Message 3 on `seq-uc10-debt-progress.drawio`: `markSettled(accountId)`.
  ///
  /// Forwards to [AccountDao.setSettled] and returns nothing meaningful to
  /// the screen — the tick arrives on the read path as
  /// [debtProgressProvider] re-emitting with `settled: true` (message 7,
  /// `riverpod.md`, the read/write asymmetry). No arithmetic check, no
  /// refusal path — NFR-4 makes settling the owner's call at any moment.
  Future<void> markSettled({required int accountId}) async {
    await _dao.setSettled(accountId);
  }

  /// Message 9 on `seq-uc02b-edit-account.drawio`: `editAccount(accountId,
  /// name, group)`.
  ///
  /// Forwards to [AccountDao.update] and returns nothing to the screen —
  /// message 13 is `ok`; the renamed/regrouped account arrives on the read
  /// path once `accountBalancesProvider` re-emits (`riverpod.md`, the
  /// read/write asymmetry). `opening_amount` is never a parameter here
  /// (UC02B plan D3) — that stays UC-03's `adjustAccount`.
  Future<void> editAccount({
    required int accountId,
    required String name,
    required AccountGroup group,
  }) async {
    await _dao.update(accountId: accountId, name: name, group: group);
  }

  /// Message 14 on `seq-uc02b-edit-account.drawio`: `deleteAccount(accountId)`.
  ///
  /// Forwards to [AccountDao.delete] — a soft delete (UC02B plan D2) — and
  /// returns nothing to the screen; the read path re-emits once the account
  /// stops appearing in `accountBalancesProvider`/`financialPositionProvider`
  /// (`riverpod.md`, the read/write asymmetry). Always proceeds — no
  /// confirmation, no guard (NFR-4, the diagram draws none).
  Future<void> deleteAccount({required int accountId}) async {
    await _dao.delete(accountId: accountId);
  }
}

final accountsProvider = NotifierProvider<AccountsNotifier, void>(
  AccountsNotifier.new,
);

/// UC-01's four figures (FR-1), messages 2–7 on
/// `seq-uc01-balance-sheet.drawio`: wraps exactly one drift stream —
/// `AccountDao.watchPosition()`'s — and nothing else.
///
/// Hand-written single-stream `StreamProvider.autoDispose`, not `@riverpod`:
/// `riverpod_generator` throws `InvalidTypeException` on any provider typed
/// over a drift row class, and codegen would rename this away from the
/// class diagram's spelling (`riverpod.md`, verified UC-13/UC-14). Not a
/// combining notifier either — the UC-11 ruling (`context/index/decisions.md`
/// 2026-08-22) bans multi-stream merging shapes; this is the single-stream
/// shape that closes cleanly.
final financialPositionProvider = StreamProvider.autoDispose<FinancialPosition>(
  (ref) {
    final database = ref.watch(appDatabaseProvider);
    return AccountDao(database).watchPosition();
  },
);

/// Per-account current amounts (FR-2), messages 8–13 on
/// `seq-uc01-balance-sheet.drawio`: wraps exactly one drift stream —
/// `AccountDao.watchBalances()`'s — same shape and reasoning as
/// [financialPositionProvider] (D8).
final accountBalancesProvider =
    StreamProvider.autoDispose<List<AccountBalance>>((ref) {
      final database = ref.watch(appDatabaseProvider);
      return AccountDao(database).watchBalances();
    });

/// UC-10's two figures for one debt (FR-11), messages 2 and 7 on
/// `seq-uc10-debt-progress.drawio`: wraps exactly one drift stream —
/// `AccountDao.watchDebtProgress(accountId)`'s — and nothing else. Family-
/// keyed by the account id being viewed, as `class-accounts.drawio` labels
/// it (*StreamProvider.family · UC-10*); the family parameter is the same
/// id `markSettled(accountId)` / `setSettled(accountId)` take.
///
/// Hand-written single-stream `StreamProvider.autoDispose.family`, not
/// `@riverpod`, for the two recorded reasons (`riverpod.md`, verified
/// UC-13/UC-14): the generator throws `InvalidTypeException` on any provider
/// typed over a drift row class — [DebtProgress]'s fields are plain `int`s,
/// but codegen would also rename this away from the diagram's spelling — and
/// the UC-11 ruling bans multi-stream merging shapes, which does not bite:
/// this is one drift stream wrapped once.
final debtProgressProvider = StreamProvider.autoDispose
    .family<DebtProgress, int>((ref, accountId) {
      final database = ref.watch(appDatabaseProvider);
      return AccountDao(database).watchDebtProgress(accountId);
    });

/// Home's balance-trend chart (FEAT07 D3): wraps exactly one drift stream —
/// `AccountDao.watchBalanceTrend()`'s — same shape and reasoning as
/// [financialPositionProvider].
final balanceTrendProvider =
    StreamProvider.autoDispose<List<BalanceTrendPoint>>((ref) {
      final database = ref.watch(appDatabaseProvider);
      return AccountDao(database).watchBalanceTrend();
    });

/// Home's income-vs-expense chart (FEAT07 D4): wraps exactly one drift
/// stream — `AccountDao.watchIncomeExpense()`'s — same shape and reasoning
/// as [financialPositionProvider].
final incomeExpenseProvider = StreamProvider.autoDispose<IncomeExpenseSummary>((
  ref,
) {
  final database = ref.watch(appDatabaseProvider);
  return AccountDao(database).watchIncomeExpense();
});

/// Home's spending-by-category chart (FEAT07 D5): wraps exactly one drift
/// stream — `AccountDao.watchCategorySpending()`'s — same shape and
/// reasoning as [financialPositionProvider].
final categorySpendingProvider =
    StreamProvider.autoDispose<List<CategorySpending>>((ref) {
      final database = ref.watch(appDatabaseProvider);
      return AccountDao(database).watchCategorySpending();
    });
