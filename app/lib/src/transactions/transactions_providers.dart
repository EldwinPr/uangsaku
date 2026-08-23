import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'category_dao.dart';
import 'transaction_dao.dart';
import 'transactions_table.dart';

/// The category + subcategory tree, watched by `CategoryManagerScreen`
/// (messages 2, 8, 14, 23 on `seq-uc13-categories.drawio`).
///
/// The diagram never draws `categoryTreeProvider → CategoryDao.watchTree()`
/// itself, but `class-transactions.drawio` does, and a provider that emits
/// four times has to be watching something — built per that edge (plan,
/// "The read path the diagram elides").
///
/// Hand-written `StreamProvider`, not `@riverpod`: verified against the real
/// toolchain while building this issue — `riverpod_generator` throws
/// `InvalidTypeException: The type is invalid and cannot be converted to
/// code` on any provider whose signature mentions `Category` or
/// `Subcategory` (drift's generated row classes, declared in
/// `app_database.g.dart`, a `part of 'app_database.dart'`). A `Stream<int>`
/// return type builds; swapping only the type to `Stream<Category>`
/// reproduces the failure, isolating the generated part-file class as the
/// cause, not this provider's shape. `riverpod.md` recommends codegen by
/// default; this is the exception, alongside `appDatabaseProvider`'s.
final categoryTreeProvider =
    StreamProvider.autoDispose<Map<Category, List<Subcategory>>>((ref) {
      final database = ref.watch(appDatabaseProvider);
      return CategoryDao(database).watchTree();
    });

/// Writes for both `Category` and `Subcategory` (UC-13). `add()` / `rename()`
/// / `remove()` forward to `CategoryDao` and return nothing to the screen —
/// the changed tree arrives on `categoryTreeProvider`'s next emission, never
/// as this notifier's return value (`riverpod.md`, the read/write asymmetry).
///
/// Hand-written `NotifierProvider`, not `@riverpod`, for a second reason on
/// top of the one above: `riverpod_generator` would name the generated
/// provider `categoriesNotifierProvider`, not the `categoriesProvider` the
/// class diagram names. Per D2's contingency, the class diagram wins — same
/// precedent `appDatabaseProvider` set in `app_database.dart` (FEAT01 ruling
/// 3).
class CategoriesNotifier extends Notifier<void> {
  late CategoryDao _dao;

  @override
  void build() {
    _dao = CategoryDao(ref.watch(appDatabaseProvider));
  }

  /// Adds a category when [categoryId] is null, otherwise a subcategory
  /// under it (D5).
  Future<void> add({int? categoryId, required String name}) {
    return _dao.insert(categoryId: categoryId, name: name);
  }

  /// Renames a category or a subcategory (FR-18).
  Future<void> rename({
    required int id,
    required bool isSubcategory,
    required String name,
  }) {
    return _dao.update(id: id, isSubcategory: isSubcategory, name: name);
  }

  /// Deletes a category or a subcategory (FR-18, D6).
  Future<void> remove({required int id, required bool isSubcategory}) {
    return _dao.delete(id: id, isSubcategory: isSubcategory);
  }
}

final categoriesProvider =
    NotifierProvider.autoDispose<CategoriesNotifier, void>(
      CategoriesNotifier.new,
    );

/// The account picker for `RecordTransactionScreen` (UC-04..UC-08):
/// component-overview.drawio assigns Transactions the read *"Accounts —
/// account picker (UC-04..UC-08)"*, served by `TransactionDao.watchAccounts()`
/// — this module's own watched select over the `Accounts` table, never
/// another module's DAO or provider (ISSUE-005 D1; plan D7 explicitly rules
/// out watching `accountBalancesProvider`, which would couple the form to
/// balance derivation it does not need).
///
/// Hand-written single-stream `StreamProvider.autoDispose`, not `@riverpod`,
/// for the two recorded reasons (`riverpod.md`, verified UC-13/UC-14): the
/// generator throws `InvalidTypeException` on any provider typed over a
/// drift row class (`Account` lives in `app_database.g.dart`, a part file),
/// and the name is not codegen's to choose. Not a combining notifier either
/// — the UC-11 ruling (`context/index/decisions.md` 2026-08-22) bans
/// multi-stream merging shapes; this wraps exactly one drift stream.
final accountPickerProvider = StreamProvider.autoDispose<List<Account>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return TransactionDao(database).watchAccounts();
});

/// The budget-group picker for the optional tag on UC-04/UC-05:
/// component-overview.drawio assigns Transactions the read *"BudgetGroups —
/// budget picker (UC-04..UC-08)"*, same mechanism and same hand-written
/// shape as [accountPickerProvider]. "Others" is the blank selection, never
/// a row in what this emits (FR-17).
final budgetGroupPickerProvider = StreamProvider.autoDispose<List<BudgetGroup>>(
  (ref) {
    final database = ref.watch(appDatabaseProvider);
    return TransactionDao(database).watchBudgetGroups();
  },
);

/// Writes for all six recording kinds (UC-04..UC-08), messages 3 on the five
/// diagrams: `recordExpense` / `recordIncome` / `transfer` / `lend` /
/// `borrow` / `repay`. Each forwards to `TransactionDao.insert()` with the
/// sides its kind requires per `docs/enums.md`'s kind table and returns
/// nothing to the screen — the row arrives on the read path as stream
/// re-emissions (`riverpod.md`, the read/write asymmetry; plan D9).
///
/// **Direction lives entirely in the sides** (plan D5): amounts are stored
/// non-negative-magnitude-or-as-entered — a negative amount is recorded as
/// entered, never negated (NFR-4, plan D9) — and which account occupies
/// `from_account_id` versus `to_account_id` is fixed per kind by
/// `docs/enums.md`'s table. **No spending predicate appears anywhere in
/// here**: "is this spending?" is `to_account_id IS NULL`, a property of the
/// rows once written (seq-uc06's note verbatim), and nothing in this module
/// reads spending back.
///
/// Hand-written `NotifierProvider.autoDispose`, not `@riverpod`, for the two
/// recorded reasons (same as [CategoriesNotifier] above): the generator
/// cannot type providers over drift row classes, and it would name this
/// `transactionsNotifierProvider`, not the class diagram's
/// `transactionsProvider`.
///
/// The side parameters are nullable (`int?`) on purpose: with an empty
/// database a fresh install has no account to preselect, and refusing the
/// save would break NFR-4's zero-refusals fit criterion — the handling the
/// plan flags as its suggested one in "Open questions" (let the save proceed
/// and leave the sides null). With any account present the form always
/// supplies a side.
class TransactionsNotifier extends Notifier<void> {
  late TransactionDao _dao;

  @override
  void build() {
    _dao = TransactionDao(ref.watch(appDatabaseProvider));
  }

  /// Message 3 on `seq-uc04-record-expense.drawio`:
  /// `recordExpense(amount, fromAccountId, categoryId, subcategoryId,
  /// budgetGroupId, note, date)`. From-side only — the row's
  /// `to_account_id` stays null, which is exactly what makes the row count
  /// as spending at read time (`docs/enums.md`'s kind table).
  Future<void> recordExpense({
    required int amount,
    int? fromAccountId,
    int? categoryId,
    int? subcategoryId,
    int? budgetGroupId,
    String? note,
    DateTime? date,
  }) {
    return _dao.insert(
      kind: TransactionKind.expense,
      amount: amount,
      occurredOn: date ?? DateTime.now(),
      fromAccountId: fromAccountId,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      budgetGroupId: budgetGroupId,
      note: note,
    );
  }

  /// Message 3 on `seq-uc05-record-income.drawio`: `recordIncome(amount,
  /// toAccountId, …)`. To-side only — `from_account_id` stays null.
  Future<void> recordIncome({
    required int amount,
    int? toAccountId,
    int? categoryId,
    int? subcategoryId,
    int? budgetGroupId,
    String? note,
    DateTime? date,
  }) {
    return _dao.insert(
      kind: TransactionKind.income,
      amount: amount,
      occurredOn: date ?? DateTime.now(),
      toAccountId: toAccountId,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      budgetGroupId: budgetGroupId,
      note: note,
    );
  }

  /// Message 3 on `seq-uc06-move-money.drawio`: `transfer(fromAccountId,
  /// toAccountId, amount, note, date)`. No tag parameters — the diagram
  /// draws none and the workbook's UC-06 Input promises none (plan D8); the
  /// tag columns stay null on transfer rows.
  ///
  /// A same-account transfer proceeds unrefused (NFR-4): both balances move
  /// by the same amount in opposite directions, netting zero — harmless, and
  /// the owner's call.
  Future<void> transfer({
    required int amount,
    int? fromAccountId,
    int? toAccountId,
    String? note,
    DateTime? date,
  }) {
    return _dao.insert(
      kind: TransactionKind.transfer,
      amount: amount,
      occurredOn: date ?? DateTime.now(),
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      note: note,
    );
  }

  /// Message 3 on `seq-uc07-lend-borrow.drawio`, `[direction = I lent]` arm:
  /// `lend(personAccountId, fromAccountId, amount, note, date)` — from the
  /// own wallet ([fromAccountId]) into the person's RECEIVABLE account
  /// ([personAccountId]). Lending the same person again adds to the single
  /// RECEIVABLE account already held against them (FR-5); no account is
  /// created here.
  Future<void> lend({
    required int amount,
    int? personAccountId,
    int? fromAccountId,
    String? note,
    DateTime? date,
  }) {
    return _dao.insert(
      kind: TransactionKind.lend,
      amount: amount,
      occurredOn: date ?? DateTime.now(),
      fromAccountId: fromAccountId,
      toAccountId: personAccountId,
      note: note,
    );
  }

  /// Message 3 on `seq-uc07-lend-borrow.drawio`, `[direction = I borrowed]`
  /// arm: `borrow(debtAccountId, toAccountId, amount, note, date)` — from
  /// the PAYABLE account ([debtAccountId]) into the own wallet
  /// ([toAccountId]).
  Future<void> borrow({
    required int amount,
    int? debtAccountId,
    int? toAccountId,
    String? note,
    DateTime? date,
  }) {
    return _dao.insert(
      kind: TransactionKind.borrow,
      amount: amount,
      occurredOn: date ?? DateTime.now(),
      fromAccountId: debtAccountId,
      toAccountId: toAccountId,
      note: note,
    );
  }

  /// Messages 3–4 on `seq-uc08-repayment.drawio`, one method carrying both
  /// `alt` arms. The arms draw the same call with the roles swapped by
  /// direction:
  ///
  /// - `[direction = they repaid]` — `repay(personAccountId, toAccountId,
  ///   …)` writes `insert(kind: repayment, fromAccountId: person's
  ///   RECEIVABLE account, toAccountId: own wallet)`; the caller maps that
  ///   arm onto `fromAccountId = personAccountId`, `toAccountId = wallet`.
  /// - `[direction = owner repaid]` — `repay(fromAccountId, debtAccountId,
  ///   …)` writes `insert(kind: repayment, fromAccountId: own wallet,
  ///   toAccountId: PAYABLE account)`; mapped onto these same two named
  ///   parameters with the wallet as source.
  ///
  /// Every parameter name below appears verbatim across the five diagrams'
  /// signatures; the direction resolution itself belongs to the screen,
  /// which holds the picked account and its group (the repayment form's
  /// group-dependent mapping, noted in `pm/active.json`). Both directions
  /// land here so the class diagram keeps its six methods, not seven.
  Future<void> repay({
    required int amount,
    int? fromAccountId,
    int? toAccountId,
    String? note,
    DateTime? date,
  }) {
    return _dao.insert(
      kind: TransactionKind.repayment,
      amount: amount,
      occurredOn: date ?? DateTime.now(),
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      note: note,
    );
  }
}

final transactionsProvider =
    NotifierProvider.autoDispose<TransactionsNotifier, void>(
      TransactionsNotifier.new,
    );
