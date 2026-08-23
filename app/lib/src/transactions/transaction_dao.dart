import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'transactions_table.dart';

/// `TransactionDao` — one write path for every kind plus this module's two
/// picker reads (UC-04..UC-08).
///
/// Writes: [insert] — all six writable kinds land through this one method;
/// they differ in which sides they set, not in which method they call
/// (ISSUE-001 D1, `drift.md` §The ledger shape). Reads: [watchAccounts] and
/// [watchBudgetGroups], written as this module's own watched selects over
/// the `Accounts` and `BudgetGroups` tables — ISSUE-005 D1
/// (`context/index/decisions.md` 2026-08-20): modules reach each other's
/// data by SQL join on the shared database, never by calling another
/// module's DAO. `AccountDao` and `BudgetDao` are not imported and no
/// Dart-side stitching happens. The accepted cost of that ruling: table
/// ownership is enforced by nothing, so a schema change to either table
/// means checking all four modules.
///
/// **Not a `@DriftAccessor`/`DatabaseAccessor` subtype** — a plain
/// composition over `AppDatabase`, the shape every DAO in this project uses
/// (`context/index/decisions.md` 2026-08-21, UC-13 ruling 1; see
/// `category_dao.dart`'s doc comment for the `invalid_override` failure
/// behind it). No `daos: […]` entry on `@DriftDatabase`.
class TransactionDao {
  TransactionDao(this._db);

  final AppDatabase _db;

  /// Messages 4–6 on all five recording diagrams: write one `Transactions`
  /// row of any kind.
  ///
  /// One method, not six (plan D5): the caller supplies the kind and the
  /// sides its kind requires per `docs/enums.md`'s kind table; this method
  /// validates nothing and refuses nothing (plan D9, NFR-4). The amount is
  /// stored exactly as handed over — `int` minor units of
  /// `Settings.currency`, never a double, converted nowhere (FR-19, NFR-2)
  /// — and direction lives entirely in which side each account occupies,
  /// never in the sign. The kind is bound with `.textEnum` storage by the
  /// generated companion, so the enum's meaning never depends on
  /// declaration order.
  ///
  /// Returns `Future<void>`; no result reaches any screen — what the owner
  /// sees afterwards arrives as stream re-emissions on the read path
  /// (`riverpod.md`, the read/write asymmetry).
  Future<void> insert({
    required TransactionKind kind,
    required int amount,
    required DateTime occurredOn,
    int? fromAccountId,
    int? toAccountId,
    int? categoryId,
    int? subcategoryId,
    int? budgetGroupId,
    String? note,
  }) {
    return _db
        .into(_db.transactions)
        .insert(
          TransactionsCompanion.insert(
            kind: kind,
            amount: amount,
            occurredOn: occurredOn,
            fromAccountId: Value(fromAccountId),
            toAccountId: Value(toAccountId),
            categoryId: Value(categoryId),
            subcategoryId: Value(subcategoryId),
            budgetGroupId: Value(budgetGroupId),
            note: Value(note),
          ),
        );
  }

  /// The account picker (message 1 on `seq-uc06-move-money.drawio` et al.):
  /// every account with its group, watched. Ordered by insertion id so
  /// emissions are deterministic — the neutral ordering `watchBalances()`
  /// already ships.
  ///
  /// A person or a debt is an ordinary row here (`docs/enums.md`: *"the
  /// owner re-confirmed that a debt is an account"*); the person/debt
  /// picker narrows these rows to their `RECEIVABLE`/`PAYABLE` groups at
  /// the form, nothing more — this method filters nothing and hides
  /// nothing.
  Stream<List<Account>> watchAccounts() {
    final query = _db.select(_db.accounts)
      ..orderBy([(row) => OrderingTerm.asc(row.accountId)]);
    return query.watch();
  }

  /// The budget-group picker (the optional tag on UC-04/UC-05), watched.
  /// Ordered by id, same reason as [watchAccounts].
  ///
  /// "Others" is the blank choice, not a row — `budget_group_id IS NULL`
  /// (FR-17, ISSUE-001 D5) — so the form renders it as the empty selection
  /// and this query returns exactly the user-created groups.
  Stream<List<BudgetGroup>> watchBudgetGroups() {
    final query = _db.select(_db.budgetGroups)
      ..orderBy([(row) => OrderingTerm.asc(row.budgetGroupId)]);
    return query.watch();
  }

  /// Message 2 and 12 on `seq-uc09-review-and-correct.drawio`:
  /// `transactions[]` — every recorded transaction, watched, each row
  /// carrying its two account-side **names** resolved here by joining
  /// `Accounts` twice (UC-09 D3).
  ///
  /// The join lives in this module, against the `Accounts` table — ISSUE-005
  /// D1 (`context/index/decisions.md` 2026-08-20), the same shape
  /// `AccountDao.watchBalances()` ships mirrored: SQL join inside the owning
  /// module, never a call into `AccountDao`, no Dart-side stitching. Accepted
  /// cost: table ownership is enforced by nothing, so a schema change to
  /// `Accounts` means checking all four modules.
  ///
  /// Ordered `(occurredOn, transactionId)` ascending — no artifact fixes a
  /// display order and `pm/questions.md` excludes presentation preferences
  /// with no downstream consequence, so the deterministic order-for-
  /// determinism convention every other watched select here ships applies.
  ///
  /// Each element is a **record**, not a new class: UC-09's plan invents no
  /// class ("every box above is already on the class diagram") and
  /// `class-transactions.drawio` deliberately draws no query-result box for
  /// the list, unlike `class-accounts.drawio`'s `FinancialPosition`/
  /// `AccountBalance`. A record is structural, so nothing enters any
  /// diagram's namespace. [fromName] / [toName] are null exactly when the
  /// row's corresponding side column is null — the list reads columns, it
  /// does not interpret kinds (UC-09 D3/D6).
  Stream<List<({Transaction transaction, String? fromName, String? toName})>>
  watchAll() {
    final transactions = _db.transactions;
    final fromAccounts = _db.alias(_db.accounts, 'from_accounts');
    final toAccounts = _db.alias(_db.accounts, 'to_accounts');

    final query =
        _db.select(transactions).join([
          leftOuterJoin(
            fromAccounts,
            fromAccounts.accountId.equalsExp(transactions.fromAccountId),
          ),
          leftOuterJoin(
            toAccounts,
            toAccounts.accountId.equalsExp(transactions.toAccountId),
          ),
        ])..orderBy([
          OrderingTerm.asc(transactions.occurredOn),
          OrderingTerm.asc(transactions.transactionId),
        ]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          (
            transaction: row.readTable(transactions),
            fromName: row.readTableOrNull(fromAccounts)?.name,
            toName: row.readTableOrNull(toAccounts)?.name,
          ),
      ],
    );
  }

  /// Messages 5–6 on `seq-uc09-review-and-correct.drawio`:
  /// `update(id, fields)` — UC-09's amend arm (FR-18). A companion write of
  /// exactly the fields message 4 carries: amount, the account side(s) the
  /// row's kind occupies per `docs/enums.md`'s table, date, the three
  /// optional tags and the note. **`kind` is deliberately not a parameter**
  /// (UC-09 D4): retagging a row across kinds is drawn nowhere.
  ///
  /// Blanks become nulls (`Value(null)` writes the column null), keeping
  /// "cleared" and "was never set" one fact — the convention UC04 shipped on
  /// the record form. Nothing validates and nothing refuses (NFR-4); a
  /// caller may legally leave a two-sided kind with a null side, because the
  /// write is exactly what was handed over (UC-09 D6).
  ///
  /// Returns `Future<void>`; the amended list reaches the screen as stream
  /// re-emissions of [watchAll], never as this method's result.
  Future<void> update({
    required int id,
    required int amount,
    required DateTime occurredOn,
    int? fromAccountId,
    int? toAccountId,
    int? categoryId,
    int? subcategoryId,
    int? budgetGroupId,
    String? note,
  }) async {
    await (_db.update(
      _db.transactions,
    )..where((row) => row.transactionId.equals(id))).write(
      TransactionsCompanion(
        amount: Value(amount),
        occurredOn: Value(occurredOn),
        fromAccountId: Value(fromAccountId),
        toAccountId: Value(toAccountId),
        categoryId: Value(categoryId),
        subcategoryId: Value(subcategoryId),
        budgetGroupId: Value(budgetGroupId),
        note: Value(note),
      ),
    );
  }

  /// Messages 10–11 on `seq-uc09-review-and-correct.drawio`:
  /// `delete(id)` — UC-09's delete arm (FR-18), **immediate and
  /// unconditional** (UC-09 D5): no guard, no confirmation whose "no" could
  /// quietly become a refusal — NFR-4's fit criterion is zero refusals.
  ///
  /// It can never fail on a foreign key: `Transactions` references
  /// `Accounts`, `Categories`, `Subcategories` and `BudgetGroups`, and **no
  /// table references `Transactions`**, so deleting a ledger row breaks
  /// nothing (UC-09 D5) — hence no migration and `schemaVersion` stays 1.
  ///
  /// Deleting a nonexistent id completes harmlessly; there is no error to
  /// surface and nothing to refuse.
  ///
  /// Returns `Future<void>`; the shortened list arrives as stream
  /// re-emissions of [watchAll] (message 12).
  Future<void> delete({required int id}) async {
    await (_db.delete(
      _db.transactions,
    )..where((row) => row.transactionId.equals(id))).go();
  }
}
