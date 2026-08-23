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
}
