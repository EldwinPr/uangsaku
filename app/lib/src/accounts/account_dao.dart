import 'package:drift/drift.dart';

import '../accounts/accounts_table.dart';
import '../budgeting/clock.dart';
import '../database/app_database.dart';
import '../transactions/transactions_table.dart';

/// `FinancialPosition` — UC-01's four figures, one query result
/// (`class-accounts.drawio`: *query result · UC-01's four figures*).
///
/// Field names are the four figures sequence-diagram message 7 names and
/// FR-1 lists: what I can spend now, what people owe me, what I owe, and the
/// net. Every field is an `int` counting minor units of `Settings.currency`
/// — never a double (NFR-2, `docs/enums.md`). Plain Dart, immutable, no
/// Flutter import.
class FinancialPosition {
  const FinancialPosition({
    required this.spendable,
    required this.owedToMe,
    required this.owedByMe,
    required this.net,
  });

  /// Σ balance(a) WHERE a.group = HOLDING (D4).
  final int spendable;

  /// Σ balance(a) WHERE a.group = RECEIVABLE (D4).
  final int owedToMe;

  /// Σ balance(a) WHERE a.group = PAYABLE (D4). Already negative — a
  /// payable account stores its amount signed (UC-02 D6, FR-4).
  final int owedByMe;

  /// spendable + owedToMe + owedByMe, summed in SQL over all groups (D4).
  final int net;
}

/// `AccountBalance` — one query result row: one account plus its derived
/// current amount (`class-accounts.drawio`: *query result · one account +
/// derived balance*).
///
/// The account is drift's generated `Account` row class (deliberately
/// omitted from the diagrams by decision — only hand-written classes get a
/// box); [balance] is D4's expression evaluated for it. Nothing here is ever
/// written back — NFR-2 forbids a stored balance.
class AccountBalance {
  const AccountBalance({required this.account, required this.balance});

  final Account account;

  /// Minor units of `Settings.currency`, derived at read time — never a
  /// double (NFR-2).
  final int balance;
}

/// `DebtProgress` — UC-10's two figures plus the settle flag, one query
/// result (`class-accounts.drawio`: *query result · UC-10 paid / remaining*).
///
/// Field names are what sequence-diagram messages 2 and 7 name: [paid] and
/// [remaining], plus [settled] — message 7's *"(settled)"*, which is how the
/// screen learns the tick landed, since the write returns nothing to it.
/// Every amount is an `int` counting minor units of `Settings.currency` —
/// never a double (NFR-2, `docs/enums.md`). Plain Dart, immutable, no
/// Flutter import. Both figures are derived at read time and never written
/// back (NFR-2) — `docs/enums.md`'s stated-non-members entry forbids storing
/// them alongside `opening_amount` and the ledger.
class DebtProgress {
  const DebtProgress({
    required this.paid,
    required this.remaining,
    required this.settled,
  });

  /// Σ t.amount WHERE t.kind = 'repayment' AND the row touches the account,
  /// either side (D4). Derived from UC-08's repayments — workbook step 2,
  /// sequence message 2, `seq-uc08-repayment.drawio`'s note.
  final int paid;

  /// ABS(balance(a)) — the outstanding amount as a magnitude (`decisions.md`
  /// 2026-08-19: *"a debt … its balance is the outstanding amount"*; D4).
  /// PAYABLE balances store signed-negative (UC-02 D6), hence the ABS.
  final int remaining;

  /// FR-11's tick — ISSUE-001 D8's flag, not a lifecycle (`docs/statuses.md`).
  final bool settled;
}

/// `AccountDao` — queries and writes for accounts.
///
/// Reads: `watchPosition()` and `watchBalances()` (UC-01),
/// `watchDebtProgress(accountId)` (UC-10). Writes: `insert()` from UC-02,
/// `insertAdjustment()` from UC-03, `setSettled(accountId)` from UC-10, and
/// `update()`/`delete()` from UC-02B — closing `pm/findings.md` F14, the one
/// entity FR-18 was left unsatisfied for.
///
/// **The join below is written here, inside `AccountDao`, against the
/// `Transactions` table** — ISSUE-005 D1 (`context/index/decisions.md`
/// 2026-08-20): modules reach each other's data by SQL join, never by calling
/// another module's DAO. `TransactionDao` is not imported and no Dart-side
/// stitching in Dart happens; the sums are SQLite's, so each figure has
/// exactly one source (NFR-2). **The ledger is written here too** —
/// `insertAdjustment()` is this module's first write into `Transactions`
/// (UC-03 plan D1, D3), the same ISSUE-005 D1 licence read the other
/// direction: `AccountDao` reaches `Transactions` directly rather than
/// calling `TransactionDao`.
///
/// **Not a `@DriftAccessor`/`DatabaseAccessor` subtype** — a plain
/// composition over `AppDatabase`, the shape every DAO in this project uses
/// (`context/index/decisions.md` 2026-08-21, UC-13 ruling 1).
///
/// The clock is injected rather than read from the system (the standing
/// discipline, `decisions.md` 2026-08-19) — the same constructor pattern
/// `BudgetDao` shipped — so `setSettled()`'s date stamp is testable.
class AccountDao {
  AccountDao(this._db, {this._clock = const Clock()});

  final AppDatabase _db;
  final Clock _clock;

  /// Message 3 on `seq-uc01-balance-sheet.drawio`.
  ///
  /// One watched query computing all four figures in SQL (D3, D4): each
  /// account's balance is its opening amount plus what entered it through
  /// `to_account_id` minus what left through `from_account_id`; the four
  /// figures are that expression grouped by `Account.group` plus their sum.
  ///
  /// The predicate references **only which sides a row touches** — no
  /// `kind` filter anywhere (D5: whichever encoding Q4 settles on for
  /// adjustments produces identical contributions to these sums), and no
  /// `to_account_id IS NULL` spending predicate (spending is UC-12's figure,
  /// not FR-1's).
  ///
  /// Enum literals arrive as bound variables holding `AccountGroup`'s stored
  /// text (`.textEnum` stores `.name`) rather than string literals inlined
  /// into the SQL, so the enum's storage stays defined in exactly one place.
  Stream<FinancialPosition> watchPosition() {
    return _db
        .customSelect(
          '''
          WITH balances AS (
            SELECT
              accounts."group" AS group_name,
              accounts.opening_amount
                + COALESCE((SELECT SUM(t.amount) FROM transactions t
                            WHERE t.to_account_id = accounts.account_id), 0)
                - COALESCE((SELECT SUM(t.amount) FROM transactions t
                            WHERE t.from_account_id = accounts.account_id), 0)
                AS balance
            FROM accounts
            WHERE NOT accounts.deleted
          )
          SELECT
            COALESCE(SUM(CASE WHEN group_name = ? THEN balance ELSE 0 END), 0)
              AS spendable,
            COALESCE(SUM(CASE WHEN group_name = ? THEN balance ELSE 0 END), 0)
              AS owed_to_me,
            COALESCE(SUM(CASE WHEN group_name = ? THEN balance ELSE 0 END), 0)
              AS owed_by_me,
            COALESCE(SUM(balance), 0) AS net
          FROM balances
          ''',
          variables: [
            Variable.withString(AccountGroup.HOLDING.name),
            Variable.withString(AccountGroup.RECEIVABLE.name),
            Variable.withString(AccountGroup.PAYABLE.name),
          ],
          readsFrom: {_db.accounts, _db.transactions},
        )
        .watchSingle()
        .map(
          (row) => FinancialPosition(
            spendable: row.read<int>('spendable'),
            owedToMe: row.read<int>('owed_to_me'),
            owedByMe: row.read<int>('owed_by_me'),
            net: row.read<int>('net'),
          ),
        );
  }

  /// Message 9 on `seq-uc01-balance-sheet.drawio`: one row per account, D4's
  /// per-account expression. Ordered by insertion id so emissions are
  /// deterministic (the diagram draws no ordering; this is the neutral one).
  Stream<List<AccountBalance>> watchBalances() {
    return _db
        .customSelect(
          '''
          SELECT
            accounts.account_id     AS account_id,
            accounts.name           AS account_name,
            accounts."group"        AS group_name,
            accounts.opening_amount AS opening_amount,
            accounts.settled        AS settled,
            accounts.settled_at     AS settled_at,
            accounts.deleted        AS deleted,
            accounts.deleted_at     AS deleted_at,
            accounts.opening_amount
              + COALESCE((SELECT SUM(t.amount) FROM transactions t
                          WHERE t.to_account_id = accounts.account_id), 0)
              - COALESCE((SELECT SUM(t.amount) FROM transactions t
                          WHERE t.from_account_id = accounts.account_id), 0)
              AS balance
          FROM accounts
          WHERE NOT accounts.deleted
          ORDER BY accounts.account_id
          ''',
          readsFrom: {_db.accounts, _db.transactions},
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              AccountBalance(
                account: Account(
                  accountId: row.read<int>('account_id'),
                  name: row.read<String>('account_name'),
                  group: _groupNamed(row.read<String>('group_name')),
                  openingAmount: row.read<int>('opening_amount'),
                  settled: row.read<bool>('settled'),
                  settledAt: row.readNullable<DateTime>('settled_at'),
                  deleted: row.read<bool>('deleted'),
                  deletedAt: row.readNullable<DateTime>('deleted_at'),
                ),
                balance: row.read<int>('balance'),
              ),
          ],
        );
  }

  /// Inverse of drift's `.textEnum` storage: `Account.group` stores
  /// `enum.name` as text (`accounts_table.dart`, `docs/enums.md`).
  static AccountGroup _groupNamed(String name) =>
      AccountGroup.values.firstWhere((value) => value.name == name);

  /// Messages 2 and 7 on `seq-uc10-debt-progress.drawio`:
  /// `watchDebtProgress(accountId)` — one watched query computing D4's two
  /// figures in SQL for one debt account.
  ///
  /// `paid` sums only `kind = 'repayment'` rows touching either side of the
  /// account (D4's citation-backed definition — workbook step 2 and sequence
  /// message 2 both name repayments; the filter is also what removes Q4's
  /// only channel into this figure, D5). The balance half carries **no**
  /// `kind` filter and no spending predicate — exactly UC-01's shipped
  /// sides-based expression, shown as a magnitude via ABS because FR-11 asks
  /// "how much is left" and PAYABLE rows store signed-negative (D4).
  ///
  /// The enum literal arrives as a bound variable holding
  /// `TransactionKind`'s stored text (`.textEnum` stores `.name`), the way
  /// [watchPosition] handles `AccountGroup` values.
  ///
  /// **Deliberately not filtered by `NOT deleted`** (UC02B D4, corrected at
  /// review): unlike [watchPosition]/[watchBalances], which aggregate
  /// *across* accounts and simply drop a deleted one from the sum, this
  /// method is keyed to one already-selected `accountId` via
  /// [`watchSingle`], which throws on zero rows. Filtering here would turn
  /// "the account you're viewing was deleted" into a crash instead of a
  /// still-resolvable historical figure — the same "history keeps
  /// displaying" principle `TransactionDao.watchAll()` follows for UC-09.
  Stream<DebtProgress> watchDebtProgress(int accountId) {
    return _db
        .customSelect(
          '''
          SELECT
            accounts.settled AS settled,
            COALESCE((SELECT SUM(t.amount) FROM transactions t
                      WHERE t.kind = ?
                        AND (t.from_account_id = accounts.account_id
                             OR t.to_account_id = accounts.account_id)), 0)
              AS paid,
            ABS(accounts.opening_amount
                + COALESCE((SELECT SUM(t.amount) FROM transactions t
                            WHERE t.to_account_id = accounts.account_id), 0)
                - COALESCE((SELECT SUM(t.amount) FROM transactions t
                            WHERE t.from_account_id = accounts.account_id), 0))
              AS remaining
          FROM accounts
          WHERE accounts.account_id = ?
          ''',
          variables: [
            Variable.withString(TransactionKind.repayment.name),
            Variable.withInt(accountId),
          ],
          readsFrom: {_db.accounts, _db.transactions},
        )
        .watchSingle()
        .map(
          (row) => DebtProgress(
            paid: row.read<int>('paid'),
            remaining: row.read<int>('remaining'),
            settled: row.read<bool>('settled'),
          ),
        );
  }

  /// Message 5 on `seq-uc10-debt-progress.drawio`: `setSettled(accountId)` —
  /// ISSUE-001 D8's flag plus date. One update: `settled = true`, `settled_at`
  /// stamped from the injected clock (D6). Returns `Future<void>`; no result
  /// reaches the screen — the read path re-emits with `settled: true`
  /// instead (message 7, `riverpod.md`'s read/write asymmetry).
  ///
  /// One move on the flag, false→true (`docs/enums.md` stated non-members) —
  /// there is deliberately no un-settle method on any diagram. Calling it
  /// twice is harmless (idempotent update, refreshed date), which NFR-4
  /// prefers to any guard.
  Future<void> setSettled(int accountId) async {
    await (_db.update(
      _db.accounts,
    )..where((row) => row.accountId.equals(accountId))).write(
      AccountsCompanion(
        settled: const Value(true),
        settledAt: Value(_clock.today()),
      ),
    );
  }

  /// Message 3 on `seq-uc02-add-account.drawio`: `insert(account)`.
  ///
  /// Returns the new account id because drift's `insert()` gives it back for
  /// free; nobody consumes it — the write path never returns its result to
  /// the UI (`riverpod.md`, the read/write asymmetry).
  Future<int> insert(AccountsCompanion account) {
    return _db.into(_db.accounts).insert(account);
  }

  /// Message 10 on `seq-uc03-adjust-account.drawio`: the diagram's
  /// `insert(kind=adjustment, account, diff)`, renamed because Dart has no
  /// overloading and [insert] already exists (UC-03 plan D2).
  ///
  /// Nothing above this method reads the current balance (messages 9→10 draw
  /// no read between them) — `AccountDao` derives it itself, inside one
  /// drift transaction, from the same expression [watchBalances] reads:
  /// `opening_amount` plus the signed movement sum over `Transactions` (D3).
  /// `diff = targetAmount − current` is then written as one `Transactions`
  /// row: `kind = adjustment`, `toAccountId = accountId` always,
  /// `fromAccountId` always null, `amount = diff` — signed, negative for a
  /// downward correction (Q4's resolved encoding, `context/index/
  /// decisions.md` 2026-08-23 "Adjustment encodes as fixed side + signed
  /// amount"). `adjustment` is the **only** `TransactionKind` whose `amount`
  /// may be negative.
  ///
  /// Unconditional (D4): a target equal to the current amount still writes a
  /// row with `amount = 0` — no guard skips a zero-diff correction.
  /// `occurredOn` comes from the injected `Clock`, not `DateTime.now()` (D7).
  ///
  /// Returns `Future<void>`; message 13 is `ok` and nothing reaches the
  /// screen — the corrected balance arrives on the read path instead
  /// (`riverpod.md`, the read/write asymmetry).
  Future<void> insertAdjustment({
    required int accountId,
    required int targetAmount,
  }) {
    return _db.transaction(() async {
      final row = await _db
          .customSelect(
            '''
            SELECT
              accounts.opening_amount
                + COALESCE((SELECT SUM(t.amount) FROM transactions t
                            WHERE t.to_account_id = accounts.account_id), 0)
                - COALESCE((SELECT SUM(t.amount) FROM transactions t
                            WHERE t.from_account_id = accounts.account_id), 0)
                AS current_amount
            FROM accounts
            WHERE accounts.account_id = ?
            ''',
            variables: [Variable.withInt(accountId)],
            readsFrom: {_db.accounts, _db.transactions},
          )
          .getSingle();
      final diff = targetAmount - row.read<int>('current_amount');

      await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              kind: TransactionKind.adjustment,
              amount: diff,
              occurredOn: _clock.today(),
              toAccountId: Value(accountId),
            ),
          );
    });
  }

  /// Message 10 on `seq-uc02b-edit-account.drawio`: `update(accountId, name,
  /// group)` — `name` and `group` only, never `opening_amount` (UC02B plan
  /// D3; correcting what an account holds is UC-03's `insertAdjustment()`,
  /// unchanged by this method).
  ///
  /// Returns `Future<void>`; message 13 is `ok` and nothing reaches the
  /// screen — the renamed/regrouped account arrives on the read path once
  /// `accountBalancesProvider` re-emits (`riverpod.md`, the read/write
  /// asymmetry).
  Future<void> update({
    required int accountId,
    required String name,
    required AccountGroup group,
  }) async {
    await (_db.update(_db.accounts)
          ..where((row) => row.accountId.equals(accountId)))
        .write(AccountsCompanion(name: Value(name), group: Value(group)));
  }

  /// Message 16 on `seq-uc02b-edit-account.drawio`: `delete(accountId)` — a
  /// **soft** delete (UC02B plan D2, `context/index/decisions.md`
  /// 2026-08-23 Q3): `deleted = true`, `deleted_at` stamped from the
  /// injected clock. Never `DELETE FROM Accounts` — the row survives so
  /// every transaction that ever referenced it keeps a real row to resolve
  /// against (UC-09's list stays correct).
  ///
  /// Cannot fail: no row is removed, so no foreign key can be violated and
  /// no guard is needed (NFR-4). Deleting an already-deleted account is
  /// idempotent — it re-writes the same flag with a fresh timestamp,
  /// harmlessly.
  Future<void> delete({required int accountId}) async {
    await (_db.update(
      _db.accounts,
    )..where((row) => row.accountId.equals(accountId))).write(
      AccountsCompanion(
        deleted: const Value(true),
        deletedAt: Value(_clock.today()),
      ),
    );
  }
}
