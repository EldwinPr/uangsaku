import 'package:drift/drift.dart';

import '../accounts/accounts_table.dart';
import '../database/app_database.dart';

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

/// `AccountDao` — queries and writes for accounts.
///
/// Reads: `watchPosition()` and `watchBalances()` (UC-01, this issue's
/// addition). Writes: `insert()` from UC-02. `watchDebtProgress()` remains
/// UC-10's and is deliberately absent, as `update()` / `setSettled()` remain
/// UC-02B / UC-10's (`pm/findings.md` F14).
///
/// **The join below is written here, inside `AccountDao`, against the
/// `Transactions` table** — ISSUE-005 D1 (`context/index/decisions.md`
/// 2026-08-20): modules reach each other's data by SQL join, never by calling
/// another module's DAO. `TransactionDao` is not imported and no Dart-side
/// stitching in Dart happens; the sums are SQLite's, so each figure has
/// exactly one source (NFR-2). The ledger is **read** here and never
/// **written** — the first write to `Transactions` belongs to UC-03/UC-04
/// (D6).
///
/// **Not a `@DriftAccessor`/`DatabaseAccessor` subtype** — a plain
/// composition over `AppDatabase`, the shape every DAO in this project uses
/// (`context/index/decisions.md` 2026-08-21, UC-13 ruling 1).
class AccountDao {
  AccountDao(this._db);

  final AppDatabase _db;

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
            accounts.opening_amount
              + COALESCE((SELECT SUM(t.amount) FROM transactions t
                          WHERE t.to_account_id = accounts.account_id), 0)
              - COALESCE((SELECT SUM(t.amount) FROM transactions t
                          WHERE t.from_account_id = accounts.account_id), 0)
              AS balance
          FROM accounts
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

  /// Message 3 on `seq-uc02-add-account.drawio`: `insert(account)`.
  ///
  /// Returns the new account id because drift's `insert()` gives it back for
  /// free; nobody consumes it — the write path never returns its result to
  /// the UI (`riverpod.md`, the read/write asymmetry).
  Future<int> insert(AccountsCompanion account) {
    return _db.into(_db.accounts).insert(account);
  }
}
